<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron" defaultPhase='wibble'>
    <sch:phase id='wibble' from='/foo/bar'>
        <sch:active pattern='wibble'/>
    </sch:phase>
    <sch:pattern>
        <sch:rule context='blort[@wibble]'>
            <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
    </sch:pattern>
</sch:schema>