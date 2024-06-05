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

(:TODO 
detect circular references
:)