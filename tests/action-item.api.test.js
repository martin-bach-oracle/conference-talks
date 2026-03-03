import { afterEach, describe, expect, it } from 'vitest';

const BASE_URL = process.env.ORDS_BASE_URL ?? 'http://localhost:8080/ords/emily/js';
const ACTION_ITEM_COLLECTION_PATH = '/actionItem/';
const ACTION_ITEM_ITEM_PATH = '/actionItem';

const createdIds = new Set();

function endpoint(path) {
	return `${BASE_URL}${path}`;
}

async function request(path, { method = 'GET', body, headers } = {}) {
	const response = await fetch(endpoint(path), {
		method,
		headers: {
			'content-type': 'application/json',
			...headers,
		},
		body: body ? JSON.stringify(body) : undefined,
	});

	let payload = null;
	const rawText = await response.text();
	if (rawText) {
		try {
			payload = JSON.parse(rawText);
		} catch {
			payload = rawText;
		}
	}

	return { response, payload };
}

function validCreateBody(suffix = 'base') {
	return {
		actionName: `new action ${suffix} task`,
		status: 'OPEN',
		team: [
			{ role: 'LEAD', staffName: 'avery johnson', staffId: 1 },
			{ role: 'MEMBER', staffName: 'blake ramirez', staffId: 2 },
		],
	};
}

async function createActionItemForTest(suffix = 'seed') {
	const { response, payload } = await request(ACTION_ITEM_COLLECTION_PATH, {
		method: 'POST',
		body: validCreateBody(suffix),
	});

	expect(response.status).toBe(201);
	expect(payload).toBeTruthy();
	expect(payload.actionId).toBeTypeOf('number');
	createdIds.add(payload.actionId);
	return payload;
}

afterEach(async () => {
	for (const id of Array.from(createdIds)) {
		try {
			await request(`${ACTION_ITEM_ITEM_PATH}/${id}`, { method: 'DELETE' });
		} finally {
			createdIds.delete(id);
		}
	}
});

describe('GET /actionItem/', () => {
	it('returns list of action items (positive)', async () => {
		const { response, payload } = await request(ACTION_ITEM_COLLECTION_PATH);

		expect(response.status).toBe(200);
		expect(payload).toBeTruthy();
		expect(payload.items).toBeTypeOf('object');
		expect(Array.isArray(payload.items)).toBe(true);
		expect(payload).toHaveProperty('hasMore');
		expect(payload).toHaveProperty('totalRows');
	});

	it('rejects invalid query params (negative)', async () => {
		const { response, payload } = await request(
			`${ACTION_ITEM_COLLECTION_PATH}?search=invalid***`
		);

		expect(response.status).toBe(400);
		expect(payload).toBeTruthy();
	});
});

describe('POST /actionItem/', () => {
	it('creates an action item (positive)', async () => {
		const { response, payload } = await request(ACTION_ITEM_COLLECTION_PATH, {
			method: 'POST',
			body: validCreateBody('post-positive'),
		});

		expect(response.status).toBe(201);
		expect(payload).toBeTruthy();
		expect(payload.actionId).toBeTypeOf('number');
		expect(payload.actionName).toContain('post-positive');
		expect(Array.isArray(payload.team)).toBe(true);
		createdIds.add(payload.actionId);
	});

	it('rejects invalid payload (negative)', async () => {
		const { response, payload } = await request(ACTION_ITEM_COLLECTION_PATH, {
			method: 'POST',
			body: {
				actionName: 'short',
				status: 'OPEN',
				team: [{ role: 'LEAD', staffName: 'avery johnson', staffId: 1 }],
			},
		});

		expect(response.status).toBe(400);
		expect(payload).toBeTruthy();
	});
});

describe('GET /actionItem/{id}', () => {
	it('returns an existing action item (positive)', async () => {
		const { response, payload } = await request(`${ACTION_ITEM_ITEM_PATH}/2`);

		expect(response.status).toBe(200);
		expect(payload).toBeTruthy();
		expect(payload.actionId).toBe(2);
		expect(payload.team).toBeTypeOf('object');
		expect(Array.isArray(payload.team)).toBe(true);
	});

	it('rejects non-numeric id (negative)', async () => {
		const { response, payload } = await request(`${ACTION_ITEM_ITEM_PATH}/abc`);

		expect(response.status).toBe(400);
		expect(payload).toBeTruthy();
	});
});

describe('PUT /actionItem/{id}', () => {
	it('updates an existing action item (positive)', async () => {
		const created = await createActionItemForTest('put-source');

		const updateBody = {
			actionId: created.actionId,
			actionName: `updated action ${created.actionId} task`,
			status: 'COMPLETE',
			team: created.team.map((member) => ({
				assignmentId: member.assignmentId,
				role: member.role,
				staffName: member.staffName,
				staffId: member.staffId,
			})),
		};

		const { response, payload } = await request(
			`${ACTION_ITEM_ITEM_PATH}/${created.actionId}`,
			{
				method: 'PUT',
				body: updateBody,
			}
		);

		expect(response.status).toBe(200);
		expect(payload).toBeTruthy();
		expect(payload.actionId).toBe(created.actionId);
		expect(payload.actionName).toBe(updateBody.actionName);
		expect(payload.status).toBe('COMPLETE');
	});

	it('rejects invalid update payload (negative)', async () => {
		const { response, payload } = await request(`${ACTION_ITEM_ITEM_PATH}/2`, {
			method: 'PUT',
			body: {
				actionId: 2,
				actionName: 'too short',
				status: 'OPEN',
				team: [],
			},
		});

		expect(response.status).toBe(400);
		expect(payload).toBeTruthy();
	});
});

describe('DELETE /actionItem/{id}', () => {
	it('deletes an existing action item (positive)', async () => {
		const created = await createActionItemForTest('delete-source');
		const id = created.actionId;

		const { response } = await request(`${ACTION_ITEM_ITEM_PATH}/${id}`, {
			method: 'DELETE',
		});

		expect(response.status).toBe(204);
		createdIds.delete(id);
	});

	it('rejects non-numeric id (negative)', async () => {
		const { response, payload } = await request(`${ACTION_ITEM_ITEM_PATH}/not-a-number`, {
			method: 'DELETE',
		});

		expect(response.status).toBe(400);
		expect(payload).toBeTruthy();
	});
});
