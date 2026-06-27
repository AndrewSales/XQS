module namespace _ = 'http://www.andrewsales.com/ns/crepdl-tests';

import module namespace crepdl = 'http://www.andrewsales.com/ns/crepdl' at '../crepdl.xqm';

declare namespace c = "http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0";

declare %unit:test function _:test-validate-filename()
{
  let $result := crepdl:validate-string(
    'Hello, world!',
    resolve-uri('test-cases/basic-latin.crepdl', static-base-uri())
  )
  return unit:assert-equals(
    $result,
    (
      <c:notIncluded>, !</c:notIncluded>,
      <c:unknown/>
    )
  )
};

(:~ The underlying Java exception propagates as XPTY0004, so catch this and inspect
 : the error message.
 :)
declare %unit:test function _:test-validate-bad-filename()
{
  let $path := resolve-uri('test-cases/no-such.crepdl', static-base-uri())
      => file:resolve-path()
  return      
  try{
    crepdl:validate-string(
      'Hello, world!',
      $path
    )
  }
  catch err:XPTY0004 {
    unit:assert-equals(
      $err:description, 
      'Resource "' || $path || ' (The system cannot find the file specified)" not found.. Caused by: com.helger.crepdl.validate.CREPDLValidator:create(File).'
    )
  }
};

declare %unit:test function _:test-validate-file-uri()
{
  let $result := crepdl:validate-string(
    'Hello, world!',
    xs:anyURI(resolve-uri('test-cases/basic-latin.crepdl', static-base-uri() => replace('\\', '/')))
  )
  return unit:assert-equals(
    $result,
    (
      <c:notIncluded>, !</c:notIncluded>,
      <c:unknown/>
    )
  )
};

(:~ The underlying Java exception propagates as XPTY0004, so catch this and inspect
 : the error message.
 :)
declare %unit:test function _:test-validate-http-uri()
{
  try{
    crepdl:validate-string('Hello, world!', xs:anyURI('http://example.com/basic-latin.crepdl'))
  }
  catch err:XPTY0004 {
   unit:assert-equals(
      $err:description,
      'Resource "http://example.com/basic-latin.crepdl" not found.. Caused by: com.helger.crepdl.validate.CREPDLValidator:create(URI).'
    ) 
  }
};

declare %unit:test function _:test-validate-schema-doc()
{
  let $result := crepdl:validate-string('Hello, world!', document{<char xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">[\p{{Alpha}}]</char>})
  return unit:assert-equals(
    $result,
    (
      <c:notIncluded>, !</c:notIncluded>,
      <c:unknown/>
    )
  )
};

declare %unit:test function _:test-validate-schema-element()
{
  let $result := crepdl:validate-string('Hello, world!', <char xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">[\p{{Alpha}}]</char>)
  return unit:assert-equals(
    $result,
    (
      <c:notIncluded>, !</c:notIncluded>,
      <c:unknown/>
    )
  )
};

(:~ invalid schema argument:)
declare %unit:test('expected', 'crepdl:invalid-schema-argument') function _:test-validate-bad-schema-argument()
{
  crepdl:validate-string(
    'Hello, world!',
    1
  )
};

declare %unit:test function _:test-validate-file()
{
  let $result := crepdl:validate-file(
    resolve-uri('test-cases/crepdl-input.txt', static-base-uri())
    => file:resolve-path(),
    <char xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">[\p{{Alpha}}]</char>,
    ()
  )
  return unit:assert-equals(
    $result,
    (
      <c:notIncluded>, !</c:notIncluded>,
      <c:unknown/>
    )
  )
};