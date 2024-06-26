import * as Board from './board.js';
import * as SFX from './sfx.js';
export function projectile(event) {
    const to = Board.square(event.to.x, event.to.y), from = Board.square(event.from.x, event.from.y), fromRect = from.getBoundingClientRect(), toRect = to.getBoundingClientRect(), projectile = createProjectile(event.subtype), table = document.getElementById('table'), animation = () => {
        return SFX.play(event.subtype).then(() => {
            table.appendChild(projectile);
            const pRect = projectile.getBoundingClientRect(), xoffset = (fromRect.width - pRect.width) / 2, yoffset = (fromRect.height - pRect.height) / 2, duration = Math.abs(fromRect.top - toRect.top) + Math.abs(fromRect.left - toRect.left) + 100, a = projectile.animate({
                top: [fromRect.top + yoffset + 'px', toRect.top + yoffset + 'px'],
                left: [fromRect.left + xoffset + 'px', toRect.left + xoffset + 'px'],
            }, { duration });
            return a.finished.then(() => {
                const child = to.firstChild;
                projectile.remove();
                if (child) {
                    return child.animate(onHit(event.subtype), { duration: 140 }).finished;
                }
            });
        });
    };
    return animation;
}
function createProjectile(subtype) {
    const projectileEl = document.createElement('div');
    projectileEl.className = `projectile ${subtype}`;
    return projectileEl;
}
function onHit(subtype) {
    if (subtype === 'spark') {
        return {
            backgroundColor: ['', 'pink', '']
        };
    }
    return {
        opacity: [1, 0.5, 1]
    };
}
export function scan({ x, y }) {
    SFX.play('tink');
    const child = Board.thingAt(x, y);
    if (child) {
        const animation = () => {
            return child.animate({ opacity: [1, 0.5, 1] }, { duration: 150 }).finished;
        };
        return animation;
    }
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
            burn(child);
        };
    }
    else {
        animation = () => {
            burn(square);
        };
    }
    return animation;
}
function burn(el) {
    return SFX.play('fire').then(() => {
        const style = window.getComputedStyle(el), bg = style.backgroundColor, bgimg = style.backgroundImage, firebg = bgimg ? `${bgimg}, url('img/fire.png')` : 'url("img/fire.png")', a = el.animate({
            backgroundColor: [bg, 'var(--ui-main-saturated)', bg],
        }, { duration: 500 });
        el.style.backgroundImage = firebg;
        return a.finished.then(() => {
            el.style.backgroundImage = bgimg;
        });
    });
}
function createContents(text) {
    const el = document.createElement('div');
    el.className = 'fullcontents';
    el.innerHTML = text;
    el.style.display = 'grid';
    el.style.placeContent = 'center';
    return el;
}
export function capture({ coord, name }) {
    return () => {
        const unit = Board.thingAt(coord.x, coord.y, 'unit'), style = window.getComputedStyle(unit), bgimg = style.backgroundImage;
        unit.style.backgroundImage = `url('img/${name}.png'), ${bgimg}`;
        return Promise.resolve(true);
    };
}
