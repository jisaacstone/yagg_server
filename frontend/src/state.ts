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

export function gamestatechange(newstate: string): void {
  document.getElementById('gamestate').innerHTML = `state: ${newstate}`;
  document.getElementsByTagName('body')[0].dataset.gamestate = newstate;
  gmeta.boardstate = newstate;
  Array.prototype.forEach.call(
    document.getElementsByClassName('playername') as HTMLCollectionOf<HTMLInputElement>,
    el => {
      el.dataset.ready = null;
    }
  );
}

export function turnchange(player) {
  gmeta.turn = player;
  if (player == null) {
    document.getElementsByTagName('body')[0].dataset.turn = null;
    (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'false';
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'false';
  } else if (player === gmeta.position) {
    document.getElementsByTagName('body')[0].dataset.turn = 'player';
    (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'true';
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'false';
  } else {
    document.getElementsByTagName('body')[0].dataset.turn = 'opponent';
    (document.querySelector('#player .playername') as HTMLElement).dataset.turn = 'false';
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.turn = 'true';
  }
}
