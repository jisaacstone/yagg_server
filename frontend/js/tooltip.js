import * as Element from './element.js';
export function addTooltip(el, text) {
    const tooltip = Element.create({
        className: 'tooltip',
        children: [
            Element.create({ className: 'tttext', innerHTML: text })
        ]
    });
    el.appendChild(tooltip);
    el.addEventListener('touchstart', () => {
        console.log({ e: 'hover', el, text });
        el.classList.add('hover');
    }, false);
}
