module namespace compile = 'http://www.andrewsales.com/ns/xqs-compile';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';  
import module namespace output = 'http://www.andrewsales.com/ns/xqs-output' at
  'svrl.xqm';    
  
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

declare variable $compile:INSTANCE_PARAM := '$Q{"http://www.andrewsales.com/ns/xqs"}uri';
declare variable $compile:INSTANCE_DOC := '$Q{"http://www.andrewsales.com/ns/xqs"}doc';
declare variable $compile:RULE_CONTEXT := '$Q{"http://www.andrewsales.com/ns/xqs"}context';
declare variable $compile:RESULT := '$Q{"http://www.andrewsales.com/ns/xqs"}result';

(:~ Compile a schema.
 : @param schema the schema to compile
 : @param phase the active phase, if any
 : @return the compiled schema
 :)
declare function compile:schema($schema as element(sch:schema), $phase as xs:string?)
as xs:string
{
  let $active-phase := context:get-active-phase($schema, $phase)
  let $active-patterns := context:get-active-patterns($schema, $active-phase)
  return string-join(
  (
    compile:prolog($schema, $active-phase),
    'declare variable ' || $compile:INSTANCE_PARAM || ' as xs:anyURI external;
    declare variable ' || $compile:INSTANCE_DOC || ' := doc(' || $compile:INSTANCE_PARAM || ');',
    $active-patterns ! compile:pattern(.),
    'declare function local:schema(){' ||
    serialize(<svrl:schematron-output>
      {output:schema-title($schema/sch:title)}
      {$schema/@schemaVersion}
      {if($phase) then attribute{'phase'}{$phase/@id}}
      {output:namespace-decls-as-svrl($schema/sch:ns)}
    {'{' || string-join(
      for $pattern in $active-patterns 
      return 'local:pattern-'|| compile:function-id($pattern) ||'()',
      ','
    ) || '}'} </svrl:schematron-output>) ||
    '}; local:schema()'
  ))
};

declare function compile:prolog($schema as element(sch:schema), $phase)
{
  $schema/sch:ns ! context:make-ns-decls(.) ||
  context:get-global-variables($schema, $phase)
  => util:global-variable-decls()
};

declare function compile:pattern($pattern as element(sch:pattern))
{
  let $function-id := compile:function-id($pattern)
  return
  ('declare function local:pattern-' || $function-id || '(){' ||
  string-join(compile:pattern-variables($pattern/sch:let), ' ') ||
    (if($pattern/sch:let) then ' return ' else ()) ||
    serialize(<svrl:active-pattern>
    {$pattern/(@id, @documents, @name, @role)}
    </svrl:active-pattern>) || ',',
    if(count($pattern/sch:rule) = 1)
    then ' local:pattern-' || $function-id || '-rule-' || 
      compile:function-id($pattern/sch:rule) || '()'
    else
    string-join(for $rule in $pattern/sch:rule 
    return ' local:pattern-' || $function-id || '-rule-' || 
    compile:function-id($rule) || '()', ','),
  '};
'),
  $pattern/sch:rule ! compile:rule(.)
};

declare function compile:rule($rule as element(sch:rule))
{
  let $function-name := 'local:pattern-' || compile:function-id($rule/..) || 
  '-rule-' || compile:function-id($rule)
  let $assertions as element()+ := $rule/(sch:assert|sch:report)
  return
  'declare function ' || $function-name || '(){' ||
  string-join(util:local-variable-decls($rule/sch:let), ' ') ||
    (if($rule/sch:let) then ' return ' else ()) ||
    'let ' || $compile:RULE_CONTEXT || ':= ' ||
    $compile:INSTANCE_DOC || '/(' || $rule/@context || 
') return if(' || $compile:RULE_CONTEXT || ') then (' || 
  serialize(<svrl:fired-rule/>) || ', ' ||
  string-join(
    for $assertion in $assertions
    return $function-name || '-' || local-name($assertion) || '-' || 
    compile:function-id($assertion) || '(' || $compile:RULE_CONTEXT || ')', 
    ','
  ) || ') else ()};' || $assertions ! compile:assertion(.)
};

declare function compile:assertion($assertion as element())
{
  typeswitch($assertion)
    case element(sch:assert) return compile:assert($assertion)
    case element(sch:report) return compile:report($assertion)
    default return error()
};

declare function compile:assert($assert as element())
{
  'declare function local:pattern-' || compile:function-id($assert/../..) || 
  '-rule-' || compile:function-id($assert/..) || '-assert-' 
  || compile:function-id($assert) || '(' || $compile:RULE_CONTEXT || '){' ||
  string-join(util:local-variable-decls($assert/../sch:let), ' ') ||
  'let ' || $compile:RESULT || ':= ' || $compile:RULE_CONTEXT || 
  '/(' || $assert/@test || ') return
  if(' || $compile:RESULT || ') then () else ' ||
  serialize(<svrl:failed-assert></svrl:failed-assert>) || '};'
};

declare function compile:report($report as element())
{
  'declare function local:pattern-' || compile:function-id($report/../..) || 
  '-rule-' || compile:function-id($report/..) || '-report-' 
  || compile:function-id($report) || '($compile:RULE_CONTEXT){' ||
  string-join(util:local-variable-decls($report/../sch:let), ' ') ||
  'let ' || $compile:RESULT || ':= ' || $compile:RULE_CONTEXT || 
  '/(' || $report/@test || ') return
  if(' || $compile:RESULT || ' then ' ||
  serialize(<svrl:successful-report></svrl:successful-report>) || ' else ()};'
};

declare %private function compile:pattern-variables($variables as element(sch:let)*)
{
  for $var in $variables 
  return 'let $' || $var/@name || ' := ' || 
  (if($var/@value) then $compile:INSTANCE_DOC || '/(' || $var/@value || ')' 
  else serialize($var/*))
};

declare %private function compile:function-id($element as element())
{
  if($element/@id) then $element/@id 
  else count(
    $element/preceding-sibling::sch:*[local-name() eq $element/local-name()]
  ) + 1
};