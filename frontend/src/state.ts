export const gmeta = {
  position: null,
  name: null,
  boardstate: null,
  turn: null,
  phase: null,
};

export function isYourTurn(): boolean {
  return gmeta.position 
    && gmeta.position === gmeta.turn;
}
