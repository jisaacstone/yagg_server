import * as Instructions from './instructions.js';
import * as LeaveButton from './leaveButton.js';
import * as SFX from './sfx.js';
import * as Soundtrack from './soundtrack.js';
import * as Board from './board.js';

export const gmeta: {
  position?: string;
  boardstate?: string;
  turn?: string;
  phase?: string;
  config?: Board.Config;
} = {};

export function setConfig(config: Board.Config) {
  gmeta.config = config;
  document.getElementById('table').dataset.config = config.name;
}

function monarchName() {
  const monarch = document.querySelector('.monarch') as HTMLElement;
  if (monarch && monarch.dataset.name) {
    return monarch.dataset.name;
  }
  console.warn('could not determine monarch name');
  return 'monarch';
}

function instructions(stateName) {
  Instructions.clear();
  if (stateName === 'placement') {
    Instructions.dropdown(
      'placement',
      `Place your ${monarchName()} and as many other units as desired`);
  } else if (stateName === 'battle') {
    const monName = monarchName(),
      instructions = (monName === 'monarch') ?
        "Destroy your opponent's monarch, protect your monarch" :
        "Capture your opponent's flag, protect your flag";
    Instructions.dropdown(`battle-${monName}`, instructions);
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
  Soundtrack.setSoundtrack(newstate);
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
