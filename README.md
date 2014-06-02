Biscotto is a [CoffeeScript](http://coffeescript.org/) API documentation generator. The underlying architecture is based on [codo](https://github.com/coffeedoc/codo); however, this uses a variant of the excellent [TomDoc](http://tomdoc.org/) notation, instead of verbose JSDoc.

[![Build Status](https://travis-ci.org/atom/biscotto.png?branch=master)](https://travis-ci.org/atom/biscotto)

## Features

* Detects classes, methods, constants, mixins & concerns.
* Generates a nice site to browse your code documentation in various ways.
* Intermediate JSON output to transform into any output

## Comment Parsing

The following section outlines how comments in your files are processed.

### TomDoc

API documentation should be written in the [TomDoc](http://tomdoc.org/)
notation. Originally conceived for Ruby, TomDoc lends itself pretty nicely to
Coffeescript. There are some slight changes in the parse rules to match
Coffeescript. Briefly, here's a list of how you should format your
documentation.

#### Visibility

Every class and method should start with one of three phrases: `Public:`,
`Internal:`, and `Private:`. During the documentation generation process, you
can flag whether or not to include Internal and Private members via the options
passed in. If you don't have one of these status indicators, Biscotto will assume the
global visibility (more on this below).

```coffeescript
# Public: This is a test class with `inline.dot`. Beware.
class TestClassDocumentation
```

#### Method arguments

Each method argument must start with the argument name, followed by a dash (`-`), and
the description of the argument:

```
argument - Some words about the arg!
```

Hash options are placed on a newline and begin with a colon:

```
options - These are the options:
          :key1 - Blah blah.
          :key2 - Blah
```

```coffeescript
# Public: Does some stuff.
#
# something - Blah blah blah. Fah fah fah? Foo foo foo!
# something2 - Bar bar bar. Cha cha cha!!
# opts - The options
#        :speed - The {String} speed
#        :repeat -  How many {Number} times to repeat
#        :tasks - The {Tasks} tasks to do
bound: (something, something2, opts) =>
```

#### Examples

The examples section must start with the word "Examples" on a line by itself. The
next line should be blank. Every line thereafter should be indented by two spaces
from the initial comment marker:

``` coffeescript
# A method to run.
#
# Examples
#
#  biscotto = require 'biscotto'
#  file = (filename, content) ->
#    console.log "New file %s with content %s", filename, content
#  done = (err) ->
#    if err
#      console.log "Cannot generate documentation:", err
#    else
#      console.log "Documentation generated"
#  biscotto.run file, done
run: ->
```

#### Return types

When returning from a method, your line must start with the word `Returns`.
You can list more than one `Returns` per method by separating each type on a different line.

```coffeescript
# Private: Do it!
#
# Returns {Boolean} when it works.
returnSingleType: ->

# Internal: Does some thing.
#
# Returns an object with the keys:
#   :duration - A {Number} of milliseconds.
returnAHash: =>
```

### Deviation from TomDoc

#### GitHub Flavored Markdown

Biscotto documentation is processed with [GitHub Flavored Markdown](https://help.github.com/articles/github-flavored-markdown).

#### Automatic link references

Biscotto comments are parsed for references to other classes, methods, and mixins, and are automatically
linked together.

There are several different link types supported:

* Normal URL links: `{http://coffeescript.org/}` or `[Try CoffeeScript](http://coffeescript.org/)`
* Link to a class or a mixin: `{Animal::Lion}` or `[The mighty lion]{Animal::Lion}`
* Direct link to an instance method: `{Animal.Lion::walk}` or `[The lion walks]{Animal.Lion::walk}`
* Direct link to a class method: `{Animal.Lion.constructor}` or `[A new king was born]{Animal.Lion.constructor}`

If you are referring to a method within the same class, you can omit the class name: `{::walk}` or `{.constructor}`.

As an added bonus, default JavaScript "types," like String, Number, Boolean, *e.t.c.*,
have automatic links generated to [MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript).

Here's an example of using links:

```coffeescript
# This links out to the `long` method of the same class.
#
# See {::internalLinkLong} for more info.
#
internalLinkShort: ->

# This links out to MDN.
#
# Returns a {Number} greater than zero.
internalLinkLong: ->
```

Note: reference resolution does not take place within code blocks.

#### Status Blocks

As noted above, classes and methods can be `Public,` `Private`, or `Internal`.

You can flag multiple methods in a file with the following syntax:

```coffee
### Public ###
```

That will mark every method underneath that block as `Public`. You can follow the
same notion for `Internal` and `Private` as well.

You can have as many block status flags as you want. The amount of `#`s must be at
least three, and you can have any text inside the block you want. For example:

```coffee
### Internal: This does some secret stuff. ###
```

If you explicitly specify a status for a method within a block, the status is respected.
For example:


```coffee
### Public ###

# Internal: A secret method
notShown: ->

shown: ->
```

`shown` is kept as Public because of the status block, while `notShown` is indeed Internal.

#### Delegation

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

Classes that are delegated should still set their own statuses. For example, even though
`Another.Class@somewhere` is Public, `delegatedMethod` is still marked as `Private`.
The same documentation remains.

#### Defaults

Unlike TomDoc, there is no notation for `default` values. Biscotto will take care of it for you.

## More Examples

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

### Gulp-Biscotto

If you want use Biscotto with [Gulp](https://gulpjs.com), see [gulp-biscotto](https://github.com/adam-lynch/gulp-biscotto).

## Keyboard navigation

You can quickly search and jump through the documentation by using the fuzzy finder dialog:

* Open fuzzy finder dialog: `Ctrl-T`

In frame mode you can toggle the list navigation frame on the left side:

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
