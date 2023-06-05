module namespace basex = 'http://www.andrewsales.com/ns/port/basex';

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

import module namespace xquery = "http://basex.org/modules/xquery";

(:~
 : Implementation of port.xqm::eval#3.
 :)
declare function basex:eval($query as xs:string, $variables as map(*)?, $context-item as item()?) as item()* {
    xquery:eval($query, map:merge(($variables, $context-item ! map { "" : $context-item })), map { "pass": fn:true() })
};
