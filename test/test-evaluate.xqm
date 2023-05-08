(:~ 
 : Unit tests for evaluating schema assertions.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-evaluation-tests';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";

import module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate' 
  at '../evaluate.xqm';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' 
  at '../context.xqm';  

(:~ schema title passed through to SVRL :)
declare %unit:test function _:test-eval-schema-title()
{
  let $svrl := eval:schema(
    <foo/>,
    <sch:schema defaultPhase='phase'>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  
  return
  (
     unit:assert-equals(
      $svrl/@title/data(),
      'Schema title'
    )
  )
};

(:~ no schema title present :)
declare %unit:test function _:test-eval-schema-no-title()
{
  let $svrl := eval:schema(
    <foo/>,
    <sch:schema defaultPhase='phase'>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  
  return
  (
     unit:assert-equals(
      $svrl/@title,
      ()
    )
  )
};

(:~ phase passed through to SVRL :)
declare %unit:test function _:test-eval-schema-phase()
{
  let $svrl := eval:schema(
    <foo/>,
    <sch:schema defaultPhase='phase'>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  
  return
  (
    unit:assert-equals(
      $svrl/@phase/data(),
      'phase'
    ) 
  )
};

(:~ no phase present :)
declare %unit:test function _:test-eval-schema-no-phase()
{
  let $svrl := eval:schema(
    <foo/>,
    <sch:schema>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  
  return
  (
    unit:assert-equals(
      $svrl/@phase,
      ()
    ) 
  )
};

(:~ namespaces passed through to SVRL :)
declare %unit:test function _:test-eval-schema-namespaces()
{
  let $svrl := eval:schema(
    <foo/>,
    <sch:schema defaultPhase='phase'>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  
  return
  (
    unit:assert-equals(
      $svrl/svrl:ns-prefix-in-attribute-values,
      <svrl:ns-prefix-in-attribute-values prefix='a' uri='b'/>
    ) 
  )
};

(:~ active pattern processed :)
declare %unit:test function _:test-process-pattern()
{
  let $result := eval:pattern(
    <sch:pattern id='e' name='f' role='g'>
      <sch:rule context='*' id='a' name='b' role='c' flag='d'/>
    </sch:pattern>,
    map{'instance':document{<foo/>}, 'globals':map{}}
  )
  return unit:assert-equals(
    $result,
    (<svrl:active-pattern id='e' name='f' role='g'/>,
    <svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>)
  )
};

(:~ rule in active pattern processed :)
declare %unit:test function _:test-process-rule()
{
  let $result := eval:rule(
    <sch:rule context='*' id='a' name='b' role='c' flag='d'/>,
    (),
    map{'instance':document{<foo/>}}
  )
  return unit:assert-equals(
    $result,
    (<svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>)
  )
};

(:~ rule in active pattern processed, with local variable :)
declare %unit:test function _:test-process-rule-local-variable()
{
  let $result := eval:rule(
    <sch:rule context='*' id='a' name='b' role='c' flag='d'>
      <sch:let name='allowed' value='"bar"'/>
    </sch:rule>,
    (),
    map{'instance':document{<foo/>}}
  )
  return unit:assert-equals(
    $result,
    (<svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>)
  )
};

(:~ Can only happen if schema is invalid. :)
declare 
%unit:test('expected', 'eval:invalid-assertion-element') 
function _:test-invalid-assertion-element()
{
  eval:assertion(
    <sch:invalid-assertion-element test='.'/>,
    '',
    <foo/>,
    map{}
  )
};

(:~ assert processed, with local variable :)
declare %unit:test function _:test-process-assert-with-variable()
{
  let $result := eval:rule(
    <sch:rule context='*' id='a' name='b' role='c' flag='d'>
      <sch:let name='allowed' value='"bar"'/>
      <sch:assert test='name(.) = $allowed'>name <sch:name/> is not allowed</sch:assert>
    </sch:rule>,
    (),
    map{'instance':document{<foo/>}}
  )
  return unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>,
      <svrl:failed-assert 
      test='name(.) = $allowed' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed</svrl:text></svrl:failed-assert>
    )
  )
};

(:~ report processed, with local variable :)
declare %unit:test function _:test-process-report-with-variable()
{
  let $result := eval:rule(
    <sch:rule context='*' id='a' name='b' role='c' flag='d'>
      <sch:let name='allowed' value='"bar"'/>
      <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed</sch:report>
    </sch:rule>,
    (),
    map{'instance':document{<foo/>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>,
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ report processed, with global variable :)
declare %unit:test function _:test-process-report-with-global-variable()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
    <sch:let name='allowed' value='"bar"'/>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed</sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report,
    (
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ report processed, with pattern variable :)
declare %unit:test function _:test-process-report-with-pattern-variable()
{
  let $result := eval:schema(
    document{<foo allowed='bar'/>},
    <sch:schema>
      <sch:pattern>
        <sch:let name='allowed' value='foo/@allowed'/>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
          <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed: <sch:value-of select='$allowed'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report/string(),
    (
      'name foo is not allowed: bar'
    )
  )
};

(:~ report processed, with global variable element node :)
declare %unit:test function _:test-process-report-with-global-variable-element-node()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed</sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report,
    (
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ report processed, with local variable as element node :)
declare %unit:test function _:test-process-report-with-variable-element-node()
{
  let $result := eval:rule(
    <sch:rule context='*' id='a' name='b' role='c' flag='d'>
      <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed</sch:report>
    </sch:rule>,
    (),
    map{'instance':document{<foo/>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>,
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ value-of and name handled in assertion message :)
declare %unit:test function _:test-value-of()
{
  let $result := eval:rule(
    <sch:rule context='*' id='a' name='b' role='c' flag='d'>
      <sch:let name='allowed' value='"bar"'/>
      <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed; bar=<sch:value-of select='@bar'/></sch:report>
    </sch:rule>,
    (),
    map{'instance':document{<foo bar='blort'/>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>,
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed; bar=blort</svrl:text></svrl:successful-report>
    )
  )
};

(:~ name/@path handled in assertion message :)
declare %unit:test function _:test-name-path()
{
  let $result := eval:rule(
    <sch:rule context='//bar'>
      <sch:report test='.'>bar found, child of <sch:name path='name(..)'/></sch:report>
    </sch:rule>,
    (),
    map{'instance':document{<foo><bar/></foo>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='//bar'/>,
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]/Q{{}}bar[1]'><svrl:text>bar found, child of foo</svrl:text></svrl:successful-report>
    )
  )
};

(:~ elements in assertion message handled correctly :)
declare %unit:test function _:test-assertion-message-elements()
{
  let $result := eval:rule(
    <sch:rule context='//bar'>
      <sch:report test='.'>bar found <foreign>hello</foreign>: <sch:emph>emph</sch:emph>,
      <sch:dir value='ltr'>dir<foreign/></sch:dir> and <sch:span class='blort'>span<foreign/></sch:span></sch:report>
    </sch:rule>,
    (),
    map{'instance':document{<foo><bar/></foo>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='//bar'/>,
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]/Q{{}}bar[1]'><svrl:text>bar found <foreign>hello</foreign>: <svrl:emph>emph</svrl:emph>,
      <svrl:dir value='ltr'>dir<foreign/></svrl:dir> and <svrl:span class='blort'>span<foreign/></svrl:span></svrl:text></svrl:successful-report>
    )
  )
};

(:~ multiple assertion matches reported correctly :)
declare %unit:test function _:test-multiple-results()
{
  let $result := eval:rule(
    <sch:rule context='//bar'>
      <sch:report test='.'>bar found, child of <sch:name path='name(..)'/></sch:report>
    </sch:rule>,
    (),
    map{'instance':document{<foo><bar/><bar/></foo>}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:fired-rule context='//bar'/>,
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]/Q{{}}bar[1]'><svrl:text>bar found, child of foo</svrl:text></svrl:successful-report>,
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]/Q{{}}bar[2]'><svrl:text>bar found, child of foo</svrl:text></svrl:successful-report>
    )
  )
};

(:~ Processing in a pattern halts when a rule context is matched:
 : "A rule element acts as an if-then-else statement within each pattern." 
 : @see ISO2020, 6.5
 :)
declare %unit:test function _:test-rule-halt-on-match()
{
  let $result := eval:pattern(
    <sch:pattern>
      <sch:rule context='*'>
        <sch:assert test='name() eq "bar"'>root element is <sch:name/></sch:assert>
      </sch:rule>
      <sch:rule context='foo'>
        <sch:report test='.'>should not reach here</sch:report>
      </sch:rule>
    </sch:pattern>,
    map{'instance':document{<foo/>}, 'globals':map{}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:active-pattern/>,
      <svrl:fired-rule context='*'/>,
      <svrl:failed-assert 
      test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:text>root element is foo</svrl:text></svrl:failed-assert>
    )
  )
};

(:~ Processing in a pattern continues when a rule context is not matched:
 : "A rule element acts as an if-then-else statement within each pattern." 
 : @see ISO2020, 6.5
 :)
declare %unit:test function _:test-rule-continue-on-no-match()
{
  let $result := eval:pattern(
    <sch:pattern>
      <sch:rule context='unknown'>
        <sch:assert test='name() eq "bar"'>root element is <sch:name/></sch:assert>
      </sch:rule>
      <sch:rule context='foo'>
        <sch:report test='.'>should reach here</sch:report>
      </sch:rule>
      <sch:rule context='*'>
        <sch:report test='.'>should NOT reach here</sch:report>
      </sch:rule>
    </sch:pattern>,
    map{'instance':document{<foo/>}, 'globals':map{}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:active-pattern/>,
      <svrl:fired-rule context='foo'/>,
      <svrl:successful-report
      test='.' location='/Q{{}}foo[1]'><svrl:text>should reach here</svrl:text></svrl:successful-report>
    )
  )
};

(: DIAGNOSTICS :)

(:~ diagnostics reported correctly in SVRL :)
declare %unit:test function _:test-diagnostics()
{
    let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='name() eq "bar"' diagnostics='d1'>root element is <sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:diagnostics>
        <sch:diagnostic id='d1' role='warning' icon='abc' see='def' fpi='xyz' xml:lang='en' xml:space='preserve'>wrong</sch:diagnostic>
      </sch:diagnostics>
    </sch:schema>,
    ''
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
      <svrl:text>root element is foo</svrl:text>
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:diagnostic-reference,
      (
        <svrl:diagnostic-reference diagnostic='d1'><svrl:text>wrong</svrl:text></svrl:diagnostic-reference>
      )
    ),
    unit:assert-equals(
      $result/svrl:failed-assert,
      (
        <svrl:failed-assert
        test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:diagnostic-reference diagnostic='d1'><svrl:text>wrong</svrl:text></svrl:diagnostic-reference><svrl:text>root element is foo</svrl:text></svrl:failed-assert>
      )
    )
  )
};

(:~ children of diagnostic handled in SVRL :)
declare %unit:test function _:test-diagnostics-mixed-content()
{
    let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:let name='root-name' value='name(*)'/>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='name() eq "bar"' diagnostics='d1'>root element is <sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:diagnostics>
        <sch:diagnostic id='d1' role='warning' icon='abc' see='def' fpi='xyz' xml:lang='en' xml:space='preserve'><foreign/><sch:emph/><sch:dir value='ltr'>dir<foreign/></sch:dir> and <sch:span class='blort'>span<foreign/></sch:span>wrong=<sch:value-of select='$root-name'/></sch:diagnostic>
      </sch:diagnostics>
    </sch:schema>,
    ''
  )
  return
  unit:assert-equals(
    $result/svrl:failed-assert,
    (
      <svrl:failed-assert
      test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:diagnostic-reference diagnostic='d1'><svrl:text><foreign/><svrl:emph/><svrl:dir value='ltr'>dir<foreign/></svrl:dir> and <svrl:span class='blort'>span<foreign/></svrl:span>wrong=foo</svrl:text></svrl:diagnostic-reference><svrl:text>root element is foo</svrl:text></svrl:failed-assert>
    )
  )
};

(:~ multiple diagnostic references handled correctly in SVRL :)
declare %unit:test function _:test-diagnostics-multiple()
{
    let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='name() eq "bar"' diagnostics='d1 d2'>root element is <sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:diagnostics>
        <sch:diagnostic id='d1' role='warning' icon='abc' see='def' fpi='xyz' xml:lang='en' xml:space='preserve'>wrong</sch:diagnostic>
        <sch:diagnostic id='d2'>more here</sch:diagnostic>
      </sch:diagnostics>
    </sch:schema>,
    ''
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
      <svrl:text>root element is foo</svrl:text>
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:diagnostic-reference,
      (
        <svrl:diagnostic-reference diagnostic='d1'><svrl:text>wrong</svrl:text></svrl:diagnostic-reference>,
        <svrl:diagnostic-reference diagnostic='d2'><svrl:text>more here</svrl:text></svrl:diagnostic-reference>
      )
    ),
    unit:assert-equals(
      $result/svrl:failed-assert,
      (
        <svrl:failed-assert
        test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:diagnostic-reference diagnostic='d1'><svrl:text>wrong</svrl:text></svrl:diagnostic-reference><svrl:diagnostic-reference diagnostic='d2'><svrl:text>more here</svrl:text></svrl:diagnostic-reference><svrl:text>root element is foo</svrl:text></svrl:failed-assert>
      )
    )
  )
};

(: PROPERTIES :)

(:~ property references reported correctly in SVRL :)
declare %unit:test function _:test-properties()
{
    let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:let name='root-name' value='name(*)'/>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='name() eq "bar"' properties='p1'>root element is <sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:properties>
        <sch:property id='p1' scheme='abc' role='def'>wrong=<sch:value-of select='$root-name'/></sch:property>
      </sch:properties>
    </sch:schema>,
    ''
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
      <svrl:text>root element is foo</svrl:text>
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:property-reference,
      (
        <svrl:property-reference property='p1' scheme='abc' role='def'><svrl:text>wrong=foo</svrl:text></svrl:property-reference>
      )
    ),
    unit:assert-equals(
      $result/svrl:failed-assert,
      (
        <svrl:failed-assert
        test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:property-reference property='p1' scheme='abc' role='def'><svrl:text>wrong=foo</svrl:text></svrl:property-reference><svrl:text>root element is foo</svrl:text></svrl:failed-assert>
      )
    )
  )
};

(:~ multiple property references reported correctly in SVRL :)
declare %unit:test function _:test-properties-multiple()
{
    let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='name() eq "bar"' properties='p1 p2'>root element is <sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:properties>
        <sch:property id='p1' scheme='abc' role='def'>wrong</sch:property>
        <sch:property id='p2' scheme='ghi' role='jkl'>still wrong</sch:property>
      </sch:properties>
    </sch:schema>,
    ''
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
      <svrl:text>root element is foo</svrl:text>
    ),
    unit:assert(
      count($result/svrl:failed-assert/svrl:property-reference) = 2
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:property-reference,
      (
        <svrl:property-reference property='p1' scheme='abc' role='def'><svrl:text>wrong</svrl:text></svrl:property-reference>,
        <svrl:property-reference property='p2' scheme='ghi' role='jkl'><svrl:text>still wrong</svrl:text></svrl:property-reference>
      )
    )
  )
};

