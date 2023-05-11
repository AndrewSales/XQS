module namespace compile = 'http://www.andrewsales.com/ns/xqs-compile';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';  
  
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

declare function compile:schema($schema as element(sch:schema), $phase as xs:string?)
{
  let $active-phase := context:get-active-phase($schema, $phase)
  let $active-patterns := context:get-active-patterns($schema, $active-phase)
  return
  (
    compile:prolog($schema, $active-phase),
    $active-patterns ! compile:pattern(.),
    string-join(
      for $pattern in $active-patterns 
      return 'local:pattern-'||$pattern/@id||'()',
      ','
    )
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
  'declare function local:pattern-' || $pattern/@id || '(){' ||
  string-join(compile:pattern-variable($pattern/sch:let), ' ') ||
    (if($pattern/sch:let) then 'return' else ()) ||
    serialize(<svrl:active-pattern>
    {$pattern/(@id, @documents, @name, @role)}
    </svrl:active-pattern>),
    (for $rule in $pattern/sch:rule 
    return ', local:pattern-' || $pattern/@id || '-rule-' || $rule/@id || '()') ||
  '};
',
  $pattern/sch:rule ! compile:rule(.)
};

declare function compile:rule($rule as element(sch:rule))
{
  'declare function local:pattern-' || $rule/../@id || '-rule-' || $rule/@id || '(){' ||
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

declare %private function compile:pattern-variable($var as element(sch:let))
{
  'let $' || $var/@name || ' := ' || 
  (if($var/@value) then '/(' || $var/@value || ')' else serialize($var/*))
};