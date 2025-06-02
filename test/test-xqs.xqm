(:~ 
 : Unit tests for main interface.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-tests';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

import module namespace xqs = 'http://www.andrewsales.com/ns/xqs' at
  '../xqs.xqm';
  
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

declare variable $_:EMPTY_MAP as map(*) := map{};

declare 
%unit:test('expected', 'xqs:invalid-query-binding') 
function _:validate-QLB-not-xquery()
{
  xqs:validate(
    <foo/>,
    <sch:schema queryBinding='xslt'>
    <sch:pattern><sch:rule context='*'><sch:assert/></sch:rule></sch:pattern>
    </sch:schema>,
    $_:EMPTY_MAP
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
    </sch:schema>,
    $_:EMPTY_MAP
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
    </sch:schema>,
    $_:EMPTY_MAP
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
    </sch:schema>,
    $_:EMPTY_MAP
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
    </sch:schema>,
    $_:EMPTY_MAP
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
    </sch:schema>,
    $_:EMPTY_MAP
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
    </sch:schema>,
    $_:EMPTY_MAP
  )
};

declare %unit:test function _:validate-expand-abstract-pattern()
{
  let $result := xqs:validate(
    document{<element/>},
    doc('test-cases/abstract-pattern.sch')/*,
    $_:EMPTY_MAP
  )
  return
  unit:assert-equals(count($result//svrl:failed-assert), 1)
};

declare %unit:test function _:validate-expand-abstract-rule()
{
  let $result := xqs:validate(
    document{<element/>},
    doc('test-cases/abstract-rule.sch')/*,
    $_:EMPTY_MAP
  )
  return
  unit:assert-equals(count($result//svrl:successful-report), 1)
};

declare %unit:test function _:validate-resolve-include()
{
  let $result := xqs:validate(
    document{<element/>},
    doc('test-cases/include.sch')/*,
    $_:EMPTY_MAP
  )
  return
  unit:assert-equals(count($result//svrl:successful-report), 1)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition()
{
  let $result := xqs:validate(
    document{<element/>},
    <sch:schema queryBinding='xquery31' schematronEdition='2025'>
      <sch:pattern><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'true'}
  )
  return
  unit:assert-equals($result[1], <sch:schema schematronEdition="2025"/>)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition-case-insensitive()
{
  let $result := xqs:validate(
    document{<element/>},
    <sch:schema queryBinding='xquery31' schematronEdition='2025'>
      <sch:pattern><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'YES'}
  )
  return
  unit:assert-equals($result[1], <sch:schema schematronEdition="2025"/>)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition-none()
{
  let $result := xqs:validate(
    document{<element/>},
    <sch:schema queryBinding='xquery31' >
      <sch:pattern><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'true'}
  )
  return
  unit:assert-equals($result[1], <sch:schema/>)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition-with-phase()
{
  let $result := xqs:validate(
    document{<element/>},
    <sch:schema queryBinding='xquery31' schematronEdition='2025'>
      <sch:phase id='myPhase'>
        <sch:active pattern='p1'/>
      </sch:phase>
      <sch:pattern id='p1'><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'true', 'phase':'myPhase'}
  )
  return
  unit:assert-equals($result[1], <sch:schema schematronEdition="2025"/>)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition-compile()
{
  let $result := xqs:compile(
    <sch:schema queryBinding='xquery31' schematronEdition='2025'>
      <sch:pattern><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'true'}
  )
  return
  unit:assert-equals($result[1], <sch:schema schematronEdition='2025'/>)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition-none-compile()
{
  let $result := xqs:compile(
    <sch:schema queryBinding='xquery31' >
      <sch:pattern><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'true'}
  )
  return
  unit:assert-equals($result[1], <sch:schema/>)
};

(:~ First item reported will be to stderr. :)
declare %unit:test function _:report-schematron-edition-with-phase-compile()
{
  let $result := xqs:compile(
    <sch:schema queryBinding='xquery31' schematronEdition='2025'>
      <sch:phase id='myPhase'>
        <sch:active pattern='p1'/>
      </sch:phase>
      <sch:pattern id='p1'><sch:rule context='*'><sch:assert test='.'/></sch:rule></sch:pattern>
    </sch:schema>,
    map{'report-edition':'true', 'phase':'myPhase'}
  )
  return
  unit:assert-equals($result[1], <sch:schema schematronEdition="2025"/>)
};