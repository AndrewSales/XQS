<?xml version="1.0" encoding="UTF-8"?>
<!-- 
Error:
Stopped at C:/.../mySchema-with-xqueryfcns.sch, 3/5:
[XPTY0004] Cannot convert document-node() to element(link): document { "file:///C:/.../sample-link.xml" }.
- C:/.../github/XQS/evaluate.xqm, 218/27
- C:/.../github/XQS/evaluate.xqm, 182/43
- C:/.../github/XQS/evaluate.xqm, 97/17
- C:/.../github/XQS/evaluate.xqm, 385/15
- C:/.../github/XQS/evaluate.xqm, 56/14
- C:/.../github/XQS/xqs.xqm, 24/14
- C:/.../validate-xqueryfcns.xq, 2/13

 -->
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xquery"
xmlns:sch="http://purl.oclc.org/dsdl/schematron">

  <sch:pattern>
    <sch:rule context="/descendant::link[@href]">
      <sch:let name="source-uri" value="local:get-source-uri(.)"/>
      <sch:assert id="temp" test="false()"><sch:value-of select="$source-uri"/></sch:assert>
    </sch:rule>
  </sch:pattern>

  <function xmlns="http://www.w3.org/2012/xquery">
    declare function local:get-source-uri(
    $ctxt as element(link)
    ) {
        resolve-uri(
          replace('foo.html', '\.html$', '.xml'),
          base-uri($ctxt)
        )
    };
  </function>

</schema>
