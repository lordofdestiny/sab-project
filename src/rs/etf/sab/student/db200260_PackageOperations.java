package rs.etf.sab.student;

import rs.etf.sab.operations.PackageOperations;

import java.math.BigDecimal;
import java.sql.Date;
import java.util.List;

public class db200260_PackageOperations implements PackageOperations {
    @Override
    public int insertPackage(int districtFrom, int districtTo, String userName, int packageType, BigDecimal weight) {
        return 0;
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
    public boolean changeWeight(int packageId, BigDecimal newWeight ) {
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
