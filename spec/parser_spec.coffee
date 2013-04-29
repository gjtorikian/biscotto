fs      = require 'fs'
walkdir = require 'walkdir'
Parser  = require '../src/parser'
diff    = require 'diff'
_       = require 'underscore'
_.str   = require 'underscore.string'

Generator = require '../src/generator'

beforeEach ->
  @addMatchers
    toBeCompiledTo: (expected) ->
      @message = -> @actual.report
      @actual.generated is expected

for filename in walkdir.sync './spec/templates'
  if filename.match /\.coffee$/
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

          if /method_delegation/.test filename
            generator = new Generator(parser, 
                                      statsOnly: true
                                      extras: []
                                      quiet: true
                                    )
            # for clazz in @parser.classes
            #   methods = clazz.getMethods()

            #   # resolve all delegations in methods
            #   for method in methods by 1
            #     delegation = method.doc.delegation
            #     if delegation
            #       originalStatus = method.doc.status
            #       [method.doc, method.parameters] = @referencer.resolveDelegation(method, delegation, clazz)
            #       method.doc.status = originalStatus

            # generator.generateClasses()

          else
            delta = diff.diffLines expected, generated
            expect(delta.length).toEqual(1)
            if (delta.length > 1)
              console.log "\nFor #{filename}:"
              for diff in delta
                if diff.added
                  console.log "Added: \n#{_.str.strip(diff.value)}"
                if diff.removed
                  console.log "Removed: \n#{_.str.strip(diff.value)}"
