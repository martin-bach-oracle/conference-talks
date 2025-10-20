package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Objects;
import java.util.concurrent.TimeUnit;
import java.time.Duration;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ClientProperties
        implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(ClientProperties.class);

    private final DataSource dataSource;

    private static final String CLIENT_INFO_MODULE = "OCSID.MODULE";
    private static final String CLIENT_INFO_ACTION = "OCSID.ACTION";
    private static final String CLIENT_INFO_CLIENTID = "OCSID.CLIENTID";
    private static final String WHOAMI_SQL = "select user";

    public ClientProperties(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    public static void main(String... args) {
        SpringApplication.run(ClientProperties.class, args);
    }

    @Override
    public void run(String... args) throws SQLException {
        log.info("Starting the execution now");

        try (Connection conn = Objects.requireNonNull(dataSource.getConnection(), "Failed to obtain a connection")) {
            log.info("Managed to obtain a connection");

            conn.setClientInfo(CLIENT_INFO_MODULE, "demo module");
            conn.setClientInfo(CLIENT_INFO_ACTION, "runing a live demo at IT-Tage");
            conn.setClientInfo(CLIENT_INFO_CLIENTID, "the guy _running_ the demo");

            log.info("Client info set (module/action/clientId). You can check v$session now but it's not yet updated.");
            log.info("Example: select sid, serial#, username, module, action, client_identifier from v$session where username = USER");

            sleepSafely(Duration.ofSeconds((30)));

            try (PreparedStatement pstmt = conn.prepareStatement(WHOAMI_SQL);
                 ResultSet rs = pstmt.executeQuery()) {

                log.info("Database query executed - check v$session again");
                while (rs.next()) {
                    String currentUser = rs.getString(1);
                    log.info("Connected as {}", currentUser);
                }
            }

            sleepSafely(Duration.ofSeconds(30));
        } catch (SQLException e) {
            log.error("Database operation failed", e);
        }
    }

    private void sleepSafely(Duration duration) {
        if (duration == null || duration.isNegative() || duration.isZero()) {
            return;
        }
        try {
            TimeUnit.MILLISECONDS.sleep(duration.toMillis());
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
            log.warn("Sleep interrupted, continuing");
        }
    }
}
