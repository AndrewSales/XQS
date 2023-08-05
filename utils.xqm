(:~ Common utility functions. :)

module namespace utils = 'http://www.andrewsales.com/ns/xqs-utils';

declare namespace xqs = 'http://www.andrewsales.com/ns/xqs';
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

(:~ Builds the string of variable declarations in the prolog, for initial
 : evaluation.
 : @param globals the global variables
 :)
declare function utils:global-variable-decls($globals as element(sch:let)*)
as xs:string?
{
  string-join(
    for $var in $globals
    return 'declare variable $' || $var/@name || ':=' || utils:variable-value($var)  || ';'
  )
};

(:~ Builds the string of external global variable declarations in the prolog.
 : Global variables are evaluated and bound as external variables.
 : @param globals the map of evaluated global variables
 :)
declare function utils:global-variable-external-decls($globals as map(*))
as xs:string?
{
  string-join(for $k in map:keys($globals)
    return 'declare variable $' || $k || ' external;')
};

(:~ Builds the string of local variable declarations.
 : @param locals the variables to declare
 :)
declare function utils:local-variable-decls($locals as element(sch:let)*)
as xs:string
{
  string-join(
    for $var in $locals
    return utils:declare-variable($var/@name, utils:variable-value($var)),
    ' '
  )
};

(:~ Adds the value to a variable declaration. 
 : @param var the variable
 : @see ISO2020, 5.4.6: "The value attribute is an expression evaluated in the 
 : current context. If no value attribute is specified, the value of the 
 : attribute is the element content of the let element."
 :)
declare function utils:variable-value($var as element(sch:let))
as xs:string
{
  if($var/@as => normalize-space() => matches('^map\([^\)]+\)')) 
  then $var/@value/data()
  else
  if($var/@value) then $var/@value/data() => utils:escape() else serialize($var/*)
};

(:~ Assembles the query prolog of namespace and variable declarations.
 : @param context the validation context
 :)
declare function utils:make-query-prolog($context as map(*))
as xs:string?
{
  ($context?ns-decls || utils:global-variable-external-decls($context?globals))
  => utils:escape() || $context?functions ! string(.)
};

(:~ Creates a QName from a prefixed variable name, looking up any URI from the
 : namespace declarations passed in.
 : @param name name of the variable
 : @param namespaces namespace declarations
 :)
declare function utils:variable-name-to-QName(
  $name as attribute(name),
  $namespaces as element(sch:ns)*
)
as xs:QName
{
  let $prefix := substring-before($name, ':')
  return QName(
    if($prefix ne '') then $namespaces[@prefix eq $prefix]/@uri else '',
    $name
  )
};

(:~ Escape ampersands in dynamically-evaluated queries.
 : @param query the string of the query to escape
 :)
declare function utils:escape($query as xs:string)
as xs:string
{
  replace($query, '&amp;', '&amp;amp;') 
  (: => replace('\{', '&amp;#x7B;') 
  => replace('\}', '&amp;#x7D;') :)
};

declare function utils:declare-variable(
  $name as xs:string,
  $value as item()+
)
as xs:string
{
  'let $' || $name || ':=' || $value
};

(:VARIABLES:)

(:~ @see ISO2020, 7.2: "A Schematron schema shall have one definition only in 
 : scope for any global variable name in the global context and any local 
 : variable name in the local context." 
 :)
declare function utils:check-duplicate-variable-names($decls as element(sch:let)*)
{
  let $names as xs:string* := $decls/@name/string()
  return
  if(count($decls) ne count(distinct-values($names)))
  then error(
    xs:QName('xqs:multiply-defined-variable'),
    'duplicate variable name in element ' || local-name(head($decls)/..) || ': '
    || $names[index-of($names, .)[2]]
  ) else()
};

(:~ Wrapper around xquery:eval() 
 : @param $query string of the query to evaluate
 : @param bindings map of bindings
 : @param options map of options
 : @param node the schema node being evaluated
 :)
declare function utils:eval(
  $query as xs:string,
  $bindings as map(*),
  $options as map(*),
  $node as node()
) as item()*
{
  if($options?dry-run eq 'true')
  then
    try{
      xquery:parse($query, map{'pass':'true'})
    }
    catch * {
      <svrl:failed-assert err:code='{$err:code}' location='{$node/path()}' 
      test='xquery:parse(.)'>
      <svrl:text>{$err:description}</svrl:text></svrl:failed-assert>
    }
  else xquery:eval($query, $bindings, map{'pass':'true'})
};