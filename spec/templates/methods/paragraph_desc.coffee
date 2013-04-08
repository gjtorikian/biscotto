class TestParagraphs

  # Public: This should be one paragraph.
  # 
  # If soft tabs are enabled, this is a space (`" "`) times the `{.getTabLength}` value.
  # Otherwise, it's a tab (`\t`).
  spacing: ->

  # Public: This is a paragraph with a br.
  #
  # Equality is based on some condition.  
  # Oh look, a BR!
  br: ->

  # Public: This is two seperate paragraphs.
  #
  # Equality is based on some condition.
  #
  # Here I am, still yapping.
  #
  # And I'm done.
  twoParagraphs: ->

  # Public: Compares two objects to determine equality.
  #
  # Equality is based on the condition that:
  #
  # * the two `{Buffer}`s are the same
  # * the two `scrollTop` and `scrollLeft` property are the same
  # * the two `{Cursor}` screen positions are the same
  #
  # 
  ulList: ->

  # Public: Compares two objects to determine equality.
  #
  # Equality is based on the condition that:
  #
  # 1. the two `{Buffer}`s are the same
  # 2. the two `scrollTop` and `scrollLeft` property are the same
  # 3. the two `{Cursor}` screen positions are the same
  #
  # 
  olList: ->