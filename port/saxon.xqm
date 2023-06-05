module namespace sxn = 'http://www.andrewsales.com/ns/port/saxon';

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

import module namespace saxon = "http://saxon.sf.net/";

(:~
 : Implementation of port.xqm::eval#3.
 :)
declare function sxn:eval($query as xs:string, $variables as map(*)?, $context-item as item()?) as item()* {
    let $xquery-fn := saxon:xquery($query)
    return
      $xquery-fn($context-item, $variables)
};
