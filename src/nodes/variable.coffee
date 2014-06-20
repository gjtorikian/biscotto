Node      = require './node'
Doc      = require './doc'

# Public: The Node representation of a CoffeeScript variable.
module.exports = class Variable extends Node

  # Public: Construct a variable node.
  #
  # entity - The variable's {Class}
  # node - The variable node (a {Object})
  # lineMapping - An object mapping the actual position of a member to its Biscotto one
  # options - The parser options (a {Object})
  # classType - A {Boolean} indicating if the class is a `class` or an `instance`
  # comment - The comment node (a {Object})
  constructor: (@entity, @node, @lineMapping, @options, @classType = false, comment = null) ->
    try
      @doc = new Doc(comment, @options)
      @getName()

    catch error
      console.warn('Create variable error:', @node, error) if @options.verbose

  # Public: Get the variable type, either `class` or `constant`
  #
  # Returns the variable type (a {String}).
  getType: ->
    unless @type
      @type = if @classType then 'class' else 'instance'

    @type

  # Public: Test if the given value should be treated ad constant.
  #
  # Returns true if a constant (a {Boolean})
  #
  isConstant: ->
    unless @constant
      @constant = /^[A-Z_-]*$/.test @getName()

    @constant

  # Public: Get the class doc
  #
  # Returns the class doc (a [Doc]).
  getDoc: -> @doc

  # Public: Get the variable name
  #
  # Returns the variable name (a {String}).
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


  # Public: Get the source line number
  #
  # Returns a {Number}.
  getLocation: ->
    try
      unless @location
        {locationData} = @node.variable
        firstLine = locationData.first_line + 1
        if !@lineMapping[firstLine]?
          @lineMapping[firstLine] = @lineMapping[firstLine - 1]

        @location = { line: @lineMapping[firstLine] }

      @location

    catch error
      console.warn("Get location error at #{@fileName}:", @node, error) if @options.verbose

  # Public: Get the variable value.
  #
  # Returns the value (a {String}).
  getValue: ->
    try
      unless @value
        @value = @node.value.base.compile({ indent: '' })

      @value

    catch error
      console.warn('Get method value error:', @node, error) if @options.verbose

  # Public: Get a JSON representation of the object
  #
  # Returns the JSON object (a {Object}).
  toJSON: ->
    json =
      doc: @doc
      type: @getType()
      constant: @isConstant()
      name: @getName()
      value: @getValue()
      location: @getLocation()

    json
