<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" 
xmlns:xqy='http://www.w3.org/2012/xquery'>
      <xqy:prolog>import module namespace fun = 'my-functions' at '../fun.xqm';</xqy:prolog>
      
      <sch:pattern id='a'>
        <sch:rule context="*">
          <sch:report test="fun:element-name-is-root(.)"><sch:name/>=<sch:value-of select='fun:element-name-is-root(.)'/></sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>