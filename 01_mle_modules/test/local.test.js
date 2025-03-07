import { validatePrice, validateQuantity } from "../mle/business_logic";
import { describe, expect, test } from "vitest";

describe("unit testing using vitest", () => {
	describe("testing invalid input - prices", () => {
		test("ensure negative prices are rejected", () => {
			expect(validatePrice("-1")).toBe(false);
		});
		test("ensure there are no more than 2 decimal places", () => {
			expect(validatePrice("0.0002")).toBe(false);
		});
		test("disallow prices in excess of 99999.99 monetary units", () => {
			expect(validatePrice("100000")).toBe(false);
		});
	});

	describe("testing invalid input - quantity", () => {
		test("reject fractional quantity", () => {
			expect(validateQuantity("1.2")).toBe(false);
		});

		test("reject negative quantity", () => {
			expect(validateQuantity("-1")).toBe(false);
		});

		test("ensure quantity > 0 is accepted", () => {
			expect(validateQuantity("42")).toBe(true);
		});
	});
});
