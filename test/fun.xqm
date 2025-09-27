module namespace fun = 'my-functions';

declare function fun:element-name-is-root($element as element())
as xs:boolean
{
  name($element) eq 'root'
};