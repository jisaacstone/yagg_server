import * as Request from './request.js';
import * as Element from './element.js';
import * as Overlay from './overlay.js';
import * as Err from './err.js';
import * as Storage from './storage.js';
const defaults = {
    'config-select': 'random',
    'public-select': 'public',
};
function fetchConfigs() {
    const values = [];
    return Request.request('configurations').then((configs) => {
        for (const config of configs) {
            values.push({ value: config.name, label: config.name, description: config.description });
        }
        return fieldSet('config-select', 'game configuration', values);
    });
}
function fieldSet(id, legend, options) {
    const inputs = [];
    const descEl = Element.create({ className: 'fs-description' });
    let selectedValue = Storage.getItem('createTable', id) || defaults[id];
    for (const { label, value, description } of options) {
        const inp = Element.create({ tag: 'input', id: value, value }), lab = Element.create({ tag: 'label', innerHTML: label });
        inp.setAttribute('name', id);
        inp.setAttribute('type', 'radio');
        if (value === selectedValue) {
            inp.setAttribute('checked', 'checked');
            descEl.innerHTML = description;
        }
        inputs.push(inp);
        lab.setAttribute('for', value);
        inputs.push(lab);
        lab.addEventListener('click', () => {
            selectedValue = value;
            descEl.innerHTML = description;
        });
    }
    return {
        el: Element.create({
            id,
            tag: 'fieldset',
            children: [
                Element.create({ tag: 'legend', innerHTML: legend }),
                Element.create({ className: 'choices', children: inputs }),
                descEl
            ]
        }),
        value: () => {
            Storage.setItem('createTable', id, selectedValue);
            return selectedValue;
        }
    };
}
export function dialog() {
    return fetchConfigs().then((configSelect) => {
        const publicSelect = fieldSet('public-select', 'game type', [
            { value: 'public', label: 'public', description: 'public game anyone can join' },
            { value: 'private', label: 'private', description: 'not visible to public, invite a friend to play' },
            { value: 'ai', label: 'vs AI', description: 'play against the computer' }
        ]), createButton = Element.create({ tag: 'button', innerHTML: 'create', className: 'uibutton ok-b' }), cancelButton = Element.create({ tag: 'button', innerHTML: 'cancel', className: 'uibutton cancel-b' }), dialog = Element.create({
            id: 'createdialog',
            children: [
                configSelect.el,
                publicSelect.el,
                createButton,
                cancelButton
            ]
        }), clearOverlay = Overlay.clearable(dialog);
        cancelButton.addEventListener('click', clearOverlay);
        createButton.addEventListener('click', () => {
            const conf = configSelect.value(), psv = publicSelect.value();
            let gtype = psv, ai = false;
            if (!conf) {
                Err.displayerror('select a config');
                return;
            }
            if (!gtype) {
                Err.displayerror('select a game type');
                return;
            }
            if (psv === 'ai') {
                gtype = 'private';
                ai = true;
            }
            return Request.post('table/new', { configuration: conf, type: gtype }).then(({ id }) => {
                let promise = Request.gameaction('join', {}, 'table', id);
                if (ai) {
                    promise = promise.then(() => {
                        return Request.gameaction('ai', {}, 'table', id);
                    });
                }
                return promise.then(() => {
                    window.location.href = `board.html?table=${id}`;
                });
            }).catch((err) => {
                if (err.request && err.request.status === 400) {
                    Err.displayerror(err.request.responseText);
                }
            });
        });
    });
}
