class OptionalArguments

  # Public: Does something.
  #
  # obj - An object with the following defaults:
  #       option1: Does some stuff
  #       option2: Does some {Integer} stuff
  method1: ({option1, option2}) ->
    console.log "wut"

  # Public: Does something else.
  #
  # obj - An object with the following defaults:
  #       option1: Does some stuff
  #       option2: Does some {Integer} stuff
  method2: ({option1, option2}={}) ->
  	
  	console.log "Yeah"