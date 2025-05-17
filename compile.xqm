module namespace compile = 'http://www.andrewsales.com/ns/xqs-compile';
import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace utils = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';  
import module namespace output = 'http://www.andrewsales.com/ns/xqs-output' at
  'svrl.xqm';    
  
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
declare namespace xqy = 'http://www.w3.org/2012/xquery';

declare variable $compile:INSTANCE_PARAM := '$Q{http://www.andrewsales.com/ns/xqs}uri';
declare variable $compile:INSTANCE_DOC := '$Q{http://www.andrewsales.com/ns/xqs}doc';
declare variable $compile:SUBORDINATE_DOCS := '$Q{http://www.andrewsales.com/ns/xqs}sub-docs';
declare variable $compile:SUBORDINATE_DOC := '$Q{http://www.andrewsales.com/ns/xqs}sub-doc';
declare variable $compile:SUBORDINATE_DOC_URIS := '$Q{http://www.andrewsales.com/ns/xqs}sub-doc-uris';
declare variable $compile:RULE := '$Q{http://www.andrewsales.com/ns/xqs}rule';
declare variable $compile:RULE_CONTEXT_NAME := 'Q{http://www.andrewsales.com/ns/xqs}context';
declare variable $compile:RULE_MATCHED := '$' || $compile:RULE_MATCHED_NAME;
declare variable $compile:RULE_MATCHED_NAME := 'Q{http://www.andrewsales.com/ns/xqs}matched';
declare variable $compile:RULE_CONTEXT := '$' || $compile:RULE_CONTEXT_NAME;
declare variable $compile:ASSERTION := '$Q{http://www.andrewsales.com/ns/xqs}assertion';
declare variable $compile:RESULT_NAME := 'Q{http://www.andrewsales.com/ns/xqs}result';
declare variable $compile:RESULT := '$' || $compile:RESULT_NAME;
declare variable $compile:RULES_FUNCTION := 'declare function local:rules(
  $rules as function(*)*,
  $contexts as function(*)*,
  $matched as node()*
)(:pass context as second arg:)
as element()*
{
    if (empty($rules))
    then
        ()
    else
        let $context := head($contexts)()
        return
        (head($rules)($context, $matched),
        local:rules(tail($rules), tail($contexts), $matched | $context))
}; ';
declare variable $compile:RULES_FUNCTION_WITH_CONTEXT := 'declare function local:rules($rules as function(*)*, $contexts as function(*)*, $matched as node()*, $doc as document-node())
as element()*
{
    $doc ! (
    if (empty($rules))
    then
        ()
    else
        let $context := head($contexts)(.)
        return
        (head($rules)($context, $matched, .),
        local:rules(tail($rules), tail($contexts), $matched | $context, $doc))
      )
}; ';  
declare variable $compile:EXTERNAL_VARIABLES := 'declare variable ' || $compile:INSTANCE_PARAM || ' external;
    declare variable ' || $compile:INSTANCE_DOC || ' as document-node() external := doc(' || $compile:INSTANCE_PARAM || ');';  

(:~ Compile a schema.
 : @param schema the schema to compile
 : @param phase the active phase, if any
 : @return the compiled schema
 :)
declare function compile:schema($schema as element(sch:schema), $phase as xs:string?)
{
  let $active-phase := context:get-active-phase($schema, $phase)
  let $active-patterns := context:get-active-patterns($schema, $active-phase)
  let $_ := (utils:check-duplicate-variable-names($schema/sch:let), utils:check-duplicate-variable-names($active-phase/sch:let))
  return
  (
    compile:prolog($schema),
    compile:user-defined-functions($schema/xqy:function),
    $active-patterns ! compile:pattern(., $active-phase),
    compile:declare-function(
      'local:schema',
      (),
      <svrl:schematron-output>
        {output:schema-title($schema/sch:title)}
        {$schema/@schemaVersion}
        {$schema/@schematronEdition}
        {if($active-phase) then attribute{'phase'}{$active-phase/@id} else ()}
        {output:namespace-decls-as-svrl($schema/sch:ns)}
      {'{', string-join(
        for $pattern in $active-patterns 
        return compile:function-name($pattern) ||'()',
        ','
      ), '}'} </svrl:schematron-output>
    )
    || $compile:RULES_FUNCTION || $compile:RULES_FUNCTION_WITH_CONTEXT ||
    'local:schema()'
  ) => serialize(map{'method':'basex'})
};

