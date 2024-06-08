<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule abstract="true" id="abstract-rule">
          <sch:report test="self::element"/>
        </sch:rule>
        <sch:rule context="element">
          <sch:extends rule="abstract-rule"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>