# XQS
XQuery for Schematron (XQS) (pron. /ɛksˈkju&#x2D0;z/) is an XQuery implementation of Schematron.

The development version is a highly conformant implementation of the forthcoming 2025 edition of the international standard, ISO/IEC 19757-3:2025.

# Limitations
The only known area of non-conformance is XInclude-like language fixup, which is mandated by Clause 6.7 _Localization and language fixup_.

See also https://github.com/AndrewSales/XQS/issues/29.

# Pre-requisites
Tested under [BaseX](https://basex.org/) 10.x.
Note that the codebase is now also tested against BaseX 12.0.

# Installation
1. Install [BaseX](https://basex.org/download/) version 10 or later.
1. Download the latest release and navigate to the root directory of the extracted archive (containing `*.xqm` files).

# Usage
XQS provides two methods of validating with a Schematron schema, by either:

- evaluating the schema dynamically; or
- compiling the schema to an XQuery main module.

## At the command line

Basic [command scripts](https://docs.basex.org/wiki/Commands#Command_Scripts) are provided in `bin/` to run XQS using BaseX in standalone mode. This allows you to use XQS as a straightforward, standalone validator.

The `-b` options given below simply bind a variable; their order is not significant.

The named example files used in the commands below are also included in this repository, in `examples/`.

### Evaluate

Run `evaluate.bxs`, passing the locations of the XML document (`uri`) and the Schematron schema (`schema`):

    basex -buri=myDoc.xml -bschema=mySchema.sch evaluate.bxs
    
You can also pass an optional phase (as `phase`):

    basex -buri=myDoc.xml -bschema=mySchema.sch -bphase=myPhase evaluate.bxs

The output is in the Schematron Validation Reporting Language (SVRL) format.

### Compile

Run `compile.bxs`, passing the location of the Schematron schema (`schema`):

    basex -bschema=mySchema.sch compile.bxs
    
Example output for this command is shown in `mySchema.xqy`.    
    
If your schema uses phases, you can also select a phase:

    basex -bschema=mySchema.sch -bphase=myPhase compile.bxs
    
Example output for this command is shown in `mySchema-myPhase.xqy`.

The output from `compile.bxs` is an XQuery main module, which contains two external variables allowing the document to validate to be passed in:

    $Q{http://www.andrewsales.com/ns/xqs}uri
    $Q{http://www.andrewsales.com/ns/xqs}doc
    
`$uri` should be a URI. If your XQuery processor supports it, you can use `$doc` to pass a document node instead. 

**CAUTION** When compiling, avoid using the XQS namespace (`http://www.andrewsales.com/ns/xqs`) in your schema, which XQS uses for variables internal to the application.

### Reporting the Schematron edition

Both evaluation and compile scripts support the `report-edition` option, which  is a new conformance requirement for implementations. In XQS, it can be invoked by passing one of the values `y`, `true`, `yes` or `1` in any combination of case to the `report-edition` option:

    basex -buri=myDoc.xml -bschema=mySchema.sch -breport-edition=Y evaluate.bxs
    
When this option is enabled, XQS reports this via an empty `schema` root element as the first item returned, including the attribute `schematronEdition` if specified in the schema e.g.

    <schema xmlns='http://purl.oclc.org/dsdl/schematron' schematronEdition='2025'/>
    
Output from evaluating or compiling the schema will be the second item returned in this scenario.    

### Validate

For convenience, if you have compiled a schema using `compile.bxs`, you can run `validate.bxs`, passing the schema and document locations:

    basex -bschema=mySchema.xqy -buri=myDoc.xml validate.bxs
    
The output is again SVRL.

## In XQuery
You can also use the XQuery API contained in `xqs.xqm`, e.g.

    import module namespace xqs = 'http://www.andrewsales.com/ns/xqs' at 'path/to/xqs.xqm;
    xqs:validate(doc('myDoc.xml'), doc('mySchema.xml')/*)
    
or

    xqs:compile(doc('mySchema.xml')/*)
    
If you use phases, you can pass them in like so:

    xqs:compile(doc('mySchema.xml')/*, map{'phase':'myPhase'})
    
or

    xqs:validate(doc('myDoc.xml'), doc('mySchema.xml')/*, map{'phase':'myPhase'})
    
where `myPhase` is the ID of the selected phase. 

Here you may also use the reserved values:
- `#ALL` - to indicate that all patterns are active;
- `#ANY` - to choose the phase dynamically based on evaluating `phase/@when` against the instance document (new in Schematron 2025); or
- `#DEFAULT` to select the default phase.     
    
## Inclusion and expansion

Inclusions are resolved and abstract rules and patterns instantiated automatically, whether you are compiling or evaluating a schema. There is no need to carry out a separate initial process.

If you do wish to perform this step only, in order to produce a fully resolved and instantiated schema, `include-expand.bxs` is provided for this purpose. Run it, passing the location of the schema, as follows:

    basex -bschema=myModularSchema.sch include-expand.bxs
    
Example output for this command is shown in `examples/myResolvedSchema.sch`.
    
The output from `include-expand.bxs` is the schema with inclusions resolved and abstract patterns and rules instantiated. (Note that this command script can be used on **any** valid Schematron schema, regardless of the target query language; it does not depend on the query language binding the schema declares.)  

# CREPDL validation
The XQS distribution includes **experimental** support for performing validation against a Character Repertoire Definition Language (CREPDL) schema using XQuery.

This in turn enables this feature to also be used within a Schematron schema.

## Dependencies
The XQS module `crepdl.xqm` uses BaseX's convenient [Java bindings](https://docs.basex.org/main/Java_Bindings) to access Philip Helger's [jcrepdl](https://github.com/phax/jcrepdl).

The jcrepdl and supporting libraries are supplied here in the `lib/` directory of this repository. 

### Installation
Place the JAR files included in `lib/` in the `lib/` directory of your BaseX installation.

## Usage
### In XQuery code
In XQuery, import the `crepdl` module and invoke one of the two functions, `crepdl:validate-string()` or `crepdl:validate-file()`:

    import module namespace crepdl = 'http://www.andrewsales.com/ns/crepdl' at 'path/to/crepdl.xqm';
    
    crepdl:validate-string('Hello, world!', 'path/to/my-schema.crepdl')
    (: OR :)
    crepdl:validate-file('path/to/my-file.txt', 'path/to/my-schema.crepdl')
    
where the first argument is a string or file path, respectively.
The second argument is the CREPDL schema and can be any one of:
- a string
- a URI
- a document node
- an element.

The result is a `result` element in the CREPDL (version 2) namespace, containing an element containing any unknown characters and one for any not included characters. These child elements will only be present if they have content, e.g. this query:

    crepdl:validate-string(
      'Hello, world!',
      <char xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">
      [\p{{Alpha}}]
      </char>
    )

will produce this result:

    <result xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">
      <notIncluded>, !</notIncluded>
    </result>
    
while the query:

    crepdl:validate-string(
      'Hello, world!',
      <char xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">
        <kernel>[A-Z]</kernel>
        <hull>[A-Za-z]</hull>
      </char>
    )
    
will produce:

    <result xmlns="http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0">
      <notIncluded>, !</notIncluded>
      <unknown>elloworld</unknown>
    </result>

### Within a Schematron schema
The two CREPDL functions can equally be invoked within a Schematron schema, e.g.

```
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
xmlns:xqy = 'http://www.w3.org/2012/xquery'
schematronEdition='2025' queryBinding='xquery31'>

  <!-- import the crepdl library module -->  
  <xqy:prolog>
  import module namespace xqs-crepdl =  
     'http://www.andrewsales.com/ns/crepdl' at
     'path/to/crepdl.xqm';
 </xqy:prolog>
  
  <!-- the CREPDL namespace --> 
  <sch:ns prefix='c' uri='http://purl.oclc.org/dsdl/crepdl/ns/structure/2.0'/>

  <!-- the XQuery library namespace -->
  <sch:ns prefix='crepdl' uri='http://www.andrewsales.com/ns/crepdl'/>
  
  <sch:pattern>
    <sch:rule context='*'>
      <sch:let name='crepdl-schema'
               value='resolve-uri("basic-latin.crepdl", base-uri())'/>
      <sch:let name='crepdl-result' 
               value='crepdl:validate-string(., $crepdl-schema)'
               as='element(c:result)'/>
      <sch:report test='$crepdl-result/c:*'>
      unknown='<sch:value-of select='$crepdl-result/c:unknown'/>';
      not included='<sch:value-of select='$crepdl-result/c:notIncluded'/>'
      </sch:report>
    </sch:rule>
  </sch:pattern>
</sch:schema>
```
The schema above and some basic CREPDL sample files are included in `examples/crepdl/`.


### Limitations
This works for both evaluated and compiled schemas, but only when using BaseX as the XQuery engine.

The CREPDL XQuery functions bundled with XQS simply invoke jcrepdl code, so refer to [that project's README](https://github.com/phax/jcrepdl/blob/main/README.md) for its documentation and limitations.
    
# Running the test suite
The test suite is found in the `test/ `sub-directory.
To run all the tests there, at the command line, specify the `-t` option and the path to the `test` directory:

    basex -t path/to/test
    
The command returns `0` if all tests pass, otherwise `1`.  
    
# Advisory notes
This is an early release and should be treated as such. Bug reports, feature requests and other observations are welcome.
Please refer to the issues for a list of known bugs and planned enhancements.

## Query language binding
Your schema should specify a `queryBinding` value of : `xquery`, `xquery3` or `xquery31`, in any combination of upper or lower case.

## Implementation-specific extensions
1. Attributes which contain expressions to be evaluated may be represented by elements instead (see https://github.com/AndrewSales/XQS/issues/71).
2. Element `xqs:copy-of` (by analogy with `xsl:copy`) is allowed in schemas wherever there is dynamic evaluation of messages for SVRL output - its `select` attribute is evaluated against the relevant context (see https://github.com/AndrewSales/XQS/issues/78 and https://github.com/Schematron/schematron-enhancement-proposals/issues/86).

# Troubleshooting

## My existing schema produces different results with XQS: rules don't fire that I expect to.

When using an XSLT implementation, a rule's `context` attribute with an XPath such as `foo` will match any instance of that element in the document being validated, and the rule is said to "fire".

The key difference with XQS is that it evaluates these XPaths _in the context of the document root_, so the expression `foo` will only match **if it is the root element**.

To address this, XPaths should be changed as appropriate, e.g. to `//foo`, which will ensure that the element would be matched anywhere in the document.

## User-defined functions in my existing schema aren't working.

If your schema was intended for use with an XSLT implementation, then any user-defined functions will most likely be expressed using `xsl:function`.

XQS is a pure XQuery implementation and doesn't recognize these, so they need to be re-written as XQuery, contained in `function` elements in the XQuery namespace, e.g.

    <function xmlns='http://www.w3.org/2012/xquery'>
    declare function local:foo($i as xs:int) as xs:int{
      $i * $i
    };
    </function>
    
## How do I import XQuery modules?    

You can use the XQS extension `<xqy:prolog>` to do this, e.g.

    <prolog xmlns='http://www.w3.org/2012/xquery'>
    import module namespace fun = 'my-functions' at '../fun.xqm';
    </prolog>

A working example is shown in https://github.com/AndrewSales/XQS/tree/main/test/test-cases/xquery-module-import.sch.

Imports will be resolved against the base URI of the schema.    

## Is there an equivalent to `xsl:copy-of` for use within a `property`?

Yes: the XQS extension `xqs:copy-of` behaves in the same way, allowing e.g.

    <sch:property id='p1' scheme='abc' role='def'>wrong=<xqs:copy-of select='.'/></sch:property>

The instruction is not limited to use in that context alone, so is also permitted within assertion messages.
