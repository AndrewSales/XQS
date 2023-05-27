(:~ Generates unit tests from the Schematron conformance suite at
 : https://github.com/Schematron/schematron-conformance
 :
 : This query expects the collection of test case documents from the repository
 : mentioned above to have been cloned alongside the top-level directory of this
 : (XQS) repository.
 :)

declare namespace cs = "tag:dmaus@dmaus.name,2019:Schematron:Testsuite";

declare function local:make-function($doc as document-node(element(cs:testcase)))
{
  for $schema at $pos in $doc/cs:testcase/cs:schemas/*
  return
  ('(:~ ' || $doc/*/cs:label || (if($doc/*/cs:reference) then '
: @see ' || $doc/*/cs:reference else '') || ' 
:)
' ||
'declare %unit:test function _:' || $doc/*/@id || $pos || '(){let $result:=',
'eval:schema(document{' || $doc/*/cs:documents/cs:primary/* => serialize() || '},
' || $schema =>serialize()
|| ', '''') return unit:assert(' ||
(if($doc/cs:testcase/@expect='valid') 
then '_:is-valid($result)' 
else 'not(_:is-valid($result))') || ')};
')  
};

let $prolog := 'module namespace _ = "http://www.andrewsales.com/ns/xqs-conformance-suite";
declare namespace sch = "http://purl.oclc.org/dsdl/schematron";
declare namespace svrl = "http://purl.oclc.org/dsdl/svrl";
import module namespace eval = "http://www.andrewsales.com/ns/xqs-evaluate" at
  "../evaluate.xqm";
declare function _:is-valid($svrl as element(svrl:schematron-output))
as xs:boolean{
  empty($svrl/(svrl:failed-assert|svrl:successful-report))
};
'

let $functions:=for $doc in collection('..\..\schematron-conformance\src\main\resources\tests\core')
return
local:make-function($doc)

return
file:write-text(
  resolve-uri('conformance-suite.xqm', static-base-uri()),
  $prolog || $functions => string-join()
)