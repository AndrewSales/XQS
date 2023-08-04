(:~ 
 : Library for evaluating schema assertions. 
 :)

module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate';

import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace output = 'http://www.andrewsales.com/ns/xqs-output' at
  'svrl.xqm';  
import module namespace utils = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

(:~ Evaluates the schema to produce SVRL output.
 : @param instance the document instance
 : @param schema the Schematron schema
 : @param phase the active phase
 : @param options map of options
 :)
declare function eval:schema(
  $instance as node(),
  $schema as element(sch:schema),
  $phase as xs:string?,
  $options as map(*)?
)
{
  if($options?dry-run eq 'true')
  then  
  <svrl:schematron-output phase='#ALL'>
  {output:schema-title($schema/sch:title)}
  {$schema/@schemaVersion}
  {output:namespace-decls-as-svrl($schema/sch:ns)}
  {for $phase in ($schema/sch:phase/@id/data(), '')
  let $context as map(*) := context:get-context($instance, $schema, $phase, $options)
  return eval:phase($context)}
  </svrl:schematron-output>
  else
  eval:schema($instance, $schema, $phase)
};

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
  let $context as map(*) := context:get-context($instance, $schema, $phase, map{})
  
  return 
  <svrl:schematron-output>
  {output:schema-title($schema/sch:title)}
  {$schema/@schemaVersion}
  {if($context?phase) then attribute{'phase'}{$context?phase/@id} else ()}
  {output:namespace-decls-as-svrl($schema/sch:ns)}
  {eval:phase($context)}
  </svrl:schematron-output>
};

(:~ Evaluates a pattern.
 : @param pattern the pattern to evaluate
 : @param context the validation context
 :)
declare function eval:pattern(
  $pattern as element(sch:pattern),
  $context as map(*)
)
{
  let $_ := utils:check-duplicate-variable-names($pattern/sch:let)
  
  (:update context in light of @documents:)
  let $context as map(*) := context:evaluate-pattern-documents($pattern/@documents, $context)
  
  (:evaluate pattern variables against global context:)
  let $globals as map(*) := context:evaluate-root-context-variables(
        $pattern/sch:let,
        $context?instance,
        $context?ns-decls,
        $pattern/../sch:ns,
        $context?globals,
        map{'dry-run':$context?dry-run}
      )
  (: let $_ := trace('PATTERN $globals='||serialize($globals, map{'method':'adaptive'})) :)
  let $context := map:put($context, 'globals', $globals)
  
  (: let $_ := trace('instance='||$context?instance=>serialize()|| ' (' || count($context?instance) || ')') :)
  
  (: let $_ := trace('PATTERN '||$pattern/@id||' prolog='||$prolog) :)
  (: let $_ := trace('PATTERN $bindings '||serialize($context?globals, map{'method':'adaptive'})) :)

  return	(:TODO active-pattern/@name:)(
    <svrl:active-pattern>
    {$pattern/(@id, @name, @role), 
    if($pattern/@documents) then attribute{'documents'}{$context?instance ! base-uri(.)} else()}
    </svrl:active-pattern>, 
    $context?instance ! eval:rules(
      $pattern/sch:rule, 
      utils:make-query-prolog($context),
      map:put($context, 'instance', .)
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
  let $_ := utils:check-duplicate-variable-names($rule/sch:let)
  let $query := string-join(
      ($prolog, utils:local-variable-decls($rule/sch:let),
      if($rule/sch:let) then 'return ' else '', $rule/@context),
      ' '
    )
  (: let $_ := trace('[2]RULE query='||$query) :)
  let $rule-context := utils:eval(
    $query => utils:escape(),
    map:merge((map{'':$context?instance}, $context?globals)),
    map{'pass':'true', 'dry-run':$context?dry-run}
  )
  return 
  if($rule-context)
  then(
    <svrl:fired-rule>
    {$rule/(@id, @name, @context, @role, @flag),
    if($rule/../@documents) then attribute{'document'}{$context?instance/base-uri()} else ()}
    </svrl:fired-rule>,
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
  let $prolog := $prolog || utils:local-variable-decls($rule/sch:let)
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
  let $result := utils:eval(
    $prolog || $assertion/@test => utils:escape(),
    map:merge((map{'':$rule-context}, $context?globals)),
    map{'pass':'true', 'dry-run':$context?dry-run}
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

declare function eval:phase($context as map(*))
{
  let $phase := $context?phase
  let $_ := utils:check-duplicate-variable-names($phase/sch:let)
  
  (:add phase variables to context:)
  let $globals as map(*) := context:evaluate-root-context-variables(
        $phase/sch:let,
        $context?instance,
        $context?ns-decls,
        $phase/../sch:ns,
        $context?globals,
        map{'dry-run':$context?dry-run}
      )
  let $context := map:put($context, 'globals', $globals)
  
  return  $context?patterns ! eval:pattern(., $context)
};