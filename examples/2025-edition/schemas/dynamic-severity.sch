<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron" defaultPhase='phase'>
        <sch:ns prefix='a' uri='b'/>
        <sch:let name='c' value='d'/>
        <sch:phase id='phase'>
            <sch:let name='dynamic-severity' value='"bar"'/>
            <sch:active pattern='foo'/>
        </sch:phase>
        <sch:pattern id='foo'>
            <sch:rule context='*'>
                <sch:assert test='false()' severity='$dynamic-severity'>...</sch:assert>
            </sch:rule>
        </sch:pattern>
    </sch:schema>