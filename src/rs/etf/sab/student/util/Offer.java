package rs.etf.sab.student.util;

import rs.etf.sab.operations.PackageOperations;

import java.math.BigDecimal;

public class Offer implements PackageOperations.Pair<Integer, BigDecimal> {
    private int offerId;
    private BigDecimal percentage;

    public Offer(int offerId, BigDecimal percentage) {
        this.offerId = offerId;
        this.percentage = percentage;
    }

    @Override
    public Integer getFirstParam() {
        return offerId;
    }

    @Override
    public BigDecimal getSecondParam() {
        return percentage;
    }
}
