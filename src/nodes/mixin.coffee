Node     = require './node'
Method   = require './method'
Variable = require './variable'
Doc      = require './doc'

# Public: The Node representation of a CoffeeScript mixins
#
module.exports = class Mixin extends Node

  # Public: Construct a mixin
  #
  # node - The mixin node (a {Object})
  # fileName - The filename (a {String})
  # options - The parser options (a {Object})
  # comment - The comment node (a {Object})
  constructor: (@node, @fileName, @options, comment) ->
    try
      @methods = []
      @variables = []

      @doc = new Doc(comment, @options)

      previousExp = null

      for exp in @node.value.base.properties

        # Recognize assigned code on the mixin
        if exp.constructor.name is 'Assign'
          doc = previousExp if previousExp?.constructor.name is 'Comment'

          if exp.value?.constructor.name is 'Code'
            @methods.push new Method(@, exp, @options, doc)

          # Recognize concerns as inner mixins
          if exp.value?.constructor.name is 'Value'
            switch exp.variable.base.value
              when 'ClassMethods'
                @classMixin = new Mixin(exp, @filename, @options, doc)

              when 'InstanceMethods'
                @instanceMixin = new Mixin(exp, @filename, options, doc)

        doc = null
        previousExp = exp

      if @classMixin? && @instanceMixin?
        @concern = true

        for method in @classMixin.getMethods()
          method.type = 'class'
          @methods.push method

        for method in @instanceMixin.getMethods()
          method.type = 'instance'
          @methods.push method
      else
        @concern = false

    catch error
      console.warn('Create mixin error:', @node, error) if @options.verbose

  # Public: Get the source file name.
  #
  # Returns the filename of the mixin (a {String}).
  getFileName: -> @fileName

  # Public: Get the mixin doc
  #
  # Returns the mixin doc (a [Doc])
  getDoc: -> @doc

  # Public: Get the full mixin name
  #
  # Returns full mixin name (a {String}).
  getMixinName: ->
    try
      unless @mixinName
        name = []
        name = [@node.variable.base.value] unless @node.variable.base.value == 'this'
        name.push p.name.value for p in @node.variable.properties
        @mixinName = name.join('.')

      @mixinName

    catch error
      console.warn('Get mixin full name error:', @node, error) if @options.verbose

  # Public: Alias for {.getMixinName}
  getFullName: ->
    @getMixinName()

  # Public: Gets the mixin name
  #
  # Returns the name (a {String}).
  getName: ->
    try
      unless @name
        @name = @getMixinName().split('.').pop()

      @name

    catch error
      console.warn('Get mixin name error:', @node, error) if @options.verbose

  # Public: Get the mixin namespace
  #
  # Returns the namespace (a {String}).
  getNamespace: ->
    try
      unless @namespace
        @namespace = @getMixinName().split('.')
        @namespace.pop()

        @namespace = @namespace.join('.')

      @namespace

    catch error
      console.warn('Get mixin namespace error:', @node, error) if @options.verbose

  # Public: Get all methods.
  #
  # Returns an {Array} of all the {Method}s.
  getMethods: -> @methods

  # Get all variables.
  #
  # Returns an {Array} of all the {Variable}s.
  getVariables: -> @variables

  # Public: Get a JSON representation of the object
  #
  # Returns the JSON object (a {Object}).
  toJSON: ->
    json =
      file: @getFileName()
      doc: @getDoc().toJSON()
      mixin:
        mixinName: @getMixinName()
        name: @getName()
        namespace: @getNamespace()
        concern: @concern
      methods: []
      variables: []

    for method in @getMethods()
      json.methods.push method.toJSON()

    for variable in @getVariables()
      json.variables.push variable.toJSON()

    json
