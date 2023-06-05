module namespace port = 'http://www.andrewsales.com/ns/port';

declare %private variable $port:processor :=
        if (fn:matches(<a/>/fn:generate-id(), "MD[0-9]+N1"))
        then
          "existdb"
        else if (<a/>/fn:generate-id() eq "d0e0")
        then
          "saxon"
        else
          "basex"
        ;

declare %private variable $port:implementation-module-ns :=
          switch ($port:processor)
            case "existdb"
            return
              "http://www.andrewsales.com/ns/port/existdb"
            case "saxon"
            return
              "http://www.andrewsales.com/ns/port/saxon"
            case "basex"
            return
              "http://www.andrewsales.com/ns/port/basex"
            default
            return
              "http://www.andrewsales.com/ns/port/basex"
         ;

declare %private variable $port:implementation-module-location-hint := "port/" || fn:replace($port:implementation-module-ns, ".+/(.+)", "$1") || ".xqm";
                  
declare %private variable $port:implementation := fn:load-xquery-module($port:implementation-module-ns, map { "location-hints":  $port:implementation-module-location-hint })?functions;

(:~
 : Dynamically evaluate a string as an XQuery expression.
 :
 : @param query the XQuery string.
 : @param bindings a map of variable bindings, keys must be of xs:string or xs:QName types.
 : @param context-item a context item for the XQuery being evaluated.
 :
 : @return The results of the execution of the XQuery expression.
 :)
declare function port:eval($query as xs:string, $variables as map(*)?, $context-item as item()?) as item()* {
  	let $eval-functions := $port:implementation(fn:QName($port:implementation-module-ns, "eval"))
  	let $eval3-function := $eval-functions?3
  	return
  		$eval3-function($query, $variables, $context-item)
};
