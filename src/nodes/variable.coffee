Node      = require './node'
Doc      = require './doc'

# A CoffeeScript variable
#
module.exports = class Variable extends Node

  # Construct a variable
  #
  # entity - the variables class (a [Class])
  # node - the node (a [Object])
  # options - the parser options (a [Object])
  # classType - whether its a class variable or not (a [Boolean])
  # comment - the comment node (a [Object])
  #
  constructor: (@entity, @node, @options, @classType = false, comment = null) ->
    try
      @doc = new Doc(comment, @options)
      @getName()

    catch error
      console.warn('Create variable error:', @node, error) if @options.verbose

  # Get the variable type, either `class` or `constant`
  #
  # Returns the variable type (a [String])
  #
  getType: ->
    unless @type
      @type = if @classType then 'class' else 'instance'

    @type

  # Test if the given value should be treated ad constant.
  #
  # Returns true if a constant (a [Boolean])
  #
  isConstant: ->
    unless @constant
      @constant = /^[A-Z_-]*$/.test @getName()

    @constant

  # Get the class doc
  #
  # Returns the class doc (a [Doc])
  #
  getDoc: -> @doc

  # Get the variable name
  #
  # Returns the variable name (a [String])
  #
  getName: ->
    try
      unless @name
        @name = @node.variable.base.value

        for prop in @node.variable.properties
          @name += ".#{ prop.name.value }"

        if /^this\./.test @name
          @name = @name.substring(5)
          @type = 'class'

      @name

    catch error
      console.warn('Get method name error:', @node, error) if @options.verbose

  # Get the variable value.
  #
  # Returns the value (a [String])
  #
  getValue: ->
    try
      unless @value
        @value = @node.value.base.compile({ indent: '' })

      @value

    catch error
      console.warn('Get method value error:', @node, error) if @options.verbose

  # Get a JSON representation of the object
  #
  # Returns the JSON object (a [Object])
  #
  toJSON: ->
    json =
      doc: @doc
      type: @getType()
      constant: @isConstant()
      name: @getName()
      value: @getValue()

    json
