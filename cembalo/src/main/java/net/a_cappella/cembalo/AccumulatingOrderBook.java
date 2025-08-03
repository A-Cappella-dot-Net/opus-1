package net.a_cappella.cembalo;

import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_ExecType_Replaced;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Canceled;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_New;
import static net.a_cappella.cembalo.generated.FixConstants.Val_OrdStatus_Replaced;

import java.util.ArrayList;
import java.util.List;
import java.util.function.DoubleFunction;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.google.common.annotations.VisibleForTesting;

import net.a_cappella.cembalo.constants.OrdType;
import net.a_cappella.cembalo.constants.Side;
import net.a_cappella.cembalo.constants.TimeInForce;

public class AccumulatingOrderBook<T extends AccumulatingLevel> {
    private static final Logger log = LoggerFactory.getLogger(AccumulatingOrderBook.class);

    protected final IExchangeServer _server;
    protected final String _securityID;
    protected final int _ordering;
    protected DoubleFunction<T> _levelSupplier;

    public List<T> _levels = new ArrayList<>(); // sorted descending by price

    public AccumulatingOrderBook(IExchangeServer server, Instrument instrument, DoubleFunction<T> supplier) {
        _server = server;
        _securityID = instrument.getSecId();
        _ordering = instrument.getOrdering();
        _levelSupplier = supplier;
    }

    public void addOrder(Order ord) {
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, null, Val_ExecType_New, Val_OrdStatus_New, 0,
                ord._securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif), ord._price, ord._size, ord._shownSize, 0.0, Double.NaN, ord._size, 0.0, Double.NaN, null);

        double px = getConventionPrice(ord);
        T level = findOrInsertNewLevel(px);
        level.add(ord);
    }

    public void cancelOrder(Order ord) {
        cancel(ord, null);

        double px = getConventionPrice(ord);
        T level = findOrInsertNewLevel(px);
        level.remove(ord);
    }

    public void cancel(Order ord, String text) {
        // send Cancel Ack back to client
        ord._lastPx = Double.NaN;
        ord._lastQty = 0.0;
        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, ord._origClOrdID,
                Val_ExecType_Canceled, Val_OrdStatus_Canceled, 0, _securityID, Side.toFix(ord._side), OrdType.toFix(ord._ordType), TimeInForce.toFix(ord._tif), ord._price,
                ord._size, ord._shownSize, ord._lastQty, ord._lastPx, ord._leavesQty, ord._cumQty, ord._avgPx, text);
    }

    public void replaceOrder(Order ord, double nPx, double nQty, double nShownQty, OrdType nOrdType) {

        double oQty = ord._size;
        ord._leavesQty += nQty - oQty; // nLeaves = nQty - cumQty = nQty - (oQty - oLeaves) = nQty - oQty + oLeaves
        ord._shownSize = nShownQty;

        _server.sendExecutionReport(ord._selectionKey, ord._user, ord._orderID, ord._clOrdID, ord._origClOrdID,
                Val_ExecType_Replaced, Val_OrdStatus_Replaced,
                0, _securityID, Side.toFix(ord._side), OrdType.toFix(nOrdType), TimeInForce.toFix(ord._tif),
                nPx, nQty, nShownQty,
                0.0, Double.NaN, ord._leavesQty, ord._cumQty, ord._avgPx, null);

        if (nOrdType == OrdType.Market) {
            nPx = (ord._side == Side.Buy) ? Double.POSITIVE_INFINITY : Double.NEGATIVE_INFINITY;
        }

        double oPx = getConventionPrice(ord);

        T level = findOrInsertNewLevel(oPx);
        if (oPx==nPx) {
            level.replaceSameLevel(ord, nQty);
        } else {
            level.replaceNewLevel(ord, nPx, nQty, nOrdType, findOrInsertNewLevel(nPx));
        }
    }

    private double getConventionPrice(Order ord) {
        double px = ord._price;
        OrdType ordType = ord._ordType;
        if (ordType == OrdType.Market) {
            px = (ord._side == Side.Buy) ? Double.POSITIVE_INFINITY : Double.NEGATIVE_INFINITY;
        }
        return px;
    }

    public T findOrInsertNewLevel(double price) {
        for (int i=0; i<_levels.size(); i++) {
            T level = _levels.get(i);
            double levelPrice = level.getPrice();
            if (levelPrice == price) {  // level exists
                return level;
            } else if (levelPrice < price) { // level does not exist
                level = _levelSupplier.apply(price);
                _levels.add(i, level);
                return level;
            }
        }
        T level =  _levelSupplier.apply(price);
        _levels.add(level);
        return level;
    }

    public T findLevel(double price) {
        for (int i=0; i<_levels.size(); i++) {
            T level = _levels.get(i);
            double levelPrice = level.getPrice();
            if (levelPrice == price) {  // level exists
                return level;
            } else if (levelPrice < price) { // level does not exist
                return null;
            }
        }
        return null;
    }

    @VisibleForTesting
    public List<T> getLevels() {
        return  _levels;
    }

    @VisibleForTesting
    public boolean isEmpty() {
        if (_levels.isEmpty()) return true;
        for (int i=0; i<_levels.size(); i++) {
            T level = _levels.get(i);
            if (level.hasBids() || level.hasOffers()) return false;
        }
        return true;
    }
}
