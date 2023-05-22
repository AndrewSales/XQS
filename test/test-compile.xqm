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

(:~ report processed, with pattern variable :)
declare %unit:test function _:process-report-with-pattern-variable()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern>
        <sch:let name='allowed' value='foo/@allowed'/>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
          <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed: <sch:value-of select='$allowed'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    '')
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo allowed='bar'/>}}
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
  let $compiled := compile:schema(
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
          <sch:report test='not(name(.) = $allowed)'>name <sch:name/> is not allowed</sch:report>
          <sch:report test='$allowed/self::allowed'></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    '')
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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

(: DIAGNOSTICS :)

(:~ diagnostics reported correctly in SVRL :)
declare %unit:test function _:diagnostics()
{
    let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
    let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
    let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
    let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}},
    map{'pass':'true'}
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
    let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
    let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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

(:~ entities, re https://mailman.uni-konstanz.de/pipermail/basex-talk/2023-May/017962.html :)
declare %unit:test function _:built-in-entities-rule-assert()
{
  let $compiled := compile:schema(
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
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo>&lt;&amp;&gt;&apos;&quot;</foo>}}
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 5)
  )
};

declare %unit:test function _:built-in-entities-global-variable()
{
  let $compiled := compile:schema(
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
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo>&lt;&amp;&gt;&apos;&quot;</foo>}}
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 6)
  )
};

declare %unit:test function _:built-in-entities-namespaces()
{
  let $compiled := compile:schema(
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
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo>&lt;&amp;&gt;&apos;&quot;</foo>}}
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 6)
  )
};

(:~ see https://github.com/AndrewSales/XQS/issues/10 :)
declare %unit:test function _:assertion-message-braces()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern>
        <sch:rule context="/">
          <sch:report test="*">{{</sch:report>
          <sch:report test="*">}}</sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo>{{}}</foo>}}
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 2)
  )
};

declare %unit:test function _:test-message-braces()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern>
        <sch:rule context="/*">
          <sch:report test="contains(., '{{')"></sch:report>
          <sch:report test="contains(., '}}')"></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo>{{}}</foo>}}
  )
  return (
    unit:assert($result/svrl:successful-report),
    unit:assert-equals(
      count($result/svrl:successful-report),
      2
    )
  )
};

(:DOCUMENTS ATTRIBUTE:)

declare %unit:test function _:pattern-documents()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern documents="/element/@secondary">
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:doc('document-01.xml')}
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
  let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern documents="/foo/subordinate">
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:doc('document-03.xml')}
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

(: USER-DEFINED FUNCTIONS :)

declare %unit:test function _:user-defined-function()
{
  let $compiled := compile:schema(
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
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<root/>}}
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