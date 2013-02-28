# Global text helpers
#
module.exports =

  # Whitespace helper function
  #
  # n - the number of spaces (a [Number])
  #
  # Returns the space string (a [String])
  #
  whitespace: (n) ->
    a = []
    while a.length < n
      a.push ' '
    a.join ''
