/**
 * testing ORDS handlers using the JavaScript fetch() API. The idea is to
 * - insert a document first
 * - get the newly inserted document's _id and store it in a global variable
 * - update the document
 * - delete the document
 */

// ------- global variable to store the _id of the last document insert. 
let ID;

import validator from 'validator';
import { describe, expect, test } from "vitest";

describe('testing ORDS handlers using the fetch() API', () => {

    test('ensure the ORDS endpoint (URL) is a valid URL', () => {

        expect(
            validator
                .isURL(
                    import.meta.env.VITE_ORDS_URL,
                    { protocols: ['http', 'https'], require_protocol: true, allow_fragments: false, }))
                .toBe(true);

    })

    test('POST to the JSON Relational Duality View', async() => {

        // note that the ORDS handler should update the price to the nearest 99 cents
        // and consolidate the stock into 1 warehouse. This is tested next.

        const newThing = {
            "available": "2024-08-16",
            "category": "books",
            "description": "A fantastic book about everyone's favourite wine",
            "name": "A history of Carlo Rossi",
            "price": 10.25,
            "stock": [
                {
                    "quantity": 11,
                    "warehouse": "baltimore"
                },
                {
                    "quantity": 11,
                    "warehouse": "baltimore"
                }
            ]
        };

        const response = await fetch(
            `${import.meta.env.VITE_ORDS_URL}/things/`, {
                body: JSON.stringify(newThing),
                method: 'POST'
            }
        );

        expect(response.ok).toBeTruthy();
    })

    test("GET the inserted document from the JSON Relational Duality View", async () => {

        // using limit = 1 means even if previous tests failed only 1 
        // matching document is fetched.
        const response = await fetch(
            `${import.meta.env.VITE_ORDS_URL}/things/?searchTerm=carlo&limit=1`
        )

        if (response.ok) {
            const json = await response.json();
            this.ID = json.items[0]._id;
        }

        expect (this.ID).toBeTypeOf('number');
    });

    test("validate the price has been rounded to the nearest 99 cent", async () => {

        const response = await fetch(
            `${import.meta.env.VITE_ORDS_URL}/things/${this.ID}`
        )

        if (! response.ok) {

            throw new Error(`failed to fetch document with ID ${this.ID}`);
        }

        const json = await response.json();

        expect (json.items[0].price.toString().split('.')[1]).toBe('99');
    });

    test("ensure multiple entries for stock are consolildated in the same warehouse", async() => {

        const response = await fetch(
            `${import.meta.env.VITE_ORDS_URL}/things/${this.ID}`
        )

        if (! response.ok) {

            throw new Error(`failed to fetch document with ID ${this.ID}`);
        }

        const json = await response.json();

        const array = json.items[0].stock.map( x => x.warehouse).sort();
        const dupes = array.filter((e, i, a) => a.indexOf(e) !== i);

        expect (dupes).toHaveLength(0);
    })

    test("update the document using a PUT call against the JSON Relational Duality View", async() => {

        const updatedThing = {
            "_id": this.ID,
            "available": "2024-08-16",
            "category": "books",
            "description": "A fantastic book about everyone's favourite wine",
            "name": "A history of Carlo Rossi, updated by vitest",
            "price": 19.12,
            "stock": [
                {
                    "quantity": 22,
                    "warehouse": "baltimore"
                }
            ]
        };

        const response = await fetch(
            `${import.meta.env.VITE_ORDS_URL}/things/${this.ID}`, {
                body: JSON.stringify(updatedThing),
                method: 'PUT'
            }
        );

        expect (response.ok).toBeTruthy();

    });

    test("DELETE the document from the JSON Relational Duality View", async () => {

        const response = await fetch(
            `${import.meta.env.VITE_ORDS_URL}/things/${this.ID}`, {
                method: 'DELETE'
            }
        );

        expect (response.ok).toBeTruthy();

    })
})