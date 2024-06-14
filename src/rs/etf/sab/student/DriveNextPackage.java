package rs.etf.sab.student;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

class DriveNextPackage {
    private final Connection connection;

    DriveNextPackage(Connection connection) throws SQLException {
        this.connection = connection;
    }

    private record CourierStatus(int courierId, int status) {
    }

    private Optional<CourierStatus> getCourierStatus(String username) throws SQLException {
        final var query = "SELECT u.[IdUser], [Status]" +
                "FROM [User] u " +
                "JOIN [Courier] c ON(u.[IdUser]=c.[IdUser])" +
                "WHERE [Username] = ?";
        try (final var getStatus = connection.prepareStatement(query)) {
            getStatus.setString(1, username);
            try (final var resultSet = getStatus.executeQuery()) {
                if (resultSet.next()) {
                    final var courierId = resultSet.getInt(1);
                    final var status = resultSet.getInt(2);
                    return Optional.of(new CourierStatus(courierId, status));
                }
                return Optional.empty();
            }
        }
    }

    private boolean updateCourierStatus(int courierId, int status) throws SQLException {
        final var query = "UPDATE [Courier] SET [Status] = ? WHERE [IdUser] = ?";
        try (final var updateState = connection.prepareStatement(query)) {
            updateState.setInt(1, status);
            updateState.setInt(2, courierId);
            return updateState.executeUpdate() > 0;
        }
    }

    private boolean addPackagesToDrive(int courierId) throws SQLException {
        final var query = "INSERT INTO [Drive]([IdUser], [IdPkg])" +
                "SELECT ?, [IdPkg] FROM [Package]" +
                "WHERE [IdCourier] = ? AND [DeliveryStatus] = 1";
        try (final var addToDrive = connection.prepareStatement(query)) {
            addToDrive.setInt(1, courierId);
            addToDrive.setInt(2, courierId);
            return addToDrive.executeUpdate() > 0;
        }
    }

    private boolean setPackagesAsPickedUp(int courierId) throws SQLException {
        final var query = "UPDATE [Package] SET [DeliveryStatus] = 2 " +
                "WHERE [IdCourier] = ? AND [DeliveryStatus] = 1";
        try (final var addToDrive = connection.prepareStatement(query)) {
            addToDrive.setInt(1, courierId);
            return addToDrive.executeUpdate() > 0;
        }
    }

    private int startDrive(int courierId) throws SQLException {
        final var query = "SELECT COUNT(*) FROM [Package]" +
                "WHERE [IdCourier] = ? AND [DeliveryStatus] = 1";
        try (final var packageCountQuery = connection.prepareStatement(query)) {
            packageCountQuery.setInt(1, courierId);
            final var resultSet = packageCountQuery.executeQuery();
            final var packageCount = resultSet.next() ? resultSet.getInt(1) : -1;
            resultSet.close();

            if (packageCount <= 0) {
                return packageCount;
            }

            if (!updateCourierStatus(courierId, 1)) {
                return -2;
            }

            if (!addPackagesToDrive(courierId)) {
                return -3;
            }

            if (!setPackagesAsPickedUp(courierId)) {
                return -4;
            }

            return packageCount;
        }
    }

    @SuppressWarnings("DuplicatedCode")
    private int nextPackageId(int courierId) throws SQLException {
        final var query = "SELECT TOP(1) d.[IdPkg]" +
                "FROM [Drive] d JOIN [Package] p ON(d.[IdPkg] = p.[IdPkg])" +
                "WHERE [IdUser] = ? AND [DeliveryStatus] = 2 " +
                "ORDER BY [TimeAccepted]";
        try (final var packageId = connection.prepareStatement(query)) {
            packageId.setInt(1, courierId);
            try (final var result = packageId.executeQuery()) {
                if (result.next()) {
                    return result.getInt(1);
                }
                return -1;
            }
        }
    }

    private boolean markPackageAsDelivered(int pkgId) throws SQLException {
        final var query = "UPDATE [Package] SET [DeliveryStatus] = 3 WHERE [IdPkg] = ?";
        try (final var addToDrive = connection.prepareStatement(query)) {
            addToDrive.setInt(1, pkgId);
            return addToDrive.executeUpdate() > 0;
        }
    }

    private int driveNextPackage(int courierId) throws SQLException {
        final var packageId = nextPackageId(courierId);
        if (packageId == -1) {
            return -1;
        }
        if (!markPackageAsDelivered(packageId)) {
            return -2;
        }
        return packageId;
    }

    @SuppressWarnings("DuplicatedCode")
    private int drivePackagesLeft(int courierId) throws SQLException {
        final var query = "SELECT COUNT(*)" +
                "FROM [Drive] d JOIN [Package] p ON (d.IdPkg = p.IdPkg)" +
                "WHERE [IdUser] = ? AND [DeliveryStatus] = 2";

        try (final var packagesLeft = connection.prepareStatement(query)) {
            packagesLeft.setInt(1, courierId);
            try (final var resultSet = packagesLeft.executeQuery()) {
                if (resultSet.next()) {
                    return resultSet.getInt(1);
                }
                return -1;
            }
        }
    }

