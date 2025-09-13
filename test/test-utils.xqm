(:~ 
 : Unit tests for utility functions.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-utils-tests';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' at
  '../utils.xqm';

declare %unit:test function _:global-variable-decls()
{
  let $decls := util:global-variable-decls(
    (<sch:let name='foo' value='bar'/>, <sch:let name='blort' value='wibble'/>)
  )
  return unit:assert-equals(
    $decls,
    'declare variable $foo:=bar;declare variable $blort:=wibble;'
  )
};

declare %unit:test function _:local-variable-decls()
{
  let $decls := util:local-variable-decls(
    (<sch:let name='foo' value='bar'/>, <sch:let name='blort' value='wibble'/>)
  )
  return unit:assert-equals(
    $decls,
    'let $foo:=bar let $blort:=wibble'
  )
};

declare %unit:test function _:global-typed-variable-decls()
{
  let $decls := util:global-variable-decls(
    (<sch:let name='foo' value='bar' as='xs:string'/>, <sch:let name='blort' value='1' as='xs:integer'/>)
  )
  return unit:assert-equals(
    $decls,
    'declare variable $foo as xs:string :=bar;declare variable $blort as xs:integer :=1;'
  )
};

declare %unit:test function _:local-typed-variable-decls()
{
  let $decls := util:local-variable-decls(
    (<sch:let name='foo' value='bar' as='xs:string'/>, <sch:let name='blort' value='1' as='xs:integer'/>)
  )
  return unit:assert-equals(
    $decls,
    'let $foo as xs:string :=bar let $blort as xs:integer :=1'
  )
};

(:~ re https://github.com/AndrewSales/XQS/issues/61 - this test only proves the
 : the exception is not caught
 :)
declare 
%unit:test('expected', 'XPST0003')
function _:eval()
{
  util:eval(
    '',	(:empty query:)
    map{},
    map{'pass':true()},
    <foo/>
  )
};

(:~ expression-containing attributes convert successfully to lone first child 
 : elements of that type
 :)
declare %unit:test function _:attributes-to-elements()
{
  let $result := util:attributes-to-elements(doc('test-cases/attributes-to-elements.sch')/*)
  return unit:assert-equals(
    $result, doc('test-cases/elements-to-attributes.sch')/*
  )
};

(:~ expression-containing lone first child elements of a given type convert 
 : successfully to attributes 
 :)
declare %unit:test function _:elements-to-attributes()
{
  let $result := util:elements-to-attributes(doc('test-cases/elements-to-attributes.sch')/*)
  return unit:assert-equals(
    $result, doc('test-cases/attributes-to-elements.sch')/*
  )
};