(:~ Common utility functions. :)

module namespace util = 'http://www.andrewsales.com/ns/xqs-utils';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

(:~ Builds the string of variable declarations in the prolog, for initial
 : evaluation.
 : @param globals the global variables
 :)
declare function util:global-variable-decls($globals as element(sch:let)*)
as xs:string?
{
  string-join(
    for $var in $globals
    return 'declare variable $' || $var/@name || ':=' || $var/@value  || ';'
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
    return 'let $' || $var/@name || ' := ' || util:local-variable-value($var),
    ' '
  )
};

(:~ Adds the value to a local variable declaration. 
 : @param var the local variable
 : @see ISO2020, 5.4.6: "The value attribute is an expression evaluated in the 
 : current context. If no value attribute is specified, the value of the 
 : attribute is the element content of the let element."
 :)
declare %private function util:local-variable-value($var as element(sch:let))
as xs:string
{
  if($var/@value) then $var/@value/data() else serialize($var/*)
};

(:~ Assembles the query prolog of namespace and variable declarations.
 : @param context the validation context
 :)
declare function util:make-query-prolog($context as map(*))
as xs:string?
{
  $context?ns-decls || util:global-variable-external-decls($context?globals)
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