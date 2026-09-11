const TYPE_ORDER = [
    'atm', 'store', 'house', 'vehicle', 'ammunation', 'bank', 'moneytruck',
    'cargotruck', 'paleto', 'jewelry', 'train', 'yacht', 'cargoship', 'bobcat', 'pacific',
];

const TYPE_LABELS = {
    atm: 'ATM',
    store: 'Store',
    house: 'House',
    vehicle: 'Vehicle',
    ammunation: 'Ammu',
    bank: 'Fleeca',
    moneytruck: 'Money truck',
    cargotruck: 'Cargo truck',
    paleto: 'Paleto',
    jewelry: 'Vangelico',
    train: 'Train',
    yacht: 'Yacht',
    cargoship: 'Ship',
    bobcat: 'Bobcat',
    pacific: 'Pacific',
};

const app = document.getElementById('app');
const typeTabs = document.getElementById('typeTabs');
const heistGrid = document.getElementById('heistGrid');
const lobby = document.getElementById('lobby');
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
    selectedType: 'all',
    selectedLocation: null,
    view: 'contracts',
    brand: 'HEIST PACK',
    subtitle: '15 scenarios',
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
    if (!window.invokeNative) {
        if (name === 'createCrew') {
            const loc = locationById(data.locationId);
            return Promise.resolve({
                ok: true,
                crew: {
                    locationId: data.locationId,
                    maxPlayers: loc?.maxPlayers || 4,
                    members: [{ name: state.name || 'You', host: true }],
                },
            });
        }
        if (name === 'leaveCrew' || name === 'startJob' || name === 'close' || name === 'invite' || name === 'minigameResult') {
            return Promise.resolve({ ok: true });
        }
        if (name === 'nearby') return Promise.resolve([]);
        if (name === 'refresh') return Promise.resolve({ ok: false });
        if (name === 'buyItem') {
            return Promise.resolve({ ok: true, store: state.store, qty: data.qty || 1, label: data.item });
        }
    }
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
    return locationById(state.selectedLocation) || state.locations[0];
}

function stars(n) {
    n = Math.max(1, Math.min(5, n || 1));
    return '◆'.repeat(n) + '◇'.repeat(5 - n);
}

function shortLabel(label) {
    return (label || '').replace('Heists', '').replace('Hits', '').replace('Robberies', '').replace('Theft', '').trim();
}

function setView(view) {
    state.view = view;
    document.querySelectorAll('.rail-btn').forEach((btn) => {
        btn.classList.toggle('active', btn.dataset.view === view);
    });
    document.getElementById('viewContracts').classList.toggle('hidden', view !== 'contracts');
    document.getElementById('viewShop').classList.toggle('hidden', view !== 'shop');
    if (view !== 'contracts') lobby.classList.add('hidden');
}

function renderTabs() {
    const types = [...state.types].sort((a, b) => TYPE_ORDER.indexOf(a.id) - TYPE_ORDER.indexOf(b.id));
    typeTabs.innerHTML = [
        `<button class="tab ${state.selectedType === 'all' ? 'active' : ''}" data-type="all">All</button>`,
        ...types.map((t) => `
            <button class="tab ${state.selectedType === t.id ? 'active' : ''}" data-type="${t.id}">${TYPE_LABELS[t.id] || shortLabel(t.label)}</button>
        `),
    ].join('');
    typeTabs.querySelectorAll('.tab').forEach((btn) => {
        btn.addEventListener('click', () => {
            state.selectedType = btn.dataset.type;
            renderHeistGrid();
            renderTabs();
        });
    });
}

