/// <reference types="mle-js" />

import { faker } from '@faker-js/faker';

/**
 * Generate a number of example rows in the eml_recipients table. This is the parent
 * table, must be populated first. Based on faker.internet.email to generate realistic,
 * yet fake, email addresses in the EN locale.
 *
 * @param {number} numRows the number of sample recipients to generate
 */
export function generateSampleRecipients(numRows: number): void {
    for (let i = 0; i < numRows; i++) {
        const recipient = faker.internet.email();

        session.execute;

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
 * Generate a user-definable number of sample emails. Must run _after_ email
 * recipients have been added (either manually or via generateSampleRecipients())
 * since this is the child table. Starts off by pulling all email recipients into an array,
 * then creates a bunch of emails.
 *
 * @param {number} numRows - number of emails to be created
 */
export function generateSampleEmail(numRows: number): void {
    // make sure parent rows exist. If this were production code this should
    // be done slightly differently to prevent fetching of millions of rows,
    // which would blow memory consumption out of the water.
    let result = session.execute('select id from eml_recipients');
    if (result.rows === undefined || result.rows.length === 0) {
        throw new Error('could not locate any email recipients in the database');
    }

    // Store the recipient (IDs) in a variable. Recipients is an array of JavaScript
    // objects like this: [{"ID":1},{"ID":2},{"ID":3},{"ID":4},{"ID":5}]
    // Grab a random one for the insert statement. For large data volumes modify the
    // select and add "order by dbms_random.random" to the query. If needed, limit to
    // x rows to prevent memory issues.
    const recipients = result.rows;
    const randomRecipientId = recipients[Math.floor(Math.random() * recipients?.length)].ID;

    // start the generation of emails (= child rows to eml_recipient)
    for (let i = 0; i < numRows; i++) {
        const emailTimestamp = faker.date.between({ from: '2020-01-01T00:00:00.000Z', to: '2025-01-01T00:00:00.000Z' });

        // 10 percent are high priority emails,
        // 70 are of normal priority,
        // and 20 percent are low priority
        let emailPriority: string;
        if (i % 10 <= 2) {
            emailPriority = 'low';
        } else if (i % 10 <= 9) {
            emailPriority = 'normal';
        } else {
            emailPriority = 'high';
        }

        // metadata must provide a priority and a timestamp as per the data model
        const metadata = {
            priority: emailPriority,
            timestamp: emailTimestamp,
        };

        // email subject will be a sentence of 3 to 5 words
        const subject = faker.lorem.sentence({ min: 3, max: 5 });

        // te email body is provided as JSON
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

        // insert the sample data into the database
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
