<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:pattern id='wibble'>
        <sch:rule context='/foo' visit-each='analyze-string(., "foo")/fn:match'>
            <sch:report test='.'><sch:value-of select='.'/> at index <sch:value-of select='string-length(
                string-join(preceding-sibling::fn:*))+1'/></sch:report>
        </sch:rule>
    </sch:pattern>
</sch:schema>