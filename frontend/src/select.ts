import { gameaction } from './request.js';

const global = { selected: null };

export function select(thisEl, meta) {
  function select() {
    const sel = global.selected;
    if (sel) {
      // something was perviously selected
      if (sel.element !== thisEl) {
        if (sel.meta.ongrid && sel.meta.inhand) {
          return;  // should not happen
        }
        if (sel.meta.inhand) {
          gameaction('place', {index: sel.meta.index, x: meta.x, y: meta.y}, 'board');
        } else {
          gameaction('move', {from_x: sel.meta.x, from_y: sel.meta.y, to_x: meta.x, to_y: meta.y}, 'board');
        }
      }
      sel.element.dataset.uistate = '';
      for (const opt of sel.options) {
        opt.dataset.uistate = '';
      }
      global.selected = null;
    } else {
      thisEl.dataset.uistate = 'selected';
      const options = [];
      if (meta.inhand) {
        Array.prototype.map.call(
          document.querySelectorAll(`.${meta.player}row .boardsquare`),
          el => {
            el.dataset.uistate = 'moveoption';
            options.push(el);
          }
        );
      } else {
        for (const neighbor of [[meta.x + 1, meta.y], [meta.x - 1, meta.y], [meta.x, meta.y + 1], [meta.x, meta.y - 1]]) {
          const nel = document.getElementById(`c${neighbor[0]}-${neighbor[1]}`);
          if (nel) {
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

