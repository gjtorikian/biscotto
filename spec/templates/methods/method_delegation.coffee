class MethodDelegation

  # {Delegates to: @delegatedClassRegular}
  delegatedClassname: ->

  # Public: I'm being delegated to!
  delegatedRegular: ->

  # {Delegates to: App.TestMethodDocumentation@lets_do_it}
  #delegatedInternalRegular: ->


  # Oh hello.
  #
  # p - A {String}
  #
  # Returns a {Boolean}.
  @delegatedClassRegular: (p) ->

  # {Delegates to: .delegatedRegular}
  @delegatedIrregular: ->


  # Blah
  #@undelegatedRegular: ->

