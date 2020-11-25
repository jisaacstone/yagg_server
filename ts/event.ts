import { getname } from './urlvars.js';
import { gameaction } from './request.js';
import { gmeta, gamestatechange, turnchange } from './state.js';
import * as Select from './select.js';
import * as Unit from './unit.js';
import { SKULL } from './constants.js';
import * as Board from './board.js';
import * as readyButton from './ready.js';
import * as Dialog from './dialog.js';
import * as Jobfair from './jobfair.js';
import * as Overlay from './overlay.js';
import * as Player from './playerdata.js';
import * as Feature from './feature.js';
import * as Hand from './hand.js';

const unitsbyindex = {};

export function game_started(event) {
  const board = document.getElementById('board'),
    state = (event.state || '').toLowerCase();
  Hand.clear();
  if (event.army_size || gmeta.phase === 'jobfair') {
    if (gmeta.boardstate === 'gameover') {
      Board.clear();
    } else {
      Overlay.clear();
    }
    gamestatechange(state || 'jobfair');
    Jobfair.render(event.army_size);
  } else {
    Overlay.clear();
    Jobfair.clear();
    if (event.dimensions) {
      Board.render(board, event.dimensions.x, event.dimensions.y);
    }
    gamestatechange(state || 'placement');
    if (state === 'placement' || state === 'gameover') {
      readyButton.display(state === 'placement' ? 'READY' : 'REMATCH');
    }
  }
}

export function battle_started() {
  gamestatechange('battle');
}

export function player_joined(event) {
  const nameEl = document.createElement('div'),
    player = Player.getLocal(),
    whois = event.name === player.name ? 'player' : 'opponent',
    container = document.getElementById(whois);
  if (container.firstElementChild && container.firstElementChild.className === 'playername') {
    return;
  }
  nameEl.className = 'playername';
  nameEl.innerHTML = event.name;
  container.appendChild(nameEl);
  if (whois === 'player') {
    gmeta.position = event.position;
  }
}

export function player_left(event) {
  document.getElementById(`${event.player}name`).innerHTML = '';
}

export function add_to_hand(event) {
  const unitEl = Hand.createCard(event.unit, event.index)
  unitsbyindex[event.index] = unitEl;
}

export function unit_assigned(event) {
  const square = document.getElementById(`c${event.x}-${event.y}`),
    unit = unitsbyindex[event.index];
  square.appendChild(unit);
}

export function new_unit(event) {
  const square = Board.square(event.x, event.y),
    unit = square.firstElementChild as HTMLElement;
  if (!unit) {
    const newunit = Unit.render(event.unit, 0);
    square.appendChild(newunit);
  } else {
    unit.innerHTML = '';
    Unit.render_into(event.unit, unit, true);
  }
}

export function unit_changed(event) {
  new_unit(event);  // for now
}

export function unit_placed(event) {
  const square = document.getElementById(`c${event.x}-${event.y}`);
  if (! square.firstChild) {
    const unit = Unit.render(event, null)
    square.appendChild(unit);
  }
}

export function player_ready(event) {
  if ( event.player === gmeta.position ) {
    (document.querySelector('#player .playername') as HTMLElement).dataset.ready = 'true';
    readyButton.hide();
  } else {
    (document.querySelector('#opponent .playername') as HTMLElement).dataset.ready = 'true';
  }
}

export function feature(event) {
  const square = document.getElementById(`c${event.x}-${event.y}`),
    feature = Feature.render(event.feature);;
  square.appendChild(feature);
}

export function unit_died(event) {
  const square = document.getElementById(`c${event.x}-${event.y}`),
    unit = square.firstChild as HTMLElement,
    animation = unit.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" });
  unit.innerHTML = `<div class="death">${SKULL}</div>`;
  const aniPromise = animation.finished.then(() => {
    unit.remove();
  });
  return { animation: aniPromise, squares: [`${event.x},${event.y}`] };
}

export function thing_moved(event) {
  const to = Board.square(event.to.x, event.to.y),
    from = Board.square(event.from.x, event.from.y),
    thing = from.firstChild as HTMLElement;
  if (to) {
    const child = to.firstChild as HTMLElement,
      fromRect = from.getBoundingClientRect(),
      toRect = to.getBoundingClientRect(),
      thingRect = thing.getBoundingClientRect(),
      animation = thing.animate({ 
        top: [fromRect.top + 'px', toRect.top + 'px'],
        left: [fromRect.left + 'px', toRect.left + 'px'],
      }, { duration: 200, easing: 'ease-in-out' });
    Object.assign(thing.style, {
      position: 'fixed',
      width: thingRect.width + 'px',
      height: thingRect.height + 'px',
    });
    to.appendChild(thing);
    const aniPromise = animation.finished.then(() => {
      thing.style.position = '';
      thing.style.width = '';
      thing.style.height = '';
      console.log(`animation ${event.to.x},${event.to.y} finished`);
    });
    return { animation: aniPromise, squares: [`${event.to.x},${event.to.y}`, `${event.from.x},${event.from.y}`] };
  } else {
    if (thing) {
      thing.className = thing.className.replace(' owned', '');
    }
    thing_gone(event.from);
  }
}

export function thing_gone(event) {
  const square = Board.square(event.x, event.y),
    thing = square.firstChild as HTMLElement;
  if (thing.className.includes('owned')) {
    thing.dataset.state = 'invisible';
  } else {
    const animation = thing.animate({ opacity: [1, 0] }, { duration: 1000, easing: "ease-in" }),
    aniPromise = animation.finished.then(() => {
      thing.remove();
    });
    return { animation: aniPromise, squares: [`${event.x},${event.y}`] }
  }
}

export function gameover(event) {
  const message = event.winner === gmeta.position ? 'you win!' : 'you lose';
  gamestatechange('gameover');
  document.getElementById('gamestate').innerHTML = `state: gameover, winner: ${event.winner}!`;
  turnchange(null);
  Dialog.displayMessage(message);
  readyButton.display('REMATCH');
}

export function turn(event) {
  turnchange(event.player);
}

export function candidate(event) {
  const jf = document.getElementById('jobfair'),
    existing = document.getElementById(`candidate-${event.index}`);
  if (existing) {
    return;
  }
  const cdd = document.createElement('div'),
    unitEl = Unit.render(event.unit, event.index, true);
  cdd.className = 'candidate';
  cdd.id = `candidate-${event.index}`;
  cdd.appendChild(unitEl);
  Select.bind_candidate(cdd, event.index);
  unitEl.addEventListener('dblclick', Unit.detailViewFn(event.unit, unitEl.className));
  jf.appendChild(cdd);
}
