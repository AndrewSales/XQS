(:~ 
 : Unit tests for evaluating schema assertions.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-evaluation-tests';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace xqy = 'http://www.w3.org/2012/xquery';  

import module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate' 
  at '../evaluate.xqm';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' 
  at '../context.xqm';  

(:~ schema title passed through to SVRL :)
declare %unit:test function _:eval-schema-title()
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
    </sch:schema>
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
declare %unit:test function _:eval-schema-no-title()
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
    </sch:schema>
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
declare %unit:test function _:eval-schema-phase()
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
    </sch:schema>
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
declare %unit:test function _:eval-schema-no-phase()
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
    </sch:schema>
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
declare %unit:test function _:eval-schema-namespaces()
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
    </sch:schema>
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
declare %unit:test function _:process-pattern()
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

(:~ active group processed :)
declare %unit:test function _:process-group()
{
  let $result := eval:group(
    <sch:group id='e' name='f' role='g'>
      <sch:rule context='*' id='a' name='b' role='c' flag='d'/>
    </sch:group>,
    map{'instance':document{<foo/>}, 'globals':map{}}
  )
  return unit:assert-equals(
    $result,
    (<svrl:active-group id='e' name='f' role='g'/>,
    <svrl:fired-rule context='*' id='a' name='b' role='c' flag='d'/>)
  )
};

(:~ rule in active pattern processed :)
declare %unit:test function _:process-rule()
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
declare %unit:test function _:process-rule-local-variable()
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
function _:invalid-assertion-element()
{
  eval:assertion(
    <sch:invalid-assertion-element test='.'/>,
    '',
    <foo/>,
    map{}
  )
};

(:~ assert processed, with local variable :)
declare %unit:test function _:process-assert-with-variable()
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
declare %unit:test function _:process-report-with-variable()
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
declare %unit:test function _:process-report-with-global-variable()
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
    </sch:schema>
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
declare %unit:test function _:process-report-with-pattern-variable()
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
    </sch:schema>
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
declare %unit:test function _:process-report-with-global-variable-element-node()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed</sch:report>
        <sch:report test='$allowed/self::allowed'></sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report,
    (
      <svrl:successful-report 
      test='not(name(.) = $allowed)' location='/Q{{}}foo[1]'><svrl:text>name foo is not allowed</svrl:text></svrl:successful-report>,
      <svrl:successful-report 
      test='$allowed/self::allowed' location='/Q{{}}foo[1]'><svrl:text></svrl:text></svrl:successful-report>
    )
  )
};

(:~ global variable reference in value-of :)
declare %unit:test function _:global-variable-in-value-of()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='$allowed/self::allowed'><sch:value-of select='$allowed/name()'/></sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report,
    (
      <svrl:successful-report 
      test='$allowed/self::allowed' location='/Q{{}}foo[1]'><svrl:text>allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ global variable reference in name :)
declare %unit:test function _:global-variable-in-name()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='$allowed/self::allowed'><sch:name path='$allowed/name()'/></sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return
  unit:assert-equals(
    $result/svrl:successful-report,
    (
      <svrl:successful-report 
      test='$allowed/self::allowed' location='/Q{{}}foo[1]'><svrl:text>allowed</svrl:text></svrl:successful-report>
    )
  )
};

(:~ report processed, with local variable as element node :)
declare %unit:test function _:process-report-with-variable-element-node()
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
declare %unit:test function _:value-of()
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
declare %unit:test function _:name-path()
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
declare %unit:test function _:assertion-message-elements()
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
declare %unit:test function _:multiple-results()
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
      <svrl:fired-rule context='//bar'/>,
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]/Q{{}}bar[2]'><svrl:text>bar found, child of foo</svrl:text></svrl:successful-report>
    )
  )
};

(:~ Processing in a pattern halts when a rule context is matched:
 : "A rule element acts as an if-then-else statement within each pattern." 
 : @see ISO2020, 6.5
 :)
