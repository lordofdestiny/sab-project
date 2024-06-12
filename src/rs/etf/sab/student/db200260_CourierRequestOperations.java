package rs.etf.sab.student;

import java.util.List;

public class db200260_CourierRequestOperations implements rs.etf.sab.operations.CourierRequestOperation {
    @Override
    public boolean insertCourierRequest(String userName, String licencePlateNumber) {
        return false;
    }

    @Override
    public boolean deleteCourierRequest(String userName) {
        return false;
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
