export function create({ tag = 'div', className = '', innerHTML = '', id = '', children = [] }) {
    const el = document.createElement(tag);
    if (className) {
        el.className = className;
    }
    if (id) {
        el.id = id;
    }
    if (innerHTML) {
        el.innerHTML = innerHTML;
    }
    for (const child of children) {
        el.appendChild(child);
    }
    return el;
}
