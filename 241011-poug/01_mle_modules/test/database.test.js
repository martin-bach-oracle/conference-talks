/**
 * Database Tests
 *
 * Using vitest to perform unit tests against JavaScript code deployed against the
 * database. The tests are controlled using vitest run, whereas the code is executed
 * in Oracle Database 23ai.
 */

import * as api from "../../tools/api.js";
import { afterAll, beforeAll, describe, expect, test } from "vitest";

describe("unit testing using vitest", () => {
	// initialise the connection to the database for all unit tests
	beforeAll(async () => {
		const options = {
			// used in combination with dbConfig.js
			adb: true,
			pool: false,
			env: "test",
		};

		await api.init(options);
	});

	describe("testing invalid input - prices", () => {
		test("ensure negative prices are rejected", async () => {
			const result = await session.execute(
				`select DEMO_THINGS_PKG.VALIDATEPRICE('-1')`,
				[],
				{ outFormat: oracledb.OUT_FORMAT_ARRAY }
			);

			expect(result.rows[0][0]).toBe(false);
		});
		
		test("ensure there are no more than 2 decimal places", async() => {
			const result = await session.execute(
				`select DEMO_THINGS_PKG.VALIDATEPRICE('100.2222')`,
				[],
				{ outFormat: oracledb.OUT_FORMAT_ARRAY }
			);

			expect(result.rows[0][0]).toBe(false);
		});

		test("disallow prices in excess of 99999.99 monetary units", async () => {
			const result = await session.execute(
				`select DEMO_THINGS_PKG.VALIDATEPRICE('100000000')`,
				[],
				{ outFormat: oracledb.OUT_FORMAT_ARRAY }
			);

			expect(result.rows[0][0]).toBe(false);
		});
	});

	describe("testing invalid input - quantity",  () => {
		test("reject fractional quantity", async () => {
			const result = await session.execute(
				`select DEMO_THINGS_PKG.VALIDATEQUANTITY('1.2')`,
				[],
				{ outFormat: oracledb.OUT_FORMAT_ARRAY }
			);

			expect(result.rows[0][0]).toBe(false);
		});

		test("reject negative quantity", async () => {
			const result = await session.execute(
				`select DEMO_THINGS_PKG.VALIDATEQUANTITY('-1')`,
				[],
				{ outFormat: oracledb.OUT_FORMAT_ARRAY }
			);

			expect(result.rows[0][0]).toBe(false);
		});

		test("ensure quantity > 0 is accepted", async () => {
			const result = await session.execute(
				`select DEMO_THINGS_PKG.VALIDATEQUANTITY('42')`,
				[],
				{ outFormat: oracledb.OUT_FORMAT_ARRAY }
			);

			expect(result.rows[0][0]).toBe(true);
		});
	});

	afterAll(async () => {
		await api.tearDown();
	});
});
