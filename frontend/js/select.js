import { gameaction } from './request.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
import * as Ready from './ready.js';
import * as Jobfair from './jobfair.js';
import * as Unit from './unit.js';
import * as Infobox from './infobox.js';
import * as Element from './element.js';
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
function action(actType, args, cb = null) {
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
            }
            else if (request.responseText.includes('noselfattack')) {
                displayerror('you cannot attack your own units');
            }
            else if (request.responseText.includes('illegal')) {
                displayerror('illegal move');
            }
        }
    });
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
    if (selected.element) {
        selected.element.dataset.uistate = '';
        for (const opt of selected.options) {
            opt.dataset.uistate = '';
        }
    }
    global.selected = {};
    Infobox.clear();
    if (rb) {
        rb.remove();
    }
}
function moveOrPlace(selected, target) {
    if (selected.element !== target.element) {
        if (selected.meta.inhand) {
            action('place', { index: selected.meta.index, x: target.meta.x, y: target.meta.y }, selected.meta.attributes.includes('monarch') ? Ready.ensureDisplayed() : null);
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
            maybeSidebar(el);
            return true;
        }
        else {
            moveOrPlace(sel, { element: el, meta });
            return true;
        }
    }
    return false;
}
function maybeSidebar(el) {
    const childEl = el.firstChild;
    if (childEl) {
        childEl.dispatchEvent(new Event('sidebar'));
    }
}
function handleSelect(el, meta) {
    const options = [];
    maybeSidebar(el);
    console.log('sidebard');
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
    el.dataset.uistate = 'selected';
    global.selected = { element: el, meta: meta, options: options };
}
export function select(thisEl, meta) {
    function select() {
        if ((gmeta.boardstate === 'gameover') ||
            (gmeta.boardstate === 'battle' && gmeta.position !== gmeta.turn) || // not your turn
            (!meta.inhand && thisEl.firstChild && thisEl.firstChild.className.includes('immobile'))) {
            maybeSidebar(thisEl);
            return;
        }
        if (handleSomethingAlreadySelected(thisEl, meta)) {
            return;
        }
        handleSelect(thisEl, meta);
    }
    return select;
}
export function bind_hand(card, index, player, attributes) {
    card.onclick = select(card, { inhand: true, index, player, attributes });
}
export function bind_candidate(candidate, index) {
    candidate.onclick = (e) => {
        const childEl = candidate.firstElementChild;
        Infobox.clear();
        if (candidate.dataset.uistate === 'selected') {
            if (Jobfair.deselect(index)) {
                candidate.dataset.uistate = '';
            }
        }
        else {
            if (Jobfair.select(index)) {
                childEl && childEl.dispatchEvent(new Event('sidebar'));
                candidate.dataset.uistate = 'selected';
            }
        }
    };
}