(:~ children of property handled in SVRL :)
declare %unit:test function _:test-properties-mixed-content()
{
    let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='name() eq "bar"' properties='p1'>root element is <sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
      <sch:properties>
        <sch:property id='p1' role='warning' icon='abc' see='def' fpi='xyz' xml:lang='en' xml:space='preserve'><sch:name/><foreign/><sch:emph/><sch:dir value='ltr'>dir<foreign/></sch:dir> and <sch:span class='blort'>span<foreign/></sch:span>wrong</sch:property>
      </sch:properties>
    </sch:schema>,
    ''
  )
  return (
    unit:assert(
      count($result/svrl:failed-assert/svrl:property-reference) = 1      
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/@property[.='p1']
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/svrl:text
    ),
    unit:assert(
      starts-with($result/svrl:failed-assert/svrl:property-reference/svrl:text,
      'foo')
    ),
    unit:assert(
      ends-with($result/svrl:failed-assert/svrl:property-reference/svrl:text,
      'wrong')
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/svrl:text/foreign
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/svrl:text/svrl:emph
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/svrl:text/svrl:dir[@value='ltr']
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/svrl:text/svrl:span[@class='blort']
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:property-reference/svrl:text/svrl:span[@class='blort']/foreign
    ),
    unit:assert(
      $result/svrl:failed-assert/svrl:text[.='root element is foo']
    ),
    unit:assert-equals(
      $result/svrl:failed-assert,
      (
        <svrl:failed-assert
        test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:property-reference property='p1' role='warning'><svrl:text>foo<foreign/><svrl:emph/><svrl:dir value='ltr'>dir<foreign/></svrl:dir> and <svrl:span class='blort'>span<foreign/></svrl:span>wrong</svrl:text></svrl:property-reference><svrl:text>root element is foo</svrl:text></svrl:failed-assert>
      )
    )
  )
};

