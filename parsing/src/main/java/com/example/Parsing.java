package com.example;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;
import java.sql.Statement;

import java.util.Random;

public class Parsing
{
    private static final Logger log = LoggerFactory.getLogger(Parsing.class);

    private String mode;
    private final int numIterations = 30000;

    private PoolDataSource pds;

    public void setMode(String mode) {

        if (!(mode.equals("trouble") || mode.equals("normal"))) {
            throw new IllegalArgumentException("mode must be one of 'trouble' or 'normal'");
        }

        log.info("switching mode to {}", mode);

        this.mode = mode;
    }

    public Parsing(String mode) {

        if (!(mode.equals("trouble") || mode.equals("normal"))) {
            throw new IllegalArgumentException("mode must be one of 'trouble' or 'normal'");
        }

        this.mode = mode;

        try {
            initUCP();
        } catch (SQLException e) {
            throw new RuntimeException(e);
        }
    }

    private void initUCP() throws SQLException {

        log.info("initialising the connection pool");

        this.pds = null;

        this.pds = PoolDataSourceFactory.getPoolDataSource();
        this.pds.setURL("jdbc:oracle:thin:@localhost:1522/freepdb1");
        this.pds.setUser("demouser");
        this.pds.setPassword(System.getenv("APP_USER_PASSWORD"));
        this.pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        this.pds.setInitialPoolSize(4);
        this.pds.setMinPoolSize(4);
        this.pds.setMaxPoolSize(4);

    }

    public void run() throws SQLException {
        log.info("Starting the execution now - mode is set to: " + this.mode);

        Connection conn = this.pds.getConnection();

        log.info("Managed to obtain a connection");

        long minId = 0, maxId = 0;

        ResultSet rs = conn.prepareStatement("select min(user_id), max(user_id) from todo_users").executeQuery();
        while (rs.next()) {
            minId = rs.getLong(1);
            maxId = rs.getLong(2);
        }

        log.info("Found the minimum ID to be {} and the maximum to be {}", minId, maxId);

        if (mode.equals("trouble")) {
            startTrouble(conn, minId, maxId);
        } else {
            showHowItShouldBeDone(conn, minId, maxId);
        }

        conn.close();

    }

    private void startTrouble(Connection conn, long minId, long maxId) {

        long startTime = System.currentTimeMillis();

        for (int i = 0; i < numIterations; i++) {

            Random random = new Random();
            long randomId = random.nextLong((maxId - minId) + 1) + minId;

            try (Statement stmt = conn.createStatement()) {
                ResultSet rs = stmt.executeQuery("select username from todo_users where user_id = " + randomId);
                while (rs.next()) {
                    String username = rs.getString(1);
                }

                if (i % 1000 == 0)
                    log.info("\titerations completed: {}", i);
                rs.close();

            } catch (SQLException e) {
                log.error("something went wrong in iteration " + i);
            }
        }

        long endTime = System.currentTimeMillis();
        long duration = (endTime - startTime);
        log.info("Wall Clock Time elapsed to process {} iterations in mode {}: {} ", numIterations, "trouble", duration);
    }

    private void showHowItShouldBeDone(Connection conn, long minId, long maxId) {
        long startTime = System.currentTimeMillis();

        PreparedStatement pstmt = null;
        try {
            pstmt = conn.prepareStatement("select username from todo_users where user_id = ?");
        } catch (SQLException e) {
            log.error("couldn't create the prepared statement - this is bad! {}", e.getMessage());
            throw new RuntimeException(e);
        }

        for (int i = 0; i < numIterations; i++) {

            Random random = new Random();
            long randomId = random.nextLong((maxId - minId) + 1) + minId;

            try {
                pstmt.setLong(1, randomId);

                ResultSet rs = pstmt.executeQuery();
                while (rs.next()) {
                    String username = rs.getString(1);
                }

                if (i % 1000 == 0)
                    log.info("\titerations completed: {}", i);
                rs.close();

            } catch (SQLException e) {
                log.error("something went wrong in iteration " + i);
            }
        }

        long endTime = System.currentTimeMillis();
        long duration = (endTime - startTime);
        log.info("Wall Clock Time elapsed to process {} iterations in mode {}: {} ", numIterations, "trouble", duration);
    }

    public static void main( String[] args ) throws SQLException {
        Parsing parsing = new Parsing("trouble");
        parsing.run();

        parsing.setMode("normal");
        parsing.run();
    }
}
