module namespace compile = 'http://www.andrewsales.com/ns/xqs-compile';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';  
  
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

declare variable $compile:INSTANCE_PARAM := '$Q{"http://www.andrewsales.com/ns/xqs"}doc';

(:~ Compile a schema.
 : @param schema the schema to compile
 : @param phase the active phase, if any
 : @return the compiled schema
 :)
declare function compile:schema($schema as element(sch:schema), $phase as xs:string?)
{
  let $active-phase := context:get-active-phase($schema, $phase)
  let $active-patterns := context:get-active-patterns($schema, $active-phase)
  return
  (
    compile:prolog($schema, $active-phase),
    'declare variable ' || $compile:INSTANCE_PARAM || ' as xs:anyURI external;',
    $active-patterns ! compile:pattern(.),
    'declare function local:schema($doc){' ||
    string-join(
      for $pattern in $active-patterns 
      return 'local:pattern-'|| compile:function-id($pattern) ||'()',
      ','
    ) ||
    '}; local:schema(' || $compile:INSTANCE_PARAM || ')'
  )
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
    </svrl:active-pattern>),
    (for $rule in $pattern/sch:rule 
    return ', local:pattern-' || $function-id || '-rule-' || 
    compile:function-id($rule) || '()') ||
  '};
'),
  $pattern/sch:rule ! compile:rule(.)
};

declare function compile:rule($rule as element(sch:rule))
{
  'declare function local:pattern-' || compile:function-id($rule/..) || 
  '-rule-' || compile:function-id($rule) || '(){' ||
  string-join(util:local-variable-decls($rule/sch:let), ' ') ||
    (if($rule/sch:let) then ' return ' else ()) ||
    string-join($rule/(sch:assert|sch:report) ! compile:assertion(.), ',') ||
  '};
'
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
  'if(' || $assert/../@context || '[' || $assert/@test || ']) then () else ' ||
  serialize(<svrl:failed-assert></svrl:failed-assert>)
};

declare function compile:report($report as element())
{
  'if(' || $report/../@context || '[' || $report/@test || ']) then ' ||
  serialize(<svrl:successful-report></svrl:successful-report>) || 'else()'
};

declare %private function compile:pattern-variables($variables as element(sch:let)*)
{
  for $var in $variables 
  return 'let $' || $var/@name || ' := ' || 
  (if($var/@value) then '/(' || $var/@value || ')' else serialize($var/*))
};

declare %private function compile:function-id($element as element())
{
  if($element/@id) then $element/@id 
  else count(
    $element/preceding-sibling::sch:*[local-name() eq $element/local-name()]
  ) + 1
};