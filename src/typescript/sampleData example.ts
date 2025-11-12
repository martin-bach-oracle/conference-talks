import { faker } from '@faker-js/faker';

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

export function generateSampleEmail(numRows: number): void {
    let result = session.execute('select id from eml_recipients');
    if (result.rows === undefined || result.rows.length === 0) {
        throw new Error('could not locate any email recipients in the database');
    }

    const recipients = result.rows;
    const randomRecipientId = recipients[Math.floor(Math.random() * recipients?.length)].ID;

    for (let i = 0; i < numRows; i++) {
        const emailTimestamp = faker.date.between({ from: '2020-01-01T00:00:00.000Z', to: '2025-01-01T00:00:00.000Z' });

        let emailPriority: string;
        if (i % 10 <= 2) {
            emailPriority = 'low';
        } else if (i % 10 <= 9) {
            emailPriority = 'normal';
        } else {
            emailPriority = 'high';
        }

        const metadata = {
            priority: emailPriority,
            timestamp: emailTimestamp,
        };

        const subject = faker.lorem.sentence({ min: 3, max: 5 });

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
