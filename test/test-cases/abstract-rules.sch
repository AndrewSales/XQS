<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron">
  <sch:rules>
    <sch:rule abstract="true" id="abstract-rule">
      <sch:report test="self::element"/>
    </sch:rule>
    <sch:rule abstract="true" id="abstract-rule-2">
      <sch:report test="name()"/>
    </sch:rule>
  </sch:rules>
  <sch:pattern>
    <sch:rule context="element">
      <sch:extends rule="abstract-rule"/>
    </sch:rule>
    <sch:rule context="*">
      <sch:extends rule="abstract-rule-2"/>
    </sch:rule>
  </sch:pattern>
</sch:schema>