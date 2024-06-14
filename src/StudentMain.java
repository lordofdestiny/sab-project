import rs.etf.sab.operations.*;
import rs.etf.sab.student.*;
import rs.etf.sab.tests.TestHandler;
import rs.etf.sab.tests.TestRunner;


public class StudentMain {

    public static void main(String[] args) {
        CityOperations cityOperations = new db200260_CityOperations();
        DistrictOperations districtOperations = new db200260_DistrictOperations();
        CourierOperations courierOperations = new db200260_CourierOperations();
        CourierRequestOperation courierRequestOperation = new db200260_CourierRequestOperations();
        GeneralOperations generalOperations = new db200260_GeneralOperations();
        UserOperations userOperations = new db200260_UserOperations();
        VehicleOperations vehicleOperations = new db200260_VehicleOperations();
        PackageOperations packageOperations = new db200260_PackageOperations();

        TestHandler.createInstance(
                cityOperations,
                courierOperations,
                courierRequestOperation,
                districtOperations,
                generalOperations,
                userOperations,
                vehicleOperations,
                packageOperations);

        TestRunner.runTests();
    }
}
