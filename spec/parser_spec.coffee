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
            private: !(/as_private/.test filename)
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
          if /delegation/.test filename
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

          delta = diff.diffLines expected, generated
          expect(delta.length).toEqual(1)
          if (delta.length > 1)
            console.log "\nFor #{filename}:"
            for diff in delta
              if diff.added
                console.log "Added: \n#{_.str.strip(diff.value)}"
              if diff.removed
                console.log "Removed: \n#{_.str.strip(diff.value)}"