declare %unit:test function _:rule-halt-on-match()
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
declare %unit:test function _:rule-continue-on-no-match()
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

(:~ "A rule context (3.19) is said to match an information item when that 
 : information item has not been matched by any lexically-previous rule-context
 : expressions in the same pattern (3.13) and the information item is one of
 : the information items that the query would specify"
 : "A rule element acts as an if-then-else statement within each pattern." 
 : @see ISO2020, 3.20 & 6.5
 :)
declare %unit:test function _:rule-processing()
{
  (:The third rule will not fire, since it was matched by the previous one. But
  the fourth rule does fire, since it hasn't been matched yet. Likewise, the 
  last rule has already been matched, so doesn't fire.:)
  let $result := eval:pattern(
    <pattern xmlns='http://purl.oclc.org/dsdl/schematron'>
        <rule context="/article"><report test=".">article</report></rule>
        <rule context="/article/section[true()]"><report test=".">section</report></rule>
        <rule context="/article/section[@role='foo']"><report test=".">section role='foo'</report></rule>
        <rule context="/article/section/@role"><report test=".">@role</report></rule>
         <rule context="/article/section/@role[.='foo']"><report test=".">@role = 'foo'</report></rule>
    </pattern>,
    map{
      'instance':document{<article><section role='foo'/></article>},
      'globals':map{}
    }
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:active-pattern/>,
      <svrl:fired-rule context='/article'/>,
      <svrl:successful-report
      test='.' location='/Q{{}}article[1]'><svrl:text>article</svrl:text></svrl:successful-report>,
      <svrl:fired-rule context='/article/section[true()]'/>,
      <svrl:successful-report
      test='.' location='/Q{{}}article[1]/Q{{}}section[1]'><svrl:text>section</svrl:text></svrl:successful-report>,
      <svrl:fired-rule context='/article/section/@role'/>,
      <svrl:successful-report
      test='.' location='/Q{{}}article[1]/Q{{}}section[1]/@role'><svrl:text>@role</svrl:text></svrl:successful-report>
    )
  )
};

(:~ Groups turn off the if-then-else processing of the rules they contain.
 : @see https://github.com/Schematron/schematron-enhancement-proposals/issues/25
 :)
declare %unit:test function _:group-continue-on-match()
{
  let $result := eval:group(
    <sch:group>
      <sch:rule context='*'>
        <sch:assert test='name() eq "bar"'>root element is <sch:name/></sch:assert>
      </sch:rule>
      <sch:rule context='foo'>
        <sch:report test='.'>should reach here</sch:report>
      </sch:rule>
    </sch:group>,
    map{'instance':document{<foo/>}, 'globals':map{}}
  )
  return
  unit:assert-equals(
    $result,
    (
      <svrl:active-group/>,
      <svrl:fired-rule context='*'/>,
      <svrl:failed-assert 
      test='name() eq "bar"' location='/Q{{}}foo[1]'><svrl:text>root element is foo</svrl:text></svrl:failed-assert>,
      <svrl:fired-rule context='foo'/>,
      <svrl:successful-report 
      test='.' location='/Q{{}}foo[1]'><svrl:text>should reach here</svrl:text></svrl:successful-report>
    )
  )
};

declare %unit:test function _:schema-group-continue-on-match()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema><sch:group>
      <sch:rule context='*'>
        <sch:assert test='name() eq "bar"'>root element is <sch:name/></sch:assert>
      </sch:rule>
      <sch:rule context='foo'>
        <sch:report test='.'>should reach here</sch:report>
      </sch:rule>
    </sch:group></sch:schema>
  )
  return (
    unit:assert-equals(
      count($result/svrl:active-group),
      1
    ),
    unit:assert-equals(
      count($result/svrl:fired-rule),
      2
    ),
    unit:assert-equals(
      count($result/svrl:failed-assert),
      1
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      1
    )
  )
};

(: DIAGNOSTICS :)

