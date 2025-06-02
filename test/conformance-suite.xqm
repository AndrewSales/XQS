module namespace _ = "http://www.andrewsales.com/ns/xqs-conformance-suite";
declare namespace xqs = 'http://www.andrewsales.com/ns/xqs';
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
import module namespace eval = "http://www.andrewsales.com/ns/xqs-evaluate" at
  "../evaluate.xqm";
import module namespace ie = "http://www.andrewsales.com/ns/xqs-include-expand" at
  "../include-expand.xqm";
declare function _:is-valid($svrl as element(svrl:schematron-output))
as xs:boolean{
  empty($svrl/(svrl:failed-assert|svrl:successful-report))
};

(: CORE :)

(:~ Extends performs base URI fixup
: @see XML Inclusions (XInclude) Version 1.1, Section 4.7.5. 
:)
declare %unit:test function _:extends-baseuri-fixup1()
{
  let $result:= eval:schema(
    document{<element/>},
    doc('extends-baseuri-fixup.sch')/* => ie:process-includes()
  ) 
  return
  (
    unit:assert(_:is-valid($result))
  )
};

(:~ Extends is recursive 
:)
declare %unit:test function _:extends-recursive1(){
  let $schema := ie:process-includes(doc('test-cases/extends-recursive.sch')/*)
  let $result := 
  eval:schema(
    document{<element/>},
    $schema
  ) 
  return unit:assert(not(_:is-valid($result)))
};
(:~ Include performs base URI fixup
: @see XML Inclusions (XInclude) Version 1.1, Section 4.7.5. 
:)
declare %unit:test function _:include-baseuri-fixup1(){let $result:=eval:schema(document{<element/>},
doc('include-baseuri-fixup.sch')/* => ie:process-includes()) return unit:assert(_:is-valid($result))};
(:~ Include is recursive 
:)
declare %unit:test function _:include-recursive1()
{
  let $result:=eval:schema(document{<element/>},
  doc('include-recursive.sch')/* => ie:process-includes()) 
    return unit:assert(not(_:is-valid($result)))
};

(:~ It is an error for a variable to be multiply defined in the current rule
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare 
%unit:test('expected', 'xqs:multiply-defined-variable') 
function _:let-name-collision-error-011(){
  eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/">
          <sch:let name="foo" value="'bar'"/>
          <sch:let name="foo" value="'bar'"/>
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>)
  };
(:~ It is an error for a variable to be multiply defined in the current pattern
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'xqs:multiply-defined-variable') 
function _:let-name-collision-error-021(){eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:let name="foo" value="'bar'"/>
        <sch:let name="foo" value="'bar'"/>
        <sch:rule context="/">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>)
  };
(:~ It is an error for a variable to be multiply defined in the current schema
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'xqs:multiply-defined-variable') 
function _:let-name-collision-error-031(){eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="foo" value="'bar'"/>
      <sch:let name="foo" value="'bar'"/>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>)
  };
(:~ It is an error for a variable to be multiply defined in the current phase
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'xqs:multiply-defined-variable') 
function _:let-name-collision-error-041(){eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:phase id="phase">
        <sch:let name="foo" value="'bar'"/>
        <sch:let name="foo" value="'bar'"/>
        <sch:active pattern="pattern"/>
      </sch:phase>
      <sch:pattern id="pattern">
        <sch:rule context="/">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>, 
    map{'phase':'phase'})};
(:~ It is an error for a variable to be multiply defined globally, BUT pattern
: variables should be local in scope.
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test function _:let-name-collision-error-051(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="foo" value="'bar'"/>
      <sch:pattern>
        <sch:let name="foo" value="'bar'"/>
        <sch:rule context="/">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ It is *NOT* an error to define a pattern variable with the same name as a 
: global variable - N.B. this differs from the conformance suite.
: @see ISO Schematron 2016: Section 5.4.5 clause 3 
:)
declare %unit:test function _:let-name-collision-error-061(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="foobar" value="1"/>
      <sch:pattern>
        <sch:let name="foobar" value="1"/>
        <sch:rule context="/">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="$foobar = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ A pattern variable *DOES NOT* have global scope - N.B. this differs from the 
: conformance suite.
: @error XPST0008 (undeclared variable)
: @see ISO Schematron 2016: Section 5.4.5 clause 1 
:)
declare %unit:test('expected', 'err:XPST0008') function _:let-pattern-global-011(){
  eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:let name="foobar" value="1"/>
        <sch:rule context="/">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="$foobar = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>)};
(:~ It is an error to reference a variable in a rule context expression that has not been defined globally
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*[local-name() = $localname]">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to reference a variable in an assert test expression that has not been defined globally
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-021(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="$variable = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to reference a variable in an report test expression that has not been defined globally
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-031(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*">
          <sch:report test="$variable = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to reference a variable in an rule variable that has not been defined globally
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-041(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*">
          <let name="ruleVariable" value="$variable"/>
          <sch:assert test="$ruleVariable"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to reference a variable in the @select expression of a sch:value-of element that has not been defined globally
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-051(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="false()">
            <sch:value-of select="$variable"/>
          </sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to reference a variable in the @path expression of a sch:name element that has not been defined globally
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-061(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="false()">
            <sch:name path="$variable"/>
          </sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to reference an undefined variable in the @documents expression of a sch:pattern element
: @see ISO Schematron 2016: Section 5.4.5 Clause 3 
:)
declare %unit:test('expected', 'err:XPST0008')
function _:let-reference-undefined-071(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern documents="$variable">
        <sch:rule context="*">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ A rule variable can use a schema variable
: @see ISO Schematron 2016: Section 6.5 clause 6 
:)
declare %unit:test function _:let-rule-global-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="global-var" value="1"/>
      <sch:pattern>
        <sch:rule context="*">
          <sch:let name="rule-var" value="$global-var + 1"/>
          <sch:assert test="$rule-var = 2"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ A rule variable can use a phase variable
: @see ISO Schematron 2016: Section 6.5 clause 6 
:)
declare %unit:test function _:let-rule-global-021(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:phase id="phase">
        <sch:let name="phase-var" value="1"/>
        <sch:active pattern="pattern"/>
      </sch:phase>
      <sch:pattern id="pattern">
        <sch:rule context="*">
          <sch:let name="rule-var" value="$phase-var + 1"/>
          <sch:assert test="$rule-var = 2"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>, 
    map{'phase':'phase'}) return unit:assert(_:is-valid($result))};
(:~ Pattern-variable is scoped to the pattern
: @see ISO Schematron 2016: Section 3.26 
:)
declare %unit:test function _:let-scope-pattern-011(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="foo" value="0"/>
      <sch:pattern>
        <sch:let name="foo" value="1"/>
        <sch:rule context="*">
          <sch:assert test="$foo = 1"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="$foo = 0"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ Phase-variable is scoped to the phase
: @see ISO Schematron 2016: Section 3.26 
:)
declare %unit:test function _:let-scope-phase-011(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="foo" value="0"/>
      <sch:phase id="phase">
        <sch:let name="foo" value="1"/>
        <sch:active pattern="pattern"/>
      </sch:phase>
      <sch:pattern id="pattern">
        <sch:rule context="/">
          <sch:assert test="$foo = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>, 
    map{'phase':'phase'}) return unit:assert(_:is-valid($result))};
(:~ Rule-variable is scoped to the rule
: @see ISO Schematron 2016: Section 3.26 
:)
declare %unit:test function _:let-scope-rule-011(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/">
          <sch:let name="foo" value="1"/>
          <sch:assert test="$foo = 1"/>
        </sch:rule>
        <sch:rule context="*">
          <sch:let name="foo" value="0"/>
          <sch:assert test="$foo = 0"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ Let uses the element content as value
: N.B. this differs from the conformance suite, possibly because of the way XSLT
: impls create variables with element content
: @see ISO Schematron 2016: Section 5.4.5 clause 2 
:)
declare %unit:test function _:let-value-element-content-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:ns prefix="html" uri="http://www.w3.org/1999/xhtml"/>
      <sch:let name="foobar">
        <html:p xmlns:html="http://www.w3.org/1999/xhtml">This is a paragraph</html:p>
      </sch:let>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="count($foobar) = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) 
    return unit:assert(_:is-valid($result))
  };
(:~ Let uses the element content as value
: @see ISO Schematron 2016: Section 5.4.5 clause 2 
:)
declare %unit:test function _:let-value-element-content-012(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite" queryBinding="xslt">
      <sch:ns prefix="html" uri="http://www.w3.org/1999/xhtml"/>
      <sch:let name="foobar">
        <html:p xmlns:html="http://www.w3.org/1999/xhtml">This is a paragraph</html:p>
      </sch:let>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="contains($foobar, 'paragraph')"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ An abstract pattern is instantiated
: @see ISO Schematron 2016: Section 6.3 
:)
declare %unit:test function _:pattern-abstract-011(){
  let $schema := ie:include-expand(<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern abstract="true" id="abstract-pattern">
        <sch:rule context="$context">
          <sch:assert test="$placeholder = 0"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern is-a="abstract-pattern">
        <sch:param name="context" value="element"/>
        <sch:param name="placeholder" value="1"/>
      </sch:pattern>
    </sch:schema>)
  let $result := eval:schema(
    document{<element/>},
    $schema
  ) 
  return unit:assert(not(_:is-valid($result)))};
(:~ Pattern in a subordinate document
: @see ISO Schematron 2016: Section 5.4.9 clause 2 
:)
declare %unit:test function _:pattern-subordinate-document-011(){
  let $result:=eval:schema(
    doc('document-01.xml'),
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern documents="/element/@secondary">
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ The subordinate document expression contains a variable 
:)
declare %unit:test function _:pattern-subordinate-document-021(){
  let $result:=eval:schema(
    doc('document.xml'),
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="extension" value="'.xml'"/>
      <sch:pattern documents="concat(/element/@secondary, $extension)">
        <sch:rule context="/">
          <sch:report test="root"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ An abstract rule is instantiated
: @see ISO Schematron 2016: Section 5.4.12 clause 5 
:)
declare %unit:test function _:rule-abstract-011(){
  let $schema := ie:include-expand(<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule abstract="true" id="abstract-rule">
          <sch:report test="self::element"/>
        </sch:rule>
        <sch:rule context="element">
          <sch:extends rule="abstract-rule"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>)
  let $result := eval:schema(
    document{<element/>},
    $schema
  ) 
  return unit:assert(not(_:is-valid($result)))};
(:~ It is an error to extend an abstract rule that is defined in a different pattern
: @see ISO Schematron 2016: Section 5.4.12 clause 5 
:)
declare %unit:test function _:rule-abstract-021(){let $result:=eval:schema(document{<element/>},
ie:include-expand(<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule abstract="true" id="abstract-rule">
          <sch:report test="self::element"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern>
        <sch:rule context="element">
          <sch:extends rule="abstract-rule"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>)) return unit:assert(not(_:is-valid($result)))};
(:~ Context node is an attribute node
: @see ISO Schematron 2016: Annex C Clause 2 (xslt), Annex H Clause 2 (xslt2), Annex I Clause 2 (xpath2) 
:)
declare %unit:test function _:rule-context-attribute-011(){let $result:=eval:schema(document{<element xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite" attribute="value"/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*/@attribute">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Context node is a comment node
: @see ISO Schematron 2016: Annex C Clause 2 (xslt), Annex H Clause 2 (xslt2), Annex I Clause 2 (xpath2) 
:)
declare %unit:test function _:rule-context-comment-011(){let $result:=eval:schema(document{<root xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
        <!-- Comment! -->
      </root>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*/comment()">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Context node is an element node
: @see ISO Schematron 2016: Annex C Clause 2 (xslt), Annex H Clause 2 (xslt2), Annex I Clause 2 (xpath2) 
:)
declare %unit:test function _:rule-context-element-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/element">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Context node is a processing instruction node
: @see ISO Schematron 2016: Annex C Clause 2 (xslt), Annex H Clause 2 (xslt2), Annex I Clause 2 (xpath2) 
:)
declare %unit:test function _:rule-context-pi-011(){let $result:=eval:schema(document{<root xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
        <?processing-instruction foobar ?>
      </root>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*/processing-instruction()">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Context node is the root node
: @see ISO Schematron 2016: Annex C clause 2 (xslt), Annex H clause 2 (xslt2) 
:)
declare %unit:test function _:rule-context-root-011(){let $result:=eval:schema(document{<root xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite"/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Context node is a text node
: @see ISO Schematron 2016: Annex C Clause 2 (xslt), Annex H Clause 2 (xslt2) 
:)
declare %unit:test function _:rule-context-text-011(){let $result:=eval:schema(document{<root xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">Content</root>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*/text()">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Rule context expression uses a pattern variable
: @see  
:)
declare %unit:test function _:rule-context-variable-011(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:let name="local-name" value="'document'"/>
        <sch:rule context="*[local-name() = $local-name]">
          <sch:assert test="true()"/>
        </sch:rule>
        <sch:rule context="*">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ Rule context expression uses a phase variable
: @see  
:)
declare %unit:test function _:rule-context-variable-021(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:phase id="phase">
        <sch:let name="local-name" value="'document'"/>
        <sch:active pattern="pattern"/>
      </sch:phase>
      <sch:pattern id="pattern">
        <sch:rule context="*[local-name() = $local-name]">
          <sch:assert test="true()"/>
        </sch:rule>
        <sch:rule context="*">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>, 
    map{'phase':'phase'}) return unit:assert(_:is-valid($result))};
(:~ Rule context expression uses a schema variable
: @see  
:)
declare %unit:test function _:rule-context-variable-031(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:let name="local-name" value="'document'"/>
      <sch:pattern>
        <sch:rule context="*[local-name() = $local-name]">
          <sch:assert test="true()"/>
        </sch:rule>
        <sch:rule context="*">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ Lexical order of rules is significant
: @see ISO Schematron 2016: Section 6.5 Clause 5 
:)
declare %unit:test function _:rule-order-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="element">
          <sch:assert test="true()"/>
        </sch:rule>
        <sch:rule context="*">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ When no phase is given, the processor uses the phase given in @defaultPhase
: @see ISO Schematron 2016: Section 5.4.13 clause 3 
:)
declare %unit:test function _:schema-default-phase-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite" defaultPhase="phase">
      <sch:phase id="phase">
        <sch:active pattern="pass"/>
      </sch:phase>
      <sch:pattern id="fail">
        <sch:rule context="*">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern id="pass">
        <sch:rule context="*">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ When a phase named '#DEFAULT' is given, the processor uses the phase given in @defaultPhase 
:)
declare %unit:test function _:schema-default-phase-021(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite" defaultPhase="phase">
      <sch:phase id="phase">
        <sch:active pattern="pass"/>
      </sch:phase>
      <sch:pattern id="fail">
        <sch:rule context="*">
          <sch:assert test="false()"/>
        </sch:rule>
      </sch:pattern>
      <sch:pattern id="pass">
        <sch:rule context="*">
          <sch:assert test="true()"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ The XSLT key element may be used before the pattern elements
: @see ISO Schematron 2020: Annex C Clause 10 (xslt), Annex H Clause 11 (xslt2), Annex J Clause 11 (xslt3) 
:)
declare %unit:ignore function _:xslt-key-011(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <xsl:key xmlns:xsl="http://www.w3.org/1999/XSL/Transform" name="index" match="*" use="'key'"/>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="count(key('index', 'key')) &gt; 0"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};
(:~ An xsl:key element can have element content
: @see ISO Schematron 2016: Annex H, XSLT 2.0 Section 16.3.1 
:)
declare %unit:ignore function _:xslt-key-element-content-011(){let $result:=eval:schema(document{<document/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <xsl:key xmlns:xsl="http://www.w3.org/1999/XSL/Transform" name="key" match="*">
        <xsl:text>key</xsl:text>
      </xsl:key>
      <sch:pattern>
        <sch:rule context="/">
          <sch:assert test="count(key('key', 'key')) = 1"/>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(_:is-valid($result))};

(: SVRL :)

(:~ Diagnostic references are copied to SVRL output 
:)
declare %unit:test function _:svrl-diagnostic-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/">
          <sch:report test="true()" diagnostics="d1 d2"/>
        </sch:rule>
      </sch:pattern>
      <sch:diagnostics>
        <sch:diagnostic id="d1">
          Context: <sch:value-of select="name()"/>
        </sch:diagnostic>
        <sch:diagnostic id="d2">
          Context: <sch:value-of select="name()"/>
        </sch:diagnostic>
      </sch:diagnostics>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Language tag of diagnostic is preserved in SVRL output 
:)
declare %unit:test function _:svrl-diagnostic-021(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/">
          <sch:report test="true()" diagnostics="d1"/>
        </sch:rule>
      </sch:pattern>
      <sch:diagnostics>
        <sch:diagnostic id="d1" xml:lang="de">
          Context: <sch:value-of select="name()"/>
        </sch:diagnostic>
      </sch:diagnostics>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ The sch:name element expands into the name of the context node if no @path is present
: @see ISO Schematron 2016: Section 5.4.6, Annex C clause 4 (xslt), Annex H clause 4 (xslt2), Annex I clause 4 (xpath2) 
:)
declare %unit:test function _:svrl-name-nopath-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/element">
          <sch:report test="true()">
            <sch:name/>
          </sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ The sch:name element expands into the value of evaluating the expression in @path
: @see ISO Schematron 2016: Section 5.4.6, Annex C clause 4 (xslt), Annex H clause 4 (xslt2), Annex I clause 4 (xpath2) 
:)
declare %unit:test function _:svrl-name-path-011(){let $result:=eval:schema(document{<element attribute="value"/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/element">
          <sch:report test="true()">
            <sch:name path="@attribute"/>
          </sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ Property references are copied to SVRL output 
:)
declare %unit:test function _:svrl-property-011(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/">
          <sch:report test="true()" properties="p1 p2"/>
        </sch:rule>
      </sch:pattern>
      <sch:properties>
        <sch:property id="p1">
          Context: <sch:value-of select="name()"/>
        </sch:property>
        <sch:property id="p2">
          Context: <sch:value-of select="name()"/>
        </sch:property>
      </sch:properties>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ A xsl:copy-of inside a sch:property is executed
: @see ISO Schematron 2016: Annex C Clause 11 (xslt), Annex H Clause 11 (xslt2) 
:)
declare %unit:test function _:svrl-property-copy-of1(){let $result:=eval:schema(document{<element/>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="*">
          <sch:assert test="false()" properties="copy-of"/>
        </sch:rule>
      </sch:pattern>
      <sch:properties>
        <sch:property id="copy-of">
          <xsl:copy-of select="."/>
        </sch:property>
      </sch:properties>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};
(:~ The sch:value-of element expands into the value of evaluating the expression in @select
: @see ISO Schematron 2016: Section 5.4.14, Annex C clause 5 (xslt), Annex H clause 5 (xslt2), Annex I clause 5 (xpath2) 
:)
declare %unit:test function _:svrl-value-of-011(){let $result:=eval:schema(document{<element>Text content</element>},
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns="tag:dmaus@dmaus.name,2019:Schematron:Testsuite">
      <sch:pattern>
        <sch:rule context="/element">
          <sch:report test="true()">
            <sch:value-of select="."/>
          </sch:report>
        </sch:rule>
      </sch:pattern>
    </sch:schema>) return unit:assert(not(_:is-valid($result)))};

(:~ duplicate declaration of schema/@param
 : @see ISO2025: "Parameter names shall be distinct within the scope of a 
 : pattern or schema."
 :)
declare %unit:test('expected', 'xqs:multiply-defined-variable') 
function _:schema-param-name-collision-error()
{
  eval:schema(
    document{<root/>},
     <sch:schema>
      <sch:param name='myParam' value='"bar"'/>
      <sch:param name='myParam'/>
      <sch:pattern id='foo'>
        <sch:rule context='*'>
          <sch:assert test='false()'><sch:value-of select='$myParam'/></sch:assert>
        </sch:rule>
      </sch:pattern>
    </sch:schema>
  )
};