package rs.etf.sab.student;

import java.math.BigDecimal;
import java.util.List;

public class db200260_VehicleOperations implements rs.etf.sab.operations.VehicleOperations{
    @Override
    public boolean insertVehicle(String licencePlateNumber, int fuelType, BigDecimal fuelConsumption) {
        return false;
    }

    @Override
    public int deleteVehicles(String... licencePlateNumbers) {
        return 0;
    }

    @Override
    public List<String> getAllVehichles() {
        return List.of();
    }

    @Override
    public boolean changeFuelType(String s, int i) {
        return false;
    }

    @Override
    public boolean changeConsumption(String licensePlateNumber, BigDecimal fuelConsumption) {
        return false;
    }
}
