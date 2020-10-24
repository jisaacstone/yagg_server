## Units

First a unit was a struct, and functions manipulated the struct directly.
To simplify things common actions are moved to the [`Unit`](../lib/unit.ex) module.
Also we have created a behaviour, and the plan is to make all units have their own module that implements the behavior.
This work is half done

## Abilities

Unit abilities are the most complex and error-prone bit of the code.

Again we are victims of history. First units only had attack and defense, later abilities were added, and most recently triggers.
[Ability](../lib/board/action/ability.ex) is a behavior, and also provides a `__using__` macro. So new abilities are expected to be modules that implement
this behavior.

The ability callback is `resolve(board, [opts]) :: {board, [events]}`
do every ability takes a board state and returns a board state and events. This design is good.
There is a problem with the opts keyword list. The problem is because I took the ability interface and reused it for triggers.
This is a problem because some triggers rely on certain opts keywords. For example the `from` and `to` keywords must be
present in most move triggers, but there is no way for the type checker to verify this. Also the ability itself has no way of
indicating if it is meant as a move trigger or death trigger or ability, etc.

A partial solution is to move the abilities to the same file or namespace as the units that use them. This provides more
context so mistakes are less likely. Best would to use some other design that enforced required keys, or at least could add a more precise spec so the type checker can catch some bugs

