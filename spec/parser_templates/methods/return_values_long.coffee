class App.ReturnValuesLongDocumentation extends App.Doc

  # Public: Compares two `Point`s.
  #
  # other - The {Point} to compare against
  #
  # Returns a {Number} matching the following rules:
  # * If the first `row` is greater than `other.row`, returns `1`.
  # * If the first `row` is less than `other.row`, returns `-1`.
  # * If the first `column` is greater than `other.column`, returns `1`.
  # * If the first `column` is less than `other.column`, returns `-1`.
  # 
  # Otherwise, returns `0`.
  compare: (other) ->