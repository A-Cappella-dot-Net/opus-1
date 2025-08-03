package net.a_cappella.cembalo.beans;

import net.a_cappella.continuo.utils.Utils;

public class MarketDataSnapshot {
    public String _securityID;
    public int _marketDepth;
    public int _bidDepth;
    public int _offerDepth;
    public MarketDataSnapshotEntry[] _bidEntries;
    public MarketDataSnapshotEntry[] _offerEntries;
    public long _tsx;

    public MarketDataSnapshot(String securityID, int marketDepth) {
        _securityID = securityID;
        _marketDepth = marketDepth;
        _bidDepth = 0;
        _offerDepth = 0;

        _bidEntries = new MarketDataSnapshotEntry[marketDepth];
        _offerEntries = new MarketDataSnapshotEntry[marketDepth];

        for (int i=0; i<marketDepth; i++) {
            _bidEntries[i] = new MarketDataSnapshotEntry(0, Double.NaN);
            _offerEntries[i] = new MarketDataSnapshotEntry(0, Double.NaN);
        }
    }
    public void reset() {
        _bidDepth = 0;
        _offerDepth = 0;
        _tsx = 0;
    }

    public MarketDataSnapshot(int marketDepth) {
        this(null, marketDepth);
    }
    public void reset(String securityID, long tsx) {
        _securityID = securityID;
        for (int i=0; i<_marketDepth; i++) {
            _bidEntries[i].reset();
            _offerEntries[i].reset();
        }
        _tsx = tsx;
    }

    public void setBid(int level, double px, double size) {
        _bidDepth = level+1;
        _bidEntries[level]._price = px;
        _bidEntries[level]._size = size;
    }
    public void setOffer(int level, double px, double size) {
        _offerDepth = level+1;
        _offerEntries[level]._price = px;
        _offerEntries[level]._size = size;
    }
    public void setTsx(long tsx) {
        _tsx = tsx;
    }
    public long getTsx() {
        return _tsx;
    }

    private String toString(int len, MarketDataSnapshotEntry[] entries) {
        String str = "";
        for (int i=0; i<len; i++) {
            if (i>0) str += ", ";
            str += entries[i];
        }
        return "["+str+"]";
    }
    public String toString() {
        return "{b:"+toString(_bidDepth, _bidEntries)+" o:"+toString(_offerDepth, _offerEntries)+" "+ Utils.formatMillis(_tsx)+"}";
    }
}
