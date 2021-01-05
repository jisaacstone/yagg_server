import { _name_ } from './urlvars.js';
import { post, request } from './request.js';
import * as Dialog from './dialog.js';
import * as Element from './element.js';

interface PlayerData {
  id: string;
  name: string;
}

const state = {
  waiting: false
}

function create(): Promise<PlayerData> {
  if ( state.waiting ) {
    return Promise.reject('already waiting');
  }
  state.waiting = true;
  return Dialog
    .prompt('enter your name', _name_())
    .then((name) => {
      return post('player/guest', { name });
    })
    .then(({ id, name }) => {
      localStorage.setItem('playerData.id', id);
      localStorage.setItem('playerData.name', name);
      return { id, name };
    })
    .finally(() => {
      state.waiting = false;
    })
}

export function check() {
  const id = localStorage.getItem('playerData.id'),
    name = localStorage.getItem('playerData.name');
  if (id && name) {
    return request(`player/${id}`, false).then((resp: any) => {
      if (resp.name !== name) {
        console.log('warning: name mismatch');
        localStorage.setItem('playerData.name', resp.name);
      }
    }).catch(() => {
      return post('player/guest', { id, name })
        .catch((err) => {
          console.error({ message: 'error recreating guest account', err });
          console.log({"localstorage": "removePlayerData", id, name});
          localStorage.removeItem('playerData.id');
          localStorage.removeItem('playerData.name');
          return create();
        })
        .finally(() => {
          state.waiting = false;
        })
    });
  }
  return create();
}

export function get(): Promise<PlayerData> {
  const id = localStorage.getItem('playerData.id'),
    name = localStorage.getItem('playerData.name');
  if (id && name) {
    return Promise.resolve({ id, name });
  }
  return create();
}

export function getLocal(): PlayerData {
  const id = localStorage.getItem('playerData.id'),
    name = localStorage.getItem('playerData.name');
  return { id, name };
}

export function avatar({ id, name }): HTMLElement {
  // avatar is radomly chosen based on ui and colored based on name
  let nameToNum = 0, i = name.length;
  while(i--) {
    nameToNum += +name.charCodeAt(i);
  }
  const el = Element.create({ className: 'avatar', tag: 'img' });
  el.setAttribute('src', `img/avatar_${+id % 8}.png`);
  el.style.filter = `hue-rotate(${nameToNum % 36}0deg)`;
  return el;
}
