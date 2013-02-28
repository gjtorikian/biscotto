Node      = require './node'
Doc       = require './doc'

_         = require 'underscore'
_.str     = require 'underscore.string'

# A class property that is defined by custom property set/get methods.
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

  # Construct a new property
  #
  # entity - The methods class (a [Class])
  # node - The class node (a [Object])
  # options - The parser options (a [Object])
  # name - The name of the property (a [String])
  # comment - The comment node (a [Object])
  #
  constructor: (@entity, @node, @options, @name, comment) ->
    @doc = new Doc(comment, @options)

    @setter  = false
    @getter  = false

  # Get the property signature.
  #
  # Returns the signature (a [String])
  #
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

  # Get a JSON representation of the object
  #
  # Returns the JSON object (a [Object])
  #
  toJSON: ->
    {
      name: @name
      signature: @getSignature()
      setter: @setter
      getter: @getter
      doc: @doc
    }
