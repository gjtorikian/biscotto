Node      = require './node'
Markdown  = require '../util/markdown'
Referencer  = require '../util/referencer'

marked = require 'marked'
_      = require 'underscore'
_.str  = require 'underscore.string'

# A documentation node is responsible for parsing
# the comments for known tags.
#
module.exports = class Doc extends Node

  # Construct a documentation
  #
  # node - the comment node (a [Object])
  # options - the parser options (a [Object])
  #
  constructor: (@node, @options) ->
    try
      if @node
        @parseBlock @leftTrimBlock(@node.comment.replace(/\u0091/gm, '').split('\n'))

    catch error
      console.warn('Create doc error:', @node, error) if @options.verbose

  # Determines if the current doc has some comments
  #
  # Returns the comment status (a [Boolean])
  #
  hasComment: ->
    !_.str.isBlank(@comment)

  # Detect whitespace on the left and removes
  # the minimum whitespace ammount.
  #
  # lines - The comment lines [[String]]
  #
  # Examples
  #
  #   leftTrimBlock(['', '  Escape at maximum speed.', '', '  @param (see #move)', '  '])
  #   => ['', 'Escape at maximum speed.', '', '@param (see #move)', '']
  #
  # This will keep indention for examples intact.
  #
  # Returns the left trimmed lines as an array of Strings
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

    delegationMatch =  text.match(/\{Delegates to: (.+?)\}/)
    if delegationMatch && @delegation = delegationMatch[1]
      return

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

        @returnValue = @parse_returns(current)
      else
        text = text.concat "\n\n#{current}"

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
    if md = /([A-Z]\w+)\:(.*)/.exec(section)
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
    while _.first(sections)
      lines = sections.shift().split("\n")
      examples.push(@deindent(lines).join("\n"))

    examples

  # Parse returns section.
  #
  # section - String containing Returns lines.
  #
  # Returns nothing.
  parse_returns: (section) ->
    returns = []
    current = []

    lines = section.split("\n")
    _.each lines, (line) ->
      line = _.str.trim(line)

      if /^Returns/.test(line)
        returns.push(
          type: Referencer.getLinkMatch(line)
          desc: Markdown.convert(line).replace /<\/?p>/g, ""
        )
        current = returns
      else if /^\S+/.test(line)
        _.last(returns).desc = _.last(returns).desc.concat "\n" + _.str.strip(line)

    returns

  # Parse arguments section. Arguments occur subsequent to
  # the description.
  #
  # section - String containing agument definitions.
  #
  # Returns nothing.
  parse_arguments: (section) ->
    args = []
    last_indent = null

    _.each section.split("\n"), (line) ->
      unless _.isEmpty(line)
        indent = line.match(/^(\s*)/)[0].length

        stripped_line = _.str.strip(line)

        if last_indent != null && indent >= last_indent && (indent != 0) && stripped_line.match(/^\w+:/) == null
          _.last(args).desc += " " + Markdown.convert(stripped_line).replace /<\/?p>/g, ""
        else
          arg = line.split(" - ")
          param = _.str.strip(arg[0])
          desc = Markdown.convert(_.str.strip(arg[1])).replace /<\/?p>/g, ""

          param_match = param.match(/^\w+:/)
          # it's a hash description
          if param_match && _.str.endsWith(param_match[0], ":")
            _.last(args).options ||= []
            key = param.split(":")
            keyDesc = _.str.strip(key[1])
            _.last(args).options.push( {name: key[0], desc: Markdown.convert(keyDesc).replace(/<\/?p>/g, ""), type: Referencer.getLinkMatch(line)} )
          else
            args.push( {name: param, desc: desc, type: Referencer.getLinkMatch(line)} )

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
  # Returns the JSON object (a [Object])
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
        delegation: @delegation
        see: @see
        returnValue: @returnValue
        throwValue: @throwValue
        overloads: @overloads
        methods: @methods
        property: @property

      json
