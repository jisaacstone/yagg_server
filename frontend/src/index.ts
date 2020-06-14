import { request, post, gameaction } from './request.js';
import { _name_ } from './urlvars.js';

function fetchConfigs(sel_el: HTMLElement) {
  request('configurations').then(
    (configs: any) => {
      for (const config of Object.keys(configs)) {
        const opt = document.createElement('option');
        opt.value = config;
        opt.innerHTML = config;
        sel_el.appendChild(opt);
      }
    }
  );
}

function displayTableData(tablesEl, data) {
  for (const tableId of data.ids) {
    const el = document.createElement('div');
    el.className = 'table';
    el.innerHTML = tableId;
    el.onclick = () => {
      const name = (document.getElementById('name') as HTMLInputElement).value || _name_();
      gameaction('join', { player: name }, 'table', tableId).then(() => {
        window.location.href = `board.html?table=${tableId}&player=${name}`;
      });
    };
    tablesEl.appendChild(el);
  }
}

window.onload = function() {
  console.log('ONLOAD!');
  const tables = document.getElementById('tables'),
    ct = document.getElementById('createtable'),
    name_el = document.getElementById('name') as HTMLInputElement,
    sel_el = document.getElementById('config') as HTMLInputElement;

  request('table').then(tabledata => {
    console.log({ tabledata });
    displayTableData(tables, tabledata);
  }).catch((e) => console.log({ e }));
  fetchConfigs(sel_el);

  ct.onclick = () => {
    const conf = sel_el.value || 'alpha',
      name = name_el.value || _name_();
    post('table/new', { configuration: conf }).then(({ id }) => {
      gameaction('join', { player: name }, 'table', id).then(() => {
        window.location.href = `board.html?table=${id}&player=${name}`;
      });
    });
  };
};
