package rs.etf.sab.student.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB {
    static {
        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
        Runtime.getRuntime().addShutdownHook(new Thread(() -> {
            try {
                disconnect();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }));
    }

    private static final String username = "sa";
    private static final String password = "123";
    private static final String database = "PackageTransportation";
    private static final int port = 1433;
    private static final String serverName = "localhost";

    private static final String connectionString = String.format(
            "jdbc:sqlserver://%s:%d;databaseName=%s;trustServerCertificate=true",
            serverName, port, database
    );

    private Connection connection = null;

    private DB() throws SQLException {
        connection = DriverManager.getConnection(connectionString, username, password);
    }
    private static DB instance = null;

    public static DB getInstance() throws SQLException {
        if (instance == null) {
            instance = new DB();
        }
        return instance;
    }

    public static void disconnect() throws SQLException {
        if (instance != null) {
            instance.connection.close();
            instance = null;
        }
    }

    public Connection getConnection() {
        return connection;
    }
}
