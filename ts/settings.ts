import * as Dialog from './dialog.js';
import * as Element from './element.js';
import * as SFX from './sfx.js';
import * as Overlay from './overlay.js';

export function show() {
  const okEl = Element.create({
      className: 'uibutton',
      innerHTML: 'ok',
    }), 
    cancelEl = Element.create({
      className: 'uibutton',
      innerHTML: 'cancel',
    }), 
    fxvolume = Element.create({ tag: 'input' }) as HTMLInputElement,
    musicvolume = Element.create({ tag: 'input' }) as HTMLInputElement,
    mute = Element.create({ tag: 'input' }) as HTMLInputElement,
    optionsEl = Dialog.createDialog(
      'options',
      Element.create({
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
      }),
      okEl,
      cancelEl
    ),
    clearOverlay = Overlay.clearable(optionsEl);

  for ( const volume of [fxvolume, musicvolume] ) {
    volume.setAttribute('type', 'range');
    volume.setAttribute('min', '0');
    volume.setAttribute('max', '10');
  }
  fxvolume.setAttribute('value', '' + Math.round(SFX.settings.fxvolume * 10));
  //musicvolume.setAttribute('value', '' + Math.round(SFX.settings.musicvolume * 10));

  mute.setAttribute('type', 'checkbox');
  if ( SFX.settings.mute ) {
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
        //SFX.soundtrack.audio.mute = true;
      } else {
        SFX.settings.mute = false;
        //SFX.soundtrack.audio.mute = false;
      }
      SFX.settings.fxvolume = +fxvolume.value / 10;
      //SFX.settings.musicvolume = +musicvolume.value / 10;
      SFX.soundtrack.setVolume();
      resolve(true);
    }
  });

}
