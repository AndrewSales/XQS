(:~ 
 : Library for establishing the validation context. 
 :)

module namespace c = 'http://www.andrewsales.com/ns/xqs-context';

import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' 
  at 'utils.xqm';    

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

declare variable $c:DEFAULT_PHASE as xs:string := '#DEFAULT';
declare variable $c:ALL_PATTERNS as xs:string := '#ALL';

(:~ Sets up the validation context: namespaces, global variables, active phase 
 : (if configured) and patterns.
 : @param instance the document instance
 : @param schema the Schematron schema
 : @param phase the active phase
 :)
declare function c:get-context(
  $instance as node(),
  $schema as element(sch:schema),
  $phase as xs:string?
)
as map(*)
{
  let $active-phase as element(sch:phase)? := c:get-active-phase($schema, $phase)
  let $active-patterns as element(sch:pattern)+ := c:get-active-patterns($schema, $active-phase)
  let $namespaces as xs:string? := c:make-ns-decls($schema/sch:ns)
  let $globals as element(sch:let)* := ($schema, $active-phase)/sch:let
  let $globals as map(*) := if($globals) 
    then c:evaluate-global-variables(
      $globals, 
      $instance, 
      $namespaces, 
      $schema/sch:ns, 
      map{}
    )
    else map{}
  
  return map{
    'phase' : $active-phase,
    'patterns' : $active-patterns,
    'ns-decls' : $namespaces,
    'globals' : $globals,
    'instance' : $instance,
    'diagnostics' : $schema/sch:diagnostics/sch:diagnostic,
    'properties' : $schema/sch:properties/sch:property
  }
};

(:NAMESPACE DECLARATIONS:)

declare function c:make-ns-decls($nss as element(sch:ns)*)
as xs:string?
{
  $nss ! c:make-ns-decl(.) => string-join()
};

declare %private function c:make-ns-decl($ns as element(sch:ns))
as xs:string
{
  'declare namespace ' || $ns/@prefix || '="' || $ns/@uri || '";'
};

(:VARIABLES:)

(:~ @see ISO2020, 7.2: "A Schematron schema shall have one definition only in 
 : scope for any global variable name in the global context and any local 
 : variable name in the local context." 
 :)
declare %private function c:check-variable-dupes($decls as element(sch:let)*)
{
  if(count($decls) ne distinct-values($decls/@name))
  then error(
    xs:QName('multiply-defined-variable')
      (:TODO report duplicates:)
  )
};

(:PHASES:)

(:~ Determines the active phase.
 : @see ISO2020 5.4.11
 : @param schema the Schematron schema
 : @param the active phase
 : @return the active phase, or the empty sequence if none is defined or can be
 : determined
 :)
