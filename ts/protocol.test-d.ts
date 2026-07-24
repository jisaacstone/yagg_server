// Compile-time contract test for the wire protocol.
//
//   make typetest      (tsc -p tsconfig.strict.json)
//
// This file emits nothing. Its only job is to FAIL COMPILATION if the
// ServerEvent union or the handler contract drifts away from what the
// backend (lib/event.ex) actually sends. The drift that broke jstest/ was
// exactly this kind of silent contract change; this test makes it loud.

import type {
  ServerEvent,
  EventName,
  PayloadOf,
  HandlerFor,
  EventHandlers,
  Position,
  KnownUnit,
  BoardUnit,
} from './protocol.js';

// --- tiny type-assertion helpers (tsd-style) ---
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false;
type Expect<T extends true> = T;

// 1. The set of wire events is frozen. Adding or removing one is a deliberate
//    edit to this list — which is the point: the contract cannot drift silently.
type _Names = Expect<Equal<EventName,
  | 'multi'
  | 'game_started'
  | 'battle_started'
  | 'timer'
  | 'player_joined'
  | 'player_left'
  | 'player_ready'
  | 'add_to_hand'
  | 'unit_assigned'
  | 'unit_placed'
  | 'new_unit'
  | 'unit_changed'
  | 'unit_died'
  | 'feature'
  | 'thing_moved'
  | 'thing_gone'
  | 'battle'
  | 'candidate'
  | 'show_ability'
  | 'ability_used'
  | 'gameover'
  | 'turn'
  | 'config_change'
  | 'table_shutdown'
>>;

// 2. ServerEvent is a real discriminated union: narrowing on `event` yields
//    the correct payload for each case.
function narrows(e: ServerEvent): void {
  switch (e.event) {
    case 'new_unit':
    case 'unit_changed': {
      const x: number = e.x;
      const y: number = e.y;
      const name: string = e.unit.name;
      void x; void y; void name;
      break;
    }
    case 'thing_moved': {
      const to = e.to; // Coord | 'offscreen' | 'hand'
      if (typeof to !== 'string') {
        const tx: number = to.x;
        void tx;
      }
      break;
    }
    case 'gameover': {
      const w: Position | 'draw' = e.winner;
      void w;
      break;
    }
    default:
      break;
  }
}
void narrows;

// 3. Well-formed payloads must typecheck.
const _newUnit: ServerEvent = {
  event: 'new_unit',
  x: 3, y: 1,
  unit: { name: 'electromouse', attack: 3, defense: 4, player: 'north', attributes: [] },
};
const _shutdown: ServerEvent = { event: 'table_shutdown' };
const _multi: ServerEvent = { event: 'multi', events: [_shutdown, _newUnit] };
void _multi;

// 4. Malformed payloads must be REJECTED by the compiler.
// @ts-expect-error unknown event tag
const _badTag: ServerEvent = { event: 'not_a_real_event' };
void _badTag;
const _goodUnit: KnownUnit = { name: 'x', attack: 1, defense: 0, player: 'north', attributes: [] };
// @ts-expect-error x must be a number, not a string
const _badField: PayloadOf<'new_unit'> = { event: 'new_unit', x: 'nope', y: 0, unit: _goodUnit };
void _badField;

// 5. The handler contract composes: a handler for K takes PayloadOf<K> and
//    returns an EventHandler (the () => Promise animation thunk).
const newUnitHandler: HandlerFor<'new_unit'> = (e) => {
  const _e: PayloadOf<'new_unit'> = e;
  void _e;
  return () => Promise.resolve();
};
const _handlers: EventHandlers = { new_unit: newUnitHandler };
void _handlers;

// 6. Unit types. KnownUnit is fully revealed with a non-null owner. BoardUnit
//    is a unit as it sits on the board: owner always known, stats optional
//    (revealed progressively via show_ability etc.).
const _boardMin: BoardUnit = { player: 'north' };  // bare owner is enough
const _boardFromKnown: BoardUnit = _goodUnit;       // a KnownUnit is a BoardUnit
void _boardMin; void _boardFromKnown;
// @ts-expect-error BoardUnit still requires an owner
const _boardNoPlayer: BoardUnit = { name: 'x' };
void _boardNoPlayer;
// @ts-expect-error player is a Position, never null
const _knownNullPlayer: KnownUnit = { name: 'x', attack: 1, defense: 0, player: null, attributes: [] };
void _knownNullPlayer;
