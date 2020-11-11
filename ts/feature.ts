import { dismissable } from './overlay.js';

export function render(type: string): HTMLElement {
  if (type === 'water') {
    return renderWater();
  } if (type === 'block') {
    return renderBlock();
  } 
  console.log(`unknown feature type: ${type}`);
  return document.createElement('marquee');
}

function renderWater(): HTMLElement {
  const waterEl = document.createElement('div');
  waterEl.className = 'feature water';
  waterEl.addEventListener('dblclick', details(`Water:
  blocks movement. Some special abilities can pass over it`));
  return waterEl;
}

function renderBlock(): HTMLElement {
  const blockEl = document.createElement('div');
  blockEl.className = 'feature block';
  blockEl.addEventListener('dblclick', details(`Block:
  Can be pushed if nothing is on the other side.`));
  return blockEl;
}

function details(deets: string) {
  const deetsEl = document.createElement('div');
  deetsEl.innerHTML = deets;
  deetsEl.className = 'details';
  return () => {
    dismissable(deetsEl);
  }
}
