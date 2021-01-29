import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as SFX from './sfx.js';
import * as Overlay from './overlay.js';
export function button() {
    const settingsEl = Element.create({
        id: 'settingsbutton',
        tag: 'button',
        className: 'uibutton',
        innerHTML: 'settings'
    });
    settingsEl.setAttribute('title', 'settings');
    settingsEl.onclick = () => {
        SFX.play('click');
        show();
    };
    if (SFX.settings.fxvolume === 0 || SFX.mute) {
        settingsEl.style.backgroundImage = 'url("img/muted.png")';
    }
    return settingsEl;
}
function show() {
    const okEl = Element.create({
        className: 'uibutton',
        innerHTML: 'ok',
    }), cancelEl = Element.create({
        className: 'uibutton',
        innerHTML: 'cancel',
    }), fxvolume = Element.create({ tag: 'input' }), musicvolume = Element.create({ tag: 'input' }), mute = Element.create({ tag: 'input' }), optionsEl = Dialog.createDialog('options', Element.create({
        children: [
            Element.create({ innerHTML: 'sfx volume' }),
            fxvolume
        ]
    }), 
    //      Element.create({
    //        children: [
    //          Element.create({ innerHTML: 'music volume' }),
    //          musicvolume
    //        ]
    //      }),
    Element.create({
        children: [
            Element.create({ innerHTML: 'mute' }),
            mute
        ]
    }), okEl, cancelEl), clearOverlay = Overlay.clearable(optionsEl);
    for (const volume of [fxvolume, musicvolume]) {
        volume.setAttribute('type', 'range');
        volume.setAttribute('min', '0');
        volume.setAttribute('max', '10');
    }
    fxvolume.setAttribute('value', '' + Math.round(SFX.settings.fxvolume * 10));
    //musicvolume.setAttribute('value', '' + Math.round(SFX.settings.musicvolume * 10));
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
                SFX.mute();
            }
            else {
                SFX.unmute();
            }
            SFX.setVolume(+fxvolume.value / 10);
            //SFX.settings.musicvolume = +musicvolume.value / 10;
            //SFX.soundtrack.setVolume();
            setbg();
            resolve(true);
        };
    });
}
export function setbg() {
    const settingsEl = document.getElementById('settingsbutton');
    if (!settingsEl) {
        return;
    }
    if (SFX.settings.fxvolume === 0 || SFX.settings.mute) {
        settingsEl.style.backgroundImage = 'url("img/muted.png")';
    }
    else {
        settingsEl.style.backgroundImage = '';
    }
}
