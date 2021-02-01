import { gameaction } from './request.js';
import { gmeta } from './state.js';
import { displayerror } from './err.js';
import * as Ready from './ready.js';
import * as Jobfair from './jobfair.js';
import * as Unit from './unit.js';
import * as Infobox from './infobox.js';
import * as Element from './element.js';
import * as SFX from './sfx.js';
import * as Dialog from './dialog.js';

const global = { selected: null };

export function selected(): boolean {
  if (global.selected === null) { return false }
  if (Object.keys(global.selected).length === 0) { return false }
  return true;
}

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
        } else if (request.responseText.includes('empty')) {
          //UI is messed up most likely
          Dialog.alert('oops, something went wrong').then(() => {
            window.location = window.location;
          });
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

export function deselect() {
  const selected = global.selected,
    rb = document.getElementById('returnbutton');
  if (selected && selected.element) {
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
      action(
        'place',
        {index: selected.meta.index, x: target.meta.x, y: target.meta.y},
        selected.meta.unit.attributes.includes('monarch') ? Ready.ensureDisplayed() : null,
      );
    } else {
      // clickd on a board square
      if (gmeta.boardstate === 'battle') {
        action('move', {from_x: selected.meta.x, from_y: selected.meta.y, to_x: target.meta.x, to_y: target.meta.y});
      } else {
        // change placement
        const index = Unit.indexOf(selected.element);
        action('place', {index: index, x: target.meta.x, y: target.meta.y});
      }
    }
  }
  deselect();
}

function displayReturnButton(el, meta) {
  const buttons = document.getElementById('buttons'),
    button = Element.create({
      tag: 'button',
      className: 'uibutton',
      id: 'returnbutton',
      innerHTML: 'return to hand'
    });
  button.onclick = () => {
    SFX.play('click');
    action(
      'return',
      {index: Unit.indexOf(el)},
      deselect,
    )
  }
  buttons.appendChild(button);
}

function handleSomethingAlreadySelected(el: HTMLElement, meta): boolean {
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
    } else if (sel.options && !sel.options.includes(el)) {
      console.log('not in options');
      // for now ignore clicks on things that are not move options
      maybeSidebar(el);
      return true;
    } else {
      moveOrPlace(sel, { element: el, meta });
      return true;
    }
  }
  return false;
}

function maybeSidebar(el: HTMLElement) {
  const childEl = el.firstChild;
  if (childEl) {
    childEl.dispatchEvent(new Event('sidebar'));
  }
}

function audioFor(el: HTMLElement) {
  if (!el) {
    return 'buzz';
  }
  if (!el.dataset.name) {
    return 'select';
  }
  return el.dataset.name;
}

function handleSelect(el: HTMLElement, meta) {
  const options = [], audio = audioFor(el.firstElementChild as HTMLElement);
  maybeSidebar(el);
  if (meta.inhand || (gmeta.boardstate === 'placement' && Unit.containsOwnedUnit(el))) {
    Array.prototype.forEach.call(
      document.querySelectorAll(`.${gmeta.position}row .boardsquare`),
      el => {
        if (! el.firstChild) {
          el.dataset.uistate = 'moveoption';
          options.push(el);
        }
      }
    );
    if (meta.ongrid) {
      displayReturnButton(el, meta);
    }
  } else {
    if (! Unit.containsOwnedUnit(el)) {
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
  el.dataset.uistate = 'selected';
  global.selected = {element: el, meta: meta, options: options};
}

export function select(thisEl, meta) {
  function select() {
    SFX.startMusic();
    if (gmeta.boardstate === 'gameover') {
      maybeSidebar(thisEl);
      return;
    } else if (gmeta.boardstate === 'battle' && (
      gmeta.position !== gmeta.turn ||  // not your turn
      (!meta.inhand && thisEl.firstChild && thisEl.firstChild.className.includes('immobile')) // cannot move
    )){
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

export function bind_hand(card: HTMLElement, index: number, unit: Unit.Unit) {
  card.onclick = select(card, { inhand: true, index, unit });
}

export function bind_candidate(candidate: HTMLElement, index: number, unit: Unit.Unit) {
  candidate.onclick = (e) => {
    SFX.startMusic();
    const childEl = candidate.firstElementChild as HTMLElement,
      audio = unit.name;
    Infobox.clear();
    if (candidate.dataset.uistate === 'selected') {
      if (Jobfair.deselect(index)) {
        SFX.play('deselect');
        candidate.dataset.uistate = '';
      }
    } else {
      if (Jobfair.select(index)) {
        if (childEl) {
          SFX.play(audio);
          childEl.dispatchEvent(new Event('sidebar'));
          candidate.dataset.uistate = 'selected';
          candidateAnimate(childEl, unit.name);
        }
      }
    }
  };
}

function candidateAnimate(el: HTMLElement, seed: string) {
  // fun little animation for selected candidates
  const rs = `${seed} *-();%#`,
    biglittle = 6 + rs.charCodeAt(0) % 5 + rs.charCodeAt(1) % 6,
    topbottom = 2 + rs.charCodeAt(2) % 7,
    leftright = 34 + (rs.charCodeAt(3) % 10) + (rs.charCodeAt(4) % 10) + (rs.charCodeAt(5) % 10),
    dur = 300 + (rs.charCodeAt(6) % 9) * 17 + (rs.charCodeAt(7) % 9) * 13,
    size = biglittle === 10 ? '90% 95%' : `${biglittle}0% ${biglittle}0%`,
    pos = `${leftright}% ${topbottom}0%`;
  return;
  el.animate({
    backgroundSize: ['100% 100%', '99% 99%', size, '100% 100%'],
    backgroundPosition: ['50% 50%', pos, '50% 50%']
  }, {
    duration: dur,
    easing: 'ease-in-out'
  });
}
