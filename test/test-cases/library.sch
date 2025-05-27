<?xml version="1.0" encoding="UTF-8"?>
<library xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
    
    <pattern id='blort'>
        <rule context="blort">
            <assert test="@wibble">Element <name/> must have attribute 'wibble'</assert>
        </rule>
    </pattern>
    
    <pattern id='wibble'>
        <rule context="wibble">
            <assert test=". = $some-global">Element <name/> must have value '<value-of select="$some-global"/>'</assert>
        </rule>
    </pattern>
    
</library>