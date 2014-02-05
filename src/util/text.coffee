# Public: Global text helpers.
#
module.exports =

  # Public: Whitespace helper function
  #
  # n - The number of spaces to create (a {Number})
  #
  # Returns the space string (a {String}).
  whitespace: (n) ->
    a = []
    while a.length < n
      a.push ' '
    a.join ''
