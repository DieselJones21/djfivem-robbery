const TYPE_ORDER = [
    'atm', 'store', 'house', 'vehicle', 'ammunation', 'bank', 'moneytruck',
    'cargotruck', 'paleto', 'jewelry', 'train', 'yacht', 'cargoship', 'bobcat', 'pacific',
];

const app = document.getElementById('app');
const typeTabs = document.getElementById('typeTabs');
const locationList = document.getElementById('locationList');
const hud = document.getElementById('hud');
const minigame = document.getElementById('minigame');

let state = {
    types: [],
    locations: [],
    crew: null,
    job: null,
    police: 0,
    name: 'Operator',
    store: { enabled: false, items: [], balance: 0 },
    selectedType: 'bank',
    selectedLocation: null,
    view: 'contracts',
    brand: 'NEXUS',
    subtitle: 'Contract Network v2',
};

let miniResolve = null;
let miniTimer = null;

function resourceName() {
    try {
        return GetParentResourceName();
    } catch (e) {
        return 'djfivem-robbery';
    }
}

function nui(name, data = {}) {
    return fetch(`https://${resourceName()}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then((res) => res.json()).catch(() => ({ ok: false }));
}

function formatCooldown(seconds) {
    seconds = Math.max(0, Math.floor(seconds || 0));
    const m = Math.floor(seconds / 60);
    const s = seconds % 60;
    return m > 0 ? `${m}m ${s}s` : `${s}s`;
}

function money(n) {
    return `$${Number(n || 0).toLocaleString()}`;
}

function typeById(id) {
    return state.types.find((t) => t.id === id);
}

function locationById(id) {
    return state.locations.find((l) => l.id === id);
}

function selectedLocation() {
    return locationById(state.selectedLocation) || state.locations.find((l) => l.type === state.selectedType);
}

function stars(n) {
    n = Math.max(1, Math.min(5, n || 1));
    return '◆'.repeat(n) + '◇'.repeat(5 - n);
}

function setView(view) {
    state.view = view;
    document.querySelectorAll('.rail-btn').forEach((btn) => {
        btn.classList.toggle('active', btn.dataset.view === view);
    });
    document.getElementById('viewContracts').classList.toggle('hidden', view !== 'contracts');
    document.getElementById('viewShop').classList.toggle('hidden', view !== 'shop');
    document.getElementById('viewCrew').classList.toggle('hidden', view !== 'crew');
    document.getElementById('viewEyebrow').textContent = view === 'shop' ? 'Black market' : view === 'crew' ? 'Lobby' : 'Available jobs';
    document.getElementById('viewTitle').textContent = view === 'shop' ? 'Market' : view === 'crew' ? 'Crew' : 'Contracts';
    typeTabs.style.display = view === 'contracts' ? 'flex' : 'none';
}

function renderTabs() {
    const types = [...state.types].sort((a, b) => TYPE_ORDER.indexOf(a.id) - TYPE_ORDER.indexOf(b.id));
    typeTabs.innerHTML = types.map((t) => `
        <button class="tab ${state.selectedType === t.id ? 'active' : ''}" data-type="${t.id}">${t.label}</button>
    `).join('');
    typeTabs.querySelectorAll('.tab').forEach((btn) => {
        btn.addEventListener('click', () => {
            state.selectedType = btn.dataset.type;
            const first = state.locations.find((l) => l.type === state.selectedType);
            if (!state.crew) state.selectedLocation = first ? first.id : null;
            render();
        });
    });
}

function renderDetail() {
    const loc = selectedLocation();
    const type = typeById(state.selectedType);
    const art = document.getElementById('heroArt');
    art.className = `hero-art d${loc?.difficulty || type?.difficulty || 1}`;
    document.getElementById('heroKicker').textContent = type ? type.label : 'Contracts';
    document.getElementById('heroTitle').textContent = loc ? loc.label : 'Choose a target';
    document.getElementById('heroDesc').textContent = loc ? loc.description : (type ? type.description : '');
    document.getElementById('heroStars').textContent = stars(loc?.difficulty || type?.difficulty);

    const items = (loc && loc.requiredItems) || [];
    document.getElementById('itemRow').innerHTML = items.length
        ? items.map((item) => `<div class="item-chip">${item.label}${item.count > 1 ? ` x${item.count}` : ''}</div>`).join('')
        : '<p class="muted">No tools listed.</p>';

    if (loc) {
        const onCd = loc.cooldown > 0;
        document.getElementById('detailMeta').innerHTML = `
            <span class="pill">Crew <em>${loc.minPlayers || 1}–${loc.maxPlayers}</em></span>
            <span class="pill">PD <em>${loc.minPolice}</em></span>
            <span class="pill">Payout <em>${loc.payoutLabel}</em></span>
            <span class="pill">${onCd ? `Locked ${formatCooldown(loc.cooldown)}` : 'Available now'}</span>
            ${loc.armed ? '<span class="pill warn">ARMED GUARDS</span>' : ''}
        `;
        document.getElementById('stageList').innerHTML = (loc.stages || []).map((s) => `<li>${s}</li>`).join('');
    } else {
        document.getElementById('detailMeta').innerHTML = '';
        document.getElementById('stageList').innerHTML = '';
    }
}

function renderLocations() {
    const type = typeById(state.selectedType);
    const rows = state.locations.filter((l) => l.type === state.selectedType);
    document.getElementById('listTitle').textContent = type ? type.label : 'Targets';
    document.getElementById('listSub').textContent = type
        ? `${type.minPolice} PD · ${type.maxPlayers} max · ${formatCooldown(type.cooldown)}`
        : 'Select a category';

    locationList.innerHTML = rows.map((loc) => {
        const selected = state.selectedLocation === loc.id ? 'selected' : '';
        const onCd = (loc.cooldown || 0) > 0;
        return `
            <button class="target ${selected}" data-id="${loc.id}">
                <span class="bar"></span>
                <div>
                    <h4>${loc.label}</h4>
                    <p>${loc.payoutLabel} · ${stars(loc.difficulty)}</p>
                    ${loc.armed ? '<p class="armed">ARMED</p>' : ''}
                </div>
                <p class="status ${onCd ? 'down' : ''}">${onCd ? formatCooldown(loc.cooldown) : 'Ready'}</p>
            </button>
        `;
    }).join('');

    locationList.querySelectorAll('.target').forEach((card) => {
        card.addEventListener('click', async () => {
            state.selectedLocation = card.dataset.id;
            if (!state.crew) {
                const result = await nui('createCrew', { locationId: state.selectedLocation });
                if (result.ok) state.crew = result.crew;
            }
            render();
        });
    });
}

function renderCrew() {
    const crew = state.crew;
    const empty = document.getElementById('crewEmpty');
    const body = document.getElementById('crewBody');
    if (!crew) {
        empty.classList.remove('hidden');
        body.classList.add('hidden');
        return;
    }
    empty.classList.add('hidden');
    body.classList.remove('hidden');
    const loc = locationById(crew.locationId);
    document.getElementById('memberList').innerHTML = crew.members.map((m) => `
        <li><span>${m.name}</span>${m.host ? '<span class="host">LEADER</span>' : ''}</li>
    `).join('');
    document.getElementById('inviteBtn').disabled = crew.members.length >= crew.maxPlayers;
    document.getElementById('startBtn').textContent = loc ? `Start ${loc.label}` : 'Start contract';
    if (loc && loc.type !== state.selectedType) state.selectedType = loc.type;
}

function renderShop() {
    const store = state.store || {};
    document.getElementById('shopLabel').textContent = store.label || 'Nexus Supply';
    document.getElementById('shopSub').textContent = store.subtitle || '';
    document.getElementById('shopBalance').textContent = money(store.balance);
    const grid = document.getElementById('shopGrid');
    if (!store.enabled) {
        grid.innerHTML = '<p class="muted">Market is disabled.</p>';
        return;
    }
    grid.innerHTML = (store.items || []).map((item) => `
        <article class="shop-card" data-item="${item.item}">
            <h4>${item.label}</h4>
            <p>${item.description}</p>
            <div class="shop-meta">
                <span class="price">${money(item.price)}</span>
                <span>${item.infinite ? 'In stock' : `${item.stock} left`}</span>
            </div>
            <div class="qty-row">
                <input type="number" min="1" max="${store.maxQty || 10}" value="1" />
                <button ${!item.infinite && item.stock < 1 ? 'disabled' : ''}>Buy</button>
            </div>
        </article>
    `).join('');
    grid.querySelectorAll('.shop-card').forEach((card) => {
        card.querySelector('button').addEventListener('click', async () => {
            const qty = Number(card.querySelector('input').value || 1);
            const result = await nui('buyItem', { item: card.dataset.item, qty });
            if (result.ok && result.store) {
                state.store = result.store;
                renderShop();
            }
        });
    });
}

function render() {
    document.getElementById('brandName').textContent = state.brand || 'NEXUS';
    document.getElementById('brandSub').textContent = state.subtitle || 'Contract Network v2';
    document.getElementById('greeting').textContent = state.name || 'Operator';
    document.getElementById('pdCount').textContent = String(state.police || 0);
    document.getElementById('cooldownLabel').textContent = (state.playerCooldown || 0) > 0
        ? formatCooldown(state.playerCooldown)
        : 'Ready';
    renderTabs();
    renderDetail();
    renderLocations();
    renderCrew();
    renderShop();
}

function applyPayload(payload, tab) {
    const first = (payload.locations || []).find((l) => l.type === (payload.crew?.type || state.selectedType || 'bank'));
    state = {
        ...state,
        ...payload,
        selectedType: payload?.crew?.type || state.selectedType || 'bank',
        selectedLocation: payload?.crew?.locationId || first?.id || null,
    };
    setView(tab || state.view || 'contracts');
    render();
}

document.querySelectorAll('.rail-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        setView(btn.dataset.view);
        render();
    });
});

document.getElementById('closeBtn').addEventListener('click', () => nui('close'));
document.getElementById('leaveBtn').addEventListener('click', async () => {
    await nui('leaveCrew');
    state.crew = null;
    document.getElementById('nearbyList').classList.add('hidden');
    const fresh = await nui('refresh');
    if (fresh.ok) Object.assign(state, fresh);
    render();
});
document.getElementById('inviteBtn').addEventListener('click', async () => {
    const nearby = await nui('nearby');
    const box = document.getElementById('nearbyList');
    box.classList.remove('hidden');
    if (!nearby || nearby.length === 0) {
        box.innerHTML = '<p class="muted">Nobody nearby.</p>';
        return;
    }
    box.innerHTML = nearby.map((p) => `<button data-src="${p.source}">Invite ${p.name}</button>`).join('');
    box.querySelectorAll('button').forEach((btn) => {
        btn.addEventListener('click', async () => {
            await nui('invite', { source: Number(btn.dataset.src) });
            const fresh = await nui('refresh');
            if (fresh.ok) Object.assign(state, fresh);
            render();
        });
    });
});
document.getElementById('startBtn').addEventListener('click', async () => {
    await nui('startJob');
    const fresh = await nui('refresh');
    if (fresh.ok) Object.assign(state, fresh);
    render();
});

function closeMinigame(ok) {
    if (miniTimer) {
        clearInterval(miniTimer);
        miniTimer = null;
    }
    minigame.classList.add('hidden');
    const resolve = miniResolve;
    miniResolve = null;
    nui('minigameResult', { ok: !!ok });
    if (resolve) resolve(!!ok);
}

function startTimer(seconds, onExpire) {
    const bar = document.getElementById('miniTimer');
    const started = Date.now();
    const total = seconds * 1000;
    miniTimer = setInterval(() => {
        const left = Math.max(0, 1 - ((Date.now() - started) / total));
        bar.style.transform = `scaleX(${left})`;
        if (left <= 0) {
            clearInterval(miniTimer);
            miniTimer = null;
            onExpire();
        }
    }, 50);
}

function runKeypad(cfg) {
    const length = cfg.keypadLength || 5;
    const code = Array.from({ length }, () => Math.floor(Math.random() * 9) + 1);
    document.getElementById('miniKicker').textContent = 'KEYPAD';
    document.getElementById('miniTitle').textContent = 'Memorize the code';
    document.getElementById('miniSub').textContent = 'Enter the sequence after it hides.';
    const body = document.getElementById('miniBody');
    body.innerHTML = `<div class="preview" id="preview">${code.join(' ')}</div><div class="keypad" id="pad"></div>`;
    const pad = document.getElementById('pad');
    for (let i = 1; i <= 9; i += 1) {
        const btn = document.createElement('button');
        btn.textContent = String(i);
        pad.appendChild(btn);
    }
    let entered = [];
    setTimeout(() => {
        document.getElementById('preview').textContent = '• '.repeat(length).trim();
        pad.querySelectorAll('button').forEach((btn) => {
            btn.addEventListener('click', () => {
                entered.push(Number(btn.textContent));
                document.getElementById('preview').textContent = entered.join(' ');
                if (entered.length === length) {
                    closeMinigame(entered.every((n, i) => n === code[i]));
                }
            });
        });
        startTimer(8, () => closeMinigame(false));
    }, cfg.keypadPreviewMs || 1400);
}

function runThermite(cfg) {
    const size = cfg.thermiteSize || 5;
    const targets = cfg.thermiteTargets || 7;
    const picks = new Set();
    while (picks.size < targets) picks.add(Math.floor(Math.random() * size * size));
    document.getElementById('miniKicker').textContent = 'THERMITE';
    document.getElementById('miniTitle').textContent = 'Burn the weak points';
    document.getElementById('miniSub').textContent = `Hit ${targets} marked cells. Misses fail the charge.`;
    const body = document.getElementById('miniBody');
    body.innerHTML = `<div class="thermite" id="grid" style="grid-template-columns:repeat(${size},1fr)"></div>`;
    const grid = document.getElementById('grid');
    let remaining = new Set(picks);
    for (let i = 0; i < size * size; i += 1) {
        const btn = document.createElement('button');
        if (picks.has(i)) btn.classList.add('target');
        btn.addEventListener('click', () => {
            if (picks.has(i)) {
                btn.classList.add('hit');
                remaining.delete(i);
                if (remaining.size === 0) closeMinigame(true);
            } else {
                btn.classList.add('miss');
                closeMinigame(false);
            }
        });
        grid.appendChild(btn);
    }
    startTimer(cfg.thermiteTime || 9, () => closeMinigame(false));
}

function runCircuit(cfg) {
    const nodes = cfg.circuitNodes || 6;
    const order = Array.from({ length: nodes }, (_, i) => i + 1);
    for (let i = order.length - 1; i > 0; i -= 1) {
        const j = Math.floor(Math.random() * (i + 1));
        [order[i], order[j]] = [order[j], order[i]];
    }
    document.getElementById('miniKicker').textContent = 'CIRCUIT';
    document.getElementById('miniTitle').textContent = 'Trace the path';
    document.getElementById('miniSub').textContent = 'Click nodes in ascending order.';
    const body = document.getElementById('miniBody');
    body.innerHTML = '<div class="circuit" id="circuit"></div>';
    const box = document.getElementById('circuit');
    let next = 1;
    order.forEach((n) => {
        const btn = document.createElement('button');
        btn.textContent = String(n);
        btn.addEventListener('click', () => {
            if (n === next) {
                btn.classList.add('on');
                next += 1;
                if (next > nodes) closeMinigame(true);
            } else {
                closeMinigame(false);
            }
        });
        box.appendChild(btn);
    });
    startTimer(cfg.circuitTime || 12, () => closeMinigame(false));
}

function openMinigame(kind, config) {
    minigame.classList.remove('hidden');
    document.getElementById('miniTimer').style.transform = 'scaleX(1)';
    if (kind === 'keypad') runKeypad(config || {});
    else if (kind === 'thermite') runThermite(config || {});
    else runCircuit(config || {});
}

function renderHud(job) {
    if (!job) {
        hud.classList.add('hidden');
        return;
    }
    hud.classList.remove('hidden');
    document.getElementById('hudTitle').textContent = job.label || 'Contract';
    document.getElementById('hudTime').textContent = job.remaining ? `${formatCooldown(job.remaining)} remaining` : 'Live';
    const completed = job.completed || {};
    const stages = job.stages || [];
    document.getElementById('hudStages').innerHTML = stages.map((stage, i) => {
        const done = Object.keys(completed).length > i;
        return `<li class="${done ? 'done' : ''}">${stage}</li>`;
    }).join('');
}

window.addEventListener('message', (event) => {
    const { action, payload, tab, job, kind, config } = event.data || {};
    if (action === 'open') {
        app.classList.remove('hidden');
        applyPayload(payload || {}, tab);
    }
    if (action === 'sync' && payload) {
        applyPayload(payload, state.view);
    }
    if (action === 'close') {
        app.classList.add('hidden');
        document.getElementById('nearbyList').classList.add('hidden');
    }
    if (action === 'hud') renderHud(job);
    if (action === 'minigame') openMinigame(kind, config);
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (!minigame.classList.contains('hidden')) {
            closeMinigame(false);
            return;
        }
        nui('close');
    }
});

function demoMode() {
    const types = TYPE_ORDER.map((id, i) => ({
        id,
        label: id.replace(/^[a-z]/, (c) => c.toUpperCase()).replace('cargoship', 'Cargo ship').replace('moneytruck', 'Money trucks').replace('ammunation', 'Ammunation'),
        description: 'Demo contract type',
        maxPlayers: id === 'pacific' || id === 'bobcat' ? 6 : 4,
        minPlayers: 1,
        minPolice: i,
        cooldown: 1800,
        difficulty: Math.min(5, 1 + Math.floor(i / 3)),
        color: '#f5c542',
        requiredItems: [],
    }));
    const locations = [
        { id: 'pacific_standard', type: 'pacific', label: 'Pacific Standard — Downtown', description: 'Multi-stage downtown vault: power, keypad, C4, trolleys, then run.', payoutLabel: '$180,000 – $320,000', minPolice: 6, maxPlayers: 6, minPlayers: 3, cooldown: 0, cooldownDuration: 4500, requiredItems: [{ name: 'hacking_laptop', count: 1, label: 'Hacking Laptop' }, { name: 'c4_charge', count: 1, label: 'C4 Charge' }], difficulty: 5, stages: ['Cut rooftop power', 'Hack inner keypad', 'C4 vault', 'Loot trolleys'], armed: true },
        { id: 'vangelico_rockford', type: 'jewelry', label: 'Vangelico — Rockford Hills', description: 'Bypass gallery security, smash displays, thermite the office safe.', payoutLabel: '$55,000 – $110,000', minPolice: 4, maxPlayers: 5, minPlayers: 2, cooldown: 0, cooldownDuration: 3000, requiredItems: [{ name: 'electronickit', count: 1, label: 'Electronic Kit' }, { name: 'crowbar', count: 1, label: 'Crowbar' }], difficulty: 4, stages: ['Hack gallery alarm', 'Smash displays', 'Thermite office safe'], armed: true },
        { id: 'bobcat_cypress', type: 'bobcat', label: 'Bobcat Security — Cypress Flats', description: 'Fight through the yard, hack the cage, C4 the vault.', payoutLabel: '$90,000 – $160,000', minPolice: 5, maxPlayers: 6, minPlayers: 3, cooldown: 120, cooldownDuration: 4200, requiredItems: [{ name: 'c4_charge', count: 1, label: 'C4 Charge' }], difficulty: 5, stages: ['Hack gate panel', 'C4 vault', 'Loot cages'], armed: true },
        { id: 'fleeca_legion', type: 'bank', label: 'Fleeca — Legion Square', description: 'Hack the panel, burn the vault, then split the boxes.', payoutLabel: '$42,000 – $95,000', minPolice: 2, maxPlayers: 4, minPlayers: 1, cooldown: 0, cooldownDuration: 2400, requiredItems: [{ name: 'electronickit', count: 1, label: 'Electronic Kit' }, { name: 'thermite', count: 1, label: 'Thermite' }], difficulty: 3, stages: ['Hack keypad', 'Thermite vault', 'Loot deposit boxes'], armed: true },
        { id: 'store_grove', type: 'store', label: 'LTD — Grove Street', description: 'Clean the tills, then drill the office safe.', payoutLabel: '$3,200 – $7,800', minPolice: 1, maxPlayers: 4, minPlayers: 1, cooldown: 0, cooldownDuration: 1320, requiredItems: [{ name: 'lockpick', count: 1, label: 'Lockpick' }, { name: 'drill', count: 1, label: 'Drill' }], difficulty: 2, stages: ['Empty registers', 'Drill office safe'], armed: false },
    ];
    applyPayload({
        ok: true,
        name: 'Adin Primrose',
        police: 4,
        playerCooldown: 0,
        types,
        locations,
        crew: null,
        store: {
            enabled: true,
            label: 'Nexus Supply',
            subtitle: 'Untraceable kit. Cash only. No receipts.',
            balance: 12450,
            maxQty: 10,
            items: [
                { item: 'lockpick', label: 'Lockpick', description: 'Tills, house doors, and boost cars.', price: 250, infinite: true, stock: 999 },
                { item: 'thermite', label: 'Thermite Charge', description: 'Vault doors and armored truck plating.', price: 3600, infinite: false, stock: 10 },
                { item: 'c4_charge', label: 'C4 Charge', description: 'Pacific vault and Bobcat cage doors.', price: 5200, infinite: false, stock: 6 },
                { item: 'hacking_laptop', label: 'Hacking Laptop', description: 'Required for Pacific and cargo-ship mainframes.', price: 4200, infinite: false, stock: 8 },
                { item: 'drill', label: 'Industrial Drill', description: 'ATMs, safes, lockers, freight seals.', price: 2800, infinite: true, stock: 999 },
                { item: 'robbery_tablet', label: 'Crime Tablet', description: 'Opens the Nexus contract network.', price: 8500, infinite: false, stock: 4 },
            ],
        },
        brand: 'NEXUS',
        subtitle: 'Contract Network v2',
    }, 'contracts');
    app.classList.remove('hidden');
    renderHud({
        label: 'Pacific Standard — Downtown',
        remaining: 1420,
        stages: ['Cut rooftop power', 'Hack inner keypad', 'C4 vault', 'Loot trolleys'],
        completed: { power: true },
    });
}

if (!window.invokeNative) {
    window.addEventListener('DOMContentLoaded', demoMode);
}
