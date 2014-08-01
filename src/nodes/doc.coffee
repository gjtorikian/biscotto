Node      = require './node'
Markdown  = require '../util/markdown'
Referencer  = require '../util/referencer'

marked = require 'marked'
_      = require 'underscore'
_.str  = require 'underscore.string'

# Public: A documentation node is responsible for parsing
# the comments for known tags.
#
module.exports = class Doc extends Node

  # Public: Construct a documentation node.
  #
  # node - The comment node (a {Object})
  # options - The parser options (a {Object})
  constructor: (@node, @options) ->
    try
      if @node
        trimmedComment = @leftTrimBlock(@node.comment.replace(/\u0091/gm, '').split('\n'))
        @comment = trimmedComment.join("\n")
        @parseBlock trimmedComment

    catch error
      console.warn('Create doc error:', @node, error) if @options.verbose

  # Public: Determines if the current doc has some comments
  #
  # Returns the comment status (a {Boolean}).
  hasComment: ->
    !_.str.isBlank(@comment)

  # Public: Is this doc public?
  #
  # Returns a {Boolean}.
  isPublic: ->
    /public/i.test(@status)

  # Public: Is this doc internal?
  #
  # Returns a {Boolean}.
  isInternal: ->
    /internal/i.test(@status)

  # Public: Is this doc private?
  #
  # Returns a {Boolean}.
  isPrivate: ->
    not @isPublic() and not @isInternal()

  isDeprecated: ->
    /deprecated/i.test(@status)

  isAbstract: ->
    /abstract/i.test(@status)

  # Public: Detect whitespace on the left and removes
  # the minimum whitespace amount.
  #
  # lines - The comment lines [{String}]
  #
  # Examples
  #
  #   leftTrimBlock(['', '  Escape at maximum speed.', '', '  @param (see #move)', '  '])
  #   => ['', 'Escape at maximum speed.', '', '@param (see #move)', '']
  #
  # This will keep indention for examples intact.
  #
  # Returns the left trimmed lines as an {Array} of {String}s.
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

  # Public: Parse the given lines as TomDoc and adds the result
  # to the result object.
  parseBlock: (lines) ->
    comment = []

    return unless lines isnt undefined

    sections       = lines.join("\n").split "\n\n"

    info_block     = @parse_description(sections.shift())

    text     = info_block.description
    @status   = info_block.status
    @generated = info_block.generated

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

    sentence = /((?:.|\n)*?[.#][\s$])/.exec(text)
    sentence = sentence[1].replace(/\s*#\s*$/, '') if sentence
    @summary = Markdown.convert(_.str.clean(sentence || text), true)

  # Public: Parse the member description.
  #
  # section - The section {String} containing a description.
  #
  # Returns nothing.
  parse_description: (section) ->
    if md = /((?:[A-Z]\w+ ?)+)\:((.|[\r\n])*)/g.exec(section)
      return {
        status:      md[1]
        description: _.str.strip(md[2]).replace(/\r?\n/g, ' ')
      }
    else if md = /~((?:[A-Z]\w+ ?)+)\~((.|[\r\n])*)/g.exec(section)
      return {
        status:      md[1]
        description: _.str.strip(md[2]).replace(/\r?\n/g, ' ')
        generated: true
      }
    else
      return { description: _.str.strip(section).replace(/\r?\n/g, ' ') }

  # Public: Parse the member examples.
  #
  # section  - The section {String} starting with "Examples"
  # sections - All sections subsequent to `section`.
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

  # Public: Parse the member's return values.
  #
  # section - The section {String} starting with "Returns"
  #
  # Returns nothing.
  parse_returns: (section) ->
    returns = []
    current = []
    in_hash = false

    lines = section.split("\n")
    _.each lines, (line) ->
      line = _.str.trim(line)

      if /^Returns/.test(line)
        in_hash = false
        returns.push(
          type: Referencer.getLinkMatch(line)
          desc: Markdown.convert(line).replace /<\/?p>/g, ""
        )
        current = returns
      else if _.last(returns) and hash_match = line.match(/^:(\w+)\s*-\s*(.*)/)
        in_hash = true
        _.last(returns).options ?= []
        name = hash_match[1]
        desc = hash_match[2]
        _.last(returns).options.push({name, desc, type: Referencer.getLinkMatch(line)})
      else if /^\S+/.test(line)
        if in_hash
          _.last(_.last(returns).options).desc += " #{line}"
        else
          _.last(returns).desc += "\n#{line}"

    returns

  # Public: Parse the member's arguments. Arguments occur subsequent to
  # the description.
  #
  # section - A {String} containing the argument definitions.
  #
  # Returns nothing.
  parse_arguments: (section) ->
    args = []
    last_indent = null
    in_hash = false

    _.each section.split("\n"), (line) ->
      unless _.isEmpty(line)
        indent = line.match(/^(\s*)/)[0].length

        stripped_line = _.str.strip(line)

        if last_indent != null && indent >= last_indent && (indent != 0) && stripped_line.match(/^:\w+/) == null
          desc = " " + Markdown.convert(stripped_line).replace /<\/?p>/g, ""
          if in_hash
            _.last(_.last(args).options).desc += desc
          else
            _.last(args).desc += desc
        else
          arg = line.split(" - ")
          param = _.str.strip(arg[0])
          desc = Markdown.convert(_.str.strip(arg[1])).replace /<\/?p>/g, ""

          # it's a hash description
          param_match = param.match(/^:(\w+)$/)

          if param_match and _.last(args)?
            in_hash = true
            _.last(args).options ?= []
            name = param_match[1]
            _.last(args).options.push({name, desc, type: Referencer.getLinkMatch(line)})
          else
            in_hash = false
            args.push( {name: param, desc: desc, type: Referencer.getLinkMatch(line)} )

        last_indent = indent

    args

  # Internal: Deindents excess whitespace from the sections.
  #
  # lines - An {Array} of {String}s
  #
  # Returns `lines` with the leftmost whitespace removed.
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

  # Public: Get a JSON representation of the object.
  #
  # Returns the JSON object (a {Object}).
  toJSON: ->
    if @node
      json =
        includes: @includeMixins
        extends: @extendMixins
        concerns: @concerns
        abstract: @isAbstract()
        private: @isPrivate()
        internal: @isInternal()
        deprecated: @isDeprecated()
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
        generated: @generated
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
