(:~ 
 : Unit tests for schema compilation.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-compile-tests';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

import module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate' 
  at '../evaluate.xqm';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' 
  at '../context.xqm';  
import module namespace compile = 'http://www.andrewsales.com/ns/xqs-compile' 
  at '../compile.xqm';    

(:~ Only first rule in first pattern should fire.
 : No failed asserts.
 :)
declare %unit:test function _:compile-schema()
{
  let $schema := <sch:schema>
      <sch:ns prefix='x' uri='y'/>
      <sch:let name="x:foo" value="0"/>
      <sch:pattern>
        <sch:let name="x:foo" value="1"/>
        <sch:rule context="//*" id='rule-1'>
          <sch:assert test="$x:foo = 1" id='a1' flag='f1' role='sdfa'><sch:emph/><foo/>foo=<sch:value-of select='$x:foo'/></sch:assert>
        </sch:rule>
        <sch:rule context="//*" id='rule-2'>
          <sch:assert test="$x:foo = 1" id='a2' flag='f1' role='sdfa'>foo=<sch:value-of select='$x:foo'/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="//*" id='rule-3'>
          <sch:assert test="$x:foo = 0" id='a3'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
    
  let $compiled := compile:schema($schema, '')
  let $result := xquery:eval(
    $compiled,
    map{'':$schema, 'Q{http://www.andrewsales.com/ns/xqs}uri':'foo.xml'}
  )
    
  return (
    unit:assert-equals(
      count($result/svrl:fired-rule),
      2
    ),
    unit:assert-equals(
      count($result/svrl:failed-assert),
      0
    ),
    unit:assert-equals(
      $result/svrl:fired-rule/@id/data(),
      ('rule-1', 'rule-3')
    )
  )
};