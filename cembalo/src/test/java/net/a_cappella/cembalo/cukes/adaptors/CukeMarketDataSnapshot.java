package net.a_cappella.cembalo.cukes.adaptors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import net.a_cappella.cembalo.beans.MarketDataSnapshot;
import net.a_cappella.cembalo.beans.MarketDataSnapshotEntry;

public class CukeMarketDataSnapshot {
    private static final Logger log = LoggerFactory.getLogger(CukeMarketDataSnapshot.class);

    private Double bidQ0;
    private Double bid0;
    private Double bidQ1;
    private Double bid1;
    private Double bidQ2;
    private Double bid2;
    private Double bidQ3;
    private Double bid3;
    private Double bidQ4;
    private Double bid4;

    private Double askQ0;
    private Double ask0;
    private Double askQ1;
    private Double ask1;
    private Double askQ2;
    private Double ask2;
    private Double askQ3;
    private Double ask3;
    private Double askQ4;
    private Double ask4;

    public CukeMarketDataSnapshot() {}

    public CukeMarketDataSnapshot(
            double bidQ4, double bid4, double bidQ3, double bid3, double bidQ2, double bid2, double bidQ1, double bid1, double bidQ0, double bid0,
            double askQ0, double ask0, double askQ1, double ask1, double askQ2, double ask2, double askQ3, double ask3, double askQ4, double ask4
    ) {
        this.bidQ4 = bidQ4;
        this.bid4  = bid4;
        this.bidQ3 = bidQ3;
        this.bid3  = bid3;
        this.bidQ2 = bidQ2;
        this.bid2  = bid2;
        this.bidQ1 = bidQ1;
        this.bid1  = bid1;
        this.bidQ0 = bidQ0;
        this.bid0  = bid0;

        this.askQ0 = askQ0;
        this.ask0  = ask0;
        this.askQ1 = askQ1;
        this.ask1  = ask1;
        this.askQ2 = askQ2;
        this.ask2  = ask2;
        this.askQ3 = askQ3;
        this.ask3  = ask3;
        this.askQ4 = askQ4;
        this.ask4  = ask4;
    }

    public double getBidQ0() {
        return bidQ0;
//		return (bidQ0 == null) ? 0.0 : bidQ0;
    }
    public double getBid0() {
        return bid0;
//		return (bid0 == null) ? Double.NaN : bid0;
    }
    public double getBidQ1() {
        return bidQ1;
//		return (bidQ1 == null) ? 0.0 : bidQ1;
    }
    public double getBid1() {
        return bid1;
//		return (bid1 == null) ? Double.NaN : bid1;
    }
    public double getBidQ2() {
        return (bidQ2 == null) ? 0.0 : bidQ2;
    }
    public double getBid2() {
        return (bid2 == null) ? Double.NaN : bid2;
    }
    public double getBidQ3() {
        return (bidQ3 == null) ? 0.0 : bidQ3;
    }
    public double getBid3() {
        return (bid3 == null) ? Double.NaN : bid3;
    }
    public double getBidQ4() {
        return (bidQ4 == null) ? 0.0 : bidQ4;
    }
    public double getBid4() {
        return (bid4 == null) ? Double.NaN : bid4;
    }
    public double getAskQ0() {
        return ask0;
//		return (askQ0 == null) ? 0.0 : askQ0;
    }
    public double getAsk0() {
        return askQ0;
//		return (ask0 == null) ? Double.NaN : ask0;
    }
    public double getAskQ1() {
        return askQ1;
//		return (askQ1 == null) ? 0.0 : askQ1;
    }
    public double getAsk1() {
        return (ask1 == null) ? Double.NaN : ask1;
    }
    public double getAskQ2() {
        return (askQ2 == null) ? 0.0 : askQ2;
    }
    public double getAsk2() {
        return (ask2 == null) ? Double.NaN : ask2;
    }
    public double getAskQ3() {
        return (askQ3 == null) ? 0.0 : askQ3;
    }
    public double getAsk3() {
        return (ask3 == null) ? Double.NaN : ask3;
    }
    public double getAskQ4() {
        return (askQ4 == null) ? 0.0 : askQ4;
    }
    public double getAsk4() {
        return (ask4 == null) ? Double.NaN : ask4;
    }

    public static CukeMarketDataSnapshot adapt(MarketDataSnapshot mds) {
        CukeMarketDataSnapshot cukeMds = new CukeMarketDataSnapshot();

        for (int i=0; i<mds._bidDepth; i++) {
            MarketDataSnapshotEntry entry = mds._bidEntries[i];
            cukeMds.set(true, i, entry._price, entry._size);
        }
        for (int i=0; i<mds._offerDepth; i++) {
            MarketDataSnapshotEntry entry = mds._offerEntries[i];
            cukeMds.set(false, i, entry._price, entry._size);
        }

        return cukeMds;
    }

