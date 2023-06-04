module namespace existdb = 'http://www.andrewsales.com/ns/port/existdb';

declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

import module namespace util = "http://exist-db.org/xquery/util";

(:~
 : Implementation of port.xqm::eval#3
 :)
declare function existdb:eval($query as xs:string, $variables as map(*)?, $context-item as item()?) as item()* {
    (: TODO(AR) it would be better to pass the variables to util:eval via a different approach, the current approach does not work for function() type parameters (e.g. also Map and Array) :)
    let $static-context :=
        <static-context>
        {
            map:for-each($variables, function($var-name, $var-value) { <variable name="{$var-name}">{$var-value}</variable> })
                
        }
        </static-context>
    return
        util:eval-with-context($query, $static-context, fn:false(), $context-item)
};
