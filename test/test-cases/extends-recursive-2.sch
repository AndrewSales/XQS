<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xquery">
    <sch:extends href='lib1.sch'/>
    <sch:pattern>
      <sch:rule context="/">
        <sch:assert test="true()">Always true</sch:assert>
      </sch:rule>
    </sch:pattern>
  </sch:schema>