Node      = require './node'
Markdown  = require '../util/markdown'

marked = require 'marked'
_      = require 'underscore'
_.str  = require 'underscore.string'

# A documentation node is responsible for parsing
# the comments for known tags.
#
module.exports = class Doc extends Node

  # Construct a documentation
  #
  # @param [Object] node the comment node
  # @param [Object] options the parser options
  #
  constructor: (@node, @options) ->
    try
      if @node
        @parseBlock @leftTrimBlock(@node.comment.replace(/\u0091/gm, '').split('\n'))     

    catch error
      console.warn('Create doc error:', @node, error) if @options.verbose

  # Determines if the current doc has some comments
  #
  # @return [Boolean] the comment status
  #
  hasComment: ->
    @node && @node.comment

  # Detect whitespace on the left and removes
  # the minimum whitespace ammount.
  #
  # @example left trim all lines
  #   leftTrimBlock(['', '  Escape at maximum speed.', '', '  @param (see #move)', '  '])
  #   => ['', 'Escape at maximum speed.', '', '@param (see #move)', '']
  #
  # This will keep indention for examples intact.
  #
  # @param [Array<String>] lines the comment lines
  # @return [Array<String>] lines left trimmed lines
  #
  leftTrimBlock: (lines) ->
    # Detect minimal left trim amount
    trimMap = _.map lines, (line) ->
      if line.length is 0
        undefined
      else
        line.length - _.str.ltrim(line).length

    minimalTrim = _.min _.without(trimMap, undefined)

    # If we have a common amount of left trim
    if minimalTrim > 0 and minimalTrim < Infinity

      # Trim same amount of left space on each line
      lines = for line in lines
        line = line.substring(minimalTrim, line.length)
        line

    lines

  # Parse the given lines as TomDoc and adds the result
  # to the result object.
  #
  parseBlock: (lines) ->
    comment = []

    return unless lines isnt undefined
    
    sections       = lines.join("\n").split "\n\n"

    info_block     = @parse_description(sections.shift())

    text     = info_block.description
    @status   = info_block.status

    current = sections.shift()

    while current
      if /^\w+\s+\-/.test(current)
        @params or= []
        @params = @parse_arguments(current)

      else if /^\s*Examples/.test(current)
        @examples or= []

        @examples = @parse_examples(current, sections)
      else if /^\s*Returns/.test(current)
        @returnValue or= []

        @returnValue.push
          type: ''
          desc: @parse_returns(current)
      else
        text = text.concat "\n#{current}"

      current = sections.shift()

    @comment = Markdown.convert(text)
    sentence = /((?:.|\n)*?[.#][\s$])/.exec(text)
    sentence = sentence[1].replace(/\s*#\s*$/, '') if sentence
    @summary = Markdown.convert(_.str.clean(sentence || text), true)

  # Parse description.
  #
  # section - String containing description.
  #
  # Returns nothing.
  parse_description: (section) ->
    if md = /([A-Z]\w+)\:\s+(.+)/.exec(section)
      return {
        status:      md[1]
        description: _.str.strip(md[2])
      }
    else
      return { description: _.str.strip(section) }

  # Parse examples.
  #
  # section  - String starting with `Examples`.
  # sections - All sections subsequent to section.
  #
  # Returns nothing.
  parse_examples: (section, sections) ->
    examples = []

    section = _.str.strip(section.replace(/Examples/, ''))

    examples.push(section) unless _.isEmpty(section)
    while _.first(sections) && !/^\S/.test(_.first(sections))
      lines = sections.shift().split("\n")
      examples.push(@deindent(lines).join("\n"))

    examples

  # Parse returns section.
  #
  # section - String contaning Returns and/or Raises lines.
  #
  # Returns nothing.
  parse_returns: (section) ->
    returns = []
    current = []

    lines = section.split("\n")  
    _.each lines, (line) ->
      if /^Returns/.test(line)
        returns.push(Markdown.convert(line))
        current = returns
      else if /^\s+/.test(line)
        _.last(current).concat _.str.clean(line)
      else
        current.concat line  # TODO: What to do with non-compliant line?

    returns

  # Parse arguments section. Arguments occur subsequent to
  # the description.
  #
  # section - String contaning agument definitions.
  #
  # Returns nothing.
  parse_arguments: (section) ->
    args = []
    last_indent = null

    _.each section.split("\n"), (line) ->
      unless _.isEmpty(_.str.strip(line))
        indent = line.match(/^(\s*)/)[0].length

        if last_indent && indent > last_indent
          _.last(args).description += _.str.clean(line)
        else
          arg = line.split(" - ")
          param = _.str.strip(arg[0])
          desc = Markdown.convert(_.str.strip(arg[1]))

          # it's a hash description
          if param[0] == ":"
            _.last(args).keys ||= []
            _.last(args).keys.push( {name: param[1 .. param.length], desc: desc} )
          else
            args.push( {name: param, desc: desc} )
        last_indent = indent

    args

  deindent: (lines) ->
    # remove indention
    spaces = _.map lines, (line) ->
      return line if _.isEmpty(_.str.strip(line))
      md = line.match(/^(\s*)/)
      if md then md[1].length else null
    
    spaces = _.compact(spaces)

    space = _.min(spaces) || 0

    _.map lines, (line) ->
      if _.isEmpty(line)
        _.str.strip(line)
      else
        line[space..-1]

  # Get a JSON representation of the object
  #
  # @return [Object] the JSON object
  #
  toJSON: ->
    if @node
      json =
        includes: @includeMixins
        extends: @extendMixins
        concerns: @concerns
        abstract: @abstract
        private: @private
        deprecated: @deprecated
        version: @version
        since: @since
        examples: @examples
        todos: @todos
        notes: @notes
        authors: @authors
        copyright: @copyright
        comment: @comment
        summary: @summary
        status: @status
        params: @params
        options: @paramsOptions
        see: @see
        returnValue: @returnValue
        throwValue: @throwValue
        overloads: @overloads
        methods: @methods
        property: @property

      json
