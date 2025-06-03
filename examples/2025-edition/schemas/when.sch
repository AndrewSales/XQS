<sch:schema schematronEdition='2025' xmlns:sch="http://purl.oclc.org/dsdl/schematron">
    <sch:phase id='foo' when='/foo'>
        <sch:active pattern='wibble-1'/>
    </sch:phase>
    <sch:phase id='wibble' when='//@wibble'>
        <sch:active pattern='wibble-2'/>
    </sch:phase>
    <sch:phase id='bar' when='/foo/bar'>
        <sch:active pattern='wibble-3'/>
    </sch:phase>
    <sch:pattern id='wibble-1'>
        <sch:rule context='//blort[@wibble]'>
            <sch:report test='@wibble'><sch:value-of select='@wibble'/></sch:report>
        </sch:rule>
    </sch:pattern>
    <sch:pattern id='wibble-2'>
        <sch:rule context='//blort[@wibble]'>
            <sch:report test='@wibble'><sch:value-of select='@wibble/..'/></sch:report>
        </sch:rule>
    </sch:pattern>
    <sch:pattern id='wibble-3'>
        <sch:rule context='//blort[@wibble]'>
            <sch:assert test='normalize-space(@wibble)'>value must not be empty</sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>