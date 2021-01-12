import * as Instructions from './instructions.js';
import * as LeaveButton from './leaveButton.js';

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
    Instructions.dropdown(
      'placement',
      'Place your monarch and as many other units as desired');
  } else if (stateName === 'battle') {
    Instructions.dropdown(
      'battle',
      "Destroy your opponent's monarch or cross your monarch to the other side to win");
  } else {
    console.log(`no instructions for ${stateName}`);
  }
}

export function isYourTurn(): boolean {
  return gmeta.position 
    && gmeta.position === gmeta.turn;
}

export function gamestatechange(newstate: string): void {
  document.getElementById('table').dataset.gamestate = newstate;
  gmeta.boardstate = newstate;
  instructions(newstate);
  Array.prototype.forEach.call(
    document.getElementsByClassName('playername') as HTMLCollectionOf<HTMLInputElement>,
    el => {
      el.dataset.ready = null;
    }
  );
  LeaveButton.ensureCreated();
}

export function turnchange(player) {
  (document.querySelector('#table') as HTMLElement).dataset.yourturn = '';
  gmeta.turn = player;
  if (player == null) {
    document.getElementsByTagName('body')[0].dataset.turn = null;
    (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'false';
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'false';
  } else if (player === gmeta.position) {
    (document.querySelector('#table') as HTMLElement).dataset.yourturn = 'yes';
    document.getElementsByTagName('body')[0].dataset.turn = 'player';
    (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'true';
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'false';
  } else {
    document.getElementsByTagName('body')[0].dataset.turn = 'opponent';
    (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'false';
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'true';
  }
}
