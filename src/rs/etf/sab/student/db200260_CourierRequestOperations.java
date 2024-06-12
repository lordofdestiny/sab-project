package rs.etf.sab.student;

import rs.etf.sab.student.util.DB;

import java.sql.SQLException;
import java.sql.Types;
import java.util.List;

public class db200260_CourierRequestOperations implements rs.etf.sab.operations.CourierRequestOperation {
    @Override
    public boolean insertCourierRequest(String userName, String licencePlateNumber) {
        final var connection = DB.getInstance().getConnection();
        try (final var insertRequest = connection.prepareCall(
                "{? = call [spInsertCourierRequest](?, ?)}"
        )) {
            insertRequest.registerOutParameter(1, Types.INTEGER);
            insertRequest.setString("username", userName);
            insertRequest.setString("licencePlateNumber", licencePlateNumber);
            insertRequest.execute();

            return insertRequest.getInt(1) == 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean deleteCourierRequest(String userName) {
        final var connection = DB.getInstance().getConnection();
        try (final var deleteCourier = connection.prepareStatement(
                "DELETE FROM [CourierRequest] WHERE [IdUser] = (SELECT [IdUser] FROM [User] WHERE [Username] = ?)"
        )) {
            deleteCourier.setString(1, userName);
            return deleteCourier.executeUpdate() > 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean changeVehicleInCourierRequest(String userName, String licencePlateNumber) {
        return false;
    }

    @Override
    public List<String> getAllCourierRequests() {
        return List.of();
    }

    @Override
    public boolean grantRequest(String username) {
        return false;
    }
}
