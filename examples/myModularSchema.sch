<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xquery">

    <phase id="myPhase">
        <active pattern="phase-demo"/>
    </phase>

    <pattern>
        <rule context="//foo">
            <report test=".">Hello, XQS world!</report>
        </rule>
    </pattern>
    
    <include href="include.sch#phase-demo"/>

</schema>
