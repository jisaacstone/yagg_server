let storage;

function setCookie(name,value,days) {
    var expires = "";
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days*24*60*60*1000));
        expires = "; expires=" + date.toUTCString();
    }
    document.cookie = name + "=" + (value || "")  + expires + "; path=/";
}
function getCookie(name) {
    var nameEQ = name + "=";
    var ca = document.cookie.split(';');
    for(var i=0;i < ca.length;i++) {
        var c = ca[i];
        while (c.charAt(0)==' ') c = c.substring(1,c.length);
        if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length,c.length);
    }
    return null;
}
function eraseCookie(name) {
    document.cookie = name +'=; Path=/; Expires=Thu, 01 Jan 1970 00:00:01 GMT;';
}

try {
  localStorage.getItem('test');
  storage = localStorage;
} catch (e) {
  console.error({msg: 'no localStorage support', e});
  // itch.io iFrame polyfill
  storage = {
    setItem: setCookie,
    getItem: getCookie,
    removeItem: eraseCookie
  };
}

export function getItem(ns: string, key: string) {
  return storage.getItem(`${ns}.${key}`);
}

export function setItem(ns: string, key: string, value: any) {
  return storage.setItem(`${ns}.${key}`, `${value}`);
}

export function removeItem(ns: string, key: string) {
  return storage.removeItem(`${ns}.${key}`);
}
