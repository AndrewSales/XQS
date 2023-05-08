module namespace xqs = 'http://www.andrewsales.com/ns/xqs';

import module namespace context = 'http://www.andrewsales.com/ns/xqs-context' at
  'context.xqm';
import module namespace eval = 'http://www.andrewsales.com/ns/xqs-evaluate' at
  'evaluate.xqm';  
import module namespace util = 'http://www.andrewsales.com/ns/xqs-utils' at
  'utils.xqm';  

declare namespace sch = "http://purl.oclc.org/dsdl/schematron";

(:~ Validates a document against a Schematron schema, without applying a phase.
 : @param instance the instance document
 : @param schema the Schematron schema
 :)
declare function xqs:validate(
  $instance as node(),
  $schema as element(sch:schema)
)
{
  xqs:check-query-binding($schema),
  eval:schema($instance, $schema, '')
};

(:~ Validates a document against a Schematron schema, applying an optional phase.
 : @param instance the instance document
 : @param schema the Schematron schema
 : @param phase the active phase
 :)
declare function xqs:validate(
  $instance as node(),
  $schema as element(sch:schema),
  $phase as xs:string
)
{
  xqs:check-query-binding($schema),
  eval:schema($instance, $schema, $phase)
};

declare function xqs:check-query-binding($schema as element(sch:schema))
{
  if(lower-case($schema/@queryBinding) = ('xquery', 'xquery3', 'xquery31'))
  then ()
  else error(
    xs:QName('invalid-query-binding'),
    'query language binding must be XQuery'
  )
};