    public CukeMarketDataSnapshot normalize() {
        if (bid0!=null && Double.isNaN(bid0) && bidQ0!=null && bidQ0==0.0) {
            bid0 = null;
            bidQ0 = null;
        }
        if (bid1!=null && Double.isNaN(bid1) && bidQ1!=null && bidQ1==0.0) {
            bid1 = null;
            bidQ1 = null;
        }
        if (bid2!=null && Double.isNaN(bid2) && bidQ2!=null && bidQ2==0.0) {
            bid2 = null;
            bidQ2 = null;
        }
        if (bid3!=null && Double.isNaN(bid3) && bidQ3!=null && bidQ3==0.0) {
            bid3 = null;
            bidQ3 = null;
        }
        if (bid4!=null && Double.isNaN(bid4) && bidQ4!=null && bidQ4==0.0) {
            bid4 = null;
            bidQ4 = null;
        }
        if (ask0!=null && Double.isNaN(ask0) && askQ0!=null && askQ0==0.0) {
            ask0 = null;
            askQ0 = null;
        }
        if (ask1!=null && Double.isNaN(ask1) && askQ1!=null && askQ1==0.0) {
            ask1 = null;
            askQ1 = null;
        }
        if (ask2!=null && Double.isNaN(ask2) && askQ2!=null && askQ2==0.0) {
            ask2 = null;
            askQ2 = null;
        }
        if (ask3!=null && Double.isNaN(ask3) && askQ3!=null && askQ3==0.0) {
            ask3 = null;
            askQ3 = null;
        }
        if (ask4!=null && Double.isNaN(ask4) && askQ4!=null && askQ4==0.0) {
            ask4 = null;
            askQ4 = null;
        }
        return this;
    }

    private void set(boolean bidSide, int index, double price, double size) {
        if (bidSide) {
            switch (index) {
                case 0:
                    bid0 = Double.isNaN(price) ? null : price;
                    bidQ0 = size==0 ? null : size;
                    break;
                case 1:
                    bid1 = Double.isNaN(price) ? null : price;
                    bidQ1 = size==0 ? null : size;
                    break;
                case 2:
                    bid2 = Double.isNaN(price) ? null : price;
                    bidQ2 = size==0 ? null : size;
                    break;
                case 3:
                    bid3 = Double.isNaN(price) ? null : price;
                    bidQ3 = size==0 ? null : size;
                    break;
                case 4:
                    bid4 = Double.isNaN(price) ? null : price;
                    bidQ4 = size==0 ? null : size;
                    break;
                default:
                    log.error("Please extend range... " + index);
            }
        } else {
            switch (index) {
                case 0:
                    ask0 = Double.isNaN(price) ? null : price;
                    askQ0 = size==0 ? null : size;
                    break;
                case 1:
                    ask1 = Double.isNaN(price) ? null : price;
                    askQ1 = size==0 ? null : size;
                    break;
                case 2:
                    ask2 = Double.isNaN(price) ? null : price;
                    askQ2 = size==0 ? null : size;
                    break;
                case 3:
                    ask3 = Double.isNaN(price) ? null : price;
                    askQ3 = size==0 ? null : size;
                    break;
                case 4:
                    ask4 = Double.isNaN(price) ? null : price;
                    askQ4 = size==0 ? null : size;
                    break;
                default:
                    log.error("Please extend range... " + index);
            }
        }
    }