function renderHeistGrid() {
    const rows = state.selectedType === 'all'
        ? state.locations
        : state.locations.filter((l) => l.type === state.selectedType);
    heistGrid.innerHTML = rows.map((loc) => {
        const selected = state.selectedLocation === loc.id ? 'selected' : '';
        const onCd = (loc.cooldown || 0) > 0;
        return `
            <button class="heist-card ${selected}" data-id="${loc.id}">
                <div class="heist-cover t-${loc.type}"></div>
                ${onCd ? `<span class="badge lock">${formatCooldown(loc.cooldown)}</span>` : (loc.armed ? '<span class="badge armed">ARMED</span>' : '')}
                <div class="heist-shade">
                    <h3>${loc.label}</h3>
                    <div class="heist-meta">
                        <span>COPS <b>${loc.minPolice}</b></span>
                        <span>TEAM <b>${loc.minPlayers || 1}-${loc.maxPlayers}</b></span>
                        <span>PAY <b>${loc.payoutLabel}</b></span>
                    </div>
                </div>
            </button>
        `;
    }).join('');
    heistGrid.querySelectorAll('.heist-card').forEach((card) => {
        card.addEventListener('click', () => openLobby(card.dataset.id));
    });
}

function renderLobbyDetail() {
    const loc = selectedLocation();
    const type = loc && typeById(loc.type);
    const cover = document.getElementById('lobbyCover');
    cover.className = `lobby-cover t-${loc?.type || 'bank'}`;
    document.getElementById('heroKicker').textContent = type ? type.label.toUpperCase() : 'HEIST';
    document.getElementById('heroTitle').textContent = loc ? loc.label : 'Choose a heist';
    document.getElementById('heroDesc').textContent = loc ? loc.description : '';
    document.getElementById('heroStars').textContent = stars(loc?.difficulty || type?.difficulty);

    const items = (loc && loc.requiredItems) || [];
    document.getElementById('itemRow').innerHTML = items.length
        ? items.map((item) => `<div class="item-chip">${item.label}${item.count > 1 ? ` x${item.count}` : ''}</div>`).join('')
        : '<p class="muted">No tools listed.</p>';

    if (loc) {
        const onCd = loc.cooldown > 0;
        document.getElementById('detailMeta').innerHTML = `
            <span class="pill">TEAM <em>${loc.minPlayers || 1}–${loc.maxPlayers}</em></span>
            <span class="pill">COPS <em>${loc.minPolice}</em></span>
            <span class="pill">PAYOUT <em>${loc.payoutLabel}</em></span>
            <span class="pill">${onCd ? `LOCKED ${formatCooldown(loc.cooldown)}` : 'READY'}</span>
            ${loc.armed ? '<span class="pill warn">ARMED GUARDS</span>' : ''}
        `;
        document.getElementById('stageList').innerHTML = (loc.stages || []).map((s) => `<li>${s}</li>`).join('');
    } else {
        document.getElementById('detailMeta').innerHTML = '';
        document.getElementById('stageList').innerHTML = '';
    }
}

async function openLobby(locationId) {
    if (state.crew && state.crew.locationId !== locationId) {
        locationId = state.crew.locationId;
    }
    state.selectedLocation = locationId;
    const loc = locationById(locationId);
    if (loc && state.selectedType !== 'all') state.selectedType = loc.type;
    if (!state.crew) {
        const result = await nui('createCrew', { locationId });
        if (result.ok) state.crew = result.crew;
    }
    lobby.classList.remove('hidden');
    render();
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
    document.getElementById('memberList').innerHTML = crew.members.map((m) => `
        <li><span>${m.name}</span>${m.host ? '<span class="host">LEADER</span>' : ''}</li>
    `).join('');
    document.getElementById('inviteBtn').disabled = crew.members.length >= crew.maxPlayers;
    const loc = locationById(crew.locationId);
    document.getElementById('startBtn').textContent = loc ? 'START HEIST' : 'START HEIST';
}

