# XQS
XQuery implementation of Schematron

# Pre-requisites
Tested under [BaseX](https://basex.org/) 10.x.

# Installation
1. Install [BaseX](https://basex.org/download/) version 10 or later.
1. XYZ

# Usage
XQS provides two methods of validating with a Schematron schema, by either:

- evaluating the schema dynamically; or
- compiling the schema to an XQuery main module.

## At the command line

Basic [command scripts](https://docs.basex.org/wiki/Commands#Command_Scripts) are provided to run XQS using BaseX in standalone mode. This allows you to use XQS as a straightforward, standalone validator.

The `-b` options given below simply bind a variable; their order is not significant.

### Evaluate

Run `evaluate.bxs`, passing the locations of the XML document (`uri`) and the Schematron schema (`schema`):

    basex -buri=myDoc.xml -bschema=mySchema.sch evaluate.bxs
    
You can also pass an optional phase (as `phase`):

    basex -buri=myDoc.xml -bschema=mySchema.sch -bphase=myPhase evaluate.bxs

The output is SVRL.

### Compile

Run `compile.bxs`, passing the location of the Schematron schema (`schema`):

    basex -bschema=mySchema.sch compile.bxs
    
You can also pass an optional phase:

    basex -bschema=mySchema.sch -bphase=myPhase compile.bxs
    
**Note** a current limitation is that schema phase can only be specified during compilation and not at validation-time: see #7.

The output is an XQuery main module, which contains two external variables allowing the document to validate to be passed in:

    $Q{http://www.andrewsales.com/ns/xqs}uri
    $Q{http://www.andrewsales.com/ns/xqs}doc

### Validate

For convenience, if you have compiled a schema using `compile.bxs`, you can run `validate.bxs`, passing the schema and document locations:

    basex -bschema=mySchema.xqy -buri=myDoc.xml
    
The output is again SVRL.

## In XQuery
You can also use the XQuery API contained in `xqs.xqm`, e.g.

    import module namespace xqs = 'http://www.andrewsales.com/ns/xqs' at 'path/to/xqs.xqm;
    xqs:validate(doc('myDoc.xml'), doc('mySchema.xml)/*[, 'myPhase'])
    
or

    xqs:compile(doc('mySchema.xml)/*[, 'myPhase'])

# Advisory notes
This is a pre-release and should be treated as such.
Please refer to the issues for a list of known bugs and planned enhancements.

## Query language binding
Your schema *must* specify a `queryBinding` value of : `xquery`, `xquery3` or `xquery31`, in any combination of upper or lower case.

**CAUTION** When compiling, avoid using the XQS namespace (`http://www.andrewsales.com/ns/xqs`) in your schema, which XQS uses for variables internal to the application.