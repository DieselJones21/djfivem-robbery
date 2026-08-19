const app = document.getElementById('app');
const typeTabs = document.getElementById('typeTabs');
const locationList = document.getElementById('locationList');
const listTitle = document.getElementById('listTitle');
const listSub = document.getElementById('listSub');
const policeCount = document.getElementById('policeCount');
const greeting = document.getElementById('greeting');
const crewEmpty = document.getElementById('crewEmpty');
const crewBody = document.getElementById('crewBody');
const crewContract = document.getElementById('crewContract');
const crewSlots = document.getElementById('crewSlots');
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

function renderTabs() {
    const order = ['bank', 'store', 'atm', 'vehicle', 'moneytruck', 'ammunation'];
    const types = [...state.types].sort((a, b) => order.indexOf(a.id) - order.indexOf(b.id));
    typeTabs.innerHTML = types.map((t) => `
        <button class="tab ${state.selectedType === t.id ? 'active' : ''}" data-type="${t.id}">
            ${t.label} · ${t.maxPlayers}p
        </button>
    `).join('');
    typeTabs.querySelectorAll('.tab').forEach((btn) => {
        btn.addEventListener('click', () => {
            state.selectedType = btn.dataset.type;
            state.selectedLocation = null;
            render();
        });
    });
}

function renderLocations() {
    const type = typeById(state.selectedType);
    const rows = state.locations.filter((l) => l.type === state.selectedType);
    listTitle.textContent = type ? type.label : 'Contracts';
    listSub.textContent = type
        ? `${type.description} Max crew ${type.maxPlayers}. Police needed ${type.minPolice}+.`
        : 'Select a job type.';

    locationList.innerHTML = rows.map((loc) => {
        const selected = state.selectedLocation === loc.id ? 'selected' : '';
        const ready = loc.available && state.police >= loc.minPolice;
        return `
            <article class="card ${selected}" data-id="${loc.id}">
                <h3>${loc.label}</h3>
                <p>${loc.description}</p>
                <div class="meta">
                    <span class="tag">${loc.payoutLabel}</span>
                    <span class="tag">${loc.maxPlayers} players</span>
                    <span class="tag">${loc.minPolice} police</span>
                    ${ready
                        ? '<span class="tag ok">Ready</span>'
                        : `<span class="tag down">${loc.available ? 'Need police' : 'Cooldown ' + formatCooldown(loc.cooldown)}</span>`}
                </div>
            </article>
        `;
    }).join('');

    locationList.querySelectorAll('.card').forEach((card) => {
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
    crewContract.textContent = loc ? loc.label : crew.locationId;
    crewSlots.textContent = `${crew.members.length} / ${crew.maxPlayers} operators`;
    memberList.innerHTML = crew.members.map((m) => `
        <li>
            <span>${m.name}</span>
            ${m.host ? '<span class="host">LEADER</span>' : ''}
        </li>
    `).join('');
    document.getElementById('inviteBtn').disabled = crew.members.length >= crew.maxPlayers;
    document.getElementById('startBtn').textContent = type
        ? `Start ${type.label}`
        : 'Start contract';
}

function render() {
    greeting.textContent = state.name || 'Operator';
    policeCount.textContent = String(state.police ?? 0);
    renderTabs();
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
        state = {
            ...state,
            ...payload,
            selectedType: payload?.crew?.type || state.selectedType || 'bank',
            selectedLocation: payload?.crew?.locationId || null,
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
