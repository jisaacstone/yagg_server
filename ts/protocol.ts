// The wire protocol between the Elixir backend and this frontend.

export type Position = 'north' | 'south';

// 8 compass points, per Board.in_direction (ts/board.ts).
export type Direction =
  | 'north' | 'south' | 'east' | 'west'
  | 'northeast' | 'northwest' | 'southeast' | 'southwest';

export interface Coord {
  x: number;
  y: number;
}

export interface Dimensions {
  width: number;
  height: number;
}

export interface Ability {
  name: string;
  description: string;
}

export interface Triggers {
  move?: Ability;
  attack?: Ability;
  death?: Ability;
}

// A fully-revealed unit: this client can see all of its stats.
export interface KnownUnit {
  name: string;
  attack: number | 'immobile';
  defense: number;
  player: Position;
  ability?: Ability;
  triggers?: Triggers;
  attributes: string[];
}

// A unit as it appears on the board/screen. Its owner-class is always known
// ('unowned' is the neutral class for ownerless display units, e.g. the how-to
// page); everything else is revealed progressively (name/ability/triggers via
// show_ability, full stats via new_unit). An opponent's un-revealed unit is
// just `{ player }`.
export type BoardUnit =
  & { player: Position | 'unowned' }
  & Partial<Omit<KnownUnit, 'player'>>;

export interface PlayerInfo {
  id: string;
  name: string;
}

// Payload revealed by a `show_ability` event.
export interface Reveal {
  name?: string;
  ability?: Ability;
  triggers?: Triggers;
}


// A batch of events applied in order (Yagg.Event.Multi).
export interface MultiEvent {
  event: 'multi';
  events: ServerEvent[];
}

export interface GameStartedEvent {
  event: 'game_started';
  state?: string;
  army_size?: number;
  dimensions?: Dimensions;
}

export interface BattleStartedEvent {
  event: 'battle_started';
}

export interface TimerEvent {
  event: 'timer';
  player: Position | 'all';
  timer: number;
}

export interface PlayerJoinedEvent {
  event: 'player_joined';
  player: PlayerInfo;
  position: Position;
}

export interface PlayerLeftEvent {
  event: 'player_left';
  player: PlayerInfo;
}

export interface PlayerReadyEvent {
  event: 'player_ready';
  player: Position;
}

export interface AddToHandEvent {
  event: 'add_to_hand';
  index: number;
  unit: KnownUnit;
}

export interface UnitAssignedEvent {
  event: 'unit_assigned';
  index: number;
  x: number;
  y: number;
}

export interface UnitPlacedEvent {
  event: 'unit_placed';
  x: number;
  y: number;
  player: Position;
}

export interface NewUnitEvent {
  event: 'new_unit';
  x: number;
  y: number;
  unit: KnownUnit;
}

export interface UnitChangedEvent {
  event: 'unit_changed';
  x: number;
  y: number;
  unit: KnownUnit;
}

export interface UnitDiedEvent {
  event: 'unit_died';
  x: number;
  y: number;
}

export interface FeatureEvent {
  event: 'feature';
  x: number;
  y: number;
  feature: string;
}

export interface ThingMovedEvent {
  event: 'thing_moved';
  from: Coord;
  to: Coord | 'offscreen' | 'hand';
  direction?: Direction;
}

export interface ThingGoneEvent {
  event: 'thing_gone';
  x: number;
  y: number;
}

export interface BattleEvent {
  event: 'battle';
  from: Coord;
  to: Coord;
}

export interface CandidateEvent {
  event: 'candidate';
  index: number;
  unit: KnownUnit;
}

export interface ShowAbilityEvent {
  event: 'show_ability';
  x: number;
  y: number;
  type: 'ability' | 'move' | 'attack' | 'death';
  reveal: Reveal;
}

// ability_used carries an ability-specific payload dispatched by `type`
// (ts/abilty_event.ts).
export interface AbilityUsedEvent {
  event: 'ability_used';
  type: string;
}

export interface GameoverEvent {
  event: 'gameover';
  winner: Position | 'draw';
  reason?: string;
}

export interface TurnEvent {
  event: 'turn';
  player: Position;
}

export interface ConfigChangeEvent {
  event: 'config_change';
  config: string;
}

export interface TableShutdownEvent {
  event: 'table_shutdown';
}

export type ServerEvent =
  | MultiEvent
  | GameStartedEvent
  | BattleStartedEvent
  | TimerEvent
  | PlayerJoinedEvent
  | PlayerLeftEvent
  | PlayerReadyEvent
  | AddToHandEvent
  | UnitAssignedEvent
  | UnitPlacedEvent
  | NewUnitEvent
  | UnitChangedEvent
  | UnitDiedEvent
  | FeatureEvent
  | ThingMovedEvent
  | ThingGoneEvent
  | BattleEvent
  | CandidateEvent
  | ShowAbilityEvent
  | AbilityUsedEvent
  | GameoverEvent
  | TurnEvent
  | ConfigChangeEvent
  | TableShutdownEvent;

// An event handler returns an animation: applying the DOM change and
// resolving when the (optional) animation finishes. The queue in
// ts/eventlistener.ts awaits each before draining the next event.
export type EventHandler = () => Promise<unknown>;

export type EventName = ServerEvent['event'];

// The payload for a specific event name.
export type PayloadOf<K extends EventName> = Extract<ServerEvent, { event: K }>;

// A handler for a specific event: takes its payload, returns an animation thunk.
export type HandlerFor<K extends EventName> = (event: PayloadOf<K>) => EventHandler;

// A (partial) map of event name -> handler.
export type EventHandlers = {
  [K in EventName]?: HandlerFor<K>;
};
