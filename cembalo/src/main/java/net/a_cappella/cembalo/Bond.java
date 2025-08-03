package net.a_cappella.cembalo;

public class Bond extends Instrument {
    private final int _maturityDate;
    private final double _contractMultiplier;
    private final double _coupon;

    public Bond(String symbol, String secId, double minQty, double minQtyIncrement, double minPriceIncrement, int ordering, int maxLevels,
                int maturityDate, double contractMultiplier, double coupon) {
        super(symbol, secId, minQty, minQtyIncrement, minPriceIncrement, ordering, maxLevels);
        _maturityDate = maturityDate;
        _contractMultiplier = contractMultiplier;
        _coupon = coupon;
    }

    public int getMaturityDate() {
        return _maturityDate;
    }
    public double getContractMultiplier() {
        return _contractMultiplier;
    }
    public double getCoupon() {
        return _coupon;
    }
}
