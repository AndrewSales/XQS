<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:pattern id='wibble'>
        <sch:rule context='/foo'>
            <sch:let name='var' value='12' as='xs:integer'/>
            <sch:report test='$var instance of xs:integer'><sch:value-of select='$var'/> is an integer</sch:report>
            <sch:assert test='$var instance of xs:string'><sch:value-of select='$var'/> is not a string</sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>