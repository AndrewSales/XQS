module namespace crepdl = 'http://www.andrewsales.com/ns/crepdl';

declare namespace c = "http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0";

declare namespace File = 'java:java.io.File';
declare namespace URI = 'java:java.net.URI';
declare namespace Validator = 'java:com.helger.crepdl.validate.CREPDLValidator';
declare namespace Result = 'java:com.helger.crepdl.validate.CREPDLStreamValidationResult';
declare namespace Reader = 'java:com.helger.crepdl.parse.CREPDLReader';

(:~
 : Load a CREPDL schema. 
 : @param schema the CREPDL schema. This argument may be one of:
 : <ul>
 : <li>xs:string, which will be treated as a file path;</li>
 : <li>xs:anyURI, treated as a URI;</li>
 : <li>document-node(), representing the schema document node;</li>
 : <li>element(), representing the schema root element.</li>
 : </ul>
 : <p>Any other type throws a crepdl:invalid-schema-argument error.</p>
 :)
declare %private function crepdl:load-schema($schema as item()) as item()
{
  if($schema instance of xs:string)
  then File:new($schema)
  else if($schema instance of xs:anyURI)
  then URI:create(string($schema))
  else if($schema instance of document-node())
  then Reader:readScriptFromString(serialize($schema), base-uri($schema))
  else if($schema instance of element())
  then Reader:readScriptFromString(serialize($schema), base-uri($schema))
  else error(xs:QName('crepdl:invalid-schema-argument'), 'schema argument must be 
  one of type xs:string, xs:anyURI, document-node() or element(); got ' || $schema)
};

(:~ 
 : Validate a file against a CREPDL schema.
 : @param path path to file to validate
 : @param schema the CREPDL schema 
 : @param encoding optional explicit encoding, defaulting to UTF-8
 : @return a <pre>result</pre> in the CREPDL v2 namespace, with <pre>notIncluded</pre> 
 : and <pre>unknowns</pre> child elements representing each class of character(s),
 : where identified. The element content of these child elements is a string of the 
 : characters identified. If none are identified, the respective element is absent.
 :)
declare function crepdl:validate-file(
  $path as xs:string,
  $schema as item(),
  $encoding as xs:string?
) as element(c:result)
{
  let $schema := crepdl:load-schema($schema)
  let $validator := Validator:create($schema)
  let $encoding := if(exists($encoding)) then $encoding else 'UTF-8'
  let $file := File:new($path)
  let $result := Validator:validateFile($validator, $file, $encoding)
  return 
  <c:result>{
     if(exists(Result:notIncluded($result))) 
     then <c:notIncluded>{Result:notIncluded($result)=>string-join()}</c:notIncluded>
     else (),
     if(exists(Result:unknowns($result))) 
     then <c:unknown>{Result:unknowns($result)=>string-join()}</c:unknown>
     else ()
   }</c:result> 
};

(:~ 
 : Validate a string against a CREPDL schema.
 : @param string the string to validate
 : @param schema the CREPDL schema 
 : @return a <pre>result</pre> in the CREPDL v2 namespace, with <pre>notIncluded</pre> 
 : and <pre>unknowns</pre> child elements representing each class of character(s),
 : where identified. The element content of these child elements is a string of the 
 : characters identified. If none are identified, the respective element is absent.
 :)
declare function crepdl:validate-string(
  $string as xs:string,
  $schema as item()
) as element(c:result)
{
  let $schema := crepdl:load-schema($schema)
  let $validator := Validator:create($schema)
  let $result := Validator:validateString($validator, $string)
  return 
  <c:result>{
     if(exists(Result:notIncluded($result))) 
     then <c:notIncluded>{Result:notIncluded($result)=>string-join()}</c:notIncluded>
     else (),
     if(exists(Result:unknowns($result))) 
     then <c:unknown>{Result:unknowns($result)=>string-join()}</c:unknown>
     else ()
   }</c:result> 
  
};