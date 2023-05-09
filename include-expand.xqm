(:~ Library for process inclusions and instantiating abstract rules and patterns.
 :)

module namespace ie = 'http://www.andrewsales.com/ns/xqs-include-expand';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

declare function ie:process-includes(
  $schema as element(sch:schema),
  $base-uri as xs:anyURI
)
{
  for $include in $schema//sch:include
  return ie:process-include($include, $base-uri)
};

declare function ie:process-include(
  $include as element(sch:include),
  $base-uri as xs:anyURI
)
{
  copy $copy := $include
    modify 
      replace node $include with <FOO/> (: doc(resolve-uri($include/@href, $include/base-uri())) :)
  return $copy    
};