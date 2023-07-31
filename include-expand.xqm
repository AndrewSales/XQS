(:~ Library for processing inclusions and instantiating abstract rules and 
 : patterns.
 :)

module namespace ie = 'http://www.andrewsales.com/ns/xqs-include-expand';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

(:~ Handle includes in the main schema document. :)
declare function ie:process-includes(
  $schema as element(sch:schema)
)
{
  let $_ := trace('base URI=' || $schema/base-uri())
  return
  copy $copy := $schema
    modify 
      for $include in $copy//sch:include 
      return
      replace node $include with ie:process-include($include, $schema/base-uri())
  return $copy    
};

(:~ Process includes, including any nested ones. :)
declare %private function ie:process-include(
  $include as node(),
  $base-uri as xs:anyURI
) as node()
{
  let $_ := trace('base URI='||$base-uri)
  let $include := ie:document-or-fragment($include/@href, $base-uri)
  return
  copy $copy := $include
    modify
      for $include in $copy//sch:include 
      return
      replace node $include with ie:process-include($include, $include/base-uri())
  return $copy    
};

(:~ Return the document or fragment to be included. :)
declare %private function ie:document-or-fragment(
  $href as attribute(href),
  $base-uri as xs:anyURI
)
as node()
{
  let $url := if(contains($href, '#')) then substring-before($href, '#')
    else $href
  let $fragment := substring-after($href, '#')
  let $doc := doc(resolve-uri($url, $base-uri))
  return
  if($fragment)
  then ($doc//*[@id = $fragment])[1]
  else $doc
};