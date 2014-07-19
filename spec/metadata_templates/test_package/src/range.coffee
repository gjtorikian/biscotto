Grim = require 'grim'
Point = require './point'
{newlineRegex} = require './helpers'
Fs = require 'fs'

# Public: Represents a region in a buffer in row/column coordinates.
#
# Every public method that takes a range also accepts a *range-compatible*
# {Array}. This means a 2-element array containing {Point}s or point-compatible
# arrays. So the following are equivalent:
#
# ```coffee
# new Range(new Point(0, 1), new Point(2, 3))
# new Range([0, 1], [2, 3])
# [[0, 1], [2, 3]]
# ```
module.exports =
class Range
  grim: Grim

  # Public: Call this with the result of {Range::serialize} to construct a new Range.
  @deserialize: (array) ->
    new this(array...)

  # Public: Convert any range-compatible object to a {Range}.
  #
  # * object:
  #     This can be an object that's already a {Range}, in which case it's
  #     simply returned, or an array containing two {Point}s or point-compatible
  #     arrays.
  # * copy:
  #     An optional boolean indicating whether to force the copying of objects
  #     that are already ranges.
  #
  # Returns: A {Range} based on the given object.
  @fromObject: (object, copy) ->
    if Array.isArray(object)
      new this(object...)
    else if object instanceof this
      if copy then object.copy() else object
    else
      new this(object.start, object.end)
  # Public: Returns a {Range} that starts at the given point and ends at the
  # start point plus the given row and column deltas.
  #
  # * startPoint:
  #     A {Point} or point-compatible {Array}
  # * rowDelta:
  #     A {Number} indicating how many rows to add to the start point to get the
  #     end point.
  # * columnDelta:
  #     A {Number} indicating how many rows to columns to the start point to get
  #     the end point.
  #
  # Returns a {Range}
  @fromPointWithDelta: (startPoint, rowDelta, columnDelta) ->
    startPoint = Point.fromObject(startPoint)
    endPoint = new Point(startPoint.row + rowDelta, startPoint.column + columnDelta)
    new this(startPoint, endPoint)

  constructor: (pointA = new Point(0, 0), pointB = new Point(0, 0)) ->
    pointA = Point.fromObject(pointA)
    pointB = Point.fromObject(pointB)

    if pointA.isLessThanOrEqual(pointB)
      @start = pointA
      @end = pointB
    else
      @start = pointB
      @end = pointA

  # Public: Returns a {Boolean} indicating whether this range has the same start
  # and end points as the given {Range} or range-compatible {Array}.
  isEqual: (other) ->
    return false unless other?
    other = @constructor.fromObject(other)
    other.start.isEqual(@start) and other.end.isEqual(@end)
