import { getname, tableid, _name_ } from './urlvars.js';
import { gmeta } from './state.js';
import { listen } from './eventlistener.js';
import * as Request from './request.js';
import * as Overlay from './overlay.js';
import * as Event from './event.js';
import * as Jobfair from './jobfair.js';
import * as Board from './board.js';
function render_board(board, players) {
    if (players !== 2) {
        return;
    }
    Event.game_started(board);
    if (board.ready) {
        Event.player_ready({ player: board.ready });
    }
    Object.entries(board.grid).forEach(([coor, feature]) => {
        if (feature) {
            const [x, y] = coor.split(',');
            if (feature.kind === 'unit') {
                Event.unit_placed({ x, y, player: feature.player });
            }
            else {
                Event.feature({ x, y, feature });
            }
        }
    });
}
function render_jobfair(jobfair) {
    Jobfair.render(jobfair.army_size);
}
function render_(boardstate, phase, players) {
    if (phase === 'jobfair') {
        render_jobfair(boardstate);
    }
    else if (phase === 'board') {
        render_board(boardstate, players);
    }
}
function gamephase(board) {
    if (board.army_size !== undefined) {
        return 'jobfair';
    }
    else if (board.grid !== undefined) {
        return 'board';
    }
    return null;
}
function waitingforplayers() {
    const waiting = document.createElement('div'), copy = document.createElement('button'), comp = document.createElement('button'), over = Overlay.create();
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
        Request.gameaction('ai', {}, 'table').then(() => {
            Overlay.clear();
        });
    };
    over.appendChild(comp);
}
function fetchgamestate() {
    Request.request(`table/${tableid()}/state`).then((gamedata) => {
        const phase = gamephase(gamedata.board);
        if (setstate(gamedata, phase)) {
            Request.request(`board/${tableid()}/player_state/${getname()}`).then((unitdata) => {
                if (phase === 'jobfair') {
                    Jobfair.unitdata(unitdata);
                }
                else if (phase === 'board') {
                    Board.unitdata(unitdata);
                }
            });
        }
    });
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
    const name = namedialog(), errbutton = document.getElementById('errbutton');
    if (errbutton) {
        errbutton.onclick = () => {
            reporterr();
        };
    }
    gmeta.name = name;
    Request.gameaction('join', { player: name }, 'table')
        .then(() => {
        fetchgamestate();
        listen(Event);
    }).catch((err) => {
        console.log({ joinerror: err });
        fetchgamestate();
        listen(Event);
    });
};
function setstate(gamedata, phase) {
    console.log({ gamedata, phase });
    let players = 0;
    for (const player of gamedata.players) {
        Event.player_joined(player);
        players++;
    }
    render_(gamedata.board, phase, players);
    if (!gamedata.board || players == 1) {
        waitingforplayers();
    }
    if (gamedata.turn) {
        Event.turn({ player: gamedata.turn });
    }
    return players === 2; // continue and fetch player hands
}
function reporterr() {
    const reporttext = prompt("Report an error with game state", "describe the problem");
    Request.post(`table/${tableid()}/report`, { report: reporttext, meta: gmeta });
}
