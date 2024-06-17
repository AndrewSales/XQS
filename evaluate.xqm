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

declare namespace xqy = 'http://www.w3.org/2012/xquery';  
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

(:~ Evaluates the schema to produce SVRL output, applying the processing options
 : specified.
 : @param instance the document instance
 : @param schema the Schematron schema
 : @param phase the active phase
 : @param options map of processing options
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
  <svrl:active-pattern name='XQS Syntax Error Summary' documents='{$schema/base-uri()}'/>
  {$schema/xqy:function ! utils:parse-function(., $options)[self::svrl:*]}
  {for $phase in ($schema/sch:phase/@id, '')
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

  let $rules := $pattern/sch:rule
  return (
    if($context?dry-run eq 'true')
    then 
    ($context?globals?*[self::svrl:*], eval:all-rules($rules, $context))
    else (
      <svrl:active-pattern>
      {$pattern/(@id, @name, @role), 
      if($pattern/@documents) then attribute{'documents'}{$context?instance ! base-uri(.)} else()}
      </svrl:active-pattern>, 
      eval:rules($rules, $context)
    )
  )
};

(:~ Evaluates all the rules in a pattern.
 : Initially added for use in dry-run mode, to check for syntax errors.
 : N.B. we don't need to map the instance each time for this purpose, since we 
 : are not evaluating @documents, but this approach could be used for 
 : evaluating sch:rule-set (see https://github.com/AndrewSales/XQS/tree/%234).
 :)
declare function eval:all-rules(
  $rules as element(sch:rule)*,
  $context as map(*)
)
as element()*
{
  $context?instance 
  ! 
  (for $rule in $rules
  return
  eval:rule(
    $rule, 
    utils:make-query-prolog($context),
    map:put($context, 'instance', .)
  ))
};

declare function eval:rules(
  $rules as element(sch:rule)*,
  $context as map(*)
)
as element()*
{
  $context?instance 
  ! 
  eval:rules(
    $rules, 
    utils:make-query-prolog($context),
    map:put($context, 'instance', .)
  )
};

(:~ Evaluate rules, only further processing those whose context has not already   : been matched.
 : @see ISO2020 6.5.
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
    let $rule := head($rules)
    let $rule-context := eval:rule-context($rule, $prolog, $context)
    (: let $_ := trace('context=' || serialize($context, map{'method':'adaptive'})) :)
    return 
    (
      eval:process-rule($rule, $prolog, $rule-context, $context),
      eval:rules(
        tail($rules), 
        $prolog, 
        (:update the matched contexts each time:)
        map:put(
          $context,
          'matched',
          $context?matched | $rule-context
        )
      )
    )
};

(:~ Evaluate the rule context.
 : @param rule the rule whose context is to be evaluated
 : @param prolog the query prolog consisting of any variable and namespace declarations
 : @param context the validation context
 : @return the rule context
 :)
declare function eval:rule-context(
  $rule as element(sch:rule),
  $prolog as xs:string?,
  $context as map(*)
) as node()*
{
  let $_ := utils:check-duplicate-variable-names($rule/sch:let)
  let $query := string-join(
      ($prolog, utils:local-variable-decls($rule/sch:let),
      if($rule/sch:let) then 'return ' else '', $rule/@context),
      ' '
    )
  (: let $_ := trace('[2]RULE query='||$query) :)
  return utils:eval(
    $query => utils:escape(),
    map:merge((map{'':$context?instance}, $context?globals)),
    map{'dry-run':$context?dry-run},
    $rule/@context
  )
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
  let $rule-context := eval:rule-context($rule, $prolog, $context)
  return 
  if($rule-context)
  then
    if($context?dry-run eq 'true')
    then 
    (
      let $variable-errors := utils:evaluate-rule-variables(
        $rule/sch:let,
        $prolog,
        map:merge((map{'':$context?instance}, $context?globals)),
        $context,
        ()
      )
      return 
      $variable-errors[self::svrl:*],
      $rule-context[self::svrl:*],
      eval:assertions($rule, $prolog, <_/>, $context)	(:pass dummy context node:)
    )
    else eval:process-rule($rule, $prolog, $rule-context, $context)
  else ()
};

(:~ Process a rule.
 : @param rule the rule to process
 : @param prolog the query prolog consisting of any variable and namespace declarations
 : @param rule-context the evaluated rule context
 : @param context the validation context :)
declare function eval:process-rule(
  $rule as element(sch:rule),
  $prolog as xs:string?,
  $rule-context as node()*,
  $context as map(*)
)
{
  if(exists($rule-context) and empty($rule-context intersect $context?matched))
  then
  (<svrl:fired-rule>
      {$rule/(@id, @name, @context, @role, @flag),
      if($rule/../@documents) then attribute{'document'}{$context?instance/base-uri()} else ()}
      </svrl:fired-rule>,
      eval:assertions($rule, $prolog, $rule-context, $context))
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
    map{'dry-run':$context?dry-run},
    $assertion/@test
  )
  return
  if($context?dry-run eq 'true')
  then 
  (
    $result[self::svrl:*],
    output:assertion-message($assertion, $prolog, $rule-context, $context)
  )
  else
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
  
  let $dry-run as map(*) := map{'dry-run':$context?dry-run}
  
  (:add phase variables to context:)
  let $globals as map(*) := context:evaluate-root-context-variables(
        $phase/sch:let,
        $context?instance,
        $context?ns-decls,
        $phase/../sch:ns,
        $context?globals,
        $dry-run
      )
  let $context := map:put($context, 'globals', $globals)
    
  return  $context?patterns ! eval:pattern(., map:merge(($context, $dry-run)))
};