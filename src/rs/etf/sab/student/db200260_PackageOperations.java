package rs.etf.sab.student;

import rs.etf.sab.operations.PackageOperations;
import rs.etf.sab.student.util.DB;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.List;

public class db200260_PackageOperations implements PackageOperations {
    @Override
    public int insertPackage(int districtFrom, int districtTo, String userName, int packageType, BigDecimal weight) {
        final var connection = DB.getInstance().getConnection();
        try (final var insertPackage = connection.prepareStatement(
                "INSERT INTO [Package](IdDistFrom, IdDistTo, IdSender, Weight, PackageType)" +
                        " VALUES (?, ?, (SELECT [IdUser] FROM [User] WHERE [Username] = ?), ?, ?)",
                PreparedStatement.RETURN_GENERATED_KEYS
        )) {
            insertPackage.setInt(1, districtFrom);
            insertPackage.setInt(2, districtTo);
            insertPackage.setString(3, userName);
            insertPackage.setBigDecimal(4, weight);
            insertPackage.setInt(5, packageType);

            if (insertPackage.executeUpdate() == 0) {
                return -1;
            }

            try (final var keySet = insertPackage.getGeneratedKeys()) {
                if (keySet.next()) {
                    return keySet.getInt(1);
                } else {
                    return -1;
                }
            }
        } catch (SQLException e) {
            return -1;
        }
    }

    @Override
    public int insertTransportOffer(String couriersUserName, int packageId, BigDecimal pricePercentage) {
        return 0;
    }

    @Override
    public boolean acceptAnOffer(int offerId) {
        return false;
    }

    @Override
    public List<Integer> getAllOffers() {
        return List.of();
    }

    @Override
    public List<Pair<Integer, BigDecimal>> getAllOffersForPackage(int packageId) {
        return List.of();
    }

    @Override
    public boolean deletePackage(int packageId) {
        return false;
    }

    @Override
    public boolean changeWeight(int packageId, BigDecimal newWeight) {
        return false;
    }

    @Override
    public boolean changeType(int packageId, int newType) {
        return false;
    }

    @Override
    public Integer getDeliveryStatus(int packageId) {
        return 0;
    }

    @Override
    public BigDecimal getPriceOfDelivery(int packageId) {
        return null;
    }

    @Override
    public Date getAcceptanceTime(int packageId) {
        return null;
    }

    @Override
    public List<Integer> getAllPackagesWithSpecificType(int type) {
        return List.of();
    }

    @Override
    public List<Integer> getAllPackages() {
        return List.of();
    }

    @Override
    public List<Integer> getDrive(String courierUsername) {
        return List.of();
    }

    @Override
    public int driveNextPackage(String courierUserName) {
        return 0;
    }
}
