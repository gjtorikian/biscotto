fs      = require 'fs'
walkdir = require 'walkdir'
Parser  = require '../src/parser'
diff    = require 'diff'
_       = require 'underscore'
_.str   = require 'underscore.string'

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

          report = "\n-------------------- CoffeeScript ----------------------\n"
          report += source
          report += "\n------------- Preprocessed CoffeeScript-----------------\n"
          report += parser.convertComments(source)
          report += "\n----------------------- Nodes --------------------------"
          report += tokens.toString()
          report += "\n-------------------- Expected JSON ------------------------\n"
          report += expected
          report += "\n------------------- Generated JSON ---------------------\n"
          report += generated
          report += "\n-------------------------------------------------------\n"

          delta = diff.diffLines expected, generated
          expect(delta.length).toEqual(1)
          if (delta.length > 1)
            console.log "\nFor #{filename}:"
            for diff in delta
              if diff.added
                console.log "Added: \n#{_.str.strip(diff.value)}"
              if diff.removed
                console.log "Removed: \n#{_.str.strip(diff.value)}"


          #console.log expected
          #console.log generated
          # expect({
          #   generated: generated
          #   report: report.split('\n').join('\n    ')
          # }).toBeCompiledTo(expected)
