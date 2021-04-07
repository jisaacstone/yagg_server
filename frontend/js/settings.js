import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as SFX from './sfx.js';
import * as Soundtrack from './soundtrack.js';
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
    if (SFX.settings().volume === 0 || SFX.settings().mute === true) {
        settingsEl.style.backgroundImage = 'url("img/muted.png")';
    }
    return settingsEl;
}
function show() {
    const okEl = Element.create({
        className: 'uibutton ok-b',
        innerHTML: 'ok',
    }), cancelEl = Element.create({
        className: 'uibutton cancel-b',
        innerHTML: 'cancel'
    }), fxvolume = Element.create({ tag: 'input' }), musicvolume = Element.create({ tag: 'input' }), mute = Element.create({ tag: 'input' }), fxsettings = SFX.settings(), stsettings = Soundtrack.settings(), optionsEl = Dialog.createDialog('options', Element.create({
        children: [
            Element.create({ innerHTML: 'sfx volume' }),
            fxvolume
        ]
    }), Element.create({
        children: [
            Element.create({ innerHTML: 'music volume' }),
            musicvolume
        ]
    }), Element.create({
        children: [
            Element.create({ innerHTML: 'mute' }),
            mute
        ]
    }), okEl, cancelEl), clearOverlay = Overlay.clearable(optionsEl);
    for (const volume of [fxvolume, musicvolume]) {
        volume.setAttribute('type', 'range');
        volume.setAttribute('min', '0');
        volume.setAttribute('max', '1');
        volume.setAttribute('step', '0.05');
    }
    fxvolume.setAttribute('value', '' + fxsettings.volume);
    fxvolume.addEventListener('input', () => {
        SFX.setVolume(+fxvolume.value);
    });
    musicvolume.setAttribute('value', '' + stsettings.volume);
    musicvolume.addEventListener('input', () => {
        Soundtrack.setVolume(+musicvolume.value);
    });
    mute.setAttribute('type', 'checkbox');
    if (fxsettings.mute) {
        mute.setAttribute('checked', 'true');
    }
    mute.addEventListener('change', () => {
        console.log('mutechange');
        if (mute.checked) {
            SFX.mute();
            Soundtrack.mute();
        }
        else {
            SFX.unmute();
            Soundtrack.unmute();
        }
    });
    return new Promise((resolve) => {
        cancelEl.onclick = () => {
            clearOverlay();
            SFX.setVolume(fxsettings.volume);
            SFX.setMute(fxsettings.mute);
            Soundtrack.setVolume(stsettings.volume);
            Soundtrack.setMute(stsettings.mute);
            resolve(true);
        };
        okEl.onclick = () => {
            clearOverlay();
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
    if (SFX.settings().volume === 0 || SFX.settings().mute) {
        settingsEl.style.backgroundImage = 'url("img/muted.png")';
    }
    else {
        settingsEl.style.backgroundImage = '';
    }
}
