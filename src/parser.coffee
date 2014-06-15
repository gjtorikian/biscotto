fs           = require 'fs'
path         = require 'path' # To load package.json
_            = require 'underscore'
_.str        = require 'underscore.string'
CoffeeScript = require 'coffee-script'
builtins     = require 'builtins'

File          = require './nodes/file'
Class         = require './nodes/class'
Mixin         = require './nodes/mixin'
VirtualMethod = require './nodes/virtual_method'

{whitespace} = require('./util/text')
{SourceMapConsumer} = require 'source-map'

packageFile = JSON.parse(fs.readFileSync(path.join(__dirname, '..', 'package.json'), 'utf-8'))

# Public: This parser is responsible for converting each file into the intermediate /
# AST representation as a JSON node.
#
module.exports = class Parser

  # Public: Construct the parser
  #
  # options - An {Object} of options
  constructor: (@options) ->
    @files   = []
    @classes = []
    @mixins  = []
    @slugs   = {}

    @fileCount = 0
    @globalStatus = "Private"

    @classMemberRegex = """

                        """

  # Public: Parse the given CoffeeScript file.
  #
  # file - A {String} representing the the CoffeeScript filename
  parseFile: (file) ->
    @parseContent fs.readFileSync(file, 'utf8'), file
    @fileCount += 1

  # Public: Parse the given CoffeeScript content.
  #
  # content - A {String} representing the CoffeeScript file content
  # file - A {String} representing the CoffeeScript file name
  #
  parseContent: (content, file = '') ->
    @previousNodes = []
    @globalStatus = "Private"

    # Defines typical conditions for entities we are looking through nodes
    entities =
      clazz: (node) -> node.constructor.name is 'Class' && node.variable?.base?.value?
      mixin: (node) -> node.constructor.name == 'Assign' && node.value?.base?.properties?

    [content, lineMapping] = @convertComments(content)

    sourceMap = CoffeeScript.compile(content, {sourceMap: true}).v3SourceMap
    @smc = new SourceMapConsumer(sourceMap)

    try
      root = CoffeeScript.nodes(content)
    catch error
      console.log('Parsed CoffeeScript source:\n%s', content) if @options.debug
      throw error

    # Find top-level methods and constants that aren't within a class
    fileClass = new File(root, file, lineMapping, @options)
    @files.push(fileClass) unless fileClass.isEmpty()

    @linkAncestors root


    # TODO:
    #
    # - [x] add `paramNames` for functions
    # - [x] convert `objects` to line numbers (and in the exports section)
    # - [x] tag builtin NodeJs modules : https://github.com/segmentio/builtins
    # - [x] add `classProperties` and `prototypeProperties`
    # - [x] add doc string
    # - [x] look up version numbers for modules

    class Visitor
      defs: {} # Local variable definitions
      exports: {}
      commentLines: {}

      constructor: (root) ->
        root.traverseChildren no, (exp) => @visit(exp) # `no` means Stop at scope boundaries

      visit: (exp) ->  @["visit#{exp.constructor.name}"](exp)
      eval:  (exp) ->  @["eval#{exp.constructor.name}"](exp)

      visitComment: (exp) ->
        # Skip the 1st comment which is added by coffeescript
        return if exp.comment is '~Private~'

        @commentLines[lineMapping[exp.locationData.last_line]] = exp.comment.trim()

      visitClass: (exp) ->
        @defs[exp.variable.base.value] = @evalClass(exp)
        no # Do not traverse into the class methods

      visitAssign: (exp) ->
        variable = @eval(exp.variable)
        value = @eval(exp.value)

        baseName = variable.base.value
        switch baseName
          when 'module'
            unless variable.properties?[0]?.name?.value is 'exports'
              throw new Error 'BUG: Does not support module.somthingOtherThanExports'
            baseName = 'exports'
            firstProp = variable.properties[1]
          when 'exports'
            firstProp = variable.properties[0]

        switch baseName
          when 'exports'
            # Handle 3 cases:
            #
            # - `exports.foo = SomeClass`
            # - `exports.foo = 42`
            # - `exports = bar`
            if firstProp
              if @defs[value.base.value]
                # case `exports.foo = SomeClass`
                @exports[firstProp.name.value] = @defs[value.base.value]
              else
                # case `exports.foo = 42`
                @exports[firstProp.name.value] =
                  type: 'primitive'
                  doc: @commentLines[lineMapping[value.locationData.first_line] - 1]
                  startLineNumber:  lineMapping[value.locationData.first_line]
                  endLineNumber:    lineMapping[value.locationData.last_line]

            else
              # case `exports = bar`
              @exports = {_default: value}

          # case left-hand-side is anything other than `exports...`
          else
            # Handle 3 common cases:
            #
            # X     = ...
            # {X}   = ...
            # {X:Y} = ...
            switch variable.base.constructor.name
              when 'Literal'
                # case X = ...
                @defs[variable.base.value] = _.extend name: variable.base.value, value
              when 'Obj'
                for key in variable.base.objects
                  switch key.constructor.name
                    when 'Value'
                      # case {X} = ...
                      @defs[key.base.value] = _.extend {}, value,
                        name: key.base.value
                        exportsProperty: key.base.value

                    when 'Assign'
                      # case {X:Y} = ...
                      @defs[key.value.base.value] = _.extend {}, value,
                        name: key.value.base.value
                        exportsProperty: key.variable.base.value
                      return no # Do not continue visiting X

                    else throw new Error "BUG: Unsupported require Obj structure: #{key.constructor.name}"

              else throw new Error "BUG: Unsupported require structure: #{variable.base.constructor.name}"

      visitCode: (exp) ->
      visitValue: (exp) ->
      visitCall: (exp) ->
      visitLiteral: (exp) ->
      visitObj: (exp) ->
      visitAccess: (exp) ->
      visitBlock: (exp) ->


      evalComment: (exp) ->
      evalClass: (exp) ->
        className = exp.variable.base.value
        classProperties = []
        prototypeProperties = []

        for subExp in exp.body.expressions
          switch subExp.constructor.name
            # when 'Assign'
            when 'Value'
              # case Prototype-level properties
              for prototypeExp in subExp.base.properties

                switch prototypeExp.constructor.name
                  when 'Comment'
                    continue
                  else
                    isClassLevel = prototypeExp.variable.this

                    if isClassLevel
                      name = prototypeExp.variable.properties[0].name.value
                    else
                      name = prototypeExp.variable.base.value

                    # Do not include the class constructor
                    continue if name is 'constructor'

                    value = @eval(prototypeExp.value)

                    if value.constructor?.name is 'Value'
                      lookedUpVar = @defs[value.base.value]
                      if lookedUpVar
                        if lookedUpVar.type is 'import'
                          value =
                            name: name
                            doc: @commentLines[lineMapping[value.locationData.first_line] - 1]
                            startLineNumber: lineMapping[value.locationData.first_line]
                            endLineNumber: lineMapping[value.locationData.last_line]
                            reference: lookedUpVar
                        else
                          value = _.extend name: name, lookedUpVar

                      else
                        # Assigning a simple var
                        value =
                          type: 'primitive'
                          name: name
                          doc: @commentLines[lineMapping[value.locationData.first_line] - 1]
                          startLineNumber:  lineMapping[value.locationData.first_line]
                          endLineNumber:    lineMapping[value.locationData.last_line]

                    else
                      value = _.extend name: name, value

                    if isClassLevel
                      @defs["#{className}.#{name}"] = value
                      classProperties.push(value)
                    else
                      @defs["#{className}::#{name}"] = value
                      prototypeProperties.push(value)
              true

        type: 'class'
        name: className
        classProperties: classProperties
        prototypeProperties: prototypeProperties
        doc: @commentLines[lineMapping[exp.locationData.first_line] - 1]
        startLineNumber:  lineMapping[exp.locationData.first_line]
        endLineNumber:    lineMapping[exp.locationData.last_line]

      evalCode: (exp) ->
        bindingType: 'variable'
        type: 'function'
        paramNames: _.map exp.params, (param) -> param.name.value
        doc: @commentLines[lineMapping[exp.locationData.first_line] - 1]
        startLineNumber:  lineMapping[exp.locationData.first_line]
        endLineNumber:    lineMapping[exp.locationData.last_line]

      evalValue: (exp) -> exp
      evalCall: (exp) ->
        # The only interesting call is `require('foo')`
        if exp.variable.base.value is 'require'
          moduleName = exp.args[0].base.value
          moduleName = moduleName.substring(1, moduleName.length - 1)

          # For npm modules include the version number
          ver = packageFile['dependencies'][moduleName]
          moduleName = "#{moduleName}@#{ver}" if ver

          ret =
            type: 'import'
            doc: @commentLines[lineMapping[exp.locationData.first_line] - 1]
            startLineNumber:  lineMapping[exp.locationData.first_line]
            # endLineNumber:    lineMapping[exp.locationData.last_line]

          if /^\./.test(moduleName)
            # Local module
            ret.path = moduleName
          else
            ret.module = moduleName
          # Tag builtin NodeJS modules
          ret.builtin = true if builtins.indexOf(moduleName) >= 0

          ret

        else
          null

      evalAssign: (exp) -> throw new Error 'BUG: Not implemented yet'
      evalLiteral: (exp) -> throw new Error 'BUG: Not implemented yet'
      evalObj: (exp) -> throw new Error 'BUG: Not implemented yet'
      evalAccess: (exp) -> throw new Error 'BUG: Not implemented yet'


    {defs:unindexedObjects, exports:exports} = new Visitor(root)
    objects = {}
    for key, value of unindexedObjects
      objects[value.startLineNumber] = value
      # Update the classProperties to be line numbers
      if value.type is 'class'
        value.classProperties = (prop.startLineNumber for prop in value.classProperties)
        value.prototypeProperties = (prop.startLineNumber for prop in value.prototypeProperties)

    if exports._default
      exports = exports._default.startLineNumber
    else
      for key, value of exports
        exports[key] = value.startLineNumber


    @slugs[file] = {objects, exports}



    root.traverseChildren true, (child) =>
      entity = false

      for type, condition of entities
        if entities.hasOwnProperty(type)
          entity = type if condition(child)

      if entity

        # Check the previous tokens for comment nodes
        previous = @previousNodes[@previousNodes.length-1]
        switch previous?.constructor.name
          # A comment is preceding the class declaration
          when 'Comment'
            doc = previous
          when 'Literal'
            # The class is exported `module.exports = class Class`, take the comment before `module`
            if previous.value is 'exports'
              node = @previousNodes[@previousNodes.length-6]
              doc = node if node?.constructor.name is 'Comment'

        if entity == 'mixin'
          name = [child.variable.base.value]

          # If p.name is empty value is going to be assigned to index...
          name.push p.name?.value for p in child.variable.properties

          # ... and therefore should be just skipped.
          if name.indexOf(undefined) == -1
            mixin = new Mixin(child, file, @options, doc)

            if mixin.doc.mixin? && (@options.private || !mixin.doc.private)
              @mixins.push mixin

        if entity == 'clazz'
          clazz = new Class(child, file, lineMapping, @options, doc)
          @classes.push clazz

      @previousNodes.push child
      true

    root

  # Public: Converts the comments to block comments, so they appear in the node structure.
  # Only block comments are considered by Biscotto.
  #
  # content - A {String} representing the CoffeeScript file content
  convertComments: (content) ->
    result         = []
    comment        = []
    inComment      = false
    inBlockComment = false
    indentComment  = 0
    globalCount = 0
    lineMapping = {}

    for line, l in content.split('\n')
      globalStatusBlock = false

      # key: the translated line number; value: the original number
      lineMapping[(l + 1) + globalCount] = l + 1

      if globalStatusBlock = /^\s*#{3} (\w+).+?#{3}/.exec(line)
        result.push ''
        @globalStatus = globalStatusBlock[1]

      blockComment = /^\s*#{3,}/.exec(line) && !/^\s*#{3,}.+#{3,}/.exec(line)

      if blockComment || inBlockComment
        inBlockComment = !inBlockComment if blockComment
        result.push line
      else
        commentLine = /^(\s*#)\s?(\s*.*)/.exec(line)
        if commentLine
          if inComment
            comment.push commentLine[2]?.replace /#/g, "\u0091#"
          else
            # append current global status flag if needed
            if !/^\s*\w+:/.test(commentLine[2])
              commentLine[2] = @globalStatus + ": " + commentLine[2]
            inComment = true
            indentComment =  commentLine[1].length - 1

            comment.push whitespace(indentComment) + '### ' + commentLine[2]?.replace /#/g, "\u0091#"
        else
          if inComment
            inComment = false
            lastComment = _.last(comment)

            # slight fix for an empty line as the last item
            if _.str.isBlank(lastComment)
              globalCount++
              comment[comment.length] = lastComment + ' ###'
            else
              comment[comment.length - 1] = lastComment + ' ###'

            # Push here comments only before certain lines
            if ///
                 ( # Class
                   class\s*[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*
                 | # Mixin or assignment
                   ^\s*[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff.]*\s+\=
                 | # Function
                   [$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*\s*:\s*(\(.*\)\s*)?[-=]>
                 | # Function
                   @[A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*\s*=\s*(\(.*\)\s*)?[-=]>
                 | # Function
                   [$A-Za-z_\x7f-\uffff][\.$\w\x7f-\uffff]*\s*=\s*(\(.*\)\s*)?[-=]>
                 | # Constant
                   ^\s*@[$A-Z_][A-Z_]*)
                 | # Properties
                   ^\s*[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*:\s*\S+
               ///.exec line

              result.push c for c in comment
            comment = []
          # A member with no preceding description; apply the global status
          member = ///
                 ( # Class
                   class\s*[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*
                 | # Mixin or assignment
                   ^\s*[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff.]*\s+\=
                 | # Function
                   [$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*\s*:\s*(\(.*\)\s*)?[-=]>
                 | # Function
                   @[A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*\s*=\s*(\(.*\)\s*)?[-=]>
                 | # Function
                   [$A-Za-z_\x7f-\uffff][\.$\w\x7f-\uffff]*\s*=\s*(\(.*\)\s*)?[-=]>
                 | # Constant
                   ^\s*@[$A-Z_][A-Z_]*)
                 | # Properties
                   ^\s*[$A-Za-z_\x7f-\uffff][$\w\x7f-\uffff]*:\s*\S+
               ///.exec line

          if member and _.str.isBlank(_.last(result))
            indentComment = /^(\s*)/.exec(line)
            if indentComment
              indentComment = indentComment[1]
            else
              indentComment = ""

            globalCount++
            # we place these here to indicate that the method had a global status applied
            result.push("#{indentComment}###~#{@globalStatus}~###")

          result.push line

    [result.join('\n'), lineMapping]

  # Public: Attach each parent to its children, so we are able
  # to traverse the ancestor parse tree. Since the
  # parent attribute is already used in the class node,
  # the parent is stored as `ancestor`.
  #
  # nodes - A {Base} representing the CoffeeScript nodes
  #
  linkAncestors: (node) ->
    node.eachChild (child) =>
      child.ancestor = node
      @linkAncestors child

  # Public: Get all the parsed methods.
  #
  # Returns an {Array} of {Method}s.
  getAllMethods: ->
    unless @methods
      @methods = []

      for file in @files
        @methods = _.union @methods, file.getMethods()

      for clazz in @classes
        @methods = _.union @methods, clazz.getMethods()

      for mixin in @mixins
        @methods = _.union @methods, mixin.getMethods()

    @methods

  # Public: Get all parsed variables.
  #
  # Returns an {Array} of {Variable}s.
  getAllVariables: ->
    unless @variables
      @variables = []

    for file in @files
      @variables = _.union @variables, file.getVariables()

    for clazz in @classes
      @variables = _.union @variables, clazz.getVariables()

    for mixin in @mixins
      @methods = _.union @methods, mixin.getMethods()

    @variables

  # Public: Show the final parsing statistics.
  showResult: (generator) ->
    fileCount      = @files.length

    classCount     = @classes.length
    noDocClasses   = _.filter(@classes, (clazz) -> !clazz.getDoc().hasComment())
    noDocClassesLength   = noDocClasses.length

    mixinCount     = @mixins.length

    methodsToCount = _.filter(@getAllMethods(), (method) -> method not instanceof VirtualMethod)
    methodCount    = methodsToCount.length
    noDocMethods   = _.filter methodsToCount, (method) ->
      if method.entity?.doc?
        method.entity.doc.isPublic() and method.doc.isPublic() and not method.doc.hasComment()
      else
        method.doc.isPublic() and not method.doc.hasComment()

    noDocMethodsLength = noDocMethods.length

    constants      = _.filter(@getAllVariables(), (variable) -> variable.isConstant())
    constantCount  = constants.length
    noDocConstants = _.filter(constants, (constant) -> !constant.getDoc().hasComment()).length

    totalFound = (classCount + methodCount + constantCount)
    totalNoDoc = (noDocClassesLength + noDocMethodsLength + noDocConstants)
    documented   = 100 - 100 / (classCount + methodCount + constantCount) * (noDocClassesLength + noDocMethodsLength + noDocConstants)

    maxCountLength = String(_.max([fileCount, mixinCount, classCount, methodCount, constantCount], (count) -> String(count).length)).length + 6
    maxNoDocLength = String(_.max([noDocClassesLength, noDocMethodsLength, noDocConstants], (count) -> String(count).length)).length

    stats =
      """
      Parsed files:    #{ _.str.pad(@fileCount, maxCountLength) }
      Classes:         #{ _.str.pad(classCount, maxCountLength) } (#{ _.str.pad(noDocClassesLength, maxNoDocLength) } undocumented)
      Mixins:          #{ _.str.pad(mixinCount, maxCountLength) }
      Non-Class files: #{ _.str.pad(fileCount, maxCountLength) }
      Methods:         #{ _.str.pad(methodCount, maxCountLength) } (#{ _.str.pad(noDocMethodsLength, maxNoDocLength) } undocumented)
      Constants:       #{ _.str.pad(constantCount, maxCountLength) } (#{ _.str.pad(noDocConstants, maxNoDocLength) } undocumented)
       #{ _.str.sprintf('%.2f', documented) }% documented (#{totalFound} total, #{totalNoDoc} with no doc)
       #{generator.referencer.errors} errors
      """

    if @options.missing
      require 'colors'
      noDocClassNames = []
      for noDocClass in noDocClasses
        noDocClassNames.push noDocClass.className.cyan

      noDocMethodNames = []
      noDocMethods.sort (method1, method2) ->
        method1.getShortSignature().localeCompare(method2.getShortSignature())
      noDocMethods = _.groupBy noDocMethods, ({entity}) -> entity.fileName
      for fileName, methods of noDocMethods
        noDocMethodNames.push "\n#{fileName}".cyan
        for noDocMethod in methods
          noDocMethodNames.push "  #{noDocMethod.getShortSignature()}"

      stats += "\nClasses missing docs:\n\n#{noDocClassNames.join('\n')}" if noDocClassNames.length > 0
      stats += "\n\nMethods missing docs:\n#{noDocMethodNames.join('\n')}" if noDocMethodNames.length > 0

    console.log stats

    console.log '==========================='
    console.log JSON.stringify(@slugs, null, 2)
    console.log '==========================='


    if @options.json && @options.json.length
      fs.writeFileSync @options.json, JSON.stringify(@toJSON(), null, "    ");

  # Public: Get a JSON representation of the object.
  #
  # Returns the JSON {Object}.
  toJSON: ->
    json = []

    for file in @files
      json.push file.toJSON()

    for clazz in @classes
      json.push clazz.toJSON()

    for mixin in @mixins
      json.push mixin.toJSON()

    json
