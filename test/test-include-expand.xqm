(:~ 
 : Unit tests for processing includes and expanding abstract patterns and rules.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-include-expand-tests';

import module namespace ie = 'http://www.andrewsales.com/ns/xqs-include-expand'
  at '../include-expand.xqm';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

declare %unit:test function _:process-include()
{
  let $doc := doc('test-cases/process-include.xml')
  let $schema := ie:process-includes($doc/*)
  return
  (
    unit:assert(not($schema/sch:include)),
    unit:assert($schema/sch:pattern)
  )
};

declare %unit:test function _:process-include-2()
{
  let $doc := doc('test-cases/include.sch')
  let $schema := ie:process-includes($doc/*)
  return
  (
    unit:assert(not($schema/sch:include)),
    unit:assert($schema/sch:pattern)
  )
};

declare %unit:test function _:process-include-recursive()
{
  let $doc := doc('test-cases/process-include-recursive.xml')
  let $schema := ie:process-includes($doc/*)
  return
  (
    unit:assert(not($schema//sch:include)),
    unit:assert($schema/sch:pattern),
    unit:assert-equals(count($schema//sch:rule), 3)
  )
};

declare %unit:test function _:include-fragment()
{
  let $doc := doc('test-cases/include-fragment.sch')
  let $schema := ie:process-includes($doc/*)
  return
  (
    unit:assert(not($schema//sch:include)),
    unit:assert-equals(count($schema//sch:rule), 1)
  )
};

declare %unit:test function _:abstract-rule()
{
  let $schema := doc('test-cases/abstract-rule.sch')
  let $result := ie:include-expand($schema/*)
  return
  (
    unit:assert(not($result//sch:extends)),
    unit:assert-equals(count($result//sch:rule), 1),
    unit:assert($result//sch:rule[@context eq 'element']),
    unit:assert($result//sch:rule/sch:report[@test eq 'self::element'])
  )
};

declare %unit:test function _:abstract-pattern()
{
  let $schema := doc('test-cases/abstract-pattern.sch')
  let $result := ie:include-expand($schema/*)
  return
  (
    unit:assert(not($result//sch:pattern[@abstract eq 'true'])),
    unit:assert-equals($result//sch:assert/@test/data(), '1 = 0')
  )
};

declare %unit:test function _:replace-param-refs()
{
  let $result := ie:replace-param-refs(
    '$foo eq $fo eq $f',
    (<sch:param name='foo' value='1'/>, <sch:param name='fo' value='2'/>,
  <sch:param name='f' value='3'/>)
  )
  return unit:assert-equals($result, '1 eq 2 eq 3')
};

(:~ No param refs to replace, so return unchanged :)
declare %unit:test function _:replace-param-refs-verbatim()
{
  let $result := ie:replace-param-refs(
    'foo bar blort',
    ()
  )
  return unit:assert-equals($result, 'foo bar blort')
};

declare %unit:test function _:pattern-attributes()
{
  let $result := ie:pattern-elements(
    <sch:assert test='$foo eq 1'/>,
    <sch:param name='foo' value='bar'/>
  )
  return
  unit:assert-equals(
    $result,
    attribute{'test'}{'bar eq 1'}
  )
};

declare %unit:test function _:pattern-filter()
{
  let $result := ie:pattern-filter(
    <sch:pattern>
        <sch:rule context="$context">
          <sch:assert test="$foo = 1"/>
        </sch:rule>
      </sch:pattern>,
    (<sch:param name='foo' value='bar'/>, <sch:param name='context' value='blort'/>)
  )
  return
  unit:assert-equals(
    $result,
    <sch:pattern>
        <sch:rule context="blort">
          <sch:assert test="bar = 1"/>
        </sch:rule>
      </sch:pattern>
  )
};

declare %unit:test function _:expand-pattern()
{
   let $result := ie:expand-pattern(
      <sch:pattern is-a="abstract-pattern">
        <sch:param name="context" value="element"/>
        <sch:param name="placeholder" value="1"/>
      </sch:pattern>,
      <sch:pattern abstract="true" id="abstract-pattern">
        <sch:rule context="$context">
          <sch:assert test="$placeholder = 0"/>
        </sch:rule>
      </sch:pattern>
    )
    return
    unit:assert-equals(
      $result,
      <sch:pattern> <sch:rule context="element">
          <sch:assert test="1 = 0"/>
        </sch:rule></sch:pattern>
    )
};

declare %unit:test function _:process-extends()
{
  let $doc := doc('test-cases/extends.sch')
  let $schema := ie:process-includes($doc/*)
  return
  (
    unit:assert(not($schema//sch:extends)),
    unit:assert(count($schema/sch:pattern) = 3)
  )
};

declare %unit:test function _:process-extends-recursive()
{
  let $doc := doc('test-cases/extends-recursive.sch')
  let $schema := ie:process-includes($doc/*)
  return
  (
    unit:assert(not($schema//sch:extends)),
    unit:assert(count($schema/sch:pattern) = 5)
  )
};

(:TODO 
detect circular references
:)