<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
xmlns:xqy = 'http://www.w3.org/2012/xquery'>
  <xqy:prolog>import module namespace xqs-crepdl = 'http://www.andrewsales.com/ns/crepdl' at '../../crepdl.xqm';</xqy:prolog>
  <sch:ns prefix='c' uri='http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0'/>
  <sch:ns prefix='crepdl' uri='http://www.andrewsales.com/ns/crepdl'/>
  <sch:pattern>
    <sch:rule context='*'>
      <sch:let name='crepdl-schema' value='resolve-uri("basic-latin.crepdl", base-uri())'/>
      <sch:let name='crepdl-result' value='crepdl:validate-string(., $crepdl-schema)' as='element(c:result)'/>
      <sch:report test='$crepdl-result/c:*'>unknown='<sch:value-of select='$crepdl-result/c:unknown'/>'; not included='<sch:value-of select='$crepdl-result/c:notIncluded'/>'</sch:report>
    </sch:rule>
  </sch:pattern>
</sch:schema>