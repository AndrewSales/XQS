<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xquery">
    
    <let name="elname" value="doc('xml-base.xml')/*/name()"/>
    <pattern>
        <rule context="//*">
            <report test="name() eq $elname">Outermost element in xml-base.xml is named <value-of select="$elname"/></report>
            <report test="true()">base-uri is <value-of select="base-uri()"/></report>
        </rule>
    </pattern>
    
</schema>