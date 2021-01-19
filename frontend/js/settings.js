import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as SFX from './sfx.js';
import * as Overlay from './overlay.js';
export function show() {
    const okEl = Element.create({
        className: 'uibutton',
        innerHTML: 'ok',
    }), cancelEl = Element.create({
        className: 'uibutton',
        innerHTML: 'cancel',
    }), volume = Element.create({ tag: 'input' }), mute = Element.create({ tag: 'input' }), optionsEl = Dialog.createDialog('options', Element.create({
        children: [
            Element.create({ innerHTML: 'volume' }),
            volume
        ]
    }), Element.create({
        children: [
            Element.create({ innerHTML: 'mute' }),
            mute
        ]
    }), okEl, cancelEl), clearOverlay = Overlay.clearable(optionsEl);
    volume.setAttribute('type', 'range');
    volume.setAttribute('min', '0');
    volume.setAttribute('max', '10');
    volume.setAttribute('value', '' + Math.round(SFX.settings.volume * 10));
    mute.setAttribute('type', 'checkbox');
    if (SFX.settings.mute) {
        mute.setAttribute('checked', 'true');
    }
    return new Promise((resolve) => {
        cancelEl.onclick = () => {
            clearOverlay();
            resolve(true);
        };
        okEl.onclick = () => {
            clearOverlay();
            if (mute.checked) {
                SFX.settings.mute = true;
            }
            else {
                SFX.settings.mute = false;
            }
            SFX.settings.volume = +volume.value / 10;
            resolve(true);
        };
    });
}
