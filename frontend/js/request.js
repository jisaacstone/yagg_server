import { hostname, getname, tableid } from './urlvars.js';
import * as Player from './player.js';
import * as Infobox from './infobox.js';
import * as Dialog from './dialog.js';
const dn = { name: null };
function _name_() {
    // random name
    if (!dn.name) {
        dn.name = [...Array(8)].map(() => Math.random().toString(36)[2]).join('');
    }
    return dn.name;
}
function add_auth(request, method, url) {
    // still no auth, get player name from query params
    const name = getname() || _name_();
    return request;
}
export function action(actType, args, cb = null) {
    gameaction(actType, args, 'board')
        .then(() => {
        if (cb) {
            cb();
        }
    })
        .catch(({ request }) => {
        if (request.status === 400) {
            if (request.responseText.includes('occupied')) {
                Dialog.displayError('space is already occupied');
            }
            else if (request.responseText.includes('noselfattack')) {
                Dialog.displayError('you cannot attack your own units');
            }
            else if (request.responseText.includes('illegal')) {
                Dialog.displayError('illegal move');
            }
            else if (request.responseText.includes('empty')) {
                //UI is messed up most likely
                Dialog.alert('oops, something went wrong').then(() => {
                    window.location = window.location;
                });
            }
        }
    });
}
export function gameaction(action, data, scope = 'table', id = null, retries = 1) {
    const tableId = id || tableid();
    const host = hostname(), url = `${host}/${scope}/${tableId}/a/${action}`;
    return Player.get().then(({ id }) => {
        Infobox.clear();
        return new Promise(function (resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.addEventListener('load', function () {
                if (xhr.status < 200 || xhr.status >= 300) {
                    reject({ request: xhr });
                }
                else {
                    resolve(xhr);
                }
            });
            xhr.onerror = function () {
                if (retries) {
                    console.warn({ retries, action, scope });
                    setTimeout(() => {
                        gameaction(action, data, scope, id, retries - 1).then((r) => {
                            resolve(r);
                        }).catch((e) => {
                            reject(e);
                        });
                    }, 500);
                }
                else {
                    reject({ request: xhr });
                }
            };
            xhr.open('POST', url);
            xhr.setRequestHeader('Content-Type', 'application/json');
            xhr.setRequestHeader('X-Userid', id);
            xhr.send(JSON.stringify(data || {}));
        });
    });
}
export function request(path, auth = true) {
    const host = hostname(), url = `${host}/${path}`, idfn = auth ? Player.get : () => Promise.resolve({ id: null });
    return idfn().then(({ id }) => {
        return new Promise(function (resolve, reject) {
            var xhr = new XMLHttpRequest();
            xhr.addEventListener('load', function () {
                if (xhr.status < 200 || xhr.status >= 300) {
                    reject({ request: xhr });
                }
                else {
                    try {
                        resolve(JSON.parse(xhr.responseText));
                    }
                    catch (e) {
                        reject(e);
                    }
                }
            });
            xhr.onerror = function (e) {
                console.log({ r: 'ONERRR', e });
                reject({ request: xhr });
                throw e;
            };
            xhr.open('GET', url);
            xhr.setRequestHeader('X-Userid', id);
            xhr.send();
        });
    });
}
export function post(path, body) {
    const host = hostname(), url = `${host}/${path}`;
    return new Promise(function (resolve, reject) {
        var xhr = new XMLHttpRequest();
        xhr.addEventListener('load', function () {
            if (xhr.status < 200 || xhr.status >= 300) {
                console.log({ status: xhr.status, text: xhr.responseText });
                reject({ request: xhr });
            }
            else {
                try {
                    resolve(JSON.parse(xhr.responseText));
                }
                catch (e) {
                    reject(e);
                }
            }
        });
        xhr.onerror = function () {
            reject({ request: xhr });
        };
        xhr.open('POST', url);
        xhr.setRequestHeader('Content-Type', 'application/json');
        xhr.send(JSON.stringify(body || {}));
    });
}
;
