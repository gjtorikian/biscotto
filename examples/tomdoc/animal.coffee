# Public: Base class for all animals.
#
# This is not used for codo. Its purpose is to show
# all possible tags within a class, even when it makes no sense at all.
# For example this reference test to {Example.Animal.Lion#move}
#
# Examples
# # How to subclass an {Example.Animal}
#   class Lion extends Animal
#     move: (direction, speed): ->
#
class Example.Animal

  # Language helpers
  get = (props) => @::__defineGetter__ name, getter for name, getter of props
  set = (props) => @::__defineSetter__ name, setter for name, setter of props

  @ANSWER = 42

  get name: -> @_name || 'unknown'
  set name: (@_name) ->

  get color: -> @_color

  # Construct a new animal.
  #
  # name - The name of the {Example.Animal}
  # birthDate - When the animal was born
  #
  #
  # Examples
  #     new Animal
  #
  #
  # Returns nothing.
  #
  # Returns String if blah.
  constructor: (@name, @birthDate = new Date()) ->

