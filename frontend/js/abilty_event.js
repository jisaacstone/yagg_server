import * as Board from './board.js';
export function projectile(event) {
    const to = Board.square(event.to.x, event.to.y), from = Board.square(event.from.x, event.from.y), fromRect = from.getBoundingClientRect(), toRect = to.getBoundingClientRect(), projectile = createProjectile(event.subtype), table = document.getElementById('table'), animation = () => {
        table.appendChild(projectile);
        const pRect = projectile.getBoundingClientRect(), xoffset = (fromRect.width - pRect.width) / 2, yoffset = (fromRect.height - pRect.height) / 2, duration = Math.abs(fromRect.top - toRect.top) + Math.abs(fromRect.left - toRect.left), a = projectile.animate({
            top: [fromRect.top + yoffset + 'px', toRect.top + yoffset + 'px'],
            left: [fromRect.left + xoffset + 'px', toRect.left + xoffset + 'px'],
        }, { duration });
        return a.finished.then(() => {
            const child = to.firstChild;
            projectile.remove();
            if (child) {
                return child.animate({ opacity: [1, 0.5, 1] }, { duration: 100 }).finished;
            }
        });
    };
    return { animation, squares: [`${event.to.x},${event.to.y}`, `${event.from.x},${event.from.y}`] };
}
function createProjectile(subtype) {
    const projectileEl = document.createElement('div');
    projectileEl.className = `projectile ${subtype}`;
    if (subtype === 'horseshoe') { // @ts-ignore
        projectileEl.innerHTML = String.fromCodePoint(0x03A9);
    }
    else if (subtype === 'spark') { // @ts-ignore
        projectileEl.innerHTML = String.fromCodePoint(0x1F4A5);
    }
    return projectileEl;
}
export function fire(event) {
    const square = Board.square(event.x, event.y), child = square.firstElementChild;
    if (!square) {
        console.error({ error: 'no such square', event });
        return;
    }
    var animation;
    if (child) {
        animation = () => {
            const bg = window.getComputedStyle(child).backgroundColor, a = child.animate({ backgroundColor: [bg, 'var(--ui-main-saturated)', bg] }, { duration: 500 });
            return a.finished;
        };
    }
    else {
        animation = () => {
            const contents = square.innerHTML, bg = window.getComputedStyle(square).backgroundColor, fire = createContents(String.fromCodePoint(0x1f525)), a = square.animate({ backgroundColor: [bg, 'var(--ui-main-saturated)', bg] }, { duration: 500 });
            square.appendChild(fire);
            return a.finished.then(() => {
                square.innerHTML = contents;
            });
        };
    }
    return { animation, squares: [`${event.x},${event.y}`] };
}
function createContents(text) {
    const el = document.createElement('div');
    el.className = 'fullcontents';
    el.innerHTML = text;
    el.style.display = 'grid';
    el.style.placeContent = 'center';
    return el;
}
