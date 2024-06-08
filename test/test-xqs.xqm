(:~ 
 : Unit tests for main interface.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-tests';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

import module namespace xqs = 'http://www.andrewsales.com/ns/xqs' at
  '../xqs.xqm';
  
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";


declare 
%unit:test('expected', 'xqs:invalid-query-binding') 
function _:validate-QLB-not-xquery()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='xslt'>
    <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare 
%unit:test
function _:validate-QLB-xquery()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='xquery'>
      <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare 
%unit:test
function _:validate-QLB-XQUERY()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='XQUERY'>
      <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare 
%unit:test
function _:validate-QLB-xquery3()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='xquery3'>
      <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare 
%unit:test
function _:validate-QLB-xquery31()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='xquery31'>
      <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare 
%unit:test
function _:validate-QLB-XQUERY3()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='XQUERY3'>
      <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare 
%unit:test
function _:validate-QLB-XQUERY31()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='XQUERY31'>
      <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>
  )
};

declare %unit:test function _:validate-expand-abstract-pattern()
{
  let $result := xqs:validate(
    document{<element/>},
    doc('test-cases/abstract-pattern.sch')/*
  )
  return
  unit:assert-equals(count($result//svrl:failed-assert), 1)
};

declare %unit:test function _:validate-expand-abstract-rule()
{
  let $result := xqs:validate(
    document{<element/>},
    doc('test-cases/abstract-rule.sch')/*
  )
  return
  unit:assert-equals(count($result//svrl:successful-report), 1)
};

declare %unit:test function _:validate-resolve-include()
{
  let $result := xqs:validate(
    document{<element/>},
    doc('test-cases/include.sch')/*
  )
  return
  unit:assert-equals(count($result//svrl:successful-report), 1)
};