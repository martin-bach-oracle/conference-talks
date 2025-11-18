/**
 * Sample data generation utilities for an Oracle MLE/APEX environment.
 *
 * Uses:
 * - @faker-js/faker to generate realistic fake data.
 * - session: global from MLE/APEX for executing SQL statements.
 * - oracledb: global providing DB types for bind parameters (e.g., DB_TYPE_NUMBER, DB_TYPE_JSON, DB_TYPE_VARCHAR).
 *
 * Note:
 * - Comments only as requested; no logic or behavior has been changed.
 */

import { faker } from '@faker-js/faker';

/**
 * Inserts `numRows` sample recipients into table EML_RECIPIENTS.
 *
 * Behavior:
 * - Generates a random email address per row via faker.
 * - Inserts the email using a positional bind variable (:recipient).
 * - Audit columns are set by the database (localtimestamp, user).
 *
 * Environment:
 * - Expects a global `session` (Oracle MLE/APEX) to execute SQL.
 *
 * @param numRows Number of recipient rows to generate and insert.
 * @returns void
 */
export function generateSampleRecipients(numRows: number): void {
    for (let i = 0; i < numRows; i++) {
        // Generate a random email address (e.g., "jane.doe@example.com").
        const recipient = faker.internet.email();

        // TODO: This standalone statement is a no-op; preserved intentionally per "comments only" scope.
        //       It does not execute anything and can be removed if desired.
        session.execute;

        // Insert a single recipient row using a positional bind for :recipient.
        // The database sets created_on and created_by automatically.
        session.execute(
            `insert into eml_recipients (
                recipient_email, created_on, created_by
            ) values (
                :recipient, localtimestamp, user
            )`,
            [recipient],
        );
    }
}

/**
 * Inserts `numRows` sample emails into table EML_EMAIL_CONTENT.
 *
 * Behavior:
 * - Reads existing recipients (IDs) from EML_RECIPIENTS.
 * - For each email to generate:
 *   - Creates metadata (priority + timestamp),
 *   - Generates a subject and a JSON body using faker,
 *   - Inserts a row using named binds with explicit oracledb types.
 *
 * Throws:
 * - Error when no recipients exist in the database.
 *
 * Environment:
 * - Expects `session` and `oracledb` globals provided by the Oracle MLE/APEX runtime.
 *
 * @param numRows Number of email content rows to generate and insert.
 * @returns void
 */
export function generateSampleEmail(numRows: number): void {
    // Load available recipients; structure of `result` depends on MLE runtime.
    let result = session.execute('select id from eml_recipients');

    // Ensure at least one recipient exists to reference.
    if (result.rows === undefined || result.rows.length === 0) {
        throw new Error('could not locate any email recipients in the database');
    }

    // Keep the result rows locally. The property name casing (ID) follows the runtime.
    const recipients = result.rows;

    // NOTE: A single random recipient is chosen here (outside the loop),
    // so all generated emails will reference this one recipient. Preserved as-is.
    const randomRecipientId = recipients[Math.floor(Math.random() * recipients?.length)].ID;

    for (let i = 0; i < numRows; i++) {
        // Create a realistic timestamp between 2020-01-01 and 2025-01-01.
        const emailTimestamp = faker.date.between({ from: '2020-01-01T00:00:00.000Z', to: '2025-01-01T00:00:00.000Z' });

        // Simple priority bucketing based on the loop counter.
        // NOTE: As written, `i % 10` is always in [0..9]. The `else if (<= 9)` branch matches
        // for values 3..9, so the final `else` ("high") is unreachable. Preserved unchanged.
        let emailPriority: string;
        if (i % 10 <= 2) {
            emailPriority = 'low';
        } else if (i % 10 <= 9) {
            emailPriority = 'normal';
        } else {
            emailPriority = 'high';
        }

        // Structured metadata attached to each email row.
        const metadata = {
            priority: emailPriority,
            timestamp: emailTimestamp,
        };

        // Short subject line with 3–5 words.
        const subject = faker.lorem.sentence({ min: 3, max: 5 });

        // Alternate body shape to demonstrate variety:
        // - Every 10th row: shorter "hacker phrase"
        // - Otherwise: multiple lorem paragraphs
        let body: object;
        if (i % 10 === 0) {
            body = {
                greeting: 'yo!',
                message: faker.hacker.phrase(),
            };
        } else {
            body = {
                greeting: 'hello',
                message: faker.lorem.paragraphs(5),
            };
        }

        // Insert into EML_EMAIL_CONTENT using named bind parameters and explicit oracledb types:
        // - recipient_id: NUMBER
        // - metadata: JSON
        // - subject: VARCHAR
        // - body: JSON
        // created_on/created_by are set by the database.
        result = session.execute(
            `insert into eml_email_content (
                recipient_id,
                metadata,
                subject,
                body,
                created_on,
                created_by
            ) values (
                :recipient_id,
                :metadata,
                :subject,
                :body,
                localtimestamp,
                user
            )`,
            {
                recipient_id: {
                    type: oracledb.DB_TYPE_NUMBER,
                    dir: oracledb.BIND_IN,
                    val: randomRecipientId,
                },
                metadata: {
                    type: oracledb.DB_TYPE_JSON,
                    dir: oracledb.BIND_IN,
                    val: metadata,
                },
                subject: {
                    type: oracledb.DB_TYPE_VARCHAR,
                    dir: oracledb.BIND_IN,
                    val: subject,
                },
                body: {
                    type: oracledb.DB_TYPE_JSON,
                    dir: oracledb.BIND_IN,
                    val: body,
                },
            },
        );
    }
}
