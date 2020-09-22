export const gmeta = {
    position: null,
    name: null,
    boardstate: null,
    turn: null,
    phase: null,
};
export function isYourTurn() {
    return gmeta.position
        && gmeta.position === gmeta.turn;
}
