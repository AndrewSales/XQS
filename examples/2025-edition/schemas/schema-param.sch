<sch:schema schematronEdition="2025" xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:param name='myParam' value='"bar"'/>
    <sch:pattern id='foo'>
        <sch:rule context='*'>
            <sch:assert test='false()'><sch:value-of select='$myParam'/></sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>