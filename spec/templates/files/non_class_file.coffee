# The greeting
GREETING = 'Hay'

# Says hello to a person
#
# name - The name of the person
#
hello = (name) ->
  console.log GREETING, name

# Says bye to a person
#
# name - The name of the person
#
bye = (name) ->
  console.log "Bye, bye #{ name }"

# Say hi to a person
#
# name - The name of the person
#
module.exports.sayHi = (hi) -> console.log "Hi #{ hi}!"