(:~ diagnostics reported correctly in SVRL :)
declare %unit:test function _:diagnostics()
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
    </sch:schema>
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
declare %unit:test function _:diagnostics-mixed-content()
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
    </sch:schema>
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
declare %unit:test function _:diagnostics-multiple()
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
    </sch:schema>
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
declare %unit:test function _:properties()
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
    </sch:schema>
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
declare %unit:test function _:properties-multiple()
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
    </sch:schema>
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
declare %unit:test function _:properties-mixed-content()
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
    </sch:schema>
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
    map{},
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
declare %unit:test function _:global-variable-relies-on-previous()
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
    </sch:schema>
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
declare %unit:test function _:pattern-variable-scope()
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
    </sch:schema>
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
declare %unit:test function _:rule-variable-scope()
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
    </sch:schema>
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
declare %unit:test function _:pattern-variable-scope-with-nss()
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
    </sch:schema>
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
declare %unit:test function _:rule-variable-with-nss()
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
    </sch:schema>
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

(:~ entities, re https://mailman.uni-konstanz.de/pipermail/basex-talk/2023-May/017962.html :)
declare %unit:test function _:built-in-entities-rule-assert()
{
  let $result := eval:schema(
    document{<foo>&lt;&amp;&gt;&apos;&quot;</foo>},
    <sch:schema>
      <sch:ns prefix='x' uri='y'/>
      <sch:pattern>
        <sch:rule context="*[contains(., '&amp;') or contains(., '&lt;') or contains(., '&gt;')]">
          <sch:report test="contains(., '&amp;')"/>
          <sch:report test="contains(., '&lt;')"/>
          <sch:report test="contains(., '&gt;')"/>
          <sch:report test='contains(., "&apos;")'/>
          <sch:report test="contains(., '&quot;')"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 5)
  )
};

declare %unit:test function _:built-in-entities-global-variable()
{
  let $result := eval:schema(
    document{<foo>&lt;&amp;&gt;&apos;&quot;</foo>},
    <sch:schema>
      <sch:ns prefix='x' uri='y'/>
      <sch:let name='foo' value="/*[contains(., '&amp;') or contains(., '&lt;') or contains(., '&gt;')]"/>
      <sch:pattern>
        <sch:rule context="*[contains(., '&amp;') or contains(., '&lt;') or contains(., '&gt;')]">
          <sch:report test="contains(., '&amp;')"/>
          <sch:report test="contains(., '&lt;')"/>
          <sch:report test="contains(., '&gt;')"/>
          <sch:report test='contains(., "&apos;")'/>
          <sch:report test="contains(., '&quot;')"/>
          <sch:report test='$foo'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 6)
  )
};

declare %unit:test function _:built-in-entities-namespaces()
{
  let $result := eval:schema(
    document{<foo>&lt;&amp;&gt;&apos;&quot;</foo>},
    <sch:schema>
      <sch:ns prefix='x' uri='y&amp;z'/>
      <sch:let name='x:foo' value="/*[contains(., '&amp;') or contains(., '&lt;') or contains(., '&gt;')]"/>
      <sch:pattern>
        <sch:rule context="*[contains(., '&amp;') or contains(., '&lt;') or contains(., '&gt;')]">
          <sch:report test="contains(., '&amp;')"/>
          <sch:report test="contains(., '&lt;')"/>
          <sch:report test="contains(., '&gt;')"/>
          <sch:report test='contains(., "&apos;")'/>
          <sch:report test="contains(., '&quot;')"/>
          <sch:report test='$x:foo'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 6)
  )
};

