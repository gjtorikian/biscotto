class MethodDelegation

  ### Public ###

  # {Delegates to: @delegatedClassRegular}
  delegatedClassname: ->

  # Public: I'm being delegated to!
  delegatedRegular: ->

  # Public: {Delegates to: .doubleDelegationTwo}
  doubleDelegationOne: ->

  # Public: {Delegates to: @doubleDelegationThree}
  doubleDelegationTwo: ->

  # At last, we have the same content!
  #
  # You might also like {@undelegatedRegular}.
  #
  # Returns a {Number}.
  @doubleDelegationThree: ->

  # {Delegates to: App.CurlyMethodDocumentation@lets_do_it}
  delegatedInternalRegular: ->

  # Private: Oh hello.
  #
  # p - A {String}
  #
  # Returns a {Boolean}.
  @delegatedClassRegular: (p) ->

  # {Delegates to: TestExample.run}
  @delegatedIrregular: ->


  # Blah
  @undelegatedRegular: ->

