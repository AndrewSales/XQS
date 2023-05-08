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
    'let $foo := bar let $blort := wibble'
  )
};