declare function compile:prolog($schema as element(sch:schema))
as xs:string*
{
  string-join($schema/sch:ns ! context:make-ns-decls(.)) => utils:escape() ||
  $compile:EXTERNAL_VARIABLES ||
  string-join(
    $schema/sch:let => compile:global-variable-decls()
  )
};

(:~ Compile a pattern to a function.
 : local:rules() takes three arguments:
 : - a sequence of functions representing its rules
 : - a sequence of functions to compute the context for each rule
 : - the accumulated contexts so far evaluated.
 : On each recursion, the rule context is calculated (via _rule-function_#0).
 : The contexts matched so far and the rule context are passed to
 : _rule-function_#2, whose body is executed if the rule context has not already
 : been matched.
 :)
declare function compile:pattern(
  $pattern as element(sch:pattern),
  $phase as element(sch:phase)?
)
{
  let $_ := (utils:check-duplicate-variable-names($pattern/sch:let),
    utils:check-duplicate-variable-names($phase/sch:let))
  return
  if($pattern/@documents)
  then compile:pattern-documents($pattern, $phase)
  else
    (compile:declare-function(
      compile:function-name($pattern),
      (),
      (
        <svrl:active-pattern>
        {$pattern/(@id, @name, @role)}
        </svrl:active-pattern>, ', local:rules((' ||
        string-join(for $rule in $pattern/sch:rule 
        return ' ' || compile:function-name($rule) || '#2', ',') || '), (' ||
        string-join(for $rule in $pattern/sch:rule 
        return ' ' || compile:function-name($rule) || '#0', ',') || '), ())')
      ),
      $pattern/sch:rule ! 
      (compile:rule(., $phase), compile:rule-context(., $phase))
    )
};

(:~ Creates a function to process a pattern which specifies subordinate 
 : documents. 
 : This implementation resolves the URIs of subordinate documents
 : against the base URI of the instance document.
 : @param pattern the pattern[@documents]
 : @param phase optional phase
 :)
declare function compile:pattern-documents(
  $pattern as element(sch:pattern),
  $phase as element(sch:phase)?
)
{
  compile:declare-function(
    compile:function-name($pattern), 
    '',
    (
      compile:declare-variable(
        $compile:SUBORDINATE_DOC_URIS,
        $compile:INSTANCE_DOC || '/(' || $pattern/@documents => utils:escape() || ')'
      ) ||
      compile:declare-variable(
        $compile:SUBORDINATE_DOCS,
        $compile:SUBORDINATE_DOC_URIS || 
          '! doc(resolve-uri(., ' || $compile:INSTANCE_DOC || '/base-uri()))',
        'document-node()*'
      ) ||
      ' return (',
      <svrl:active-pattern 
        documents='{{string-join({$compile:SUBORDINATE_DOCS} ! base-uri(.))}}'>
      {$pattern/(@id, @name, @role)}
      </svrl:active-pattern>, 
      ', ' || $compile:SUBORDINATE_DOCS || ' ! local:rules((' ||
      string-join(
        for $rule in $pattern/sch:rule 
        return compile:function-name($rule) || '#3',
        ','
      ) || '), (' ||
      string-join(for $rule in $pattern/sch:rule 
      return ' ' || compile:function-name($rule) || '#1', ',') ||
      '), (), .))'
    )
  ),
    $pattern/sch:rule ! 
    (
      compile:rule-documents(., $phase), 
      compile:rule-context-documents(., $phase)
    )
};

(:~ Creates a function for a rule to process a subordinate document. :)
declare function compile:rule-documents(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
{
  let $_ := utils:check-duplicate-variable-names($rule/sch:let)
  let $function-name := compile:function-name($rule)
  let $assertions as element()+ := $rule/(sch:assert|sch:report)
  return (
    compile:declare-function(
      $function-name, 
      ($compile:RULE_CONTEXT, $compile:RULE_MATCHED, $compile:SUBORDINATE_DOCS),      (
      string-join(utils:local-variable-decls($rule/sch:let), ' ') ||
      (if($rule/sch:let) then ' return ' else ()) ||
      utils:declare-variable(
        $compile:RULE_CONTEXT_NAME,
        $compile:SUBORDINATE_DOCS || '/(' || $rule/@context => utils:escape() || ')'
      ) ||
      ' return if(exists(' || $compile:RULE_CONTEXT || ') and empty(' ||
        $compile:RULE_CONTEXT || ' intersect ' || $compile:RULE_MATCHED || ')) then (',
      <svrl:fired-rule document='{{base-uri({$compile:SUBORDINATE_DOCS})}}'>
      {$rule/(@id, @name, @context, @role, @flag)}
      </svrl:fired-rule>,
      ', ' || $compile:RULE_CONTEXT || '! (',
      string-join(
        for $assertion in $assertions
        return compile:function-name($assertion, true()) || '(.)', 
        ','
      ) 
      || ')) else ()'
      )
  ) || string-join($assertions ! compile:assertion(., $phase, true()))
  )
};

(:~ Creates a function returning the rule context.
 : @param rule the rule
 : @param phase optional phase
 :)
declare function compile:rule-context(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
as xs:string
{
  compile:declare-function(
    compile:function-name($rule),
    '',
    compile:rule-context-body($rule, $phase, $compile:INSTANCE_DOC)
  )
};

(:~ Creates a function returning the rule context.
 : @param rule the rule
 : @param phase optional phase
 :)
declare function compile:rule-context-documents(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
{
  compile:declare-function(
    compile:function-name($rule),
    $compile:SUBORDINATE_DOC,
    compile:rule-context-body($rule, $phase, $compile:SUBORDINATE_DOC)
  )
};

declare %private function compile:rule-context-body(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?,
  $doc as xs:string
)
as xs:string
{
  compile:variables($rule, $phase) ||
  (if(($rule|$phase|$rule/..)/sch:let) then ' return ' else ()) ||
  $doc ||
  (if($phase/@from) then '/(' || $phase/@from => utils:escape() || ')' else ())
  || '/(' || $rule/@context => utils:escape() || ')'
};

declare function compile:rule(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
{
  let $_ := utils:check-duplicate-variable-names($rule/sch:let)
  let $assertions as element()+ := $rule/(sch:assert|sch:report)
  return (
    compile:declare-function(
      compile:function-name($rule),
      ($compile:RULE_CONTEXT, $compile:RULE_MATCHED),
      (
        'if(exists(' || $compile:RULE_CONTEXT || ') and empty(' ||
        $compile:RULE_CONTEXT || ' intersect ' || $compile:RULE_MATCHED || ')) then (',
        <svrl:fired-rule>
        {$rule/(@id, @name, @context, @role, @flag)}
        </svrl:fired-rule>,
        ', ' || $compile:RULE_CONTEXT || '! (' ||
        string-join(
          for $assertion in $assertions
          return compile:function-name($assertion) || '(.)', 
          ','
        ) 
        || ')) else ()'
      )
    ) || string-join($assertions ! compile:assertion(., $phase, false()))
  )
};

declare function compile:assertion(
  $assertion as element(),
  $phase as element(sch:phase)?,
  $distinct-name as xs:boolean
)
{
  if(not($assertion/(self::sch:assert|self::sch:report)))
  then error()	(:shouldn't happen if schema is valid:)
  else
  compile:declare-function(
    compile:function-name($assertion, $distinct-name),
    $compile:RULE_CONTEXT,
    compile:variables($assertion, $phase) || ' ' ||
    utils:declare-variable(
      $compile:RESULT_NAME,
      $compile:RULE_CONTEXT || '/(' || $assertion/@test => utils:escape() || ')'
    ) ||
    ' return if(' || $compile:RESULT || ') then ' ||
    (
      if($assertion/self::sch:assert) 
      then '() else ' || compile:assertion-message($assertion) => serialize()
      else compile:assertion-message($assertion) => serialize() || ' else ()'
    )
  )
};

declare %private function compile:assertion-message($assertion as element())
as element()
{
  element{
    QName("http://purl.oclc.org/dsdl/svrl", 
    if($assertion/self::sch:assert) then 'svrl:failed-assert' else 'svrl:successful-report')
  }
  {
    attribute{'location'}{
      if($assertion/@subject or $assertion/../@subject)
      then '{path(($Q{http://www.andrewsales.com/ns/xqs}context)/' ||
        ($assertion/@subject, $assertion/../@subject)[1] || ')}'
      else '{path($Q{http://www.andrewsales.com/ns/xqs}context)}'},
    $assertion/(@id, @role, @flag),
    attribute{'test'}{$assertion/@test => replace('\{', '{{') => replace('\}', '}}')},
    $assertion/root()//sch:diagnostic[@id = tokenize($assertion/@diagnostics)]
    !
    <svrl:diagnostic-reference diagnostic='{@id}'>
    {compile:assertion-message-content(./node())}
    </svrl:diagnostic-reference>,
    $assertion/root()//sch:property[@id = tokenize($assertion/@properties)]
    !
    <svrl:property-reference property='{@id}'>
    {@scheme, @role}
    {compile:assertion-message-content(./node())}
    </svrl:property-reference>,
    compile:assertion-message-content($assertion/node())
  }
};

declare %private function compile:variables(
  $context as element(),
  $phase as element(sch:phase)?
)
as xs:string?
{
  string-join(
    (compile:root-context-variables($context, $phase),  
    utils:local-variable-decls($context/ancestor-or-self::sch:rule/sch:let)), 
    ' '
  )
};

declare %private function compile:root-context-variables(
  $context as element(),
  $phase as element(sch:phase)?
)
as xs:string*
{
  $phase/sch:let ! compile:root-context-variable(.),
  $context/ancestor::sch:pattern/sch:let ! compile:root-context-variable(.)
};

declare %private function compile:root-context-variable($var as element(sch:let))
as xs:string?
{
  utils:declare-variable(
    $var/@name,
    $compile:INSTANCE_DOC || '/(' || 
    (
      if($var/@value) 
      then $var/@value => utils:escape()
      else serialize($var/*)
    )
    || ')',
    $var/@as
  )
};

declare %private function compile:function-name($element as element())
as xs:string
{
  'local:' ||
  $element/ancestor-or-self::*[ancestor-or-self::sch:pattern] ! 
  (local-name(.) || compile:function-id(.))
  => string-join('-')
};

declare %private function compile:function-name(
  $element as element(),
  $distinct as xs:boolean
)
as xs:string
{
  let $name := compile:function-name($element)
  return
  if($distinct eq true()) then $name || generate-id($element)
  else $name
};

declare %private function compile:function-id($element as element())
{
  if($element/@id) then $element/@id 
  else count(
    $element/preceding-sibling::sch:*[local-name() eq $element/local-name()]
  ) + 1
};

declare function compile:assertion-message-content($content as node()*)
as element(svrl:text)
{
  <svrl:text>{(:TODO attributes:)
  for $node in $content
    return
    typeswitch($node)
      case element(sch:name)
        return if($node/@path) 
          then ('{(' || $compile:RULE_CONTEXT || ')/' || $node/@path || '}') 
          else '{name(' || $compile:RULE_CONTEXT || ')}'
      case element(sch:value-of)
        return ('{let $result := (' || $compile:RULE_CONTEXT || ')/' || $node/@select
           || ' return if($result instance of node()) then $result/data() else $result}')
      case element(sch:emph)
        return output:assertion-child-elements($node)
      case element(sch:dir)
        return output:assertion-child-elements($node)
      case element(sch:span)
        return output:assertion-child-elements($node)
    default return $node
  }</svrl:text>
};

(:~ Builds the string of variable declarations in the prolog, for initial
 : evaluation.
 : @param globals the global variables
 :)
declare function compile:global-variable-decls($globals as element(sch:let)*)
as xs:string?
{
  string-join(
    for $var in $globals
    return 'declare variable $' || $var/@name || 
    (if($var/@as) then ' as ' || $var/@as else '') || ':=' || 
    (
      (: if($var/@value instance of xs:anyAtomicType+)
      then $var/@value/data() => utils:escape()
      else :) 
      $compile:INSTANCE_DOC || '/(' || utils:variable-value($var) || ')'
    )
    || ';'
  )
};

(:~ Adds user-defined functions declared in the schema. :)
declare function compile:user-defined-functions($functions as element(xqy:function)*)
as xs:string*
{
  $functions ! string(.)
};

(:~ Declare a function.
 : @param name function name
 : @param params function parameters
 : @param body function body
 :)
declare %private function compile:declare-function(
  $name as xs:string, 
  $params as xs:string*,
  $body as item()*
)
as xs:string
{
  'declare function ' || $name || '(' || string-join($params, ',') || '){'
  || serialize($body, map{'method':'basex'}) || '};'
};

(:~ Create a variable declaration. 
 : @param name variable name
 : @param value variable value
 :)
declare %private function compile:declare-variable(
  $name as xs:string,
  $value as xs:string
)
as xs:string
{
  'let ' || $name || ':=' || $value
};

(:~ Create a variable declaration. 
 : @param name variable name
 : @param value variable value
 : @param type variable type
 :)
declare %private function compile:declare-variable(
  $name as xs:string,
  $value as xs:string,
  $type as xs:string
)
as xs:string
{
  'let ' || $name || ' as ' || $type || ' :=' || $value
};