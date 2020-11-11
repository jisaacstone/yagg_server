export function hostname() {
  const host = window.location.hostname,
    port = window.location.port,
    hostname = port ? `${host}:${port}` : host;
  return hostname;
}

export function getname() {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('player');
}

export function tableid() {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('table');
}

export function _name_() {
  return [...Array(8)].map(() => Math.random().toString(36)[2]).join('');
}
