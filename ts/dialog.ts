import * as Overlay from './overlay.js';
import * as Element from './element.js';

export function createDialog(cls: string, ...children: HTMLElement[]): HTMLElement {
  // wrap so we can get drop-shadow effect
  const msgEl = Element.create({ className: `message ${cls}`, children });
  return Element.create({
    className: 'msg-wrapper',
    children: [ msgEl ]
  });
}

export function displayMessage(message: string, cls='info') {
  const messageEl = createDialog(cls, Element.create({ innerHTML: message }));
  Overlay.dismissable(messageEl);
}

export function alert(message: string, confirm='ok'): Promise<boolean> {
  const okEl = Element.create({
      className: 'uibutton',
      innerHTML: confirm
    }), 
    alertEl = createDialog(
      'alert',
      Element.create({ innerHTML: message }),
      okEl
    ),
    clearOverlay = Overlay.clearable(alertEl);
  return new Promise((resolve) => {
    okEl.onclick = () => {
      clearOverlay();
      resolve(true);
    };
  });
}

export function prompt(message: string, defaultv='', confirm='ok'): Promise<string> {
  const okEl = Element.create({
      className: 'uibutton',
      innerHTML: confirm
    }), 
    inputEl = Element.create({
      tag: 'input'
    }) as HTMLInputElement,
    promptEl = createDialog(
      'prompt',
      Element.create({ innerHTML: message }),
      inputEl,
      okEl
    ),
    clearOverlay = Overlay.clearable(promptEl);
  inputEl.setAttribute('type', 'text');
  inputEl.setAttribute('default', defaultv);
  return new Promise((resolve) => {
    okEl.onclick = () => {
      const value = inputEl.value;
      if (value) {
        clearOverlay();
        resolve(value);
      } else {
        displayMessage('you must enter something!', 'error');
      }
    };
  });
}

export function confirm(message: string, confirm='ok', cancel='cancel'): Promise<boolean> {
  const okEl = Element.create({
      className: 'uibutton',
      innerHTML: confirm
    }), 
    cancelEl = Element.create({
      className: 'uibutton',
      innerHTML: cancel
    }), 
    promptEl = createDialog(
      'confirm',
      Element.create({ innerHTML: message }),
      okEl,
      cancelEl
    ),
    clearOverlay = Overlay.clearable(promptEl);
  return new Promise((resolve) => {
    okEl.onclick = () => {
      clearOverlay();
      resolve(true);
    };
    cancelEl.onclick = () => {
      clearOverlay();
      resolve(false);
    };
  });
}

export function choices(message: string, choices: {[key: string]: () => any}) {
  const children = [ Element.create({ innerHTML: message }) ],
    choiceEls = [];
  for (let [choice, effect] of Object.entries(choices)) {
    const choiceEl = Element.create({
      tag: 'button',
      className: 'uibutton',
      innerHTML: choice,
    });
    choiceEls.push({ el: choiceEl, effect });
    children.push(choiceEl);
  }
  const promptEl = createDialog('choices', ...children),
    clearOverlay = Overlay.clearable(promptEl);
  for (const {el, effect} of choiceEls) {
    el.onclick = () => {
      clearOverlay();
      effect();
    };
  }
}