function renderShop() {
    const store = state.store || {};
    document.getElementById('shopLabel').textContent = store.label || 'MARKET';
    document.getElementById('shopSub').textContent = store.subtitle || '';
    document.getElementById('shopBalance').textContent = money(store.balance);
    const grid = document.getElementById('shopGrid');
    if (!store.enabled) {
        grid.innerHTML = '<p class="muted">Market is disabled.</p>';
        return;
    }
    grid.innerHTML = (store.items || []).map((item) => `
        <article class="shop-card" data-item="${item.item}">
            <div class="shop-icon">▣</div>
            <h4>${item.label}</h4>
            <p>${item.description}</p>
            <div class="shop-meta">
                <span class="price">${money(item.price)}</span>
                <span>${item.infinite ? 'IN STOCK' : `${item.stock} LEFT`}</span>
            </div>
            <div class="qty-row">
                <input type="number" min="1" max="${store.maxQty || 10}" value="1" />
                <button ${!item.infinite && item.stock < 1 ? 'disabled' : ''}>BUY</button>
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
    document.getElementById('brandName').textContent = state.brand || 'HEIST PACK';
    document.getElementById('brandSub').textContent = state.subtitle || '15 scenarios';
    document.getElementById('greeting').textContent = state.name || 'Operator';
    document.getElementById('pdCount').textContent = String(state.police || 0);
    document.getElementById('cooldownLabel').textContent = (state.playerCooldown || 0) > 0
        ? formatCooldown(state.playerCooldown)
        : 'Ready';
    renderTabs();
    renderHeistGrid();
    renderLobbyDetail();
    renderCrew();
    renderShop();
}

function applyPayload(payload, tab) {
    const first = (payload.locations || [])[0];
    state = {
        ...state,
        ...payload,
        selectedType: payload?.crew?.type || state.selectedType || 'all',
        selectedLocation: payload?.crew?.locationId || state.selectedLocation || first?.id || null,
        brand: payload?.brand || 'HEIST PACK',
        subtitle: payload?.subtitle || '15 scenarios',
    };
    setView(tab === 'shop' ? 'shop' : (tab || state.view || 'contracts'));
    if (payload?.crew?.locationId) {
        lobby.classList.remove('hidden');
        state.view = 'contracts';
        setView('contracts');
    }
    render();
}

document.querySelectorAll('.rail-btn').forEach((btn) => {
    btn.addEventListener('click', () => {
        setView(btn.dataset.view);
        render();
    });
});

document.getElementById('lobbyBack').addEventListener('click', () => {
    lobby.classList.add('hidden');
});

document.getElementById('closeBtn').addEventListener('click', () => {
    nui('close');
    if (!window.invokeNative) {
        app.classList.add('hidden');
        lobby.classList.add('hidden');
        document.getElementById('nearbyList').classList.add('hidden');
        if (state.job) renderHud(state.job);
    }
});
document.getElementById('leaveBtn').addEventListener('click', async () => {
    await nui('leaveCrew');
    state.crew = null;
    document.getElementById('nearbyList').classList.add('hidden');
    lobby.classList.add('hidden');
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
    document.getElementById('hudTitle').textContent = job.label || 'Heist';
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
        hud.classList.add('hidden');
        applyPayload(payload || {}, tab);
    }
    if (action === 'sync' && payload) {
        applyPayload(payload, state.view);
    }
    if (action === 'close') {
        app.classList.add('hidden');
        lobby.classList.add('hidden');
        document.getElementById('nearbyList').classList.add('hidden');
        if (state.job) renderHud(state.job);
    }
    if (action === 'hud') {
        state.job = job || null;
        if (app.classList.contains('hidden')) renderHud(job);
        else hud.classList.add('hidden');
    }
    if (action === 'minigame') openMinigame(kind, config);
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (!minigame.classList.contains('hidden')) {
            closeMinigame(false);
            return;
        }
        if (!lobby.classList.contains('hidden')) {
            lobby.classList.add('hidden');
            return;
        }
        nui('close');
    }
});

function demoMode() {
    const types = TYPE_ORDER.map((id, i) => ({
        id,
        label: TYPE_LABELS[id] || id,
        description: 'Demo heist',
        maxPlayers: id === 'pacific' || id === 'bobcat' ? 6 : 4,
        minPlayers: 1,
        minPolice: Math.min(6, i),
        cooldown: 1800,
        difficulty: Math.min(5, 1 + Math.floor(i / 3)),
        requiredItems: [],
    }));
    const samples = [
        { id: 'atm_legion', type: 'atm', label: 'ATM — Legion Square', description: 'Drill a street cassette and grab the cash.', payoutLabel: '$1,400 – $2,800', minPolice: 0, maxPlayers: 2, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Drill', count: 1 }], difficulty: 1, stages: ['Drill cassette'], armed: false },
        { id: 'store_grove', type: 'store', label: 'LTD — Grove Street', description: 'Clean the tills, then drill the office safe.', payoutLabel: '$3,200 – $7,800', minPolice: 1, maxPlayers: 4, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Lockpick', count: 1 }, { label: 'Drill', count: 1 }], difficulty: 2, stages: ['Empty registers', 'Drill office safe'], armed: false },
        { id: 'house_grove', type: 'house', label: 'Grove bungalow', description: 'Quiet entry, search every room, leave fast.', payoutLabel: '$4,200 – $8,500', minPolice: 1, maxPlayers: 3, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Lockpick', count: 1 }], difficulty: 2, stages: ['Lockpick door', 'Search rooms'], armed: false },
        { id: 'veh_sultan_city', type: 'vehicle', label: 'Sultan — La Mesa', description: 'Boost the marked car and dump it at the chop.', payoutLabel: '$7,000 – $11,000', minPolice: 1, maxPlayers: 2, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Lockpick', count: 1 }], difficulty: 2, stages: ['Lockpick', 'Deliver'], armed: false },
        { id: 'ammu_pillbox', type: 'ammunation', label: 'Ammunation — Pillbox', description: 'Kill cameras, smash cases, drill the locker.', payoutLabel: 'Guns + cash', minPolice: 2, maxPlayers: 4, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Electronic Kit', count: 1 }], difficulty: 3, stages: ['Hack', 'Smash', 'Locker'], armed: true },
        { id: 'fleeca_legion', type: 'bank', label: 'Fleeca — Legion Square', description: 'Hack the panel, burn the vault, split the boxes.', payoutLabel: '$42,000 – $95,000', minPolice: 2, maxPlayers: 4, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Electronic Kit', count: 1 }, { label: 'Thermite', count: 1 }], difficulty: 3, stages: ['Hack keypad', 'Thermite vault', 'Loot boxes'], armed: true },
        { id: 'truck_city', type: 'moneytruck', label: 'Gruppe Sechs — Legion', description: 'Stop the Stockade, drop the guards, thermite the rear.', payoutLabel: '$34,000 – $58,000', minPolice: 3, maxPlayers: 4, minPlayers: 2, cooldown: 0, requiredItems: [{ label: 'Thermite', count: 1 }], difficulty: 3, stages: ['Intercept', 'Loot crates'], armed: true },
        { id: 'cargo_docks', type: 'cargotruck', label: 'Sealed mule — Elysian', description: 'Hijack the freight mule and crack the container.', payoutLabel: '$18,000 – $32,000', minPolice: 2, maxPlayers: 4, minPlayers: 1, cooldown: 0, requiredItems: [{ label: 'Crowbar', count: 1 }], difficulty: 3, stages: ['Stop mule', 'Crack crate'], armed: true },
        { id: 'paleto_savings', type: 'paleto', label: 'Paleto Savings', description: 'Cut power, thermite the vault, fight county security.', payoutLabel: '$70,000 – $140,000', minPolice: 4, maxPlayers: 5, minPlayers: 2, cooldown: 0, requiredItems: [{ label: 'Electronic Kit', count: 1 }], difficulty: 4, stages: ['Cut power', 'Vault', 'Loot'], armed: true },
        { id: 'vangelico_rockford', type: 'jewelry', label: 'Vangelico — Rockford', description: 'Bypass gallery security, smash displays, thermite the safe.', payoutLabel: '$55,000 – $110,000', minPolice: 4, maxPlayers: 5, minPlayers: 2, cooldown: 0, requiredItems: [{ label: 'Electronic Kit', count: 1 }, { label: 'Crowbar', count: 1 }], difficulty: 4, stages: ['Hack alarm', 'Smash cases', 'Office safe'], armed: true },
        { id: 'train_quartz', type: 'train', label: 'Davis Quartz freight', description: 'Board the freight, drop car guards, grind the cash car.', payoutLabel: '$40,000 – $78,000', minPolice: 4, maxPlayers: 5, minPlayers: 2, cooldown: 0, requiredItems: [{ label: 'Crowbar', count: 1 }], difficulty: 4, stages: ['Crowbar car', 'Drill cash car'], armed: true },
        { id: 'yacht_aquarius', type: 'yacht', label: 'Aquarius yacht', description: 'Board the yacht, clear the crew, loot cabins and the safe.', payoutLabel: '$48,000 – $95,000', minPolice: 4, maxPlayers: 5, minPlayers: 2, cooldown: 0, requiredItems: [{ label: 'Lockpick', count: 1 }], difficulty: 4, stages: ['Board', 'Hack bridge', 'Safe'], armed: true },
        { id: 'ship_elysian', type: 'cargoship', label: 'Elysian freighter', description: 'Hack the container mainframe and lift sealed crates.', payoutLabel: '$55,000 – $105,000', minPolice: 4, maxPlayers: 6, minPlayers: 2, cooldown: 0, requiredItems: [{ label: 'Hacking Laptop', count: 1 }], difficulty: 4, stages: ['Hack mainframe', 'Loot crates'], armed: true },
        { id: 'bobcat_cypress', type: 'bobcat', label: 'Bobcat Security', description: 'Fight the yard, plant C4, empty the cages.', payoutLabel: '$90,000 – $160,000', minPolice: 5, maxPlayers: 6, minPlayers: 3, cooldown: 120, requiredItems: [{ label: 'C4 Charge', count: 1 }], difficulty: 5, stages: ['Hack gate', 'C4 vault', 'Loot cages'], armed: true },
        { id: 'pacific_standard', type: 'pacific', label: 'Pacific Standard', description: 'Kill rooftop power, crack the pad, C4 the vault, empty trolleys.', payoutLabel: '$180,000 – $320,000', minPolice: 6, maxPlayers: 6, minPlayers: 3, cooldown: 0, requiredItems: [{ label: 'Hacking Laptop', count: 1 }, { label: 'C4 Charge', count: 1 }], difficulty: 5, stages: ['Cut power', 'Hack keypad', 'C4 vault', 'Loot trolleys'], armed: true },
    ];
    applyPayload({
        ok: true,
        name: 'Adin Primrose',
        police: 4,
        playerCooldown: 0,
        types,
        locations: samples,
        crew: null,
        store: {
            enabled: true,
            label: 'MARKET',
            subtitle: 'Buy kit before you start a scenario.',
            balance: 12450,
            maxQty: 10,
            items: [
                { item: 'lockpick', label: 'Lockpick', description: 'Tills, house doors, and boost cars.', price: 250, infinite: true, stock: 999 },
                { item: 'thermite', label: 'Thermite', description: 'Vault doors and armored plating.', price: 3600, infinite: false, stock: 10 },
                { item: 'c4_charge', label: 'C4 Charge', description: 'Pacific vault and Bobcat cages.', price: 5200, infinite: false, stock: 6 },
                { item: 'hacking_laptop', label: 'Laptop', description: 'Pacific and cargo-ship mainframes.', price: 4200, infinite: false, stock: 8 },
                { item: 'drill', label: 'Drill', description: 'ATMs, safes, lockers, freight seals.', price: 2800, infinite: true, stock: 999 },
                { item: 'robbery_tablet', label: 'Tablet', description: 'Opens the heist pack.', price: 8500, infinite: false, stock: 4 },
            ],
        },
        brand: 'HEIST PACK',
        subtitle: '15 scenarios',
    }, 'contracts');
    app.classList.remove('hidden');
    state.job = {
        label: 'Pacific Standard',
        remaining: 1420,
        stages: ['Cut rooftop power', 'Hack inner keypad', 'C4 vault', 'Loot trolleys'],
        completed: { power: true },
    };
}

if (!window.invokeNative) {
    window.addEventListener('DOMContentLoaded', demoMode);
}
