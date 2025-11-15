<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xquery">

    <pattern id='phase-demo'>
        <rule context="//bar">
            <report test=".">Hello, XQS phases world!</report>
        </rule>
    </pattern>

</schema>
