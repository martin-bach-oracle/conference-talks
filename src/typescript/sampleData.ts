/// <reference types="mle-js" />

import { faker } from "@faker-js/faker";

/**
 * Generate a user-definable number of sample rows
 * @param {number} numRows - number of rows to be created
 */
export function generateSampleData(numRows: number) {
    for (let i = 0; i < numRows; i++) {
        const recipient = faker.internet.email();
        const subject = faker.lorem.sentence({ min: 3, max: 5 });

        let body: string;
        if (i % 10 === 0) body = faker.hacker.phrase();
        else body = faker.lorem.paragraphs(5);

        const metadata = {
            userAgent: faker.internet.userAgent(),
            virusChecked: faker.datatype.boolean(),
        };

        session.execute(
            `insert into em_email_1 (
                recipient_email,
                subject,
                body,
                metadata
            ) values (
                :recipient,
                :subject,
                :body,
                :metadata 
            ) returning id into :id`,
            {
                recipient: {
                    dir: oracledb.BIND_IN,
                    val: recipient,
                    type: oracledb.DB_TYPE_VARCHAR,
                },
                subject: {
                    dir: oracledb.BIND_IN,
                    val: subject,
                    type: oracledb.DB_TYPE_VARCHAR,
                },
                body: {
                    dir: oracledb.BIND_IN,
                    val: body,
                    type: oracledb.DB_TYPE_NVARCHAR,
                },
                metadata: {
                    dir: oracledb.BIND_IN,
                    val: metadata,
                    type: oracledb.DB_TYPE_JSON,
                },
                id: {
                    dir: oracledb.BIND_OUT,
                    type: oracledb.ORACLE_NUMBER,
                },
            },
        );
    }
}