(: GLOBAL VARIABLES :)

declare %unit:test function _:global-variable-bindings()
{
  let $bindings := context:evaluate-global-variables(
    (<sch:let name='foo' value='/*/@bar'/>, <sch:let name='blort' value='/*/*'/>),
    document{<foo bar='some value'><blort/></foo>},
    '',
    (),
    map{}
  )
  return (
    unit:assert-equals(
      map:keys($bindings), 
      (xs:QName('foo'), xs:QName('blort'))
    ),
    unit:assert-equals(
      $bindings, 
      map{
        xs:QName('foo'):attribute{'bar'}{'some value'},
        xs:QName('blort'):<blort/>
      }
    )
  )
};

(:~ global variable evaluated in context of lexically previous one :)
declare %unit:test function _:test-global-variable-relies-on-previous()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:let name='allowed-name' value='name($allowed)'/>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed, as defined in <sch:value-of select='$allowed-name'/></sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report,
    (
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed, as defined in allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ pattern variable is scoped to pattern
 : @see https://github.com/Schematron/schematron-conformance/blob/master/src/main/resources/tests/core/let-scope-pattern-01.xml
 :)
declare %unit:test function _:test-pattern-variable-scope()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:let name="foo" value="0"/>
      <sch:pattern>
        <sch:let name="foo" value="1"/>
        <sch:rule context="*">
          <sch:assert test="$foo = 1"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="$foo = 0"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return (
    unit:assert(count($result/svrl:active-pattern)=2),
    unit:assert(count($result/svrl:fired-rule[@context='*'])=2),
    unit:assert-equals(
      $result/svrl:failed-assert,
      ()
    )
  )
};

