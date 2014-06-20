# Public: Here's a class.
class Foo
  # Here's a method, baz.
  baz: () -> 'baz'

# Public: Here is a method on Foo, called bar.
Foo::bar = () -> 'bar'

# Public: Show that other prototypes are safe
Bing::bang = () -> 'koof'
