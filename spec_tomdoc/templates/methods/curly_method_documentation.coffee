class App.TestMethodDocumentation extends App.Doc

  # Should be overloaded to change fetch limit.
  #
  # Returns the {Number} of items per fetch
  #
  fetchLimit: () -> 5

  # Private: Do it!
  #
  # See #undo for more information.
  #
  # it - The {String} thing to do
  # again - A {Boolean} for do it again
  # options - The do options
  #           :speed - The {String} speed
  #           :repeat - How many {Number} times to repeat
  #           :tasks - The {[Tasks]} tasks to do
  # 
  # Returns {Boolean} when successfully executed
  #
  do: (it, again, options) ->

  # Private: Do it!
  #
  # See #undo for more information.
  #
  # it - The {String} thing to do
  # again - A {Boolean} for do it again
  # options - The do options
  #           :speed - The {String} speed
  #           :repeat - How many {Number} times to repeat
  #           :tasks - The {[Tasks]} tasks to do
  #
  # Returns {Boolean} when successfully executed
  #
  doWithoutSpace:(it, again, options)->

  # Private: Do it!
  #
  # See #undo for more information.
  #
  # it - The {String} thing to do
  # again - A {Boolean} for do it again
  # options - The do options
  #           :speed - The {String} speed
  #           :repeat - How many {Number} times to repeat
  #           :tasks - The {[Tasks]} tasks to do
  #
  # Returns {Boolean} when successfully executed
  #
  @lets_do_it = (it, options) ->
