import { gameaction } from './request.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
import * as Ready from './ready.js';
import * as Jobfair from './jobfair.js';

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

export function select(thisEl, meta) {
  function select() {
    if (gmeta.boardstate === 'gameover') {
      return;
    }
    const sel = global.selected;
    if (sel && sel.element && sel.element.firstChild) {
      // something was perviously selected
      if (sel.element !== thisEl) {
        if (sel.meta.inhand) {
          action(
            'place',
            {index: sel.meta.index, x: meta.x, y: meta.y},
            sel.meta.unit_name === 'monarch' ? Ready.ensureDisplayed() : null,
          );
        } else {
          // clickd on a board square
          if (gmeta.boardstate === 'battle') {
            action('move', {from_x: sel.meta.x, from_y: sel.meta.y, to_x: meta.x, to_y: meta.y});
          } else {
            // change placement
            const index = +sel.element.firstChild.dataset.index;
            action('place', {index: index, x: meta.x, y: meta.y});
          }
        }
      }
      sel.element.dataset.uistate = '';
      for (const opt of sel.options) {
        opt.dataset.uistate = '';
      }
      global.selected = null;
    } else {
      if (gmeta.boardstate === 'battle' && gmeta.position !== gmeta.turn) {
        // Not your turn
        return;
      }
      const options = [];
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
        const childEl = thisEl.firstChild;
        if (! childEl || ! childEl.className.includes(gmeta.position)) {
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
      global.selected = {element: thisEl, meta: meta, options: options};
    }
  }
  return select;
}

export function bind_hand(card: HTMLElement, index: number, player: string, unit_name: string) {
  card.onclick = select(card, { inhand: true, index, player, unit_name });
}

export function bind_candidate(candidate: HTMLElement, index: number) {
  candidate.onclick = (e) => {
    if (candidate.dataset.uistate === 'selected') {
      if (Jobfair.deselect(index)) {
        candidate.dataset.uistate = '';
      }
    } else {
      if (Jobfair.select(index)) {
        candidate.dataset.uistate = 'selected';
      }
    }
  };
}
