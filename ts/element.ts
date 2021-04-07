export interface spec {
  className: string;
  innerHTML: string;
  tag: string;
  title?: string;
  value?: string;
  children: HTMLElement[];
}

export function create({tag='div', className='', innerHTML='', id='', children=[], title='', value=''}) {
  const el = document.createElement(tag);
  if (className) {
    el.className = className;
  }
  if (id) {
    el.id = id;
  }
  if (innerHTML) {
    el.innerHTML = innerHTML;
  }
  for (const child of children) {
    el.appendChild(child);
  }
  if (title) {
    el.setAttribute('title', title);
  }
  if (value) {
    el.setAttribute('value', value);
  }
  if (tag === 'button') {
    el.setAttribute('type', 'button');
  }
  return el
}
