package rs.etf.sab.student;

import rs.etf.sab.operations.GeneralOperations;
import rs.etf.sab.student.util.DB;

import java.sql.BatchUpdateException;
import java.sql.Connection;
import java.sql.SQLException;

public class db200260_GeneralOperations implements GeneralOperations {

    @SuppressWarnings({"SqlConstantCondition", "SqlConstantExpression"})
    @Override
    public void eraseAll() {
        Connection conn = DB.getInstance().getConnection();
        try (final var stmt = conn.createStatement()) {
            stmt.addBatch("DELETE FROM [RidePackages] WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [Ride] WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [CourierRequest]  WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [Offer] WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [Package] WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [District]  WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [City]  WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [Admin]  WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [Courier]  WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [Vehicle]  WHERE 1 = 1");
            stmt.addBatch("DELETE FROM [User]  WHERE 1 = 1");
            stmt.executeBatch();
        } catch (SQLException e) {
            if (e instanceof BatchUpdateException) {
                System.out.println("One of the deletes violates referential integrity.");
            }
        }
    }

}
