required_class = require("./fixtures/required_class")

# Public: A class that requires another file.
class SomeRequiredMethodDelegation

  ### Public ###

  # {Delegates to: RequiredClass.someDelegatedMethod}
  delegatedMethod: ->