declare function c:get-active-phase(
  $schema as element(sch:schema), 
  $phase as xs:string
)
as element(sch:phase)?
{
  if($phase = ('', $c:DEFAULT_PHASE)) 
  then
    if($schema/@defaultPhase)
    then $schema/sch:phase[@id eq $schema/@defaultPhase]	(:default phase:)
    else ()	(:fall back to #ALL:)	(:TODO report as info?:)
  else
    if($phase eq $c:ALL_PATTERNS)
    then ()
    else $schema/sch:phase[@id eq $phase]	(:TODO report if none?:)
};

(:~ Determines the active patterns.
 : @see ISO2020 5.4.11
 : @param schema the Schematron schema
 : @param the active phase
 : @return the active patterns
 :)
declare function c:get-active-patterns(
  $schema as element(sch:schema), 
  $active-phase as element(sch:phase)?
)
as element(sch:pattern)+
{
  $schema/sch:pattern[sch:rule][
    if($active-phase) then @id = $active-phase/sch:active/@pattern else true()
  ]  
};

(:~ Determines the global variables declared, i.e. with the current schema or 
 : active phase.
 : Note that this <emph>excludes</emph> pattern variables from the global scope:
 : "It is an error to reference a variable that has not been defined in the 
 : current schema, phase, pattern or rule"
 : @see ISO2020 5.4.6
 : @param schema the Schematron schema
 : @param the active phase
 : @return global variable declarations
 :)
declare function c:get-global-variables(
  $schema as element(sch:schema),
  $active-phase as element(sch:phase)?  
)
as element(sch:let)*
{
  ($schema,$active-phase)/sch:let
};

(:~ Evaluates global variables against the instance document root.
 : @see ISO2020, 5.4.6: "If the let element is the child of a rule element, the
 : variable is calculated and scoped to the current rule and context. Otherwise,
 : the variable is calculated with the context of the instance document root."
 : @return map of global variable bindings
 : @param variables global variables
 : @param instance the document instance
 : @param namespaces namespace declarations
 : @param bindings global variable bindings
 :)
declare function c:evaluate-global-variables(
  $variables as element(sch:let)*,
  $instance as node(),
  $namespaces as xs:string?,
  $ns-elems as element(sch:ns)*,
  $bindings as map(*)
)
as map(*)
{
  if(empty($variables))
  then $bindings
  else 
    let $var := head($variables)
    let $prolog := $namespaces || 
      util:global-variable-external-decls($bindings) || 
      util:global-variable-decls($var)
    
    (: let $_ := trace('[1]$prolog='||serialize($prolog)) :)
    (: let $_ := trace('[2]$bindings='||serialize($bindings, map{'method':'adaptive'})) :)
    let $_ := trace('[3]evaluating GLOBAL variable $'||$var/@name)
    
    let $binding := c:evaluate-global-variable(
      $var,
      $instance,
      $prolog || '$' || $var/@name,
      $ns-elems,
      $bindings
    )    
    
    (: let $_ := trace('[5]$bindings='||serialize($binding, map{'method':'adaptive'})) :)
    
    return c:evaluate-global-variables(
      tail($variables),
      $instance,
      $namespaces,
      $ns-elems,
      $binding
    )
};

(:~ Evaluates pattern variables against the instance document root.
 : @see ISO2020, 5.4.6: "If the let element is the child of a rule element, the
 : variable is calculated and scoped to the current rule and context. Otherwise,
 : the variable is calculated with the context of the instance document root."
 : @return map of global and pattern-level variable bindings
 : @param variables pattern variables
 : @param instance the document instance
 : @param prolog global variable and namespace declarations
 :)
declare function c:evaluate-pattern-variables(
  $variables as element(sch:let)*,
  $instance as node(),
  $namespaces as xs:string?,
  $ns-elems as element(sch:ns)*,
  $bindings as map(*)
)
as map(*)
{
  if(empty($variables))
  then $bindings
  else 
    let $var := head($variables)
    let $prolog := $namespaces || 
      util:global-variable-external-decls($bindings)
    
    (: let $_ := trace('[1]$prolog='||serialize($prolog)) :)
    (: let $_ := trace('[2]$bindings='||serialize($bindings, map{'method':'adaptive'})) :)
    (: let $_ := trace('[3]evaluating PATTERN variable $'||$var/@name|| ' ' || serialize($var)) :)
    
    let $binding := c:evaluate-global-variable(
      $var,
      $instance,
      $prolog ||  util:local-variable-decls($var) || ' return $' || $var/@name,
      $ns-elems,
      $bindings
    )    
    
    (: let $_ := trace('[5]$bindings='||serialize($binding, map{'method':'adaptive'})) :)
    
    return c:evaluate-pattern-variables(
      tail($variables),
      $instance,
      $namespaces,
      $ns-elems,
      $binding
    )
};

(:~ 
 : @return updated map of global variable bindings
 : @param variables global variables
 : @param instance the document instance
 : @param prolog global variable and namespace declarations
 :)
declare function c:evaluate-global-variable(
  $variable as element(sch:let),
  $instance as node(),
  $query as xs:string?,
  $ns-elems as element(sch:ns)*,
  $bindings as map(*)
)
as map(*)
{
  (: let $_ := trace('>>>QUERY='||$query) :)
  let $value as item()* := if($variable/@value) 
    then xquery:eval(
      $query => util:escape(), 
      map:merge(($bindings, map{'':$instance})),
      map{'pass':'true'}
    )
    else $variable/*
  let $bindings := map:merge(
    (
      map{util:variable-name-to-QName($variable/@name, $ns-elems):$value},
      $bindings
    )
  )
  (: let $_ := trace('[4]$bindings='||serialize($bindings, map{'method':'adaptive'})) :)
  return $bindings
};