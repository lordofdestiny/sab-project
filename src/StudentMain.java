import rs.etf.sab.*;
import tests.TestHandler;
import tests.TestRunner;


public class StudentMain {

    public static void main(String[] args) {
        CityOperations cityOperations = null; // Change this to your implementation.
        DistrictOperations districtOperations = null; // Do it for all classes.
        CourierOperations courierOperations = null; // e.g. = new MyDistrictOperations();
        CourierRequestOperation courierRequestOperation = null;
        GeneralOperations generalOperations = null;
        UserOperations userOperations = null;
        VehicleOperations vehicleOperations = null;
        PackageOperations packageOperations = null;

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
