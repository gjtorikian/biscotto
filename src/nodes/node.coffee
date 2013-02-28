# Base class for all nodes.
#
module.exports = class Node

  # Find an ancestor node by type.
  #
  # type - the class name (a [String])
  # node - the CoffeeScript node (a [Base])
  #
  findAncestor: (type, node = @node) ->
    if node.ancestor
      if node.ancestor.constructor.name is type
        node.ancestor
      else
        @findAncestor type, node.ancestor

    else
      undefined
