Point = require './point'
Range = require './range'

# Public: A mutable text container with undo/redo support and the ability to
# annotate logical regions in the text.
module.exports =
class TestClass
  @Range: Range
  @newlineRegex: newlineRegex
