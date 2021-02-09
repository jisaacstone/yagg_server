import { _name_ } from './urlvars.js';
import { post, request } from './request.js';
import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as Storage from './storage.js';

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
      Storage.setItem('playerData', 'id', id);
      Storage.setItem('playerData', 'name', name);
      return { id, name };
    })
    .finally(() => {
      state.waiting = false;
    })
}

export function check(): Promise<PlayerData> {
  const id = Storage.getItem('playerData', 'id'),
    name = Storage.getItem('playerData', 'name');
  if (id && name) {
    return request(`player/${id}`, false).then((resp: any) => {
      if (resp.name !== name) {
        console.log('warning: name mismatch');
        Storage.setItem('playerData', 'name', resp.name);
      }
      return { id, name: resp.name };
    }).catch(() => {
      return post('player/guest', { id, name })
        .catch((err) => {
          console.error({ message: 'error recreating guest account', err });
          console.log({"localstorage": "removePlayerData", id, name});
          Storage.removeItem('playerData', 'id');
          Storage.removeItem('playerData', 'name');
          return create();
        })
        .finally(() => {
          state.waiting = false;
        })
    }).then(({ id, name }) => {
      return { id, name };
    });
  }
  return create();
}

export function get(): Promise<PlayerData> {
  const id = Storage.getItem('playerData', 'id'),
    name = Storage.getItem('playerData', 'name');
  if (id && name) {
    return Promise.resolve({ id, name });
  }
  return create();
}

export function getLocal(): PlayerData {
  const id = Storage.getItem('playerData', 'id'),
    name = Storage.getItem('playerData', 'name');
  return { id, name };
}

export function avatar({ id, name }): HTMLElement {
  // avatar is radomly chosen based on ui and colored based on name
  let nameToNum = 0, i = name.length;
  while(i--) {
    nameToNum += +name.charCodeAt(i);
  }
  const el = Element.create({ className: 'avatar', tag: 'img' });
  el.setAttribute('src', `img/avatar_${+id % 9}.png`);
  el.style.filter = `hue-rotate(${nameToNum % 36}0deg)`;
  return el;
}

export function render(player: PlayerData): HTMLElement {
  return Element.create({
    className: 'playerdetails',
    children: [
      Element.create({ className: 'playername', innerHTML: player.name }),
      avatar(player),
      Element.create({ className: 'timer' })
    ]
  });
}
