fs      = require 'fs'
walkdir = require 'walkdir'
Parser  = require '../src/parser'
Referencer = require '../src/util/referencer'
Generator = require '../src/generator'

diff    = require 'diff'
_       = require 'underscore'
_.str   = require 'underscore.string'

beforeEach ->
  @addMatchers
    toBeCompiledTo: (expected) ->
      @message = -> @actual.report
      @actual.generated is expected

for filename in walkdir.sync './spec/templates'
  isFixture = /fixtures/.test(filename)

  if filename.match(/\.coffee$/) && !isFixture
    source = fs.readFileSync filename, 'utf8'
    expected = JSON.stringify(JSON.parse(fs.readFileSync filename.replace(/\.coffee$/, '.json'), 'utf8'), null, 2)

    do (source, expected, filename) ->
      describe "The CoffeeScript file #{ filename }", ->
        it 'parses correctly to JSON', ->

          parser = new Parser({
            inputs: []
            output: ''
            extras: []
            readme: ''
            title: ''
            quiet: false
            private: true
            github: ''
          })

          filename = filename.substring process.cwd().length + 1

          tokens = parser.parseContent source, filename
          generated = JSON.stringify(parser.toJSON(), null, 2)

          # each file is parsed one at a time; delegations need multiple files parsed
          if /delegation/.test filename
            parser.parseFile "./spec/templates/methods/method_example.coffee"
            parser.parseFile "./spec/templates/methods/curly_method_documentation.coffee"
            parser.parseFile "./spec/templates/methods/fixtures/private_class.coffee"

            # since delegation happens in the generator, we need to force that
            # magic here
            generator = new Generator(parser,
                                      noOutput: true
                                      stats: true
                                      extras: []
                                      quiet: false
                                    )
            referencer = new Referencer(parser.classes, parser.mixins, {quiet: false})
            for clazz in parser.classes
              methods = clazz.getMethods()

              # resolve all delegations in methods
              for method in methods by 1
                delegation = method.doc.delegation
                if delegation
                  originalStatus = method.doc.status
                  [method.doc, method.parameters] = referencer.resolveDelegation(method, delegation, clazz)
                  method.doc.status = originalStatus

            # [0], because we don't want the parsed files in the resulting JSON
            generated = JSON.stringify([parser.toJSON()[0]], null, 2)

          delta = diff.diffLines(expected, generated)
          if (delta.length > 1)
            console.error "\nFor #{filename}:"
            for hunk in delta
              if hunk.added
                console.error "Added: \n#{_.str.strip(diff.value)}"
              if hunk.removed
                console.error "Removed: \n#{_.str.strip(diff.value)}"
            console.error delta
            # TODO: we basically want to flag this test as false, but print out the debug info above
            expect(true).toBe(false)
