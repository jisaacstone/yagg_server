export function boardhtml(el: HTMLElement, width=5, height=5) {
  for (let y=0; y < height; y++) {
    let row = document.createElement('div');
    row.className = 'boardrow';
    el.appendChild(row);
    for (let x=0; x < width; x++) {
      let square = document.createElement('div')
      square.className = 'boardsquare';
      square.id = `c${x}-${y}`;
      row.appendChild(square);
    }
  }
}
