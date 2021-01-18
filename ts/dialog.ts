import * as Overlay from './overlay.js';
import * as Element from './element.js';

export function displayMessage(message: string, cls='info') {
  const messageEl = Element.create({
    innerHTML: message,
    className: `message ${cls}`
  });
  Overlay.dismissable(messageEl);
}

export function alert(message: string, confirm='ok'): Promise<boolean> {
  const okEl = Element.create({
      className: 'uibutton',
      innerHTML: confirm
    }), 
    alertEl = Element.create({
      className: 'message alert',
      children: [
        Element.create({ innerHTML: message }),
        okEl
      ]
    }),
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
    promptEl = Element.create({
      className: 'message prompt',
      children: [
        Element.create({ innerHTML: message }),
        inputEl,
        okEl
      ]
    }),
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
    promptEl = Element.create({
      className: 'message confirm',
      children: [
        Element.create({ innerHTML: message }),
        okEl,
        cancelEl
      ]
    }),
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
  const promptEl = Element.create({
      className: 'message choices',
      children: [
        Element.create({ innerHTML: message }),
      ]
    }),
    clearOverlay = Overlay.clearable(promptEl);

  for (let [choice, effect] of Object.entries(choices)) {
    const choiceEl = Element.create({
      tag: 'button',
      className: 'uibutton',
      innerHTML: choice,
    });
    choiceEl.onclick = () => {
      clearOverlay();
      effect();
    };
    promptEl.appendChild(choiceEl);
  }
}
