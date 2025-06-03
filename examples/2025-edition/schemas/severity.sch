<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:pattern>
        <sch:rule context='*'>
            <sch:report test='true()' severity='error'><sch:name/></sch:report>
            <sch:assert test='false()' severity='warning'><sch:name/></sch:assert>
            <sch:assert test='false()' severity='12345'><sch:name/></sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>