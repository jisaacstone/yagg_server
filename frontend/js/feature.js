import { dismissable } from './overlay.js';
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
    const waterEl = document.createElement('div');
    waterEl.className = 'feature water';
    waterEl.addEventListener('dblclick', details(`Water:
  blocks movement. Some special abilities can pass over it`));
    return waterEl;
}
function renderBlock() {
    const blockEl = document.createElement('div');
    blockEl.className = 'feature block';
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
