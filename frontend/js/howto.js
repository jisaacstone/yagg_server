import * as Unit from './unit.js';
import * as Request from './request.js';
import * as Element from './element.js';
function fetchUnits() {
    const unitsEl = document.getElementById('units');
    return Request.request('units').then((units) => {
        for (const unit of units) {
            unit.player = "unowned";
            const unitEl = Unit.render(unit, 0, true);
            unitEl.onclick = Unit.detailViewFn(unit, unitEl.className);
            unitsEl.appendChild(Element.create({
                id: `unit-${unit.name}`,
                children: [unitEl]
            }));
        }
    });
}
window.onload = () => {
    fetchUnits();
};
