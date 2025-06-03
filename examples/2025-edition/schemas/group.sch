<sch:schema schematronEdition="2025" xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:group>
        <sch:rule context="*">
            <sch:assert test='name() eq "bar"'>root element is <sch:name/></sch:assert>
        </sch:rule>
        <sch:rule context="foo">
            <sch:report test=".">should reach here</sch:report>
        </sch:rule>
    </sch:group>
</sch:schema>
