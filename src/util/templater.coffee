fs      = require 'fs'
path    = require 'path'
mkdirp  = require 'mkdirp'
_       = require 'underscore'
_.str   = require 'underscore.string'
walkdir = require 'walkdir'
hamlc   = require 'haml-coffee'

# Public: Haml Coffee template compiler.
#
module.exports = class Templater

  # Public: Construct the templater. Reads all templates and constructs
  # the global template context.
  #
  # options - The options (a {Object})
  # referencer - The link type referencer (a {Referencer})
  # parser - The biscotto parser (a {Parser})
  constructor: (@options, @referencer, @parser) ->
    @JST = []

    @globalContext =
      biscottoVersion: 'v' + JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'package.json'), 'utf-8'))['version']
      generationDate: new Date().toString()
      JST: @JST
      underscore: _
      str: _.str
      title: @options.title
      stability: @options.stability
      referencer: @referencer
      analytics: @options.analytics
      fileCount: @parser.files.length
      classCount: @parser.classes.length
      mixinCount: @parser.mixins.length
      methodCount: @parser.getAllMethods().length
      extraCount: _.union([@options.readme], @options.extras).length
      repo: "#{@options.origin}/blob/#{@options.tag}"

    for filename in walkdir.sync path.join(__dirname, '..', '..', 'theme', 'default', 'templates')
      if match = /theme[/\\]default[/\\]templates[/\\](.+).hamlc$/.exec filename
        varname = match[1].replace(/\\/g, "/")
        @JST[varname] = hamlc.compile(fs.readFileSync(filename, 'utf-8'))

  # Public: Redirect template generation to a callback.
  #
  # file - The file callback {Function}
  redirect: (file) -> @file = file

  # Public: Render the given template with the context and the
  # global context object merged as template data. Writes
  # the file as the output filename.
  #
  # template - The template name (a {String})
  # context - The context object (a {Object})
  # filename - The output file name (a {String})
  render: (template, context = {}, filename = '') ->
    html = @JST[template](_.extend(@globalContext, context))

    unless _.isEmpty filename

      # Callback generated content
      if @file
        @file(filename, html)

      # Write to file system
      else
        unless @options.noOutput
          file = path.join @options.output, filename
          dir  = path.dirname(file)
          mkdirp dir, (err) =>
            if err
              console.error "[ERROR] Cannot create directory #{ dir }: #{ err }"
            else
              fs.writeFile file, html

    html
