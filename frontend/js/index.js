import { request, post, gameaction } from './request.js';
import * as Player from './playerdata.js';
function fetchConfigs(sel_el) {
    request('configurations').then((configs) => {
        for (const config of Object.keys(configs)) {
            const opt = document.createElement('option');
            opt.value = config;
            opt.innerHTML = config;
            sel_el.appendChild(opt);
        }
    });
}
function displayTableData(tablesEl, data) {
    const currentName = document.getElementById('name').value;
    if (!data.tables || !data.tables.length) {
        tablesEl.innerHTML = '<p>No open tables right now';
    }
    for (const table of data.tables) {
        if (currentName && table.players.some(({ name }) => name === currentName)) {
            const el = document.createElement('div');
            el.className = 'table';
            el.innerHTML = `REJOIN ${table.id}`;
            el.onclick = () => {
                window.location.href = `board.html?table=${table.id}&player=${currentName}`;
            };
            tablesEl.appendChild(el);
        }
        else if (table.players.length < 2) {
            const el = document.createElement('div');
            el.className = 'table';
            el.innerHTML = table.id;
            table.players.forEach(({ name }) => {
                const nel = document.createElement('div');
                nel.className = 'playername';
                nel.innerHTML = name;
                el.appendChild(nel);
            });
            el.onclick = () => {
                gameaction('join', {}, 'table', table.id).then(() => {
                    window.location.href = `board.html?table=${table.id}`;
                });
            };
            tablesEl.appendChild(el);
        }
    }
}
window.onload = function () {
    const tables = document.getElementById('tables'), ct = document.getElementById('createtable'), sel_el = document.getElementById('config');
    Player.check();
    request('table').then(tabledata => {
        console.log({ tabledata });
        displayTableData(tables, tabledata);
    }).catch((e) => console.log({ e }));
    fetchConfigs(sel_el);
    ct.onclick = () => {
        const conf = sel_el.value || 'random';
        post('table/new', { configuration: conf }).then(({ id }) => {
            gameaction('join', {}, 'table', id).then(() => {
                window.location.href = `board.html?table=${id}`;
            });
        });
    };
};
