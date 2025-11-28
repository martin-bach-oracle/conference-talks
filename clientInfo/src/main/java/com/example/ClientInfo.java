package com.example;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.time.Duration;
import java.util.concurrent.TimeUnit;


public class ClientInfo
{
    private static final Logger log = LoggerFactory.getLogger(ClientInfo.class);

    private static final String CLIENT_INFO_MODULE = "OCSID.MODULE";
    private static final String CLIENT_INFO_ACTION = "OCSID.ACTION";
    private static final String CLIENT_INFO_CLIENTID = "OCSID.CLIENTID";
    private static final String WHOAMI_SQL = "select user";

    public ClientInfo() {
        super();
    }

    /**
     * Note that the APP_USER_PASSWORD must be defined in the run configuration!
     * Expects the database to be up and running based on the compose file. The compose file sets username and
     * password for the demouser
     *
     * @throws SQLException
     */
    public void run() throws SQLException {
        log.info("Starting the execution now");

        PoolDataSource pds = null;
        try {
            pds = PoolDataSourceFactory.getPoolDataSource();
            pds.setURL("jdbc:oracle:thin:@localhost:1522/freepdb1");
            pds.setUser("demouser");
            pds.setPassword(System.getenv("APP_USER_PASSWORD"));
            pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
            pds.setInitialPoolSize(4);
            pds.setMinPoolSize(4);
            pds.setMaxPoolSize(4);

            Connection conn = pds.getConnection();

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

            conn.close();
        } catch (SQLException e) {
            System.err.println("Database error: " + e.getMessage());
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

    public static void main(String ...args) {
        ClientInfo ci = new ClientInfo();
        try {
            ci.run();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }
}
