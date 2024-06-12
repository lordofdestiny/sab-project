package rs.etf.sab.student;

import rs.etf.sab.student.util.DB;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class db200260_VehicleOperations implements rs.etf.sab.operations.VehicleOperations {
    @Override
    public boolean insertVehicle(String licencePlateNumber, int fuelType, BigDecimal fuelConsumption) {
        final var connection = DB.getInstance().getConnection();
        try {
            final var insertVehicle = connection.prepareStatement(
                    "INSERT INTO [Vehicle] ([LicencePlateNumber], [FuelType], [FuelConsumption]) VALUES (?, ?, ?)"
            );
            insertVehicle.setString(1, licencePlateNumber);
            insertVehicle.setInt(2, fuelType);
            insertVehicle.setBigDecimal(3, fuelConsumption);
            return insertVehicle.executeUpdate() == 1;
        } catch (Exception e) {
            return false;
        }
    }

    @Override
    public int deleteVehicles(String... licencePlateNumbers) {
        final var connection = DB.getInstance().getConnection();
        try (final var deleteVehicles = connection.prepareStatement(
                "DELETE FROM [Vehicle] WHERE [LicencePlateNumber] = ?"
        )) {
            // noinspection Duplicates
            for (var licencePlateNumber : licencePlateNumbers) {
                deleteVehicles.setString(1, licencePlateNumber);
                deleteVehicles.addBatch();
            }
            final var result = deleteVehicles.executeBatch();
            return Arrays.stream(result).filter(i -> i > 0).map(i -> 1).sum();
        } catch (Exception e) {
            return 0;
        }
    }

    @Override
    public List<String> getAllVehichles() {
        final var connection = DB.getInstance().getConnection();
        try (final var getAllVehicles = connection.createStatement();
             final var resultSet = getAllVehicles.executeQuery(
                     "SELECT [LicencePlateNumber] FROM [Vehicle]"
             )) {
            final var vehicles = new ArrayList<String>();
            while (resultSet.next()){
                vehicles.add(resultSet.getString(1).strip());
            }
            return vehicles;
        } catch (SQLException e) {
            return List.of();
        }
    }

    @Override
    public boolean changeFuelType(String licensePlateNumber, int fuelType) {
        final var connection = DB.getInstance().getConnection();
        try (final var changeFuelType = connection.prepareStatement(
                "UPDATE [Vehicle] SET [FuelType] = ? WHERE [LicencePlateNumber] = ?"
        )) {
            changeFuelType.setInt(1, fuelType);
            changeFuelType.setString(2, licensePlateNumber);
            return changeFuelType.executeUpdate() == 1;
        } catch (SQLException e) {
            return false;
        }
    }

    @Override
    public boolean changeConsumption(String licensePlateNumber, BigDecimal fuelConsumption) {
        final var connection = DB.getInstance().getConnection();
        try (final var changeFuelType = connection.prepareStatement(
                "UPDATE [Vehicle] SET [FuelConsumption] = ? WHERE [LicencePlateNumber] = ?"
        )) {
            changeFuelType.setBigDecimal(1, fuelConsumption);
            changeFuelType.setString(2, licensePlateNumber);
            return changeFuelType.executeUpdate() == 1;
        } catch (SQLException e) {
            return false;
        }
    }
}
