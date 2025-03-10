/// <reference types="mle-js" />

import { faker } from "@faker-js/faker";

/**
 * Generate a number of example rows in the eml_recipients table. This is the parent
 * table, must be populated first.
 * @param {number} numRows the number of sample recipients to generate
 */
export function generateSampleRecipients(numRows: number): void {
    for (let i = 0; i < numRows; i++) {
        const recipient = faker.internet.email();

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
 * Generate a user-definable number of sample rows
 * @param {number} numRows - number of rows to be created
 */
export function generateSampleEmail(numRows: number): void {
    // create an array of recipients in random order
    let result = session.execute("select id from eml_recipients");

    if (result.rows === undefined || result.rows.length === 0) {
        throw new Error("could not locate any email recipients in the database");
    }
    const recipients = result.rows;

    for (let i = 0; i < numRows; i++) {
        const emailTimestamp = faker.date.between({ from: "2020-01-01T00:00:00.000Z", to: "2025-01-01T00:00:00.000Z" });

        // 10 percent are high priority emails,
        // 70 are of normal priority,
        // and 20 percent are low priority
        let emailPriority: string;
        if (i % 10 <= 2) {
            emailPriority = "low";
        } else if (i % 10 <= 9) {
            emailPriority = "normal";
        } else {
            emailPriority = "high";
        }

        // metadata must provide a priority and a timestamp
        const metadata = {
            priority: emailPriority,
            timestamp: emailTimestamp,
        };

        // email subject
        const subject = faker.lorem.sentence({ min: 3, max: 5 });

        // email body
        let body: object;
        if (i % 10 === 0) {
            body = {
                greeting: "hello",
                message: faker.hacker.phrase(),
            };
        } else {
            body = {
                greeting: "hello",
                message: faker.lorem.paragraphs(5),
            };
        }

        const randomRecipientId = recipients[Math.floor(Math.random() * recipients?.length)].ID;

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
