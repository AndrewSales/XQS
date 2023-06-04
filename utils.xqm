(:~ Common utility functions. :)

module namespace util = 'http://www.andrewsales.com/ns/xqs-utils';

declare namespace xqs = 'http://www.andrewsales.com/ns/xqs';
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

(:~ Builds the string of variable declarations in the prolog, for initial
 : evaluation.
 : @param globals the global variables
 :)
declare function util:global-variable-decls($globals as element(sch:let)*)
as xs:string?
{
  string-join(
    for $var in $globals
    return 'declare variable $' || $var/@name || ':=' || util:variable-value($var)  || ';'
  )
};

(:~ Builds the string of external global variable declarations in the prolog.
 : Global variables are evaluated and bound as external variables.
 : @param globals the map of evaluated global variables
 :)
declare function util:global-variable-external-decls($globals as map(*))
as xs:string?
{
  string-join(for $k in map:keys($globals)
    return 'declare variable $' || $k || ' external;')
};

(:~ Builds the string of local variable declarations.
 : @param locals the variables to declare
 :)
declare function util:local-variable-decls($locals as element(sch:let)*)
as xs:string
{
  string-join(
    for $var in $locals
    return util:declare-variable($var/@name, util:variable-value($var)),
    ' '
  )
};

(:~ Adds the value to a variable declaration. 
 : @param var the variable
 : @see ISO2020, 5.4.6: "The value attribute is an expression evaluated in the 
 : current context. If no value attribute is specified, the value of the 
 : attribute is the element content of the let element."
 :)
declare function util:variable-value($var as element(sch:let))
as xs:string
{
  if($var/@as => normalize-space() => matches('^map\([^\)]+\)')) 
  then $var/@value/data()
  else
  if($var/@value) then $var/@value/data() => util:escape() else serialize($var/*)
};

(:~ Assembles the query prolog of namespace and variable declarations.
 : @param context the validation context
 :)
declare function util:make-query-prolog($context as map(*))
as xs:string?
{
  ($context?ns-decls || util:global-variable-external-decls($context?globals))
  => util:escape() || $context?functions ! string(.)
};

(:~ Creates a QName from a prefixed variable name, looking up any URI from the
 : namespace declarations passed in.
 : @param name name of the variable
 : @param namespaces namespace declarations
 :)
declare function util:variable-name-to-QName(
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
declare function util:escape($query as xs:string)
as xs:string
{
  replace($query, '&amp;', '&amp;amp;') 
  (: => replace('\{', '&amp;#x7B;') 
  => replace('\}', '&amp;#x7D;') :)
};

declare function util:declare-variable(
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
declare function util:check-duplicate-variable-names($decls as element(sch:let)*)
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
