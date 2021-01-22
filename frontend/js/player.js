import { _name_ } from './urlvars.js';
import { post, request } from './request.js';
import * as Dialog from './dialog.js';
import * as Element from './element.js';
const state = {
    waiting: false
};
function create() {
    if (state.waiting) {
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
    });
}
export function check() {
    const id = localStorage.getItem('playerData.id'), name = localStorage.getItem('playerData.name');
    if (id && name) {
        return request(`player/${id}`, false).then((resp) => {
            if (resp.name !== name) {
                console.log('warning: name mismatch');
                localStorage.setItem('playerData.name', resp.name);
            }
            return { id, name: resp.name };
        }).catch(() => {
            return post('player/guest', { id, name })
                .catch((err) => {
                console.error({ message: 'error recreating guest account', err });
                console.log({ "localstorage": "removePlayerData", id, name });
                localStorage.removeItem('playerData.id');
                localStorage.removeItem('playerData.name');
                return create();
            })
                .finally(() => {
                state.waiting = false;
            });
        }).then(({ id, name }) => {
            return { id, name };
        });
    }
    return create();
}
export function get() {
    const id = localStorage.getItem('playerData.id'), name = localStorage.getItem('playerData.name');
    if (id && name) {
        return Promise.resolve({ id, name });
    }
    return create();
}
export function getLocal() {
    const id = localStorage.getItem('playerData.id'), name = localStorage.getItem('playerData.name');
    return { id, name };
}
export function avatar({ id, name }) {
    // avatar is radomly chosen based on ui and colored based on name
    let nameToNum = 0, i = name.length;
    while (i--) {
        nameToNum += +name.charCodeAt(i);
    }
    const el = Element.create({ className: 'avatar', tag: 'img' });
    el.setAttribute('src', `img/avatar_${+id % 8}.png`);
    el.style.filter = `hue-rotate(${nameToNum % 36}0deg)`;
    return el;
}
export function render(player) {
    return Element.create({
        className: 'playerdetails',
        children: [
            Element.create({ className: 'playername', innerHTML: player.name }),
            avatar(player),
            Element.create({ className: 'timer' })
        ]
    });
}
