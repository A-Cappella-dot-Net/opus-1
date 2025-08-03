package net.a_cappella.cembalo;

public class Instrument {
    private static final double EPSILON = 0.00000001;

    public static final int ORDERING_PRICE = 1; // TODO enum
    public static final int ORDERING_YIELD = 2;

    private final String symbol;
    private final String secId;
    private final double minQty;
    private final double minQtyIncrement;
    private final double minPriceIncrement;
    private final int ordering;
    private final int maxLevels;

    public Instrument(String symbol, String secId, double minQty, double minQtyIncrement, double minPriceIncrement, int ordering, int maxLevels) {
        this.symbol = symbol;
        this.secId = secId;
        this.minQty = minQty;
        this.minQtyIncrement = minQtyIncrement;
        this.minPriceIncrement = minPriceIncrement;
        this.ordering = ordering;
        this.maxLevels = maxLevels;
    }

    public String getSymbol() {
        return symbol;
    }
    public String getSecId() {
        return secId;
    }
    public double getMinQty() {
        return minQty;
    }
    public double getMinQtyIncrement() {
        return minQtyIncrement;
    }
    public double getMinPriceIncrement() {
        return minPriceIncrement;
    }
    public int getOrdering() {
        return ordering;
    }
    public int getMaxLevels() {
        return maxLevels;
    }

    public String validate(double px, double qtyShown, double qty) {
        if (qtyShown == 0.0) qtyShown = qty;
        if (minQty>qtyShown) {
            return "MinQty restriction not met: "+minQty+">"+qtyShown;
        }
        double numQtyIncrements = (qty - minQty) / minQtyIncrement;
        if (Math.abs(numQtyIncrements - Math.rint(numQtyIncrements)) > EPSILON) {
            return "Qty "+qty+" does not align to minQtyIncrement of "+minQtyIncrement+" where minQty is "+minQty;
        }
        if (qtyShown!=qty) {
            numQtyIncrements = (qtyShown - minQty) / minQtyIncrement;
            if (Math.abs(numQtyIncrements - Math.rint(numQtyIncrements)) > EPSILON) {
                return "Shown Qty "+qtyShown+" does not align to minQtyIncrement of "+minQtyIncrement+" where minQty is "+minQty;
            }
        }
        double numPxIncrements = px / minPriceIncrement;
        if (Math.abs(numPxIncrements-Math.rint(numPxIncrements)) > EPSILON) {
            return "Price "+px+" does not align to minPriceIncrement of "+minPriceIncrement;
        }
        return null;
    }

    @Override
    public String toString() {
        return
                "Instrument{" +
                        symbol + " " +
                        minQty + " " + minQtyIncrement + " " + minPriceIncrement + " " +
                        ordering + " " + maxLevels + "}";
    }
}