(:~ scope of rule variable :)
declare %unit:test function _:test-rule-variable-scope()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:let name="foo" value="0"/>
      <sch:pattern>
        <sch:let name="foo" value="1"/>
        <sch:rule context="*">
          <sch:let name="foo" value="2"/>
          <sch:assert test="$foo = 2"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="$foo = 0"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return (
    unit:assert(count($result/svrl:active-pattern)=2),
    unit:assert(count($result/svrl:fired-rule[@context='*'])=2),
    unit:assert-equals(
      $result/svrl:failed-assert,
      ()
    )
  )
};

(:~ (prefixed~) pattern variable is scoped to pattern
 : @see https://github.com/Schematron/schematron-conformance/blob/master/src/main/resources/tests/core/let-scope-pattern-01.xml
 :)
declare %unit:test function _:test-pattern-variable-scope-with-nss()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:ns prefix='x' uri='y'/>
      <sch:let name="x:foo" value="0"/>
      <sch:pattern>
        <sch:let name="x:foo" value="1"/>
        <sch:rule context="*">
          <sch:assert test="$x:foo = 1"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="$x:foo = 0"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return (
    unit:assert(count($result/svrl:active-pattern)=2),
    unit:assert(count($result/svrl:fired-rule[@context='*'])=2),
    unit:assert-equals(
      $result/svrl:failed-assert,
      ()
    )
  )
};

(:~ local variable with namespace prefix :)
declare %unit:test function _:test-rule-variable-with-nss()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:ns prefix='x' uri='y'/>
      <sch:pattern>
        <sch:rule context="*">
          <sch:let name="x:foo" value="1"/>
          <sch:assert test="$x:foo = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  return (
    unit:assert(count($result/svrl:active-pattern)=1),
    unit:assert(count($result/svrl:fired-rule[@context='*'])=1),
    unit:assert-equals(
      $result/svrl:failed-assert,
      ()
    )
  )
};

(:TODO
- 
:)