    private Optional<BigDecimal> fuelPricePerKm(int courierId) throws SQLException {
        final var sql = "SELECT [FuelConsumption], [FuelPrice] FROM [Vehicle] v " +
                "JOIN [Courier] c ON (v.[IdVeh] = c.[IdVeh])" +
                "JOIN [FuelType] ft ON (v.[FuelType] = ft.[IdFuelT])" +
                "WHERE c.[IdUser] = ?";
        try (final var pricePerKm = connection.prepareStatement(sql)) {
            pricePerKm.setInt(1, courierId);
            try (final var resultSet = pricePerKm.executeQuery()) {
                if (resultSet.next()) {
                    final var consumption = resultSet.getBigDecimal(1);
                    final var fuelPrice = resultSet.getBigDecimal(1);
                    return Optional.of(consumption.multiply(fuelPrice));
                }
                return Optional.empty();
            }
        }
    }

    private record DeliveredPackageInfo(BigDecimal price, BigDecimal distance) {
    }

    private List<DeliveredPackageInfo> getDrivePackagesInfo(int courierId) throws SQLException {
        final var query = "SELECT [Price], [dbo].[fPackageDistance](d.[IdPkg])" +
                "FROM [Drive] d JOIN [Package] p ON (d.[IdPkg] = p.[IdPkg])" +
                "WHERE d.[IdUser] = ?";
        try (final var packagesInfo = connection.prepareStatement(query)) {
            packagesInfo.setInt(1, courierId);
            try (final var resultSet = packagesInfo.executeQuery()) {
                final var data = new ArrayList<DeliveredPackageInfo>();
                while (resultSet.next()) {
                    final var price = resultSet.getBigDecimal(1);
                    final var distance = resultSet.getBigDecimal(2);
                    data.add(new DeliveredPackageInfo(price, distance));
                }
                return data;
            }
        }
    }

    private boolean updateCourierStats(int courierId, BigDecimal driveProfit) throws SQLException {
        final var query = "UPDATE [Courier] SET" +
                "[TotalProfit] = [TotalProfit] + ?," +
                "[DeliveredPackages] = [DeliveredPackages] + " +
                "(SELECT COUNT(*) FROM [Drive] WHERE [IdUser] = ?)" +
                "WHERE [IdUser] = ?";
        try (final var updateStats = connection.prepareStatement(query)) {
            updateStats.setBigDecimal(1, driveProfit);
            updateStats.setInt(2, courierId);
            updateStats.setInt(3, courierId);
            return updateStats.executeUpdate() > 0;
        }
    }


    private boolean deleteDrivePackages(int courierId) throws SQLException {
        final var query = "DELETE FROM [Drive] WHERE [IdUser] = ?";
        try (final var deletePackages = connection.prepareStatement(query)) {
            deletePackages.setInt(1, courierId);
            return deletePackages.executeUpdate() > 0;
        }
    }

    private boolean finishDrive(int courierId) throws SQLException {
        final var fuelPricePerKmOptional = fuelPricePerKm(courierId);
        if (fuelPricePerKmOptional.isEmpty()) {
            return false;
        }
        final var fuelPrice = fuelPricePerKmOptional.get();
        final var packagesInfo = getDrivePackagesInfo(courierId);
        final var totalGain = packagesInfo.stream().map(p -> p.price)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        final var totalLoss = packagesInfo.stream().map(p -> p.distance)
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .multiply(fuelPrice);
        final var totalProfit = totalGain.subtract(totalLoss);

        if (!updateCourierStats(courierId, totalProfit)) {
            return false;
        }

        if (!deleteDrivePackages(courierId)) {
            return false;
        }
        return true;
    }

    private static class FailedOperation extends Exception {
        final int code;

        FailedOperation(int code) {
            this.code = code;
        }
    }

    public int execute(String courierUserName) throws SQLException {
        try {
            connection.setAutoCommit(false);
            final var courierStatusOptional = getCourierStatus(courierUserName);
            // User is not a courier
            if (courierStatusOptional.isEmpty()) {
                throw new FailedOperation(-2);
            }
            final var courierId = courierStatusOptional.get().courierId;
            final var courierStatus = courierStatusOptional.get().status;

            if (courierStatus == 0) {
                final var result = startDrive(courierId);
                if (result == 0) {
                    throw new FailedOperation(-1);
                } else if (result < 0) {
                    throw new FailedOperation(-2);
                }
            }
            // Drive next package
            final var drivenPackageId = driveNextPackage(courierId);
            if (drivenPackageId < 0) {
                throw new FailedOperation(-2);
            }

            // if no more packages return last package id
            final var packagesLeft = drivePackagesLeft(courierId);
            if (packagesLeft < 0) {
                throw new FailedOperation(-2);
            }

            // finish drive if there are no more packages left
            if (packagesLeft == 0 && !finishDrive(courierId)) {
                throw new FailedOperation(-2);
            }

            connection.commit();
            return drivenPackageId;
        } catch (SQLException e) {
            connection.rollback();
            return -2;
        } catch (FailedOperation e) {
            connection.rollback();
            return e.code;
        } finally {
            connection.setAutoCommit(true);
        }
    }

}
