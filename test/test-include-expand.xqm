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

(:TODO detect circular references:)