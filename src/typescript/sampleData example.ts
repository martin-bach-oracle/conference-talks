/**
 * Sample-data generation utilities for the demo schema.
 *
 * This module:
 * - Inserts fake recipients into the eml_recipients table (parent)
 * - Inserts fake emails into the eml_email_content table (child)
 *
 * Dependencies/assumptions:
 * - A global `session` object provides `execute(...)` for SQL statements.
 * - A global `oracledb` object provides DB type constants for binds.
 * - Faker is used to generate realistic yet fake values.
 */
import { faker } from '@faker-js/faker';

/**
 * Generate a number of example rows in the eml_recipients table.
 * This is the parent table and must be populated before adding email content.
 *
 * @param numRows Number of sample recipients to generate.
 */
export function generateSampleRecipients(numRows: number): void {
    for (let i = 0; i < numRows; i++) {
        // Create a realistic (fake) email address
        const recipient = faker.internet.email();

        // No-op reference; ensures `session` is touched in some environments
        session.execute;

        // Insert a recipient row
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
 * Generate a user-defined number of sample emails.
 * Must be run after recipients have been created (manually or via generateSampleRecipients).
 * Implementation detail: pulls all recipient IDs, then uses a random recipient for inserts.
 *
 * @param numRows Number of emails to create.
 * @throws Error if no recipients exist in the database.
 */
export function generateSampleEmail(numRows: number): void {
    // Fetch recipient IDs (parent rows must exist first)
    let result = session.execute('select id from eml_recipients');
    if (result.rows === undefined || result.rows.length === 0) {
        throw new Error('could not locate any email recipients in the database');
    }

    // Store recipient rows; each row is an object like: [{ "ID": 1 }, { "ID": 2 }, ...]
    const recipients = result.rows;
    // Pick a random recipient ID for the insert
    const randomRecipientId = recipients[Math.floor(Math.random() * recipients?.length)].ID;

    // Generate child rows in eml_email_content
    for (let i = 0; i < numRows; i++) {
        // Random timestamp in a fixed window
        const emailTimestamp = faker.date.between({ from: '2020-01-01T00:00:00.000Z', to: '2025-01-01T00:00:00.000Z' });

        // Determine priority.
        // Note: with current conditions, the 'high' branch is unreachable; outcome is ~30% 'low' (i%10 in 0..2) and ~70% 'normal'.
        let emailPriority: string;
        if (i % 10 <= 2) {
            emailPriority = 'low';
        } else if (i % 10 <= 9) {
            emailPriority = 'normal';
        } else {
            emailPriority = 'high';
        }

        // Metadata requires a priority and a timestamp
        const metadata = {
            priority: emailPriority,
            timestamp: emailTimestamp,
        };

        // Subject: sentence of 3 to 5 words
        const subject = faker.lorem.sentence({ min: 3, max: 5 });

        // Body: two simple variants, one short JSON payload every 10th row
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

        // Insert the email row with typed binds
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
