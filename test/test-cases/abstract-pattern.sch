<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern abstract="true" id="abstract-pattern">
        <sch:rule context="$context">
          <sch:assert test="$placeholder = 0"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern is-a="abstract-pattern">
        <sch:param name="context" value="element"/>
        <sch:param name="placeholder" value="1"/>
      </sch:pattern>
    </sch:schema>