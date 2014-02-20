Node      = require './node'
Parameter = require './parameter'
Doc       = require './doc'

_         = require 'underscore'
_.str     = require 'underscore.string'

# Public: The Node representation of a CoffeeScript method.
module.exports = class Method extends Node

  # Public: Constructs the documentaion node.
  #
  # entity - The method's {Class}
  # node - The method node (a {Object})
  # fileName - The filename (a {String})
  # lineMapping - An object mapping the actual position of a member to its Biscotto one
  # options - The parser options (a {Object})
  # comment - The comment node (a {Object})
  constructor: (@entity, @node, @lineMapping, @options, comment) ->
    try
      @parameters = []

      @doc = new Doc(comment, @options)

      for param in @node.value.params
        if param.name.properties? and param.name.properties[0].base?
          for property in param.name.properties
            @parameters.push new Parameter(param, @options, true)
        else
          @parameters.push new Parameter(param, @options)

      @getName()

    catch error
      console.warn('Create method error:', @node, error) if @options.verbose

  # Get the method type, either `class` or `instance`
  #
  # @return {String} the method type
  #
  getType: ->
    unless @type
      switch @entity.constructor.name
        when 'Class'
          @type = 'instance'
        when 'Mixin'
          @type = 'mixin'
        when 'File'
          @type = 'file'

    @type

  # Get the class doc
  #
  # @return [Doc] the class doc
  #
  getDoc: -> @doc

  # Get the full method signature.
  #
  # @return {String} the signature
  #
  getSignature: ->
    try
      unless @signature
        @signature = switch @getType()
                     when 'class'
                       '.'
                     when 'instance'
                       '::'
                     else
                       '? '
        doc = @getDoc()

        # this adds a superfluous space if there's no type defined
        if doc.returnValue && doc.returnValue[0].type
          retVals = []
          for retVal in doc.returnValue
            retVals.push "#{ _.str.escapeHTML retVal.type }"
          @signature = retVals.join("|") + " #{@signature}"

        @signature += "<strong>#{ @getName() }</strong>"
        @signature += '('

        params = []
        paramOptionized = []

        for param, i in @getParameters()
          if param.optionized
            @inParamOption = true
            optionizedDefaults = param.getOptionizedDefaults()
            paramOptionized.push param.getName(i)
          else
            if @inParamOption
              @inParamOption = false
              paramValue = "{#{paramOptionized.join(', ')}}"
              paramValue += "=#{optionizedDefaults}" if optionizedDefaults
              params.push(paramValue)
              paramOptionized = []
            else
              params.push param.getSignature()

        # that means there was only one argument, a param'ed one
        if paramOptionized.length > 0
          paramValue = "{#{paramOptionized.join(', ')}}"
          paramValue += "=#{optionizedDefaults}" if optionizedDefaults
          params.push(paramValue)

        @signature += params.join(', ')
        @signature += ')'

      @signature

    catch error
      console.warn('Get method signature error:', @node, error) if @options.verbose

  # Get the short method signature.
  #
  # @return {String} the short signature
  #
  getShortSignature: ->
    try
      unless @shortSignature
        @shortSignature = switch @getType()
                          when 'class'
                            '@'
                          when 'instance'
                            '.'
                          else
                            ''
        @shortSignature += @getName()

      @shortSignature

    catch error
      console.warn('Get method short signature error:', @node, error) if @options.verbose

  # Get the method name
  #
  # @return {String} the method name
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

        if /^module.exports\./.test @name
          @name = @name.substring(15)
          @type = 'class'

        if /^exports\./.test @name
          @name = @name.substring(8)
          @type = 'class'

        # Reserved names will result in a name like { '0': 'd', '1': 'e', '2': 'l', '3': 'e', '4': 't', '5': 'e' }
        if _.isObject(@name) && @name.reserved is true
          name = @name
          delete name.reserved
          @name = ''
          @name += c for p, c of name

      @name

    catch error
      console.warn('Get method name error:', @node, error) if @options.verbose

  # Public: Get the source line number
  #
  # Returns a {Number}
  #
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

  # Get the method parameters
  #
  # @param [Array<Parameter>] the method parameters
  #
  getParameters: -> @parameters

  # Get a JSON representation of the object
  #
  # @return {Object} the JSON object
  #
  toJSON: ->
    json =
      doc: @getDoc().toJSON()
      type: @getType()
      signature: @getSignature()
      name: @getName()
      bound: @node.value.bound
      parameters: []
      location: @getLocation()

    for parameter, i in @getParameters()
      json.parameters.push(parameter.toJSON(i))

    json
