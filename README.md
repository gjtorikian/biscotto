Biscotto is a [CoffeeScript](http://coffeescript.org/) API documentation generator. The underlying architecture is based on [codo](https://github.com/netzpirat/codo); however, this uses [TomDoc](http://tomdoc.org/) notation, instead of JSDoc.

## Features

* Detects classes, methods, constants, mixins & concerns.
* Generates a nice site to browse your code documentation in various ways.
# JSON output

## Text processing

### TomDoc Notation

API documentation should be written in the [TomDoc](http://tomdoc.org/) notation.  
Originally conceived for Ruby, TomDoc lends itself pretty nicely to Coffeescript.
There are some slight changes in the parse rules to match Coffeescript.
Briefly, here's a list of how you should format your documentation:

#### Status types

Every class and method should start with one of three phrases: `Public:`, `Internal:`,
and `Private:`. You can flag whether or not to include Internal and Private members
via the options.

#### Method arguments

Each method argument starts with the argument name, followed by a dash (`-`), and
the description of the argument:

```
argument - Some word about the arg!
```

Hash options are placed on a newline and end with a colon:

```
options - These are the options:
          key1: Blah blah.
          key2: Blah
```

If a description has a default value, define it at the end of the
description with `(default: <desc>)`.

#### Return types

When returning from a method, your line should start with the word `Returns`. When
describing the return type, wrap it in the link reference notation (two curly braces,
like this: `{ }`). This ensures that the generated methods correlates a return type.
Methods without return types returned `undefined`. You can list more than one `Returns`
per method by separating each type on a different line.

### Status Blocks

You can flag methods in a file with the following syntax:

```coffee
### Public ###
```

That will mark every method underneath that block as `Public`. You can follow the
same notion for `Internal` as well.

You can have as many block status flags as you want. The amount of `#`s must be at
least three, and you can have any text inside the block you want. For example:

```coffee
### Internal: This does some secret stuff. ###
```

If you specify a status for a method within a block, the status is respected.
For example:


```coffee
### Public ###

# Internal: A secret method
notShown: ->

shown: ->
```

`shown` is kept as Public because of the status block, while `notShown` is indeed Internal.

### GitHub Flavored Markdown

Biscotto documentation is processed with [GitHub Flavored Markdown](http://github.github.com/github-flavored-markdown/).

### Automatically link references

Biscotto comments and all tag texts will be parsed for references to other classes, methods and mixins, and are automatically
linked. The reference searching will not take place within code blocks, thus you can avoid reference searching errors
by surround your code block that contains curly braces with backticks.

There are several ways of link types supported and all can take an optional label after the link.

* Normal URL links: `{http://coffeescript.org/}` or `[Try CoffeeScript](http://coffeescript.org/)`
* Link to a class or mixin: `{Animal.Lion}` or `[The mighty lion]{Animal.Lion}`
* Direct link to an instance method: `{Animal.Lion.walk}` or `[The lion walks]{Animal.Lion.walk}`
* Direct link to a class method: `{Animal.Lion@constructor}` or `[A new king was born]{Animal.Lion@constructor}`

If you are referring to a method within the same class, you can omit the class name: `{#walk}` or `{.constructor}`.

### Delegation

If you're writing methods that do the exact same thing as another method, you can
choose to copy over the documentation via _delegation_. For example:

```coffee
# {Delegates to: .delegatedRegular}
delegatedMethod: ->

# Public: I'm being delegated to!
# 
# a - A {Number}
# b - A {String}
#
# Returns a {Boolean}
delegatedRegular: (a, b) ->
```

`delegatedMethod` has the same arguments, return type, and documentation as 
`delegatedRegular`. You can also choose to delegate to a different class:

```coffee
# Private: {Delegates to: Another.Class@somewhere}
delegatedMethod: ->
```

Classes that are delegated should still set their own statuses. For example, if
`Another.Class@somewhere` is Public, `delegatedMethod` is still marked as `Private`.
The same documentation remains.

### Examples

For more technical examples, peruse the [spec](./spec) folder, which contains all
the tests for Biscotto.

## Generate

After the installation, you will have a `biscotto` binary that can be used to generate the documentation recursively for all CoffeeScript files within a directory.

To view a list of commands, type

```bash
$ biscotto --help
```

Biscotto wants to be smart and tries to detect the best default settings for the sources, the readme, the extra files, and
the project name, so the above defaults may be different on your project.

### Project defaults

You can define your project defaults by writing your command line options to a `.biscottoopts` file:

```bash
--name       "Biscotto"
--readme     README.md
--title      "Biscotto Documentation"
--private
--quiet
--output-dir ./doc
./src
-
LICENSE
CHANGELOG.md
```

Put each option flag on a separate line, followed by the source directories or files, and optionally any extra file that
should be included into the documentation separated by a dash (`-`). If your extra file has the extension `.md`, it'll
be rendered as Markdown.

## Keyboard navigation

You can quickly search and jump through the documentation by using the fuzzy finder dialog:

* Open fuzzy finder dialog: `Ctrl-T`

In frame mode you can toggle the list naviation frame on the left side:

* Toggle list view: `Ctrl-L`

You can focus a list in frame mode or toggle a tab in frameless mode:

* Class list: `Ctrl-C`
* Mixin list: `Ctrl-I`
* File list: `Ctrl-F`
* Method list: `Ctrl-M`
* Extras list: `Ctrl-E`

You can focus and blur the search input:

* Focus search input: `Ctrl-S`
* Blur search input: `Esc`

In frameless mode you can close the list tab:

* Close list tab: `Esc`

## License

(The MIT License)

Copyright (c) 2013 Garen J. Torikian

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
