# board

keep it small and simple

thinking initial version 5x5 board 10 units each player.

maybe do like a half-size stratego board, two holes in the middle like so

    X X X X X
    X X X X X
    X   X   X
    X X X X X
    X X X X X

Lots of other possible board configurations, including hexgrid, but starting simple is good?

I like the idea of a `monarch` or `hero` unit, capture it and win.

# Unit ideas
All units have attack and defence. All units can move one square. Some units have special abilities. Using the special ability replaces movement.

* Berserker
  * Attack: 5
  * Defense: 1
* Shieldbearer
  * Attack: 1
  * Defense: 5
* Monarch:
  * Attack: 2
  * Defense: 1
* Mounted:
  * Attack: 3
  * Defense: 2
  * Can move two squares, can leap over units/terrain
* Demolitions
  * Attack: 1
  * Defense: 2
  * Can place a mine in any adjacent square. Next unit to occupy that square is destroyed
* Spy
  * Attack: 2
  * Defense: 2
  * Can investigate any unit within two squares. The identity of that unit is revealed
* Regular Dude
  * Attack: 3
  * Defense: 3
* Inspiring Leader
  * Attack: 3
  * Defense: 1
  * Friendly units in the same row as this unit have +1 attack
* Trench Engineer
  * Attack: 1
  * Defense: 3
  * Friendly units in adjacent squares have +1 defense
* Sniper
  * Attack: 2
  * Defense: 2
  * Can attack any unit within the same row or column
* Venomous Blades
  * Attack: 2
  * Defense: 2
  * When this unit is killed the attacking unit is also killed
* Transport
  * Attack: 1
  * Defense: 2
  * Can switch places with any friendly unit