    @Override
    public String toString() {
        return "{ "
                + (bidQ4==null && bid4==null ? "" : bidQ4+"@"+bid4+" ")
                + (bidQ3==null && bid3==null ? "" : bidQ3+"@"+bid3+" ")
                + (bidQ2==null && bid2==null ? "" : bidQ2+"@"+bid2+" ")
                + (bidQ1==null && bid1==null ? "" : bidQ1+"@"+bid1+" ")
                + (bidQ0==null && bid0==null ? "" : bidQ0+"@"+bid0+" ")
                + "/ "
                + (askQ0==null && ask0==null ? "" : askQ0+"@"+ask0+" ")
                + (askQ1==null && ask1==null ? "" : askQ1+"@"+ask1+" ")
                + (askQ2==null && ask2==null ? "" : askQ2+"@"+ask2+" ")
                + (askQ3==null && ask3==null ? "" : askQ3+"@"+ask3+" ")
                + (askQ4==null && ask4==null ? "" : askQ4+"@"+ask4+" ")
                + "}";
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((ask0 == null) ? 0 : ask0.hashCode());
        result = prime * result + ((ask1 == null) ? 0 : ask1.hashCode());
        result = prime * result + ((ask2 == null) ? 0 : ask2.hashCode());
        result = prime * result + ((ask3 == null) ? 0 : ask3.hashCode());
        result = prime * result + ((ask4 == null) ? 0 : ask4.hashCode());
        result = prime * result + ((askQ0 == null) ? 0 : askQ0.hashCode());
        result = prime * result + ((askQ1 == null) ? 0 : askQ1.hashCode());
        result = prime * result + ((askQ2 == null) ? 0 : askQ2.hashCode());
        result = prime * result + ((askQ3 == null) ? 0 : askQ3.hashCode());
        result = prime * result + ((askQ4 == null) ? 0 : askQ4.hashCode());
        result = prime * result + ((bid0 == null) ? 0 : bid0.hashCode());
        result = prime * result + ((bid1 == null) ? 0 : bid1.hashCode());
        result = prime * result + ((bid2 == null) ? 0 : bid2.hashCode());
        result = prime * result + ((bid3 == null) ? 0 : bid3.hashCode());
        result = prime * result + ((bid4 == null) ? 0 : bid4.hashCode());
        result = prime * result + ((bidQ0 == null) ? 0 : bidQ0.hashCode());
        result = prime * result + ((bidQ1 == null) ? 0 : bidQ1.hashCode());
        result = prime * result + ((bidQ2 == null) ? 0 : bidQ2.hashCode());
        result = prime * result + ((bidQ3 == null) ? 0 : bidQ3.hashCode());
        result = prime * result + ((bidQ4 == null) ? 0 : bidQ4.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        CukeMarketDataSnapshot other = (CukeMarketDataSnapshot) obj;
        if (ask0 == null) {
            if (other.ask0 != null)
                return false;
        } else if (!ask0.equals(other.ask0))
            return false;
        if (ask1 == null) {
            if (other.ask1 != null)
                return false;
        } else if (!ask1.equals(other.ask1))
            return false;
        if (ask2 == null) {
            if (other.ask2 != null)
                return false;
        } else if (!ask2.equals(other.ask2))
            return false;
        if (ask3 == null) {
            if (other.ask3 != null)
                return false;
        } else if (!ask3.equals(other.ask3))
            return false;
        if (ask4 == null) {
            if (other.ask4 != null)
                return false;
        } else if (!ask4.equals(other.ask4))
            return false;
        if (askQ0 == null) {
            if (other.askQ0 != null)
                return false;
        } else if (!askQ0.equals(other.askQ0))
            return false;
        if (askQ1 == null) {
            if (other.askQ1 != null)
                return false;
        } else if (!askQ1.equals(other.askQ1))
            return false;
        if (askQ2 == null) {
            if (other.askQ2 != null)
                return false;
        } else if (!askQ2.equals(other.askQ2))
            return false;
        if (askQ3 == null) {
            if (other.askQ3 != null)
                return false;
        } else if (!askQ3.equals(other.askQ3))
            return false;
        if (askQ4 == null) {
            if (other.askQ4 != null)
                return false;
        } else if (!askQ4.equals(other.askQ4))
            return false;
        if (bid0 == null) {
            if (other.bid0 != null)
                return false;
        } else if (!bid0.equals(other.bid0))
            return false;
        if (bid1 == null) {
            if (other.bid1 != null)
                return false;
        } else if (!bid1.equals(other.bid1))
            return false;
        if (bid2 == null) {
            if (other.bid2 != null)
                return false;
        } else if (!bid2.equals(other.bid2))
            return false;
        if (bid3 == null) {
            if (other.bid3 != null)
                return false;
        } else if (!bid3.equals(other.bid3))
            return false;
        if (bid4 == null) {
            if (other.bid4 != null)
                return false;
        } else if (!bid4.equals(other.bid4))
            return false;
        if (bidQ0 == null) {
            if (other.bidQ0 != null)
                return false;
        } else if (!bidQ0.equals(other.bidQ0))
            return false;
        if (bidQ1 == null) {
            if (other.bidQ1 != null)
                return false;
        } else if (!bidQ1.equals(other.bidQ1))
            return false;
        if (bidQ2 == null) {
            if (other.bidQ2 != null)
                return false;
        } else if (!bidQ2.equals(other.bidQ2))
            return false;
        if (bidQ3 == null) {
            if (other.bidQ3 != null)
                return false;
        } else if (!bidQ3.equals(other.bidQ3))
            return false;
        if (bidQ4 == null) {
            if (other.bidQ4 != null)
                return false;
        } else if (!bidQ4.equals(other.bidQ4))
            return false;
        return true;
    }

}
