Node      = require './node'
Doc       = require './doc'

_         = require 'underscore'
_.str     = require 'underscore.string'

# Public: A class property that is defined by custom property set/get methods.
#
# Examples
#
#   class Test
#
#    get = (props) => @::__defineGetter__ name, getter for name, getter of props
#    set = (props) => @::__defineSetter__ name, setter for name, setter of props
#
#    get name: -> @name
#    set name: (@name) ->
#
module.exports = class Property extends Node

  # Public: Construct a new property node.
  #
  # entity - The property's {Class}
  # node - The property node (a {Object})
  # lineMapping - An object mapping the actual position of a member to its Biscotto one
  # options - The parser options (a {Object})
  # name - The filename (a {String})
  # comment - The comment node (a {Object})
  constructor: (@entity, @node, @lineMapping, @options, @name, comment) ->
    @doc = new Doc(comment, @options)

    @setter  = false
    @getter  = false

  # Public: Get the source line number
  #
  # Returns a {Number}.
  getLocation: ->
    try
      unless @location
        {locationData} = @node.variable
        firstLine = locationData.first_line
        @location = { line: firstLine - @lineMapping[firstLine] + 1 }

      @location

    catch error
      console.warn("Get location error at #{@fileName}:", @node, error) if @options.verbose

  # Public: Get the property signature.
  #
  # Returns the signature (a {String})
  getSignature: ->
    try
      unless @signature
        @signature = ''

        if @doc
          @signature += if @doc.property then "(#{ _.str.escapeHTML @doc.property }) " else "(?) "

        @signature += "<strong>#{ @name }</strong>"

      @signature

    catch error
      console.warn('Get property signature error:', @node, error) if @options.verbose

  # Public: Get a JSON representation of the object
  #
  # Returns the JSON object (a {Object})
  toJSON: ->
    {
      name: @name
      signature: @getSignature()
      location: @getLocation()
      setter: @setter
      getter: @getter
      doc: @doc
    }
