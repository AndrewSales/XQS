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
  
declare variable $_:URI_PARAM := 'Q{http://www.andrewsales.com/ns/xqs}uri';  
declare variable $_:DOC_PARAM := 'Q{http://www.andrewsales.com/ns/xqs}doc';  

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
    map{$_:URI_PARAM:'foo.xml'}
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

(:~ elements in assertion message handled correctly :)
declare %unit:test function _:assertion-message-elements()
{
  let $schema := <sch:schema>
    <sch:pattern>
      <sch:rule context='//bar'>
        <sch:report test='.'>bar found <foreign>hello</foreign>: <sch:emph>emph</sch:emph>,
      <sch:dir value='ltr'>dir<foreign/></sch:dir> and <sch:span class='blort'>span<foreign/></sch:span></sch:report>
    </sch:rule></sch:pattern>
    </sch:schema>
    
  let $compiled := compile:schema($schema, '')
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo><bar/></foo>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:schematron-output>
      <svrl:active-pattern/>
      <svrl:fired-rule context='//bar'/>
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]/Q{{}}bar[1]'><svrl:text>bar found <foreign>hello</foreign>: <svrl:emph>emph</svrl:emph>,
      <svrl:dir value='ltr'>dir<foreign/></svrl:dir> and <svrl:span class='blort'>span<foreign/></svrl:span></svrl:text></svrl:successful-report>
      </svrl:schematron-output>
    )
  )
};