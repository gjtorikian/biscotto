fs      = require 'fs'
{inspect} = require 'util'
walkdir = require 'walkdir'
Parser  = require '../src/parser'
Referencer = require '../src/util/referencer'
Generator = require '../src/generator'

{diff}    = require 'jsondiffpatch'
_         = require 'underscore'
_.str     = require 'underscore.string'
require('jasmine-focused')

describe "Parser", ->
  parser = null

  constructDelta = (filename, hasReferences = false) ->
    source = fs.readFileSync filename, 'utf8'

    parser.parseContent source, filename

    expected = JSON.stringify(JSON.parse(fs.readFileSync filename.replace(/\.coffee$/, '.json'), 'utf8'), null, 2)
    generated =  JSON.stringify(parser.toMetadata(), null, 2)

    diff(expected, generated)
    checkDelta(expected, generated, diff(expected, generated))

  checkDelta = (expected, generated, delta) ->
    if delta?
      console.error expected, generated
      console.error(delta)
      expect(delta).toBe(undefined)

  beforeEach ->
    parser = new Parser({
      inputs: []
      output: ''
      extras: []
      readme: ''
      title: ''
      quiet: false
      private: true
      verbose: true
      github: ''
    })

  describe "Classes", ->
    it 'understands descriptions', ->
      constructDelta("spec/visitor_templates/classes/basic_class.coffee")

    fit 'understands class properties', ->
      constructDelta("spec/visitor_templates/classes/class_with_class_properties.coffee")
