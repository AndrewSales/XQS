<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron" defaultPhase='phase'>
    <sch:phase id='phase' from='/no/such/path'>
        <sch:active pattern='wibble'/>
    </sch:phase>
    <sch:pattern id='wibble'>
        <sch:rule context='blort[@wibble]'>
            <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
    </sch:pattern>
</sch:schema>