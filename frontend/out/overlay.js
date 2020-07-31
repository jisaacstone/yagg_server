export function create() {
    const overlay = document.createElement('div'), container = document.createElement('div');
    overlay.className = 'overlay';
    container.className = 'overlaycontainer';
    document.body.appendChild(container);
    container.appendChild(overlay);
    return overlay;
}
export function clear() {
    Array.prototype.forEach.call(document.getElementsByClassName('overlaycontainer'), (el) => {
        el.remove();
    });
}
