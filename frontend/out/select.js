import { gameaction } from './request.js';
import { gmeta } from './state.js';
const global = { selected: null };
export function select(thisEl, meta) {
    function select() {
        if (gmeta.boardstate === 'gameover') {
            return;
        }
        const sel = global.selected;
        if (sel) {
            // something was perviously selected
            if (sel.element !== thisEl) {
                if (sel.meta.inhand) {
                    gameaction('place', { index: sel.meta.index, x: meta.x, y: meta.y }, 'board');
                }
                else {
                    console.log({ gmeta });
                    // clickd on a board square
                    if (gmeta.boardstate === 'battle') {
                        gameaction('move', { from_x: sel.meta.x, from_y: sel.meta.y, to_x: meta.x, to_y: meta.y }, 'board');
                    }
                    else {
                        // change placement
                        const index = +sel.element.firstChild.dataset.index;
                        gameaction('place', { index: index, x: meta.x, y: meta.y }, 'board');
                    }
                }
            }
            sel.element.dataset.uistate = '';
            for (const opt of sel.options) {
                opt.dataset.uistate = '';
            }
            global.selected = null;
        }
        else {
            const options = [];
            if (meta.inhand) {
                thisEl.dataset.uistate = 'selected';
                Array.prototype.forEach.call(document.querySelectorAll(`.${meta.player}row .boardsquare`), el => {
                    if (!el.firstChild) {
                        el.dataset.uistate = 'moveoption';
                        options.push(el);
                    }
                });
            }
            else {
                const childEl = thisEl.firstChild;
                if (!childEl || !childEl.className.includes(gmeta.position)) {
                    // Square with no owned unit
                    return;
                }
                else if (gmeta.boardstate === 'battle' && gmeta.position !== gmeta.turn) {
                    // Not your turn
                    return;
                }
                for (const neighbor of [[meta.x + 1, meta.y], [meta.x - 1, meta.y], [meta.x, meta.y + 1], [meta.x, meta.y - 1]]) {
                    const nel = document.getElementById(`c${neighbor[0]}-${neighbor[1]}`);
                    if (nel && !nel.firstChild) {
                        nel.dataset.uistate = 'moveoption';
                        options.push(nel);
                    }
                }
            }
            global.selected = { element: thisEl, meta: meta, options: options };
        }
    }
    return select;
}
