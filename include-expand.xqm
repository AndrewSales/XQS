(:~ Library for processing inclusions and instantiating abstract rules and 
 : patterns.
 :)

module namespace ie = 'http://www.andrewsales.com/ns/xqs-include-expand';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

(:~ Perform inclusion and expansion.
 :)
declare function ie:include-expand($schema as element(sch:schema)) 
{
  ie:process-includes($schema) => ie:process-abstracts()
};

(:~ Perform abstract rule and pattern expansion. :)
declare function ie:process-abstracts($schema as element(sch:schema))
{
  ie:expand-rules($schema) => ie:expand-patterns()
};

(:~ Handle includes in the main schema document. 
 : Resolve any includes, then recurse if any remain as a result.
 :)
declare function ie:process-includes(
  $schema as element(sch:schema)
)
{
  let $_ := trace('SCHEMA base URI=' || $schema/base-uri())
  let $copy :=
  copy $copy := $schema
    modify
      for $include in ($copy//sch:include | $copy//sch:extends[@href]) 
      return
      replace node $include with ie:process-include($include, $schema/base-uri())
    return $copy
    
  return 
  if($copy//sch:include | $copy//sch:extends[@href])
  then ie:process-includes($copy)
  else $copy
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
      let $resolved-uri := resolve-uri($include/@href, $include-base-uri)
      return
      replace value of node $include/@href with $resolved-uri
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

(:~ Expand abstract rules by replacing the contents of extends with the contents
 : of the abstract rule referenced, then removing all abstract rules.
 : @param schema the containing schema
 :)
declare function ie:expand-rules($schema as element(sch:schema))
as element(sch:schema)
{
  copy $copy := $schema
  modify
    (for $extends in $copy//sch:extends[@rule]
    return replace node $extends with ie:expand-rule($extends, $schema),
    for $abstract in $copy//sch:rule[@abstract eq 'true']
    return delete node $abstract)
  return $copy
};

declare function ie:expand-rule(
  $extends as element(sch:extends),
  $schema as element(sch:schema)
)
as node()*
{
  let $abstract := $schema//sch:rule[@id eq $extends/@rule]
  return
  if(empty($abstract))
  then error(xs:QName('no-such-abstract-rule'), $extends/@rule)
  else 
  $abstract/node()
  (:TODO language fixup:)
  (:replace extends[@rule] with children of abstract rule:)
};

declare function ie:expand-patterns($schema as element(sch:schema))
{
  
};

declare function ie:expand-pattern($abstract as element(sch:pattern))
as element(sch:pattern)
{
  <sch:pattern>
  {@* except @is-a}
  (: TODO language fixup :)
  (: TODO @documents :)
  (: TODO properties :)
  (: TODO diagnostics :)
  (: TODO replace params in abstract pattern (**only if pattern[param]**)
  sch:assert/@test | sch:report/@test | sch:rule/@context | sch:value-of/@select | sch:pattern/@documents | sch:name/@path | sch:let/@value:)
  </sch:pattern>
};

declare function ie:replace-params($param as attribute())
as xs:string
{
  (:sort params by desc length of name:)
  (:...:)
};