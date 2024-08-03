declare variable $Q{http://www.andrewsales.com/ns/xqs}uri external;
    declare variable $Q{http://www.andrewsales.com/ns/xqs}doc as document-node() external := doc($Q{http://www.andrewsales.com/ns/xqs}uri);
declare function local:patternphase-demo(){<svrl:active-pattern xmlns:svrl="http://purl.oclc.org/dsdl/svrl" id="phase-demo"/>
, local:rules(( local:patternphase-demo-rule1#2), ( local:patternphase-demo-rule1#0), ())};
declare function local:patternphase-demo-rule1($Q{http://www.andrewsales.com/ns/xqs}context,$Q{http://www.andrewsales.com/ns/xqs}matched){if(exists($Q{http://www.andrewsales.com/ns/xqs}context) and empty($Q{http://www.andrewsales.com/ns/xqs}context intersect $Q{http://www.andrewsales.com/ns/xqs}matched)) then (
<svrl:fired-rule xmlns:svrl="http://purl.oclc.org/dsdl/svrl" context="//bar"/>
, $Q{http://www.andrewsales.com/ns/xqs}context! (local:patternphase-demo-rule1-report1(.))) else ()};declare function local:patternphase-demo-rule1-report1($Q{http://www.andrewsales.com/ns/xqs}context){ let $Q{http://www.andrewsales.com/ns/xqs}result:=$Q{http://www.andrewsales.com/ns/xqs}context/(.) return if($Q{http://www.andrewsales.com/ns/xqs}result) then <svrl:successful-report xmlns:svrl="http://purl.oclc.org/dsdl/svrl" location="{path($Q{http://www.andrewsales.com/ns/xqs}context)}" test=".">
  <svrl:text>Hello, XQS phases world!</svrl:text>
</svrl:successful-report> else ()};
declare function local:patternphase-demo-rule1(){$Q{http://www.andrewsales.com/ns/xqs}doc/(//bar)};
declare function local:schema(){<svrl:schematron-output xmlns:svrl="http://purl.oclc.org/dsdl/svrl" phase="myPhase">{ local:patternphase-demo() }</svrl:schematron-output>};declare function local:rules(
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
}; declare function local:rules($rules as function(*)*, $contexts as function(*)*, $matched as node()*, $doc as document-node())
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
}; local:schema()