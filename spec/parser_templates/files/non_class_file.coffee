# Public: The greeting
GREETING = 'Hay'

# Public: Says hello to a person
#
# name - The name of the person
#
hello = (name) ->
  console.log GREETING, name

# Public: Says bye to a person
#
# name - The name of the person
#
bye = (name) ->
  console.log "Bye, bye #{ name }"

# Public: Say hi to a person
#
# name - The name of the person
#
module.exports.sayHi = (hi) -> console.log "Hi #{ hi}!"
