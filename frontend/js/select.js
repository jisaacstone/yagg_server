import { action } from './request.js';
import { gmeta } from './state.js';
import * as Ready from './ready.js';
import * as Jobfair from './jobfair.js';
import * as Unit from './unit.js';
import * as Element from './element.js';
import * as SFX from './sfx.js';
import * as Soundtrack from './soundtrack.js';
const global = { selected: null };
export function selected() {
    if (global.selected === null) {
        return false;
    }
    if (Object.keys(global.selected).length === 0) {
        return false;
    }
    return true;
}
function ismoveoption(el) {
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
export function deselect() {
    const selected = global.selected, rb = document.getElementById('returnbutton');
    if (selected && selected.element) {
        selected.element.dataset.uistate = '';
        for (const opt of selected.options) {
            opt.dataset.uistate = '';
        }
    }
    global.selected = {};
    Unit.clearButtonOverlay();
    if (rb) {
        rb.remove();
    }
}
function moveOrPlace(selected, target) {
    if (selected.element !== target.element) {
        if (selected.meta.inhand) {
            action('place', { index: selected.meta.index, x: target.meta.x, y: target.meta.y }, selected.meta.unit.attributes.includes('monarch') ? Ready.ensureDisplayed() : null);
        }
        else {
            // clickd on a board square
            if (gmeta.boardstate === 'battle') {
                action('move', { from_x: selected.meta.x, from_y: selected.meta.y, to_x: target.meta.x, to_y: target.meta.y });
            }
            else {
                // change placement
                const index = Unit.indexOf(selected.element);
                action('place', { index: index, x: target.meta.x, y: target.meta.y });
            }
        }
    }
    deselect();
}
function displayReturnButton(el, meta) {
    const buttons = document.getElementById('buttons'), button = Element.create({
        tag: 'button',
        className: 'uibutton',
        id: 'returnbutton',
        innerHTML: 'return to hand'
    });
    button.onclick = () => {
        SFX.play('click');
        action('return', { index: Unit.indexOf(el) }, deselect);
    };
    buttons.appendChild(button);
}
function handleSomethingAlreadySelected(el, meta) {
    // return "true" if select event was handled, false if logic should continue
    const sel = global.selected;
    if (sel && sel.element) {
        if (!sel.element.firstChild) {
            console.log({ error: 'no child of selected element', sel, el, meta });
            deselect();
            return true;
        }
        if (sel.element === el) {
            // clicking the same thing again deselects
            deselect();
            return true;
        }
        // something was perviously selected
        if (Unit.containsOwnedUnit(el) || (meta.inhand && sel.meta.inhand)) {
            // if we are clicking on another of our units ignore previously selected unit
            deselect();
            return false;
        }
        else if (sel.options && !sel.options.includes(el)) {
            console.log('not in options');
            // for now ignore clicks on things that are not move options
            return true;
        }
        else {
            moveOrPlace(sel, { element: el, meta });
            return true;
        }
    }
    return false;
}
function audioFor(el) {
    if (!el) {
        return 'buzz';
    }
    if (!el.dataset.name) {
        return 'select';
    }
    return el.dataset.name;
}
function handleSelect(el, meta) {
    const options = [], audio = audioFor(el.firstElementChild);
    if (meta.inhand || (gmeta.boardstate === 'placement' && Unit.containsOwnedUnit(el))) {
        Array.prototype.forEach.call(document.querySelectorAll(`.${gmeta.position}row .boardsquare`), el => {
            if (!el.firstChild) {
                el.dataset.uistate = 'moveoption';
                options.push(el);
            }
        });
        if (meta.ongrid) {
            displayReturnButton(el, meta);
        }
    }
    else {
        // on board
        if (!Unit.containsOwnedUnit(el)) {
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
    SFX.play(audio);
    Unit.overlayInfo(el.firstChild);
    el.dataset.uistate = 'selected';
    global.selected = { element: el, meta: meta, options: options };
}
export function select(thisEl, meta) {
    function select() {
        Soundtrack.play();
        if (gmeta.boardstate === 'gameover') {
            return;
        }
        else if (gmeta.boardstate === 'battle' && (gmeta.position !== gmeta.turn || // not your turn
            (!meta.inhand && thisEl.firstChild && thisEl.firstChild.className.includes('immobile')) // cannot move
        )) {
            return;
        }
        if (handleSomethingAlreadySelected(thisEl, meta)) {
            return;
        }
        handleSelect(thisEl, meta);
    }
    return select;
}
export function bind_hand(card, index, unit) {
    card.onclick = select(card, { inhand: true, index, unit });
}
export function bind_candidate(candidate, index, unit) {
    candidate.onclick = (e) => {
        Soundtrack.play();
        const childEl = candidate.firstElementChild, audio = unit.name;
        if (candidate.dataset.uistate === 'selected') {
            if (Jobfair.deselect(index)) {
                SFX.play('deselect');
                candidate.dataset.uistate = '';
            }
        }
        else {
            if (Jobfair.select(index)) {
                if (childEl) {
                    SFX.play(audio);
                    candidate.dataset.uistate = 'selected';
                }
            }
        }
    };
}
