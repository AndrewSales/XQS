(:~ 
 : Unit tests for setting up the validation context.
 :)

module namespace _ = 'http://www.andrewsales.com/ns/xqs-context-tests';

import module namespace c = 'http://www.andrewsales.com/ns/xqs-context' at
  '../context.xqm';

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

declare variable $_:DUMMY_DOC := <foo/>;
declare variable $_:EMPTY_MAP := map{};

(: PHASES :)

(:~ no active phase specified :)  
declare %unit:test function _:active-phase-none()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron"/>,
    $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    $_:EMPTY_MAP
  )
  return unit:assert-equals(
    $active-phase, 
    ()
  )
};

(:~ #DEFAULT phase specified :)
declare %unit:test function _:active-phase-default()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron" defaultPhase='foo'>
      <phase id='foo'/>
    </schema>,
    $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    map{'phase':$c:DEFAULT_PHASE}
  )
  return unit:assert-equals(
    $active-phase, 
    <phase xmlns="http://purl.oclc.org/dsdl/schematron" id='foo'/>
  )
};

(:~ #DEFAULT phase specified, but none present in schema :)
declare %unit:test function _:active-phase-no-default()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron"/>,
    $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    map{'phase':$c:DEFAULT_PHASE}
  )
  return unit:assert-equals(
    $active-phase, 
    ()
  )
};

(:~ #DEFAULT phase not specified, but present in schema :)
declare %unit:test function _:active-phase-schema-default()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron" defaultPhase='phase'>
      <phase id='phase'/>
    </schema>,
    $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    $_:EMPTY_MAP
  )
  return unit:assert-equals(
    $active-phase, 
    <phase xmlns="http://purl.oclc.org/dsdl/schematron" id='phase'/>
  )
};

(:~ #ALL specified: same effect as none :)
declare %unit:test function _:active-phase-all()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron"/>,
    $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    map{'phase':$c:ALL_PATTERNS}
  )
  return unit:assert-equals(
    $active-phase, 
    ()
  )
};

(:~ phase ID specified :)
declare %unit:test function _:active-phase-by-id()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='foo'/>
    </schema>,
    $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    map{'phase':'foo'}
  )
  return unit:assert-equals(
    $active-phase, 
    <phase xmlns="http://purl.oclc.org/dsdl/schematron" id='foo'/>
  )
};

declare %unit:test function _:active-phase-when()
{
  let $active-phase := c:get-active-phase(
    <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='foo' when='//@wibble'/>
    </schema>,
    document{<foo>
    <blort wibble='1'/>
    <bar><blort wibble='2'/><blort wibble='3'/></bar></foo>},
    $_:EMPTY_MAP,
    map{'phase':$c:ANY_PHASE}
  )
  return unit:assert-equals(
    $active-phase, 
    <phase xmlns="http://purl.oclc.org/dsdl/schematron" id='foo' when='//@wibble'/>
  )
};

(: PATTERNS :)

(:~ no phase specified, same effect as #ALL :)
declare %unit:test function _:get-active-patterns-no-phases()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <pattern id='foo'><rule/></pattern>
    </schema>
  let $active-patterns := c:get-active-patterns(
    $schema,
    c:get-active-phase(
      $schema,
      $_:DUMMY_DOC,
    $_:EMPTY_MAP,
    $_:EMPTY_MAP
    )
  )
  return unit:assert-equals(
    $active-patterns, 
    <pattern xmlns="http://purl.oclc.org/dsdl/schematron" id='foo'><rule/></pattern>
  )
};

(:~ #ALL patterns :)
declare %unit:test function _:get-active-patterns-all()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='phase1'>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'><rule/></pattern>>
    </schema>
  let $active-patterns := c:get-active-patterns(
    $schema,
    c:get-active-phase(
      $schema,
      $_:DUMMY_DOC,
      $_:EMPTY_MAP,
      map{'phase':$c:ALL_PATTERNS}
    )
  )
  return unit:assert-equals(
    count($active-patterns), 
    2
  )
};

declare %unit:test function _:get-active-patterns-default-phase()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron"
  defaultPhase='phase1'>
      <phase id='phase1'>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'/>
    </schema>
  let $active-patterns := c:get-active-patterns(
    $schema,
    c:get-active-phase(
      $schema,
      $_:DUMMY_DOC,
      $_:EMPTY_MAP,
      map{'phase':$c:DEFAULT_PHASE}
    )
  )
  return unit:assert-equals(
    $active-patterns, 
    <pattern xmlns="http://purl.oclc.org/dsdl/schematron" id='foo'><rule/></pattern>
  )
};

declare %unit:test function _:get-active-patterns-by-phase-id()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='phase1'>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'><rule/></pattern>
    </schema>
    
  let $active-phase := c:get-active-phase(
      $schema,
      $_:DUMMY_DOC,
      $_:EMPTY_MAP,
      map{'phase':'phase1'}
    )
    
  let $active-patterns := c:get-active-patterns(
    $schema,
    $active-phase
  )
  return
  (
    unit:assert-equals($active-phase, <phase id='phase1' xmlns="http://purl.oclc.org/dsdl/schematron">
        <active pattern='foo'/>
      </phase>), 
    unit:assert-equals(
      $active-patterns, 
      <pattern xmlns="http://purl.oclc.org/dsdl/schematron" id='foo'><rule/></pattern>
    )
  )
};

