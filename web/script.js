const JOB_IMAGES = {
    fleeca_legion: 'images/jobs/fleeca.jpg',
    fleeca_alta: 'images/jobs/fleeca.jpg',
    fleeca_burton: 'images/jobs/fleeca.jpg',
    paleto_savings: 'images/jobs/paleto.jpg',
    store_grove: 'images/jobs/ltd.jpg',
    store_seoul: 'images/jobs/ltd.jpg',
    store_innocence: 'images/jobs/store247.jpg',
    store_vinewood: 'images/jobs/store247.jpg',
    store_sandy: 'images/jobs/store247.jpg',
    store_paleto: 'images/jobs/store247.jpg',
    atm_legion: 'images/jobs/atm-city.jpg',
    atm_pillbox: 'images/jobs/atm-city.jpg',
    atm_grove: 'images/jobs/atm-city.jpg',
    atm_vinewood: 'images/jobs/atm-city.jpg',
    atm_paleto: 'images/jobs/atm-rural.jpg',
    atm_sandy: 'images/jobs/atm-rural.jpg',
    veh_sultan_city: 'images/jobs/sultan.jpg',
    veh_buffalo_vinewood: 'images/jobs/buffalo.jpg',
    veh_banshee_docks: 'images/jobs/banshee.jpg',
    veh_sultanrs_sandy: 'images/jobs/sultanrs.jpg',
    truck_city: 'images/jobs/truck-city.jpg',
    truck_paleto: 'images/jobs/truck-rural.jpg',
    truck_sandy: 'images/jobs/truck-rural.jpg',
    ammu_pillbox: 'images/jobs/ammu-city.jpg',
    ammu_vinewood: 'images/jobs/ammu-city.jpg',
    ammu_seoul: 'images/jobs/ammu-city.jpg',
    ammu_sandy: 'images/jobs/ammu-town.jpg',
    ammu_paleto: 'images/jobs/ammu-town.jpg',
};

const TYPE_IMAGES = {
    bank: 'images/jobs/fleeca.jpg',
    store: 'images/jobs/store247.jpg',
    atm: 'images/jobs/atm-city.jpg',
    vehicle: 'images/jobs/sultan.jpg',
    moneytruck: 'images/jobs/truck-city.jpg',
    ammunation: 'images/jobs/ammu-city.jpg',
};

const ITEM_IMAGES = {
    lockpick: 'images/items/lockpick.svg',
    drill: 'images/items/drill.jpg',
    electronickit: 'images/items/electronickit.jpg',
    thermite: 'images/items/thermite.jpg',
    crowbar: 'images/items/crowbar.jpg',
};

const TAB_ICONS = {
    bank: '<svg viewBox="0 0 24 24"><path d="M3 10h18M5 10v8h14v-8M12 4l9 6H3z"/></svg>',
    store: '<svg viewBox="0 0 24 24"><path d="M4 7h16l-1 13H5L4 7zM4 7l1-3h14l1 3"/></svg>',
    atm: '<svg viewBox="0 0 24 24"><rect x="6" y="3" width="12" height="18" rx="2"/><path d="M9 8h6M9 12h6"/></svg>',
    vehicle: '<svg viewBox="0 0 24 24"><path d="M4 14h16l-2-6H6zM6 18h.01M18 18h.01"/></svg>',
    moneytruck: '<svg viewBox="0 0 24 24"><rect x="3" y="8" width="13" height="8" rx="1"/><path d="M16 10h4v6h-4M7 18h.01M18 18h.01"/></svg>',
    ammunation: '<svg viewBox="0 0 24 24"><path d="M8 15l8-8M6 18h4M14 6h4"/></svg>',
};