(:don't allow the XML namespace to be (re-)declared :)
declare %unit:test function _:xml-ns-decls()
{
  let $result := eval:schema(
    document{<foo xml:lang='en' xml:space='default' xml:base='blort.xml'></foo>},
    <sch:schema>
      <sch:ns prefix='xml' uri=''/>
      <sch:pattern>
        <sch:rule context="*/@xml:*">
          <sch:report test="."/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )  
  return (
    unit:assert(count($result/svrl:successful-report) = 3)
  )
};

(:DOCUMENTS ATTRIBUTE:)

declare %unit:test function _:pattern-documents()
{
  let $result := eval:schema(
    doc('document-01.xml'),
    <sch:schema>
      <sch:pattern documents="/element/@secondary">
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert($result/svrl:active-pattern/@documents),
    unit:assert-equals(
      count($result/svrl:successful-report),
      1
    )
  )
};

declare %unit:test function _:pattern-documents-multiple()
{
  let $result := eval:schema(
    doc('document-03.xml'),
    <sch:schema>
      <sch:pattern documents="/foo/subordinate">
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert($result/svrl:active-pattern/@documents),
    unit:assert-equals(
      count($result/svrl:successful-report),
      2
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[1]/@document/data(),
      resolve-uri('document-04.xml', static-base-uri())
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[2]/@document/data(),
      resolve-uri('document-05.xml', static-base-uri())
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[3]/@document/data(),
      resolve-uri('document-06.xml', static-base-uri())
    )
  )
};

(:~ re https://github.com/AndrewSales/XQS/issues/17 :)
declare %unit:test('expected', 'err:XPST0008') function _:pattern-documents-variable-scope()
{
  eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:pattern documents="/foo/subordinate[$bar]">
        <sch:let name='bar' value='"blort"'/>
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
};

(:~ see https://github.com/AndrewSales/XQS/issues/10 :)
declare %unit:test function _:assertion-message-braces()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context="/">
          <sch:report test="*">{{</sch:report>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
      <sch:rule context="/">
          <sch:report test="*"><foo>}}</foo></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      count($result/svrl:successful-report),
      2
    ),
    unit:assert-equals(
      $result/svrl:successful-report[1]/data(),
      '{'
    ),
    unit:assert-equals(
      $result/svrl:successful-report[2]/svrl:text/foo/data(),
      '}'
    )
  )
};

(: USER-DEFINED FUNCTIONS :)

declare %unit:test function _:user-defined-function()
{
  let $result := eval:schema(
    document{<root/>},
    <sch:schema>
      <sch:ns prefix='myfunc' uri='xyz'/>
      <function xmlns='http://www.w3.org/2012/xquery'>
      declare function myfunc:test($arg as xs:string) as xs:string{{$arg}};
      </function>
      <sch:pattern>
        <sch:rule context="/">
          <sch:report test="root"><sch:value-of select='myfunc:test(name(root))'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      count($result/svrl:successful-report),
      1
    ),
    unit:assert-equals(
      $result/svrl:successful-report/data(),
      'root'
    )
  )
};

