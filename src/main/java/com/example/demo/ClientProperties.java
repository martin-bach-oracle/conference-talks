package com.example.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.SQLException;
import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.ResultSet;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.jdbc.datasource.DataSourceUtils;

@SpringBootApplication
public class ClientProperties
        implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(ClientProperties.class);

    @Autowired
    private DataSource dataSource;

    public static void main(String... args) {
        SpringApplication.run(ClientProperties.class, args);
    }

    @Override
    public void run(String... args) throws SQLException {
        log.info("Starting the execution now");

        Connection conn = DataSourceUtils.getConnection(dataSource);

        log.info("Managed to obtain a connection");

        try {
            conn.setClientInfo("OCSID.MODULE", "IT-Tage");
            conn.setClientInfo("OCSID.ACTION", "starting the command line runner");
            conn.setClientInfo("OCSID.CLIENTID", "the guy running this demo");

            log.info("Module/Action set - v$session still empty");
            log.info("select sid,serial#,username,module,action,client_identifier from v$session where username = 'DEMOUSER'");

            Thread.sleep(30000);

            ResultSet rs = conn.createStatement().executeQuery("select user");

            log.info("Database query executed - check v$session again");

            while (rs.next()) {
                System.out.println("you are connected as " + rs.getString(1));
            }
            
            Thread.sleep(100000);

            rs.close();
            
        } catch(InterruptedException e1) {
            // nothing
        } catch(SQLException e2) {
            // nothing
        } finally {
            DataSourceUtils.releaseConnection(conn, dataSource);
        }
    }
}
