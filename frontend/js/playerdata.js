import { _name_ } from './urlvars.js';
import { post, request } from './request.js';
function create() {
    const name = prompt('enter your name', _name_());
    return post('player/guest', { name: name }).then(({ id, name }) => {
        localStorage.setItem('playerData.id', id);
        localStorage.setItem('playerData.name', name);
        return { id, name };
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
        }).catch(() => {
            console.log({ "localstorage": "removePlayerData", id, name });
            localStorage.removeItem('playerData.id');
            localStorage.removeItem('playerData.name');
            return create();
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