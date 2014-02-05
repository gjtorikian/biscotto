# Public: The base class for all nodes.
#
module.exports = class Node

  # Public: Find an ancestor node by type.
  #
  # type - The type name (a {String})
  # node - The CoffeeScript node to search on (a {Base})
  findAncestor: (type, node = @node) ->
    if node.ancestor
      if node.ancestor.constructor.name is type
        node.ancestor
      else
        @findAncestor type, node.ancestor

    else
      undefined