(: GLOBAL VARIABLES :)

(:~ no global variables declared :)
declare %unit:test function _:get-global-variables-none()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='phase1'>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'><rule/></pattern>
    </schema>
    
  let $globals := ($schema, c:get-active-patterns($schema, ()))/sch:let
  
  return unit:assert-equals(count($globals), 0)
};

(:~ global variables declared at schema, phase and pattern level :)
declare %unit:test function _:get-global-variables-with-phase()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <let name='foo' value='bar'/>
      <phase id='phase1'>
        <let name='bar' value='blort'/>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><let name='foo1' value='.'/><rule/></pattern>
      <pattern id='bar'><let name='bar1' value='.'/><rule/></pattern>
    </schema>
    
  let $active-phase := $schema/*:phase
    
  let $globals := (
    $schema,
    c:get-active-patterns($schema, $active-phase),
    $active-phase
  )/sch:let
  
  return unit:assert-equals(count($globals), 3)
};

(:~ global variables declared at schema and pattern level :)
declare %unit:test function _:get-global-variables-without-phase()
{
  let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <let name='foo' value='bar'/>
      <phase id='phase1'>
        <let name='bar' value='blort'/>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><let name='foo1' value='.'/><rule/></pattern>
      <pattern id='bar'><let name='bar1' value='.'/><rule/></pattern>
    </schema>
    
  let $globals := ($schema, c:get-active-patterns($schema, ()))/sch:let
  
  return unit:assert-equals(count($globals), 3)
};

(: VALIDATION CONTEXT :)

(:~ retrieve active patterns from validation context map :)
declare %unit:test function _:get-context-patterns()
{
    let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='phase1'>
        <active pattern='foo'/>
        <active pattern='bar'/>
      </phase>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'><rule/></pattern>
      <pattern id='blort'><rule/></pattern>
    </schema>
  
  let $patterns := c:get-context(
    <foo/>,
    $schema,
    map{'phase':'phase1'}
  )?patterns
  
  return unit:assert-equals(
    count($patterns),
    2
  )
};

(:~ retrieve active groups from validation context map :)
declare %unit:test function _:get-context-groups()
{
    let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='phase1'>
        <active pattern='foo'/>
        <active pattern='bar'/>
      </phase>
      <group id='foo'><rule/></group>
      <group id='bar'><rule/></group>
      <group id='blort'><rule/></group>
    </schema>
  
  let $groups := c:get-context(
    <foo/>,
    $schema,
    map{'phase':'phase1'}
  )?groups
  
  return unit:assert-equals(
    count($groups),
    2
  )
};

(:~ retrieve active phase from validation context map :)
declare %unit:test function _:get-context-active-phase()
{
    let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <phase id='phase1'>
        <active pattern='foo'/>
        <active pattern='bar'/>
      </phase>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'><rule/></pattern>
      <pattern id='blort'><rule/></pattern>
    </schema>
  
  let $phase := c:get-context(
    <foo/>,
    $schema,
    map{'phase':'phase1'}
  )?phase
  
  return unit:assert-equals(
    $phase,
    <phase id='phase1' xmlns="http://purl.oclc.org/dsdl/schematron">
      <active pattern='foo'/>
      <active pattern='bar'/>
    </phase>  
  )
};

(:~ retrieve namespace declarations from validation context map :)
declare %unit:test function _:get-context-namespaces()
{
    let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <ns prefix='a' uri='uri1'/>
      <ns prefix='b' uri='uri2'/>
      <pattern id='foo'><rule/></pattern>
      <pattern id='bar'><rule/></pattern>
      <pattern id='blort'><rule/></pattern>
    </schema>
  
  let $ns-decls := c:get-context(
    <foo/>,
    $schema,
    map{}
  )?ns-decls
  
  return unit:assert-equals(
    $ns-decls,
    'declare namespace a="uri1";declare namespace b="uri2";'
  )
};

(:~ retrieve global variable declarations from validation context map
 : N.B. patterns are not added to the global decls
 :)
declare %unit:test function _:get-context-globals()
{
    let $schema := <schema xmlns="http://purl.oclc.org/dsdl/schematron">
      <let name='foo' value='bar'/>
      <phase id='phase1'>
        <let name='bar' value='blort'/>
        <let name='blort' value='wibble'/>
        <active pattern='foo'/>
      </phase>
      <pattern id='foo'><let name='foo1' value='.'/><rule/></pattern>
      <pattern id='bar'><let name='bar1' value='.'/><rule/></pattern>
    </schema>
  
  let $globals := c:get-context(
    <foo/>,
    $schema,
    map{'phase':'phase1'}
  )?globals
  
  return unit:assert-equals(
    count(map:keys($globals)),
    1	(:schema-level only; not phase variables:)
  )
};