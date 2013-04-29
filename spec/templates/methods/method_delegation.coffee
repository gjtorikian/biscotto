class MethodDelegation

  # {Delegates to: @delegatedClassRegular}
  delegatedClassname: ->

  # {Delegates to: App.TestMethodDocumentation@lets_do_it}
  #delegatedInternalRegular: ->

  # Public: {Delegates to: TestInstanceMethods.someMethod}
  #delegatedRegular: ->

  # Oh hello.
  #
  # p - A {String}
  #
  # Returns a {Boolean}.
  @delegatedClassRegular: (p) ->

  # {Delegates to: .delegatedRegular}
  #@delegatedIrregular: ->


  # Blah
  #@undelegatedRegular: ->

