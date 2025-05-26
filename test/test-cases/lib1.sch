<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    
    <extends href="library.sch"/>
    
    <let name="some-global" value="'blort'"/>
    
    <pattern id='foo'>
        <rule context="foo">
            <assert test="@wibble">Element <name/> must have attribute 'wibble'</assert>
        </rule>
    </pattern>
    
    <pattern id='bar'>
        <rule context="bar">
            <assert test=". = $some-global">Element <name/> must have value '<value-of select="$some-global"/>'</assert>
        </rule>
    </pattern>
    
</schema>