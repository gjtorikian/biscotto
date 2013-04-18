class App.TestLinks

  # External link short.
  #
  # http://coffeescript.org/
  #
  externalLinkShort: ->

  # External link [long](http://coffeescript.org/).
  #
  externalLinkLong: ->

  # internalClassLinkShort 
  #
  # {.internalLinkLong}
  #
  internalLinkShort: ->

  # internalClass [Link Long]{App.TestLinks}
  #
  internalLinkLong: ->

  # internalInstanceLinkShort {.externalLinkShort}
  #
  internalInstanceLinkShort: ->

  # internalInstance [Link Long]{.externalLinkLong}
  #
  internalInstanceLinkLong: ->

  # internalClassLinkShort {@internalClassLinkLong}
  #
  @internalClassLinkShort: ->

  # internalClass [LinkLong]{@internalClassLinkShort}
  #
  @internalClassLinkLong: ->