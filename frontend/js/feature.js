import { dismissable } from './overlay.js';
import * as Element from './element.js';
import * as Select from './select.js';
export function render(type) {
    if (type === 'water') {
        return renderWater();
    }
    if (type === 'block') {
        return renderBlock();
    }
    console.log(`unknown feature type: ${type}`);
    return document.createElement('marquee');
}
function renderWater() {
    const waterEl = Element.create({ className: 'feature water' });
    waterEl.addEventListener('click', sidebar(waterEl, 'water'));
    waterEl.addEventListener('dblclick', details(`Water:
  blocks movement. Some special abilities can pass over it`));
    return waterEl;
}
function renderBlock() {
    const blockEl = Element.create({ className: 'feature block' });
    blockEl.addEventListener('click', sidebar(blockEl, 'block'));
    blockEl.addEventListener('dblclick', details(`Block:
  Can be pushed if nothing is on the other side.`));
    return blockEl;
}
function details(deets) {
    const deetsEl = document.createElement('div');
    deetsEl.innerHTML = deets;
    deetsEl.className = 'details';
    return () => {
        dismissable(deetsEl);
    };
}
function sidebar(el, text) {
    return () => {
        if (!Select.selected()) {
            const infobox = document.getElementById('infobox'), info = Element.create({
                className: el.className + ' info',
                children: [
                    Element.create({ className: 'text', innerHTML: text })
                ]
            });
            infobox.innerHTML = '';
            infobox.appendChild(info);
        }
    };
}
