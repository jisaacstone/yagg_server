import * as Instructions from './instructions.js';
export const gmeta = {
    position: null,
    name: null,
    boardstate: null,
    turn: null,
    phase: null,
};
function instructions(stateName) {
    Instructions.clear();
    if (stateName === 'placement') {
        Instructions.dropdown('placement', 'Place your monarch and as many other units as desired');
    }
    else if (stateName === 'battle') {
        Instructions.dropdown('battle', "Destroy your opponent's monarch or cross your monarch to the other side to win");
    }
    else {
        console.log(`no instructions for ${stateName}`);
    }
}
export function isYourTurn() {
    return gmeta.position
        && gmeta.position === gmeta.turn;
}
export function gamestatechange(newstate) {
    document.getElementById('gamestate').innerHTML = `state: ${newstate}`;
    document.getElementsByTagName('body')[0].dataset.gamestate = newstate;
    gmeta.boardstate = newstate;
    instructions(newstate);
    Array.prototype.forEach.call(document.getElementsByClassName('playername'), el => {
        el.dataset.ready = null;
    });
}
export function turnchange(player) {
    gmeta.turn = player;
    if (player == null) {
        document.getElementsByTagName('body')[0].dataset.turn = null;
        document.querySelector('#player .playername').dataset.turn = 'false';
        document.querySelector('#opponent .playername').dataset.turn = 'false';
    }
    else if (player === gmeta.position) {
        document.getElementsByTagName('body')[0].dataset.turn = 'player';
        document.querySelector('#player .playername').dataset.turn = 'true';
        document.querySelector('#opponent .playername').dataset.turn = 'false';
    }
    else {
        document.getElementsByTagName('body')[0].dataset.turn = 'opponent';
        document.querySelector('#player .playername').dataset.turn = 'false';
        document.querySelector('#opponent .playername').dataset.turn = 'true';
    }
}
