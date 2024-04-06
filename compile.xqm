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
declare variable $compile:RULES_FUNCTION_WITH_CONTEXT := 'declare function local:rules($rules as function(*)*, $contexts as function(*)*, $matched as node()*, $doc as document-node()*)
as element()*
{
    $doc ! (
    if (empty($rules))
    then
        ()
    else
        let $context := head($contexts)(.)
        return
        (head($rules)($context, $matched),
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
    'declare function local:schema(){',
    <svrl:schematron-output>
      {output:schema-title($schema/sch:title)}
      {$schema/@schemaVersion}
      {if($active-phase) then attribute{'phase'}{$active-phase/@id} else ()}
      {output:namespace-decls-as-svrl($schema/sch:ns)}
    {'{', string-join(
      for $pattern in $active-patterns 
      return compile:function-name($pattern) ||'()',
      ','
    ), '}'} </svrl:schematron-output>,
    '};' || $compile:RULES_FUNCTION || $compile:RULES_FUNCTION_WITH_CONTEXT ||
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
    ('declare function ' || compile:function-name($pattern) || '(){',
      <svrl:active-pattern>
      {$pattern/(@id, @name, @role)}
      </svrl:active-pattern>, ', local:rules((' ||
      string-join(for $rule in $pattern/sch:rule 
      return ' ' || compile:function-name($rule) || '#2', ',') || '), (' ||
      string-join(for $rule in $pattern/sch:rule 
      return ' ' || compile:function-name($rule) || '#0', ',') || '), ())',
      '};',
      $pattern/sch:rule ! 
      (compile:rule(., $phase), compile:rule-context(., $phase))
    )
};

(:~ Creates a function to process a pattern which specifies subordinate 
 : documents. 
 :)
declare function compile:pattern-documents(
  $pattern as element(sch:pattern),
  $phase as element(sch:phase)?
)
{
  let $function-id := compile:function-id($pattern)
  return
  compile:declare-function(compile:function-name($pattern), '') || '{' ||
    'let ' || $compile:SUBORDINATE_DOC_URIS || ':=' || 
    $compile:INSTANCE_DOC || '/(' || $pattern/@documents => utils:escape() || ')' ||
    'let ' || $compile:SUBORDINATE_DOC || ' as document-node()* :=' ||
    $compile:SUBORDINATE_DOC_URIS || '!' || 'doc(.) return (',
    <svrl:active-pattern 
      documents='{{string-join({$compile:SUBORDINATE_DOC} ! base-uri(.))}}'>
    {$pattern/(@id, @name, @role)}
    </svrl:active-pattern>, ', local:rules((' ||
    string-join(
      for $rule in $pattern/sch:rule 
      return compile:function-name($rule) || '#3',
      ','
    ) || '), ' || $compile:SUBORDINATE_DOC || ')',
    ')};',
    $pattern/sch:rule ! compile:rule-documents(., $phase)
};

(:~ Creates a function for a rule to process a subordinate document. :)
declare function compile:rule-documents(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
{
  let $function-name := compile:function-name($rule)
  let $assertions as element()+ := $rule/(sch:assert|sch:report)
  return (
    compile:declare-function($function-name, $compile:SUBORDINATE_DOC) || 
    ' as document-node(){' ||
    string-join(utils:local-variable-decls($rule/sch:let), ' ') ||
      (if($rule/sch:let) then ' return ' else ()) ||
      utils:declare-variable(
        $compile:RULE_CONTEXT_NAME,
        $compile:SUBORDINATE_DOC || '/(' || $rule/@context => utils:escape() || ')'
      ) ||
    ' return if(' || $compile:RULE_CONTEXT || ') then (',
      <svrl:fired-rule document='{{base-uri({$compile:SUBORDINATE_DOC})}}'>
      {$rule/(@id, @name, @context, @role, @flag)}
      </svrl:fired-rule>,
    ', ' || $compile:RULE_CONTEXT || '! (',
    string-join(
      for $assertion in $assertions
      return compile:function-name($assertion, true()) || '(.)', 
      ','
    ) 
    || ')) else ()};' || string-join($assertions ! compile:assertion(., $phase, true()))
  )
};

declare function compile:rule-context(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
{
  let $function-name := compile:function-name($rule)
  return (
    compile:declare-function($function-name, '') || '{' ||
    string-join(compile:root-context-variables($phase/sch:let), ' ') ||
    string-join(compile:root-context-variables($rule/../sch:let), ' ') ||
    string-join(utils:local-variable-decls($rule/sch:let), ' ') ||
      (if(($rule|$phase|$rule/..)/sch:let) then ' return ' else ()) ||
    $compile:INSTANCE_DOC || '/(' || $rule/@context => utils:escape() || ')'
    ) || '};'
};

declare function compile:rule(
  $rule as element(sch:rule),
  $phase as element(sch:phase)?
)
{
  let $_ := utils:check-duplicate-variable-names($rule/sch:let)
  let $function-name := compile:function-name($rule)
  let $assertions as element()+ := $rule/(sch:assert|sch:report)
  return (
    compile:declare-function($function-name, ($compile:RULE_CONTEXT, $compile:RULE_MATCHED)) || '{' ||
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
    || ')) else ()};' || string-join($assertions ! compile:assertion(., $phase, false()))
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
  'declare function ' || compile:function-name($assertion, $distinct-name) ||
  '(' || $compile:RULE_CONTEXT || '){' ||
  string-join(compile:root-context-variables($phase/sch:let), ' ') ||
  string-join(compile:root-context-variables($assertion/../../sch:let), ' ') ||
  string-join(utils:local-variable-decls($assertion/../sch:let), ' ') || ' ' ||
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
  || '};'
};

declare %private function compile:assertion-message($assertion as element())
as element()
{
  element{
    QName("http://purl.oclc.org/dsdl/svrl", 
    if($assertion/self::sch:assert) then 'svrl:failed-assert' else 'svrl:successful-report')
  }
  {
    attribute{'location'}{'{path($Q{http://www.andrewsales.com/ns/xqs}context)}'},
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

declare %private function compile:root-context-variables($variables as element(sch:let)*)
{
  for $var in $variables 
  return utils:declare-variable(
    $var/@name,
    if($var/@value) then $compile:INSTANCE_DOC || '/(' || $var/@value => utils:escape() || ')'
    else serialize($var/*)
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

declare function compile:declare-function($name as xs:string, $params as xs:string*)
{
  'declare function ' || $name || '(' || string-join($params, ',') || ')'
};