const app = document.getElementById('app');
const typeTabs = document.getElementById('typeTabs');
const locationList = document.getElementById('locationList');
const listTitle = document.getElementById('listTitle');
const listSub = document.getElementById('listSub');
const cooldownLabel = document.getElementById('cooldownLabel');
const greeting = document.getElementById('greeting');
const heroImage = document.getElementById('heroImage');
const heroTitle = document.getElementById('heroTitle');
const heroKicker = document.getElementById('heroKicker');
const heroDesc = document.getElementById('heroDesc');
const itemRow = document.getElementById('itemRow');
const detailMeta = document.getElementById('detailMeta');
const metrics = document.getElementById('metrics');
const crewEmpty = document.getElementById('crewEmpty');
const crewBody = document.getElementById('crewBody');
const memberList = document.getElementById('memberList');
const nearbyList = document.getElementById('nearbyList');

let state = {
    types: [],
    locations: [],
    crew: null,
    job: null,
    police: 0,
    name: 'Operator',
    selectedType: 'bank',
    selectedLocation: null,
};

function nui(name, data = {}) {
    return fetch(`https://${GetParentResourceName()}/${name}`, {
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

function typeById(id) {
    return state.types.find((t) => t.id === id);
}

function locationById(id) {
    return state.locations.find((l) => l.id === id);
}

function jobImage(loc) {
    if (!loc) return TYPE_IMAGES[state.selectedType];
    return JOB_IMAGES[loc.id] || TYPE_IMAGES[loc.type];
}

function itemImage(name) {
    return ITEM_IMAGES[name] || ITEM_IMAGES.lockpick;
}

function selectedLocation() {
    return locationById(state.selectedLocation) || state.locations.find((l) => l.type === state.selectedType);
}

function renderTabs() {
    const order = ['bank', 'store', 'atm', 'vehicle', 'moneytruck', 'ammunation'];
    const types = [...state.types].sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
    typeTabs.innerHTML = types.map((t) => `
        <button class="tab ${state.selectedType === t.id ? 'active' : ''}" data-type="${t.id}">
            ${TAB_ICONS[t.id] || ''}
            <span>${t.label.replace(' Robberies', '').replace(' Hits', '').replace(' Jobs', '').replace(' Heists', '')}</span>
        </button>
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

function renderMetrics() {
    const loc = selectedLocation();
    const type = typeById(state.selectedType);
    const onCd = loc && loc.cooldown > 0;
    const crewCount = state.crew ? state.crew.members.length : 0;
    metrics.innerHTML = `
        <article class="metric">
            <p>Crew</p>
            <strong>${crewCount}/${type ? type.maxPlayers : 0}</strong>
            <b>${state.crew ? 'Formed' : 'Open'}</b>
        </article>
        <article class="metric">
            <p>Location cooldown</p>
            <strong>${onCd ? formatCooldown(loc.cooldown) : 'Ready'}</strong>
            <b class="${onCd ? 'red' : 'ok'}">${loc ? formatCooldown(loc.cooldownDuration) + ' timer' : '—'}</b>
        </article>
        <article class="metric">
            <p>Payout</p>
            <strong>${loc ? loc.payoutLabel.replace(' – ', '–') : '—'}</strong>
            <b class="ok">Dirty cash</b>
        </article>
        <article class="metric">
            <p>Players</p>
            <strong>${type ? `1–${type.maxPlayers}` : '—'}</strong>
            <b>No cops required</b>
        </article>
    `;
}

function renderDetail() {
    const loc = selectedLocation();
    const type = typeById(state.selectedType);
    heroImage.src = jobImage(loc);
    heroKicker.textContent = type ? type.label : 'Contracts';
    heroTitle.textContent = loc ? loc.label : 'Choose a target';
    heroDesc.textContent = loc ? loc.description : (type ? type.description : '');

    const items = (loc && loc.requiredItems) || [];
    itemRow.innerHTML = items.length ? items.map((item) => `
        <div class="item-chip">
            <img src="${itemImage(item.name)}" alt="${item.label}" />
            <span>${item.label}${item.count > 1 ? ` x${item.count}` : ''}</span>
        </div>
    `).join('') : '<p class="muted">No tools listed.</p>';

    if (loc) {
        const onCd = loc.cooldown > 0;
        detailMeta.innerHTML = `
            <span class="pill">Crew <em>1–${loc.maxPlayers}</em></span>
            <span class="pill">Cooldown <em>${formatCooldown(loc.cooldownDuration)}</em></span>
            <span class="pill">${onCd ? `Locked ${formatCooldown(loc.cooldown)}` : 'Available now'}</span>
        `;
    } else {
        detailMeta.innerHTML = '';
    }
}

function renderLocations() {
    const type = typeById(state.selectedType);
    const rows = state.locations.filter((l) => l.type === state.selectedType);
    listTitle.textContent = type ? type.label : 'Targets';
    listSub.textContent = type
        ? `${type.maxPlayers} player max · ${formatCooldown(type.cooldown)} cooldown`
        : 'Select a category';

    locationList.innerHTML = rows.map((loc) => {
        const selected = state.selectedLocation === loc.id ? 'selected' : '';
        const onCd = (loc.cooldown || 0) > 0;
        return `
            <button class="target ${selected}" data-id="${loc.id}">
                <img src="${jobImage(loc)}" alt="${loc.label}" />
                <div class="target-copy">
                    <h4>${loc.label}</h4>
                    <p>${loc.payoutLabel}</p>
                    <p class="status ${onCd ? 'down' : ''}">${onCd ? 'Cooldown ' + formatCooldown(loc.cooldown) : 'Ready'}</p>
                </div>
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
    if (!crew) {
        crewEmpty.classList.remove('hidden');
        crewBody.classList.add('hidden');
        nearbyList.classList.add('hidden');
        return;
    }
    crewEmpty.classList.add('hidden');
    crewBody.classList.remove('hidden');
    const loc = locationById(crew.locationId);
    const type = loc && typeById(loc.type);
    memberList.innerHTML = crew.members.map((m) => `
        <li>
            <span>${m.name}</span>
            ${m.host ? '<span class="host">LEADER</span>' : ''}
        </li>
    `).join('');
    document.getElementById('inviteBtn').disabled = crew.members.length >= crew.maxPlayers;
    document.getElementById('startBtn').textContent = loc ? `Start ${loc.label}` : 'Start robbery';
    if (type && loc && loc.type !== state.selectedType) {
        state.selectedType = loc.type;
    }
}

function render() {
    greeting.textContent = state.name || 'Operator';
    cooldownLabel.textContent = (state.playerCooldown || 0) > 0
        ? formatCooldown(state.playerCooldown)
        : 'Ready';
    renderTabs();
    renderMetrics();
    renderDetail();
    renderLocations();
    renderCrew();
}

document.getElementById('closeBtn').addEventListener('click', () => nui('close'));
document.getElementById('leaveBtn').addEventListener('click', async () => {
    await nui('leaveCrew');
    state.crew = null;
    nearbyList.classList.add('hidden');
    const fresh = await nui('refresh');
    if (fresh.ok) Object.assign(state, fresh);
    render();
});
document.getElementById('inviteBtn').addEventListener('click', async () => {
    const nearby = await nui('nearby');
    nearbyList.classList.remove('hidden');
    if (!nearby || nearby.length === 0) {
        nearbyList.innerHTML = '<p class="muted">Nobody nearby.</p>';
        return;
    }
    nearbyList.innerHTML = nearby.map((p) => `
        <button data-src="${p.source}">Invite ${p.name}</button>
    `).join('');
    nearbyList.querySelectorAll('button').forEach((btn) => {
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

window.addEventListener('message', (event) => {
    const { action, payload } = event.data || {};
    if (action === 'open') {
        const first = (payload.locations || []).find((l) => l.type === (payload.crew?.type || 'bank'));
        state = {
            ...state,
            ...payload,
            selectedType: payload?.crew?.type || state.selectedType || 'bank',
            selectedLocation: payload?.crew?.locationId || first?.id || null,
        };
        app.classList.remove('hidden');
        render();
    }
    if (action === 'close') {
        app.classList.add('hidden');
        nearbyList.classList.add('hidden');
    }
});

window.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') nui('close');
});
