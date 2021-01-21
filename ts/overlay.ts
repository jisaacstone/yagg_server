import * as SFX from './sfx.js';

export function create() {
  const overlay = document.createElement('div'),
    container = document.createElement('div');
  overlay.className = 'overlay';
  container.className = 'overlaycontainer';
  document.body.appendChild(container);
  container.appendChild(overlay);
  return overlay;
}

export function clear() {
  Array.prototype.forEach.call(
    document.getElementsByClassName('overlaycontainer'),
    (el) => {
      el.remove();
    }
  );
}

export function dismissable(el: HTMLElement) {
  const overlay = create(),
    container = overlay.parentNode as HTMLElement;
  overlay.appendChild(el);
  container.onclick = () => {
    SFX.play('click');
    container.remove();
  }
}

export function clearable(el: HTMLElement): () => void {
  const overlay = create(),
    container = overlay.parentNode as HTMLElement;
  overlay.appendChild(el);
  return () => {
    SFX.play('click');
    container.remove();
  }
}
