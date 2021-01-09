import { external_backend } from './exthost.js';

export function hostname() {
  const remote = external_backend();
  if ( remote ) {
    return remote;
  }
  const host = window.location.hostname,
    port = window.location.port,
    local = port ? `${host}:${port}` : host;
  return local;
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
