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
  let $_ := trace('SCHEMA base URI=' || $schema/base-uri())
  return
  copy $copy := $schema
    modify 
      for $include in ($copy//sch:include | $copy//sch:extends[@href]) 
      return
      replace node $include with ie:process-include($include, $schema/base-uri())
  return $copy    
};

(:~ Process includes, including any nested ones. :)
declare %private function ie:process-include(
  $include as element(),
  $base-uri as xs:anyURI
) as node()
{
  let $_ := trace('include='||$include=>serialize())
  let $_ := trace('base URI='||$base-uri)
  let $_ := trace('resolving include='||$include/@href)
  let $include := ie:get-inclusion($include/@href, $base-uri)
  let $include-base-uri := $include/base-uri()	(:store before we create the copy:)
  return
  copy $copy := $include
    modify
      for $include in ($copy/descendant-or-self::sch:include | $copy/descendant-or-self::sch:extends[@href]) 
      return
      replace node $include with ie:process-include($include, $include-base-uri)
  return $copy    
};

(:~ Return the document or element to be included. :)
declare %private function ie:get-inclusion(
  $href as attribute(href),
  $base-uri as xs:anyURI
)
as node()
{
  let $url := if(contains($href, '#')) then substring-before($href, '#') else $href
  let $fragment := substring-after($href, '#')
  let $doc := doc(resolve-uri($url, $base-uri))
  let $inclusion as element() :=
    if($fragment)
    then ($doc//*[@id = $fragment])[1]
    else $doc/*
  let $inclusion :=
    if($href/parent::sch:extends)
    then $inclusion/*
    else $inclusion
  let $_ := trace('inclusion='||serialize($inclusion)||' base URI='||$inclusion/base-uri())
  
  return $inclusion
};