declare %unit:test function _:user-defined-function-from-file()
{
  let $result := eval:schema(
    document{<root/>},
    doc('user-defined-function.xml')/*
  )
  return (
    unit:assert-equals(
      count($result/svrl:successful-report),
      1
    ),
    unit:assert-equals(
      $result/svrl:successful-report/data(),
      'root'
    )
  )
};

declare %unit:test function _:undetected-syntax-error()
{
  let $result := eval:schema(
    document{<root/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context="/..">
          <sch:report test="?????"><sch:value-of select='myfunc:test(name(root))'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      count($result/svrl:successful-report),
      0
    )
  )
};

declare %unit:test function _:map-global-variable()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:let name='foo' value="map{{'a':'{{'}}" as='map(*)'/>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="$foo instance of map(*)"/>
          <sch:report test="not($foo instance of map(*))"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert(empty($result/svrl:failed-assert)),
    unit:assert(empty($result/svrl:successful-report))
  )
};

declare %unit:test function _:map-pattern-variable()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:let name='foo' value="map{{'a':'{{'}}" as='map(*)'/>
        <sch:rule context="/">
          <sch:assert test="$foo instance of map(*)"/>
          <sch:report test="not($foo instance of map(*))"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert(empty($result/svrl:failed-assert)),
    unit:assert(empty($result/svrl:successful-report))
  )
};

declare %unit:test function _:map-rule-variable()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="/">
          <sch:let name='foo' value="map{{'a':'{{'}}" as='map(*)'/>
          <sch:assert test="$foo instance of map(*)"/>
          <sch:report test="not($foo instance of map(*))"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert(empty($result/svrl:failed-assert)),
    unit:assert(empty($result/svrl:successful-report))
  )
};

declare %unit:test function _:global-variable-syntax-error()
{
  let $result := eval:schema(
    document{<root/>},
     doc('global-variable-syntax-error.sch')/*,
    map{'dry-run':'true'}
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/@location/data(),
      "/Q{http://purl.oclc.org/dsdl/schematron}schema[1]/Q{http://purl.oclc.org/dsdl/schematron}let[1]/@value" 
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/@err:code/data(),
      "err:XPST0003" 
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
      <svrl:text>No specifier after lookup operator: ';'. @value='?'</svrl:text>
    )
  )
};

declare %unit:test function _:pattern-variable-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:let name='y' value='$'/>
        <sch:rule context="/">
          <sch:report test="true()"></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      $result/svrl:failed-assert[ends-with(@location ,'/Q{http://purl.oclc.org/dsdl/schematron}pattern[1]/Q{http://purl.oclc.org/dsdl/schematron}let[1]/@value')]
      /svrl:text,
      <svrl:text>Incomplete FLWOR expression, expecting 'return'. @value='$'</svrl:text>
    )
  )
};

declare %unit:test function _:rule-context-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="">
          <sch:report test="true()"></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
      <svrl:text>Expecting expression. @context=''</svrl:text>
    )
  )
};

declare %unit:test function _:dry-run-all-rules-processed()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="">
        </sch:rule>
        <sch:rule context='*'></sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      count($result/svrl:fired-rule),
      2
    )
  )
};

declare %unit:test function _:rule-variable-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="*">
          <sch:let name='bar' value=''/>
          <sch:assert test='foo'/>
        </sch:rule>
        <sch:rule context='*'></sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      count($result/svrl:failed-assert[ends-with(@location, '/Q{http://purl.oclc.org/dsdl/schematron}pattern[1]/Q{http://purl.oclc.org/dsdl/schematron}rule[1]/Q{http://purl.oclc.org/dsdl/schematron}let[1]/@value')]),
      1
    ),
    unit:assert-equals(
     $result/svrl:failed-assert[ends-with(@location, '/Q{http://purl.oclc.org/dsdl/schematron}pattern[1]/Q{http://purl.oclc.org/dsdl/schematron}rule[1]/Q{http://purl.oclc.org/dsdl/schematron}let[1]/@value')]/svrl:text,
    <svrl:text>Incomplete FLWOR expression, expecting 'return'. @value=''</svrl:text>
    )
  )
};

declare %unit:test function _:report-test-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="*">
          <sch:report test='ns:*'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      count($result/svrl:failed-assert[ends-with(@location, '/Q{http://purl.oclc.org/dsdl/schematron}pattern[1]/Q{http://purl.oclc.org/dsdl/schematron}rule[1]/Q{http://purl.oclc.org/dsdl/schematron}report[1]/@test')]),
      1
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
    <svrl:text>Namespace prefix not declared: ns. @test='ns:*'</svrl:text>  
    )
  )
};

declare %unit:test function _:name-path-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="*">
          <sch:report test="."><sch:name path='...'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      count($result/svrl:failed-assert[ends-with(@location, '/Q{http://purl.oclc.org/dsdl/schematron}pattern[1]/Q{http://purl.oclc.org/dsdl/schematron}rule[1]/Q{http://purl.oclc.org/dsdl/schematron}report[1]/Q{http://purl.oclc.org/dsdl/schematron}name[1]/@path')]),
      1
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
    <svrl:text>Unexpected end of query: '.'. @path='...'</svrl:text>  
    )
  )
};

declare %unit:test function _:value-of-select-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:pattern>
        <sch:rule context="*">
          <sch:report test="."><sch:value-of select='...'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      count($result/svrl:failed-assert[ends-with(@location, '/Q{http://purl.oclc.org/dsdl/schematron}pattern[1]/Q{http://purl.oclc.org/dsdl/schematron}rule[1]/Q{http://purl.oclc.org/dsdl/schematron}report[1]/Q{http://purl.oclc.org/dsdl/schematron}value-of[1]/@select')]),
      1
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/svrl:text,
    <svrl:text>Unexpected end of query: '.'. @select='...'</svrl:text>  
    )
  )
};

declare %unit:test function _:phase-variable-scope-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
       <sch:phase id='one'>
         <sch:let name='foo' value='bar'/>
         <sch:active pattern='a'/>
       </sch:phase>
       <sch:phase id='two'>
         <sch:active pattern='a'/>
       </sch:phase>
      <sch:pattern id='a'>
        <sch:rule context="*">
          <sch:report test="."><sch:value-of select='$foo'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true', 'phase':'two'}
  )
  return
  (
    unit:assert-equals(
      ($result/svrl:failed-assert)[1]/svrl:text,
      <svrl:text>Undeclared variable: $foo. @select='$foo'</svrl:text>
    )
  )
};

(:TODO:)
declare %unit:ignore function _:function-syntax-error()
{
  let $result :=
  eval:schema(
    document{<root/>},
     <sch:schema>
      <xqy:function></xqy:function> 
      <sch:pattern id='a'>
        <sch:rule context="*">
          <sch:report test="."><sch:value-of select='foo'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'dry-run':'true'}
  )
  return
  (
    unit:assert-equals(
      ($result/svrl:failed-assert)[1]/svrl:text,
      <svrl:text>Calculation is incomplete. xqy:function='declare function local:foo(){{**}};'</svrl:text>
    )
  )
};

declare %unit:test function _:subject-assert()
{
    let $result := eval:schema(
    document{<foo bar='blort'/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='@bar eq "bar"' subject='@bar'>expected 'bar'; got <sch:value-of select='@bar'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/@location/data(),
      '/Q{}foo[1]/@bar'
    )
  )
};

declare %unit:test function _:subject-report()
{
    let $result := eval:schema(
    document{<foo bar='blort'/>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:report test='@bar ne "bar"' subject='@bar'>expected 'bar'; got <sch:value-of select='@bar'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:successful-report/@location/data(),
      '/Q{}foo[1]/@bar'
    )
  )
};

declare %unit:test function _:subject-rule()
{
    let $result := eval:schema(
    document{<root><foo bar='blort'/></root>},
    <sch:schema>
      <sch:pattern>
        <sch:rule context='//foo' subject='..'>
          <sch:assert test='@bar eq "bar"'>expected 'bar'; got <sch:value-of select='@bar'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/@location/data(),
      '/Q{}root[1]'
    )
  )
};

(:~ Without @from, this will identify 3 blort elements, rather than the 2 at 
 : the XPath specified by @from. 
 :)
declare %unit:test function _:phase-from-attribute()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:phase id='wibble' from='/foo/bar'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:pattern id='wibble'>
        <sch:rule context='.//blort[@wibble]'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'phase':'wibble'}
  )
  return (
    unit:assert-equals(
      count($result/svrl:successful-report),
      2
    )
  )
};

(:~ @from present, but relevant phase not selected, so this will identify all 
 : 3 blort elements, rather than the 2 at the XPath specified by @from. 
 :)
declare %unit:test function _:phase-from-attribute-no-phase()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:phase id='wibble' from='/foo/bar'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:pattern id='wibble'>
        <sch:rule context='.//blort[@wibble]'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      count($result/svrl:successful-report),
      3
    )
  )
};

(:~ @from present and phase selected, but evaluation result is empty: rule does
 : not fire and so no assertions are evaluated.
 :)
declare %unit:test function _:phase-from-attribute-evaluates-empty()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:phase id='wibble' from='/no/such/path'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:pattern id='wibble'>
        <sch:rule context='.//blort[@wibble]'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'phase':'wibble'}
  )
  return (
    unit:assert-equals(
      count($result/svrl:fired-rule),
      0
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      0
    )
  )
};

(:~ schema/@schematronEdition
 :)
declare %unit:test function _:schematron-edition()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema schematronEdition='2025'>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:report test='true()'><sch:name/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/@schematronEdition/data(),
      '2025'
    )
  )
};

(:~ New attribute severity.
 :)
declare %unit:test function _:attribute-severity()
{
  let $result := eval:schema(
    document{<foo/>},
    <sch:schema schematronEdition='2025'>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:report test='true()' severity='error'><sch:name/></sch:report>
          <sch:assert test='false()' severity='warning'><sch:name/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      count($result/(svrl:successful-report|svrl:failed-assert)/@severity),
      2
    ),
    unit:assert-equals(
      $result/svrl:successful-report/@severity/data(),
      'error'
    ),
    unit:assert-equals(
      $result/svrl:failed-assert/@severity/data(),
      'warning'
    )
  )
};

(:~ @when present and phase selected
 :)
declare %unit:test function _:phase-when-attribute()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:phase id='wibble' when='//@wibble'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:pattern id='wibble'>
        <sch:rule context='//blort[@wibble]'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'phase':'#ANY'}
  )
  return (
    unit:assert-equals(
      count($result/svrl:fired-rule),
      3
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      3
    )
  )
};

(:~ @when present and first matching phase selected
 :)
declare %unit:test function _:phase-when-attribute-first-match()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:phase id='foo' when='/foo'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:phase id='wibble' when='//@wibble'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:phase id='bar' when='/foo/bar'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:pattern id='wibble'>
        <sch:rule context='//blort[@wibble]'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'phase':'#ANY'}
  )
  return (
    unit:assert-equals(
      $result/@phase/data(),
      'foo'
    ),
    unit:assert-equals(
      $result/svrl:active-pattern/@id/data(),
      'wibble'
    ),
    unit:assert-equals(
      count($result/svrl:fired-rule),
      3
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      3
    )
  )
};

(:~ @when present and no matching phase
 :)
declare %unit:test function _:phase-when-attribute-no-match()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:phase id='foo' when='/foot'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:phase id='wibble' when='//@wibblet'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:phase id='bar' when='/foot/bart'>
        <sch:active pattern='wibble'/>
      </sch:phase>
      <sch:pattern id='wibble'>
        <sch:rule context='//blort[@wibble]'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
      <sch:pattern id='non-phase'>
        <sch:rule context='//bar'>
          <sch:report test='blort'><sch:value-of select='count(blort)'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{'phase':'#ANY'}
  )
  return (
    unit:assert-equals(
      $result/@phase,
      ()
    ),
    unit:assert-equals(
      count($result/svrl:active-pattern),
      2
    ),
    unit:assert-equals(
      count($result/svrl:fired-rule),
      4
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      4
    )
  )
};

(:~ @visit-each
 :)
declare %unit:test function _:attribute-visit-each()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:pattern id='wibble'>
        <sch:rule context='//bar' visit-each='blort'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:active-pattern/@id/data(),
      'wibble'
    ),
    unit:assert-equals(
      count($result/svrl:fired-rule),
      4
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      4
    )
  )
};

(:~ @visit-each: SVRL output
 :)
declare %unit:test function _:attribute-visit-each-svrl()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:pattern id='wibble'>
        <sch:rule context='//bar' visit-each='blort'>
          <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:active-pattern/@id/data(),
      'wibble'
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[1]/@context/data(),
      '//bar'
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[2]/@context/data(),
      '//bar'
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[1]/@visit-each/data(),
      'blort'
    ),
    unit:assert-equals(
      $result/svrl:fired-rule[2]/@visit-each/data(),
      'blort'
    )
  )
};

(:~ @visit-each
 :)
declare %unit:test function _:attribute-visit-each-analyze-string()
{
  let $result := eval:schema(
    document{<foo>foo bar blort foo bar</foo>},
    <sch:schema>
      <sch:pattern id='wibble'>
        <sch:rule context='/foo' visit-each='analyze-string(., "foo")/fn:match'>
          <sch:report test='.'><sch:value-of select='.'/> at index <sch:value-of select='string-length(
            string-join(preceding-sibling::fn:*))+1'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:active-pattern/@id/data(),
      'wibble'
    ),
    unit:assert-equals(
      count($result/svrl:fired-rule),
      2
    ),
    unit:assert-equals(
      count($result/svrl:successful-report),
      2
    )
  )
};

(:~ @visit-each with local variable
 :)
declare %unit:test function _:attribute-visit-each-with-let()
{
  let $result := eval:schema(
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    <sch:schema>
      <sch:pattern id='wibble'>
        <sch:rule context='//bar' visit-each='blort'>
          <sch:let name='context' value='.'/>
          <sch:report test='$context/@wibble'><sch:value-of select='$context/@wibble'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert-equals(
      $result/svrl:active-pattern/@id/data(),
      'wibble'
    ),
    unit:assert-equals(
      count($result/svrl:fired-rule),
      4
    ),
    unit:assert-equals(
      count($result/svrl:successful-report[. eq '2']),
      2
    ),
    unit:assert-equals(
      count($result/svrl:successful-report[. eq '3']),
      2
    )
  )
};


(:~ re https://github.com/Schematron/schematron-enhancement-proposals/issues/64 :)
declare %unit:test function _:dynamic-role()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema defaultPhase='phase'>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:let name='dynamic-role' value='"bar"'/>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='false()' role='$dynamic-role'></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert($result/svrl:failed-assert),
    unit:assert-equals(
      $result/svrl:failed-assert/@role/data(),
      'bar'
    )
  )
};

(:~ re https://github.com/Schematron/schematron-enhancement-proposals/issues/64 :)
declare %unit:test function _:dynamic-flag()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema defaultPhase='phase'>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:let name='dynamic-flag' value='"bar"'/>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='false()' flag='$dynamic-flag'></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert($result/svrl:failed-assert),
    unit:assert-equals(
      $result/svrl:failed-assert/@flag/data(),
      'bar'
    )
  )
};

(:~ re https://github.com/Schematron/schematron-enhancement-proposals/issues/64 :)
declare %unit:test function _:dynamic-severity()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema defaultPhase='phase'>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:let name='dynamic-severity' value='"bar"'/>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='false()' severity='$dynamic-severity'></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert($result/svrl:failed-assert),
    unit:assert-equals(
      $result/svrl:failed-assert/@severity/data(),
      'bar'
    )
  )
};

(:~ schema/param, re https://github.com/Schematron/schematron-enhancement-proposals/issues/34 :)
declare %unit:test function _:schema-param()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:param name='myParam' value='"bar"'/>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='false()'><sch:value-of select='$myParam'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
  return (
    unit:assert($result/svrl:failed-assert),
    unit:assert-equals(
      $result/svrl:failed-assert/data(),
      'bar'
    )
  )
};

(:~ override schema/param, re https://github.com/Schematron/schematron-enhancement-proposals/issues/34 
: to address via https://github.com/AndrewSales/XQS/issues/54
:)
declare %unit:ignore function _:schema-param-override()
{
  let $result := eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:param name='myParam' value='"bar"'/>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='false()'><sch:value-of select='$myParam'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    map{
      'params':map{'myParam':'blort'}
    }	(:params passed in should override schema-declared values:)
  )
  return (
    unit:assert($result/svrl:failed-assert),
    unit:assert-equals(
      $result/svrl:failed-assert/data(),
      'blort'
    )
  )
};



(:TODO
@when with @from
@visit-each
@visit-each in SVRL?
@visit-each and @subject?
:)