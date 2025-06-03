<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:pattern id='wibble'>
        <sch:rule context='//bar' visit-each='blort'>
            <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
    </sch:pattern>
</sch:schema>