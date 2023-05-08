(:~ 
 : Library for evaluating schema assertions. 
 :)

module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate';

import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace output = 'http://www.andrewsales.com/ns/xqs-output' at
  'svrl.xqm';  
import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

(:~ Evaluates the schema to produce SVRL output.
 : @param instance the document instance
 : @param schema the Schematron schema
 : @param phase the active phase
 :)
declare function eval:schema(
  $instance as node(),
  $schema as element(sch:schema),
  $phase as xs:string?
)
{
  let $context as map(*) := context:get-context($instance, $schema, $phase)
  
  return 
  <svrl:schematron-output>
  {output:schema-title($schema/sch:title)}
  {$schema/@schemaVersion}
  {if($context?phase) then attribute{'phase'}{$context?phase/@id}}
  {output:namespace-decls-as-svrl($schema/sch:ns)}
  {$context?patterns ! eval:pattern(., $context)}
  </svrl:schematron-output>
};

(:~ Evaluates a pattern.
 : N.B. this implementation evaluates *all* pattern variables as global variables.
 : @param pattern the pattern to evaluate
 : @param context the validation context
 :)
declare function eval:pattern(
  $pattern as element(sch:pattern),
  $context as map(*)
)
{
  let $prolog := util:make-query-prolog($context)
    
  (:evaluate pattern variables against global context:)
  let $globals as map(*) := context:evaluate-pattern-variables(
        $pattern/sch:let,
        $context?instance,
        $context?ns-decls,
        $pattern/../sch:ns,
        $context?globals
      )
  (: let $_ := trace('PATTERN $globals='||serialize($globals, map{'method':'adaptive'})) :)
  let $context := map:put($context, 'globals', $globals)
  
  (: let $_ := trace('PATTERN '||$pattern/@id||' prolog='||$prolog) :)
  (: let $_ := trace('PATTERN $bindings '||serialize($context?globals, map{'method':'adaptive'})) :)
    
  return (
    <svrl:active-pattern>
    {$pattern/(@id, @documents, @name, @role)}
    </svrl:active-pattern>, 
    eval:rules(
      $pattern/sch:rule, 
      util:make-query-prolog($context), 
      $context
    )
  )
};

(:~ Evaluate rules, stopping once one fires.
 : (Necessitated by ISO2020 6.5.)
 : @param rules the rules to evaluate
 : @param prolog the query prolog consisting of any variable and namespace declarations
 : @param context the validation context
 :)
declare function eval:rules(
  $rules as element(sch:rule)*,
  $prolog as xs:string?,
  $context as map(*)
)
as element()*
{
  if(empty($rules))
  then ()
  else
    (: let $_ := trace('[1]RULE prolog='||$prolog) :)
    let $result := eval:rule(head($rules), $prolog, $context)
    return if($result)
    then $result
    else eval:rules(tail($rules), $prolog, $context)
};

(:~ Evaluates a rule.
 : @param rule the rule to evaluate
 : @param prolog the query prolog consisting of any variable and namespace declarations
 : @param context the validation context
 :)
declare function eval:rule(
  $rule as element(sch:rule),
  $prolog as xs:string?,
  $context as map(*)
)
as element()*
{
  let $query := string-join(
      ($prolog, util:local-variable-decls($rule/sch:let), 
      if($rule/sch:let) then 'return ' else '', $rule/@context),
      ' '
    )
  (: let $_ := trace('[2]RULE query='||$query) :)
  let $rule-context := xquery:eval(
    $query,
    map:merge((map{'':$context?instance}, $context?globals)),
    map{'pass':'true'}	(:report exception details:)
  )
  return 
  if($rule-context)
  then(
    <svrl:fired-rule>{$rule/(@id, @name, @context, @role, @flag, @document)}</svrl:fired-rule>,
    eval:assertions($rule, $prolog, $rule-context, $context)
  )
  else ()
};

(:~ Evaluates assertions within a rule.
 : @param rule the containing rule
 : @param prolog the query prolog consisting of any variable and namespace declarations
 : @param rule-context the rule context
 : @param context the validation context
 :)
declare function eval:assertions(
  $rule as element(sch:rule),
  $prolog as xs:string?,
  $rule-context as node()+,
  $validation-context as map(*)
)
as element()*
{
  let $prolog := $prolog || util:local-variable-decls($rule/sch:let)
  (: let $_ := trace('[3]ASSERTION prolog='||$prolog) :)
  for $context in $rule-context
    let $prolog := $prolog || (if($rule/sch:let) then ' return ' else '')
    (: let $_ := trace('[4]ASSERTION query='||$prolog) :)
    return $rule/(sch:assert|sch:report) 
    ! 
    eval:assertion(
      ., 
      $prolog,
      $context,
      $validation-context
    )
};

(:~ Evaluates an assertion.
 : @param assertion the assertion to evaluate
 : @param prolog the query prolog consisting of any variable and namespace declarations
 : @param rule-context the rule context
 : @param context the validation context
 :)
declare function eval:assertion(
  $assertion as element(),
  $prolog as xs:string?,
  $rule-context as node(),
  $context as map(*)
)
{
  let $result := xquery:eval(
    $prolog || $assertion/@test,
    map:merge((map{'':$rule-context}, $context?globals)),
    map{'pass':'true'}
  )
  return
  typeswitch($assertion)
    case element(sch:assert)
      return if($result) then () 
        else output:assertion-message($assertion, $prolog, $rule-context, $context)
    case element(sch:report)
      return if($result) 
        then output:assertion-message($assertion, $prolog, $rule-context, $context) 
        else ()
  default return error(
    xs:QName('eval:invalid-assertion-element'), 
    'invalid assertion element: '||$assertion/name()
  )
};