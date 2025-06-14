(:~
 : Dry-run utilities. 
 : The purpose of dry-run mode is to evaluate expressions in the schema, to check for
 : syntax errors that might otherwise only be identified at run-time.
 :)
 
module namespace dr = 'http://www.andrewsales.com/ns/xqs-dry-run';

import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate' at
  'evaluate.xqm';  
import module namespace output = 'http://www.andrewsales.com/ns/xqs-output' at
  'svrl.xqm';
import module namespace utils = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';  

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";  
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace xqy = 'http://www.w3.org/2012/xquery';

declare function dr:schema(
  $instance as node(),
  $schema as element(sch:schema),
  $options as map(*)?
)
{
<svrl:schematron-output phase='#ALL'>
  {output:schema-title($schema/sch:title)}
  {$schema/@schemaVersion}
  {output:namespace-decls-as-svrl($schema/sch:ns)}
  <svrl:active-pattern name='XQS Syntax Error Summary' documents='{$schema/base-uri()}'/>
  {$schema/xqy:function ! utils:parse-function(., $options)[self::svrl:*]}
  {for $phase in ($schema/sch:phase/@id, '')
  let $context as map(*) := context:get-context($instance, $schema, $options)
  return eval:phase($context)}
  </svrl:schematron-output>
};

declare function dr:pattern(
    $context as map(*),
    $rules as element(sch:rule)*
)
{
    ($context?globals?*[self::svrl:*], eval:all-rules($rules, $context))
};

declare function dr:rule(
  $rule as element(sch:rule),
  $prolog as xs:string?,
  $rule-context as node()*,
  $context as map(*)
)
{
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
};

declare function dr:assertion(
    $result as item()*,
    $assertion as element(),
    $prolog as xs:string?,
    $rule-context as node(),
    $context as map(*)
)
{
  (
    $result[self::svrl:*],
    output:assertion-message($assertion, $prolog, $rule-context, $context)
  )
};