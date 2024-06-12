package rs.etf.sab.student;

import java.math.BigDecimal;
import java.util.List;

public class db200260_CourierOperations implements rs.etf.sab.operations.CourierOperations{
    @Override
    public boolean insertCourier(String courierUserName, String licencePlateNumber) {
        return false;
    }

    @Override
    public boolean deleteCourier(String courierUserName) {
        return false;
    }

    @Override
    public List<String> getCouriersWithStatus(int statusOfCourier) {
        return List.of();
    }

    @Override
    public List<String> getAllCouriers() {
        return List.of();
    }

    @Override
    public BigDecimal getAverageCourierProfit(int numberOfDeliveries) {
        return null;
    }
}
