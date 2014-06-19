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
    generated = if hasReferences then followReferences(parser) else JSON.stringify(parser.toJSON(), null, 2)

    diff(expected, generated)

  followReferences = (parser) ->
    # since delegation happens in the generator, we need to force that magic here
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

  checkDelta = (delta) ->
    if delta?
      console.error(inspect(delta))
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
      github: ''
    })

  describe "Classes", ->
    it 'understands descriptions', ->
      delta = constructDelta("spec/templates/classes/class_description_markdown.coffee")
      checkDelta(delta)

    it 'understands documentation', ->
      delta = constructDelta("spec/templates/classes/class_documentation.coffee")
      checkDelta(delta)

    it 'understands extends', ->
      delta = constructDelta("spec/templates/classes/class_extends.coffee")
      checkDelta(delta)

    it 'understands empty classes', ->
      delta = constructDelta("spec/templates/classes/empty_class.coffee")
      checkDelta(delta)

    it 'understands exporting classess', ->
      delta = constructDelta("spec/templates/classes/export_class.coffee")
      checkDelta(delta)

    it 'understands inner classes', ->
      delta = constructDelta("spec/templates/classes/inner_class.coffee")
      checkDelta(delta)

    it 'understands namespaced classes', ->
      delta = constructDelta("spec/templates/classes/namespaced_class.coffee")
      checkDelta(delta)

    it 'understands simple classes', ->
      delta = constructDelta("spec/templates/classes/simple_class.coffee")
      checkDelta(delta)

  describe "non class files", ->
    it 'understands descriptions', ->
      delta = constructDelta("spec/templates/files/non_class_file.coffee")
      checkDelta(delta)

  describe "Methods", ->
    it 'understands assigned parameters classes', ->
      delta = constructDelta("spec/templates/methods/assigned_parameters.coffee")
      checkDelta(delta)

    it 'understands class methods', ->
      delta = constructDelta("spec/templates/methods/class_methods.coffee")
      checkDelta(delta)

    it 'understands curly notation', ->
      delta = constructDelta("spec/templates/methods/curly_method_documentation.coffee")
      checkDelta(delta)

    it 'understands private classes', ->
      delta = constructDelta("spec/templates/methods/fixtures/private_class.coffee")
      checkDelta(delta)

    it 'understands hash parameters', ->
      delta = constructDelta("spec/templates/methods/hash_parameters.coffee")
      checkDelta(delta)

    it 'understands instance methods', ->
      delta = constructDelta("spec/templates/methods/instance_methods.coffee")
      checkDelta(delta)

    it 'understands links in methods', ->
      delta = constructDelta("spec/templates/methods/links.coffee")
      checkDelta(delta)

    it 'understands method delegation', ->
      delta = constructDelta("spec/templates/methods/method_delegation.coffee", true)
      checkDelta(delta)

    it 'understands method delegation from public to private', ->
      delta = constructDelta("spec/templates/methods/method_delegation_as_private.coffee", true)
      checkDelta(delta)

    it 'understands basic methods', ->
      delta = constructDelta("spec/templates/methods/method_example.coffee")
      checkDelta(delta)

    it 'understands methods with paragraph descriptions for parameters', ->
      delta = constructDelta("spec/templates/methods/method_paragraph_param.coffee")
      checkDelta(delta)

    it 'understands methods with no descriptions', ->
      delta = constructDelta("spec/templates/methods/method_shortdesc.coffee")
      checkDelta(delta)

    it 'understands optional arguments', ->
      delta = constructDelta("spec/templates/methods/optional_arguments.coffee")
      checkDelta(delta)

    it 'understands paragraph length descriptions', ->
      delta = constructDelta("spec/templates/methods/paragraph_desc.coffee")
      checkDelta(delta)

    it 'understands preprocessor flagging for visibility', ->
      delta = constructDelta("spec/templates/methods/preprocessor_flagging.coffee")
      checkDelta(delta)

    it 'understands return values', ->
      delta = constructDelta("spec/templates/methods/return_values.coffee")
      checkDelta(delta)

    it 'understands paragraph length return values', ->
      delta = constructDelta("spec/templates/methods/return_values_long.coffee")
      checkDelta(delta)
