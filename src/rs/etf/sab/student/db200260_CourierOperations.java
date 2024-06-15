package rs.etf.sab.student;

import rs.etf.sab.student.util.DB;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

public class db200260_CourierOperations implements rs.etf.sab.operations.CourierOperations {
    @Override
    public boolean insertCourier(String courierUserName, String licencePlateNumber) {
        final var connection = DB.getInstance().getConnection();
        try (final var insertRequest = connection.prepareCall(
                "{? = call [spInsertCourier](?, ?)}"
        )) {
            insertRequest.registerOutParameter(1, Types.INTEGER);
            insertRequest.setString(2, courierUserName);
            insertRequest.setString(3, licencePlateNumber);
            insertRequest.execute();

            return insertRequest.getInt(1) == 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean deleteCourier(String courierUserName) {
        final var connection = DB.getInstance().getConnection();
        try (final var deleteCourier = connection.prepareStatement(
                "DELETE FROM [Courier] WHERE [IdUser] = (SELECT [IdUser] FROM [User] WHERE [Username] = ?)"
        )) {
            deleteCourier.setString(1, courierUserName);
            return deleteCourier.executeUpdate() == 1;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public List<String> getCouriersWithStatus(int statusOfCourier) {
        final var connection = DB.getInstance().getConnection();
        try (final var getCouriers = connection.prepareStatement(
                "SELECT [Username] FROM [Courier] c JOIN [User] u ON (c.[IdUser] = u.[IdUser]) WHERE [Status] = ?"
        )) {
            getCouriers.setInt(1, statusOfCourier);
            try (final var usernameSet = getCouriers.executeQuery()) {
                final var usernames = new ArrayList<String>();
                while (usernameSet.next()) {
                    usernames.add(usernameSet.getString(1).strip());
                }
                return usernames;
            }
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public List<String> getAllCouriers() {
        final var connection = DB.getInstance().getConnection();
        try (final var getCouriers = connection.createStatement();
             final var usernameSet = getCouriers.executeQuery(
                     "SELECT [Username] FROM [User] u, [Courier] c WHERE u.[IdUser] = c.[IdUser]"
             )
        ) {
            final var usernames = new ArrayList<String>();
            while (usernameSet.next()) {
                usernames.add(usernameSet.getString(1).strip());
            }
            return usernames;
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public BigDecimal getAverageCourierProfit(int numberOfDeliveries) {
        final var connection = DB.getInstance().getConnection();
        try(final var averageProfits = connection.prepareStatement(
                "SELECT AVG([TotalProfit]) FROM [Courier] WHERE [DeliveredPackages] >= ?"
        )){
            averageProfits.setInt(1, numberOfDeliveries);
            try(final var resultSet = averageProfits.executeQuery()){
                if (resultSet.next()){
                    return resultSet.getBigDecimal(1);
                }
            }
            return BigDecimal.valueOf(0);
        } catch (SQLException e) {
            return null;
        }
    }
}
