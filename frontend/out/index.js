import { request, post, gameaction, hostname } from './request.js';
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
function _name_() {
    return [...Array(8)].map(() => Math.random().toString(36)[2]).join('');
}
function displayTableData(tables, data) {
}
window.onload = function () {
    console.log('ONLOAD!');
    const tables = document.getElementById('tables'), ct = document.getElementById('createtable'), name_el = document.getElementById('name'), sel_el = document.getElementById('config');
    request('table').then(tabledata => {
        console.log({ tabledata });
        displayTableData(tables, tabledata);
    }).catch((e) => console.log({ e }));
    fetchConfigs(sel_el);
    ct.onclick = () => {
        const conf = sel_el.value || 'alpha', name = name_el.value || _name_();
        post('table/new', { configuration: conf }).then(({ id }) => {
            gameaction('join', { player: name }, 'table', id).then(() => {
                window.location.href = `${hostname()}/board.html?game=${id}&player=${name}`;
            });
        });
    };
};
