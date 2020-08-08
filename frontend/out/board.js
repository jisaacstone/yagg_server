import { gameaction, request } from './request.js';
import { getname, tableid, _name_ } from './urlvars.js';
import { gmeta } from './state.js';
import { listen } from './eventlistener.js';
import * as overlay from './overlay.js';
import * as eventHandlers from './event.js';
function waitingforplayers() {
    const waiting = document.createElement('div'), copy = document.createElement('button'), comp = document.createElement('button'), over = overlay.create();
    over.className = over.className + ' waiting';
    waiting.innerHTML = 'waiting for opponent';
    over.appendChild(waiting);
    copy.innerHTML = 'copy join link';
    copy.className = 'linkcopy';
    copy.onclick = () => {
        const url = new URL(window.location.toString());
        url.searchParams.delete('player');
        navigator.clipboard.writeText(url.toString()).then(() => {
            alert('copied!');
        });
    };
    over.appendChild(copy);
    comp.innerHTML = 'play the computer';
    comp.className = 'aibutton';
    comp.onclick = function () {
        gameaction('ai', {}, 'table').then(() => {
            overlay.clear();
        });
    };
    over.appendChild(comp);
}
function fetchgamestate() {
    request(`table/${tableid()}/state`).then((gamedata) => {
        setstate(gamedata);
        request(`board/${tableid()}/player_state/${getname()}`).then((unitdata) => {
            for (const ob of unitdata.grid) {
                eventHandlers.new_unit(ob);
            }
            Array.prototype.forEach.call(Object.entries(unitdata.hand), ([index, card]) => {
                eventHandlers.add_to_hand({ index: +index, unit: card.unit });
                if (card.assigned) {
                    eventHandlers.unit_assigned({ index: +index, x: card.assigned.x, y: card.assigned.y });
                }
            });
        });
    });
}
function setstate(gamedata) {
    let players = 0;
    for (const player of gamedata.players) {
        eventHandlers.player_joined(player);
        players++;
    }
    if (gamedata.board) {
        eventHandlers.game_started(gamedata.board);
        if (players >= 2) {
            if (gamedata.board.ready) {
                eventHandlers.player_ready({ player: gamedata.board.ready });
            }
            Object.entries(gamedata.board.grid).forEach(([coor, feature]) => {
                if (feature) {
                    const [x, y] = coor.split(',');
                    if (feature.kind === 'unit') {
                        eventHandlers.unit_placed({ x, y, player: feature.player });
                    }
                    else {
                        eventHandlers.feature({ x, y, feature });
                    }
                }
            });
            eventHandlers.turn({ player: gamedata.turn });
        }
    }
    if (!gamedata.board || gamedata.board.state === 'open') {
        waitingforplayers();
    }
}
function namedialog() {
    const gn = getname();
    if (gn) {
        return gn;
    }
    const name = prompt('enter your name', _name_());
    history.pushState({ name }, '', `${window.location}&player=${name}`);
    return name;
}
window.onload = function () {
    const name = namedialog();
    gmeta.name = name;
    gameaction('join', { player: name }, 'table')
        .then(() => {
        fetchgamestate();
        listen(eventHandlers);
    }).catch((err) => {
        console.log({ joinerror: err });
        fetchgamestate();
        listen(eventHandlers);
    });
};
