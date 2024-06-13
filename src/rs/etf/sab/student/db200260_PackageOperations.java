package rs.etf.sab.student;

import rs.etf.sab.operations.PackageOperations;
import rs.etf.sab.student.util.DB;
import rs.etf.sab.student.util.Offer;

import java.math.BigDecimal;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
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
        final var connection = DB.getInstance().getConnection();
        try (final var insertOffer = connection.prepareCall(
                "{? = call [spInsertOffer](?, ?, ?, ?)}"
        )) {
            insertOffer.registerOutParameter(1, Types.INTEGER);
            insertOffer.setString(2, couriersUserName);
            insertOffer.setInt(3, packageId);
            insertOffer.setBigDecimal(4, pricePercentage);
            insertOffer.registerOutParameter(5, Types.INTEGER);
            insertOffer.execute();

            if (insertOffer.getInt(1) != 0) {
                return -1;
            }

            return insertOffer.getInt(5);
        } catch (SQLException e) {
            return -1;
        }
    }

    @Override
    public boolean acceptAnOffer(int offerId) {
        final var connection = DB.getInstance().getConnection();
        try (final var acceptOffer = connection.prepareCall(
                "{? = call [spAcceptOffer](?)}"
        )) {
            acceptOffer.registerOutParameter(1, Types.INTEGER);
            acceptOffer.setInt(2, offerId);
            acceptOffer.execute();

            return acceptOffer.getInt(1) == 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public List<Integer> getAllOffers() {
        final var connection = DB.getInstance().getConnection();
        try (final var getOffers = connection.createStatement();
             final var offerIdSet = getOffers.executeQuery(
                     "SELECT [IdOff] FROM [Offer]"
             )
        ) {
            final var offers = new ArrayList<Integer>();
            while (offerIdSet.next()) {
                offers.add(offerIdSet.getInt(1));
            }
            return offers;
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public List<Pair<Integer, BigDecimal>> getAllOffersForPackage(int packageId) {
        final var connection = DB.getInstance().getConnection();
        try (final var getOffers = connection.prepareStatement(
                "SELECT [IdOff], [Percent] FROM [Offer] WHERE [IdPkg] = ?"
        )) {
            getOffers.setInt(1, packageId);
            try (final var offerSet = getOffers.executeQuery()) {
                final var offers = new ArrayList<Pair<Integer, BigDecimal>>();
                while (offerSet.next()) {
                    final var idOff = offerSet.getInt(1);
                    final var percent = offerSet.getBigDecimal(2);
                    offers.add(new Offer(idOff, percent));
                }
                return offers;
            }
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public boolean deletePackage(int packageId) {
        final var connection = DB.getInstance().getConnection();
        try (final var deletePackage = connection.prepareStatement(
                "DELETE FROM [Package] WHERE [IdPkg] = ? AND [DeliveryStatus] IN (0, 1)"
        )) {
            deletePackage.setInt(1, packageId);
            return deletePackage.executeUpdate() > 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean changeWeight(int packageId, BigDecimal newWeight) {
        final var connection = DB.getInstance().getConnection();
        try (final var changeWeight = connection.prepareStatement(
                "UPDATE [Package] SET [Weight] = ? WHERE [IdPkg] = ? AND [DeliveryStatus] = 0"
        )) {
            changeWeight.setBigDecimal(1, newWeight);
            changeWeight.setInt(2, packageId);

            return changeWeight.executeUpdate() > 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean changeType(int packageId, int newType) {
        final var connection = DB.getInstance().getConnection();
        try (final var changeType = connection.prepareStatement(
                "UPDATE [Package] SET [PackageType] = ? WHERE [IdPkg] = ? AND [DeliveryStatus] = 0"
        )) {
            changeType.setInt(1, newType);
            changeType.setInt(2, packageId);

            return changeType.executeUpdate() > 0;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public Integer getDeliveryStatus(int packageId) {
        final var connection = DB.getInstance().getConnection();
        try (final var packageStatus = connection.prepareStatement(
                "SELECT [DeliveryStatus] FROM [Package] WHERE [IdPkg] = ?"
        )) {
            packageStatus.setInt(1, packageId);
            try (final var resultSet = packageStatus.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt(1);
                }
                return null;
            }
        } catch (SQLException e) {
            return null;
        }
    }

    @Override
    public BigDecimal getPriceOfDelivery(int packageId) {
        final var connection = DB.getInstance().getConnection();
        try (final var packageStatus = connection.prepareStatement(
                "SELECT [Price] FROM [Package] WHERE [IdPkg] = ?"
        )) {
            packageStatus.setInt(1, packageId);
            try (final var resultSet = packageStatus.executeQuery()) {
                if (resultSet.next()) {
                    // This also correctly handles the case
                    // when price was not yet calculated
                    // and the field is NULL
                    return resultSet.getBigDecimal(1);
                }
                return null;
            }
        } catch (SQLException e) {
            return null;
        }
    }

    @Override
    public Date getAcceptanceTime(int packageId) {
        final var connection = DB.getInstance().getConnection();
        try (final var packageStatus = connection.prepareStatement(
                "SELECT [TimeAccepted] FROM [Package] WHERE [IdPkg] = ?"
        )) {
            packageStatus.setInt(1, packageId);
            try (final var resultSet = packageStatus.executeQuery()) {
                if (resultSet.next()) {
                    // This also correctly handles the case
                    // when no offer was not accepted so far
                    // and the field NULL
                    return resultSet.getDate(1);
                }
                return null;
            }
        } catch (SQLException e) {
            return null;
        }
    }

    @Override
    public List<Integer> getAllPackagesWithSpecificType(int type) {
        final var connection = DB.getInstance().getConnection();
        try (final var getPackages = connection.prepareStatement(
                "SELECT [IdPkg] FROM [Package] WHERE [PackageType] = ?"
        )) {
            //noinspection DuplicatedCode
            getPackages.setInt(1, type);
            try (final var packageSet = getPackages.executeQuery()) {
                final var packages = new ArrayList<Integer>();
                while (packageSet.next()) {
                    packages.add(packageSet.getInt(1));
                }
                return packages;
            }
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public List<Integer> getAllPackages() {
        final var connection = DB.getInstance().getConnection();
        try (final var getPackages = connection.createStatement();
             final var packageSet = getPackages.executeQuery(
                     "SELECT [IdPkg] FROM [Package]"
             )
        ) {
            final var packages = new ArrayList<Integer>();
            while (packageSet.next()) {
                packages.add(packageSet.getInt(1));
            }
            return packages;
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public List<Integer> getDrive(String courierUsername) {
        final var connection = DB.getInstance().getConnection();
        try (final var getDrive = connection.prepareStatement(
                "SELECT [IdPkg] FROM [Drive]" +
                        "WHERE [IdUser] = (SELECT [IdUser] FROM dbo.[User] WHERE [Username] = ?)"
        )) {
            getDrive.setString(1, courierUsername);
            try(final var packageSet = getDrive.executeQuery()){
                final var packages = new ArrayList<Integer>();
                while (packageSet.next()){
                    packages.add(packageSet.getInt(1));
                }
                return packages;
            }
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public int driveNextPackage(String courierUserName) {
        return 0;
    }
}
