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

(:don't allow the XML namespace to be (re-)declared :)
declare %unit:test function _:xml-ns-decls()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:ns prefix='xml' uri=''/>
      <sch:pattern>
        <sch:rule context="*/@xml:*">
          <sch:report test="."/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo xml:lang='en' xml:space='default' xml:base='blort.xml'></foo>}}
  )
  return (
    unit:assert(count($result/svrl:successful-report) = 3)
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

declare %unit:test function _:assertion-message-braces-from-file()
{
  let $compiled := compile:schema(
    doc('assertion-message-braces.xml')/*,
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

declare %unit:test function _:test-message-braces-from-file()
{
  let $compiled := compile:schema(
    doc('message-braces.xml')/*,
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

(:~ re https://github.com/AndrewSales/XQS/issues/17 :)
declare %unit:test('expected', 'err:XPST0008') function _:pattern-documents-variable-scope()
{
  compile:schema(
    <sch:schema>
      <sch:pattern documents="/foo/subordinate[$bar]">
        <sch:let name='bar' value='"blort"'/>
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  ) => xquery:eval(map{$_:DOC_PARAM:document{<root/>}})
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

declare %unit:test function _:user-defined-function-from-file()
{
  let $compiled := compile:schema(
    doc('user-defined-function.xml')/*,
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

(: MAPS :)

declare %unit:test function _:map-global-variable()
{
  let $compiled := compile:schema(
     <sch:schema>
      <sch:let name='foo' value="map{{'a':'{{'}}" as='map(*)'/>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="$foo instance of map(*)"/>
          <sch:report test="not($foo instance of map(*))"/>
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
    unit:assert(empty($result/svrl:failed-assert)),
    unit:assert(empty($result/svrl:successful-report))
  )
};

declare %unit:test function _:map-pattern-variable()
{
  let $compiled := compile:schema(
     <sch:schema>
      <sch:pattern>
        <sch:let name='foo' value="map{{'a':'{{'}}" as='map(*)'/>
        <sch:rule context="/">
          <sch:assert test="$foo instance of map(*)"/>
          <sch:report test="not($foo instance of map(*))"/>
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
    unit:assert(empty($result/svrl:failed-assert)),
    unit:assert(empty($result/svrl:successful-report))
  )
};

declare %unit:test function _:map-rule-variable()
{
  let $compiled := compile:schema(
     <sch:schema>
      <sch:pattern>
        <sch:rule context="/">
          <sch:let name='foo' value="map{{'a':'{{'}}" as='map(*)'/>
          <sch:assert test="$foo instance of map(*)"/>
          <sch:report test="not($foo instance of map(*))"/>
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
    unit:assert(empty($result/svrl:failed-assert)),
    unit:assert(empty($result/svrl:successful-report))
  )
};

(:~ schema title passed through to SVRL :)
declare %unit:test function _:compile-schema-title()
{
  let $compiled := compile:schema(
    <sch:schema defaultPhase='phase'>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='.'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<root/>}}
  )
  return
  (
     unit:assert-equals(
      $result/@title/data(),
      'Schema title'
    )
  )
};

(:~ no schema title present :)
declare %unit:test function _:compile-schema-no-title()
{
  let $compiled := compile:schema(
    <sch:schema defaultPhase='phase'>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='.'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
  )
  return
  (
     unit:assert-equals(
      $result/@title,
      ()
    )
  )
};

(:~ phase passed through to SVRL :)
declare %unit:test function _:compile-schema-default-phase()
{
  let $compiled := compile:schema(
    <sch:schema defaultPhase='phase'>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='.'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
  )
  return
  (
    unit:assert-equals(
      $result/@phase/data(),
      'phase'
    ) 
  )
};

(:~ phase passed through to SVRL :)
declare %unit:test function _:compile-schema-explicit-phase()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='.'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    'phase'
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
  )
  return
  (
    unit:assert-equals(
      $result/@phase/data(),
      'phase'
    ) 
  )
};

(:~ no phase present :)
declare %unit:test function _:compile-schema-no-phase()
{
  let $compiled := compile:schema(
    <sch:schema>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='.'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
  )
  return
  (
    unit:assert-equals(
      $result/@phase,
      ()
    ) 
  )
};

(:~ namespaces passed through to SVRL :)
declare %unit:test function _:compile-schema-namespaces()
{
  let $compiled := compile:schema(
    <sch:schema defaultPhase='phase'>
      <sch:title>Schema title</sch:title>
      <sch:ns prefix='a' uri='b'/>
      <sch:let name='c' value='d'/>
      <sch:phase id='phase'>
        <sch:active pattern='foo'/>
      </sch:phase>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='.'/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
  )
  return
  (
    unit:assert-equals(
      $result/svrl:ns-prefix-in-attribute-values,
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
  let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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

(:~ global variable reference in value-of :)
declare %unit:test function _:global-variable-in-value-of()
{
  let $compiled := compile:schema(
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='$allowed/self::allowed'><sch:value-of select='$allowed/name()'/></sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
  let $compiled := compile:schema(
    <sch:schema>
    <sch:let name='allowed'><allowed>bar</allowed></sch:let>
      <sch:pattern>
        <sch:rule context='*' id='a' name='b' role='c' flag='d'>
        <sch:report test='$allowed/self::allowed'><sch:name path='$allowed/name()'/></sch:report>
      </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
  let $compiled := compile:schema(
    <schema xmlns='http://purl.oclc.org/dsdl/schematron'>
      <pattern>
        <rule context="/article"><report test=".">article</report></rule>
        <rule context="/article/section[true()]"><report test=".">section</report></rule>
        <rule context="/article/section[@role='foo']"><report test=".">section role='foo'</report></rule>
        <rule context="/article/section/@role"><report test=".">@role</report></rule>
         <rule context="/article/section/@role[.='foo']"><report test=".">@role = 'foo'</report></rule>
      </pattern>
    </schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<article><section role='foo'/></article>}}
  )
  return
    (
    unit:assert-equals(count($result/svrl:fired-rule), 3),
    unit:assert-equals(
      $result,
      (
        <svrl:schematron-output><svrl:active-pattern/>
        <svrl:fired-rule context='/article'/>
        <svrl:successful-report
        test='.' location='/Q{{}}article[1]'><svrl:text>article</svrl:text></svrl:successful-report>
        <svrl:fired-rule context='/article/section[true()]'/>
        <svrl:successful-report
        test='.' location='/Q{{}}article[1]/Q{{}}section[1]'><svrl:text>section</svrl:text></svrl:successful-report>
        <svrl:fired-rule context='/article/section/@role'/>
        <svrl:successful-report
        test='.' location='/Q{{}}article[1]/Q{{}}section[1]/@role'><svrl:text>@role</svrl:text></svrl:successful-report></svrl:schematron-output>
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
  let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
  let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
  let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
  let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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
  let $compiled := compile:schema(
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
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo/>}}
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

declare %unit:test function _:subject-assert()
{
    let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:assert test='@bar eq "bar"' subject='@bar'>expected 'bar'; got <sch:value-of select='@bar'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo bar='blort'/>}}
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
    let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern>
        <sch:rule context='*'>
          <sch:report test='@bar ne "bar"' subject='@bar'>expected 'bar'; got <sch:value-of select='@bar'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<foo bar='blort'/>}}
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
    let $compiled := compile:schema(
    <sch:schema>
      <sch:pattern>
        <sch:rule context='//foo' subject='..'>
          <sch:assert test='@bar eq "bar"'>expected 'bar'; got <sch:value-of select='@bar'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>,
    ''
  )
  let $result := xquery:eval(
    $compiled,
    map{$_:DOC_PARAM:document{<root><foo bar='blort'/></root>}}
  )
  return (
    unit:assert-equals(
      $result/svrl:failed-assert/@location/data(),
      '/Q{}root[1]'
    )
  )
};