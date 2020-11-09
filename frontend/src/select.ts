import { gameaction } from './request.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
import * as Ready from './ready.js';
import * as Jobfair from './jobfair.js';
import * as Unit from './unit.js';

const global = { selected: null };

function action(actType, args, cb=null) {
  gameaction(actType, args, 'board')
    .then(() => {
      if (cb) {
        cb();
      }
    })
    .catch(({ request }) => {
      if (request.status === 400) {
        if (request.responseText.includes('occupied')) {
          displayerror('space is already occupied');
        } else if (request.responseText.includes('noselfattack')) {
          displayerror('you cannot attack your own units');
        } else if (request.responseText.includes('illegal')) {
          displayerror('illegal move');
        }
      }
    });
}

function ismoveoption(el: HTMLElement) {
  if (!el) {
    return false;
  }
  if (el.firstElementChild) {
    if (el.firstElementChild.className.includes(gmeta.position)) {
      return false;
    } 
    if (el.firstElementChild.className.includes('water')) {
      return false;
    } 
  }
  return true;
}

export function deselect(sel = null) {
  var selected = sel || global.selected;
  selected.element.dataset.uistate = '';
  for (const opt of selected.options) {
    opt.dataset.uistate = '';
  }
  selected = {};
  document.getElementById('infobox').innerHTML='';
}

function moveOrPlace(selected, target) {
  if (selected.element !== target.element) {
    if (selected.meta.inhand) {
      action(
        'place',
        {index: selected.meta.index, x: target.meta.x, y: target.meta.y},
        selected.meta.unit_name === 'monarch' ? Ready.ensureDisplayed() : null,
      );
    } else {
      // clickd on a board square
      if (gmeta.boardstate === 'battle') {
        action('move', {from_x: selected.meta.x, from_y: selected.meta.y, to_x: target.meta.x, to_y: target.meta.y});
      } else {
        // change placement
        const index = +selected.element.firstChild.dataset.index;
        action('place', {index: index, x: target.meta.x, y: target.meta.y});
      }
    }
  }
  deselect(selected);
}

export function select(thisEl, meta) {
  function select() {
    if (gmeta.boardstate === 'gameover') {
      return;
    }
    const sel = global.selected;
    if (sel && sel.element && sel.element.firstChild) {
      // something was perviously selected
      if (Unit.containsOwnedUnit(thisEl) || (meta.inhand && sel.meta.inhand)) {
        // if we are clicking on another of our units ignore previously selected unit
        deselect(global.selected);
      } else {
        return moveOrPlace(sel, { element: thisEl, meta });
      }
    }
    if (gmeta.boardstate === 'battle' && gmeta.position !== gmeta.turn) {
      // Not your turn
      return;
    }
    const options = [];
    const childEl = thisEl.firstChild;
    if (meta.inhand || gmeta.boardstate === 'placement') {
      thisEl.dataset.uistate = 'selected';
      Array.prototype.forEach.call(
        document.querySelectorAll(`.${meta.player}row .boardsquare`),
        el => {
          if (! el.firstChild) {
            el.dataset.uistate = 'moveoption';
            options.push(el);
          }
        }
      );
    } else {
      if (! Unit.containsOwnedUnit(thisEl)) {
        // Square with no owned unit
        return;
      }
      for (const neighbor of [[meta.x + 1, meta.y], [meta.x - 1, meta.y], [meta.x, meta.y + 1], [meta.x, meta.y - 1]]) {
        const nel = document.getElementById(`c${neighbor[0]}-${neighbor[1]}`);
        if (ismoveoption(nel)) {
          nel.dataset.uistate = 'moveoption';
          options.push(nel);
        }
      }
    }
    if (childEl) {
      childEl.dispatchEvent(new Event('sidebar'));
    }
    global.selected = {element: thisEl, meta: meta, options: options};
  }
  return select;
}

export function bind_hand(card: HTMLElement, index: number, player: string, unit_name: string) {
  card.onclick = select(card, { inhand: true, index, player, unit_name });
}

export function bind_candidate(candidate: HTMLElement, index: number) {
  candidate.onclick = (e) => {
    const childEl = candidate.firstElementChild;
    document.getElementById('infobox').innerHTML='';
    if (candidate.dataset.uistate === 'selected') {
      if (Jobfair.deselect(index)) {
        candidate.dataset.uistate = '';
      }
    } else {
      if (Jobfair.select(index)) {
        childEl && childEl.dispatchEvent(new Event('sidebar'));
        candidate.dataset.uistate = 'selected';
      }
    }
  };
}
