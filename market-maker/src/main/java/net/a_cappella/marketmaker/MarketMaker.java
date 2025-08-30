package net.a_cappella.marketmaker;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.*;
import net.a_cappella.madrigal.common.obj.*;
import net.a_cappella.presto.obj.PingObj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

import static net.a_cappella.madrigal.common.constants.MadrigalOrdType.LIMIT;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Buy;
import static net.a_cappella.madrigal.common.constants.MadrigalSide.Sell;
import static net.a_cappella.madrigal.common.constants.MadrigalTimeInForce.*;

public class MarketMaker {
    private static final Logger log = LoggerFactory.getLogger(MarketMaker.class);

    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(MarketMaker.class.getSimpleName() + "-%d").setDaemon(true).build();

    public static final String SNIPER_ORDER_ID_PREFIX = "sn_";

    private static final String _loopbackTimerSql = "select * from ping where mine=%d and onLoopback=true";

    private final MarketMakerManager _mgr;
    private final String _instrId;
    private final int _normalSpreadTicks;
    private final int _wideSpreadTicks;

    private MadrigalInstrStatus _contStatus = MadrigalInstrStatus.CLOSED;
    private MadrigalInstrPhase _contPhase = MadrigalInstrPhase.CLOSED;
    private MadrigalInstrPhase _openPhase = MadrigalInstrPhase.CLOSED;
    private MadrigalInstrPhase _closePhase = MadrigalInstrPhase.CLOSED;
    private double _minPriceIncrement = Double.NaN;
    private double _minQty = Double.NaN;

	private double _mid = Double.NaN;

	private final MarketMakerSide _bidSide;
	private final MarketMakerSide _askSide;

	private double _bidSidePx;
	private double _bidSideQty;
	private double _askSidePx;
	private double _askSideQty;

	private final ScheduledThreadPoolExecutor _scheduler = new ScheduledThreadPoolExecutor(1, _threadFactory);

	public MarketMaker(MarketMakerManager mgr, String instrId,
			int normalSpreadTicks, int wideSpreadTicks, int whenHitInterval, boolean pullOrderWhenHit,
			double bidSize, double askSize) {
		_mgr = mgr;
		_instrId = instrId;
		_normalSpreadTicks = normalSpreadTicks;
		_wideSpreadTicks = wideSpreadTicks;

		_bidSide = new MarketMakerSide(mgr, this, instrId, Buy, bidSize, whenHitInterval, pullOrderWhenHit);
		_askSide = new MarketMakerSide(mgr, this, instrId, Sell, askSize, whenHitInterval, pullOrderWhenHit);
	}

	public void handleEcnInstrument(EcnInstrumentObj ecnInstrument) {
		log.info("handling ecnInstrument {}", ecnInstrument);
		_minPriceIncrement = ecnInstrument.getMinPriceIncrement();
		double normalSpread = _normalSpreadTicks * _minPriceIncrement;
		double wideSpread = _wideSpreadTicks * _minPriceIncrement;
		_minQty = ecnInstrument.getMinQty();
		log.info("minPriceIncrement={} normalSpread={} wideSpread={}", _minPriceIncrement, normalSpread, wideSpread);
		_bidSide.setInstrumentDetails(_minPriceIncrement, normalSpread, wideSpread);
		_askSide.setInstrumentDetails(_minPriceIncrement, normalSpread, wideSpread);
	}

	public void handleEcnInstrStatus(EcnInstrStatusObj ecnInstrStatus) {
		log.info("handling ecnInstrStatus {}", ecnInstrStatus);
		if (ecnInstrStatus.getBook() == MadrigalOrderBook.CONTINUOUS) {
			_contStatus = ecnInstrStatus.getStatus();
			_contPhase = ecnInstrStatus.getPhase();
		}
		if (ecnInstrStatus.getBook() == MadrigalOrderBook.CLOSE) {
			_closePhase = ecnInstrStatus.getPhase();
		}
		if (ecnInstrStatus.getBook() == MadrigalOrderBook.OPEN) {
			_openPhase = ecnInstrStatus.getPhase();
		}
	}

	public void handleMidFeed(MidFeedObj midFeed) {
		if (!_mgr.isLoggedIn()) return;
		if (_contStatus == MadrigalInstrStatus.CLOSED) return;

		log.info("handling midFeed {}", midFeed);
		_mid = midFeed.getMid();
		if (Utils.doubleCmp(_mid, _bidSide._mid) < 0) {
	        _bidSide.handleMidChange(_mid);
	        _askSide.handleMidChange(_mid);
		} else if (Utils.doubleCmp(_mid, _bidSide._mid) > 0) {
	        _askSide.handleMidChange(_mid);
	        _bidSide.handleMidChange(_mid);
		}
	}

	public void handleEcnPrice(EcnPriceObj ecnPrice) {
		log.info("handling ecnPrice {}", ecnPrice);
		_bidSidePx = ecnPrice.getBid0();
		_bidSideQty = ecnPrice.getBidSize0();
		_askSidePx = ecnPrice.getOffer0();
		_askSideQty = ecnPrice.getOfferSize0();
		_bidSide.handleMarketDataSnapshot();
		_askSide.handleMarketDataSnapshot();
	}

	public void handleOrderResponse(OrderObj response) {
		if (response.getOrdId().startsWith(SNIPER_ORDER_ID_PREFIX)) {
			return; // ignore sniper responses
		}
		MadrigalSide side = response.getSide();
		if (Buy == side) {
			_bidSide.handleOrderResponse(response);
		} else { // Sell
			_askSide.handleOrderResponse(response);
		}
	}

	public void handleUserStatus(boolean loggedIn) {
		log.info("handling userStatus {}", loggedIn);
		if (loggedIn) {
			if (_contStatus == MadrigalInstrStatus.CLOSED) return;
			if (!Double.isNaN(_mid)) {
		        _bidSide.handleMidChange(_mid);
		        _askSide.handleMidChange(_mid);
			}
		}
	}

    private static final double EPSILON = 0.00000001;
	public boolean sanitize(double px, MadrigalSide side) {
		boolean sanitized;
		if (Buy == side) {
			if (Double.isNaN(_askSidePx)) {
				sanitized = true;
			} else {
				sanitized = px < _askSidePx - EPSILON;
			}
		} else { // "Sell"
			if (Double.isNaN(_bidSidePx)) {
				sanitized = true;
			} else {
				sanitized = px > _bidSidePx + EPSILON;
			}
		}
		if (!sanitized || log.isDebugEnabled()) {
			log.info("sanitizing {} {} ({}-{}) => {}", side, px, Utils.frc(_bidSidePx), Utils.frc(_askSidePx), sanitized);
		}
		return sanitized;
	}


	private final PingObj _timeoutObj = new PingObj();
	private double _tobFraction;

	public void scheduleSniper(short mmId, int periodMillis, double sizePercent) {
		_timeoutObj.setMine(mmId);
		_tobFraction = sizePercent;

        try {
			_mgr.getClient().subscribe(String.format(_loopbackTimerSql, mmId), (obj, subsId) -> {
				onTimeoutMsg((PingObj) obj);
			});

			_scheduler.scheduleAtFixedRate(
				() -> {
					try {
						_mgr.getClient().loopback(_timeoutObj);
					} catch (Exception e) {
						log.error("", e);
					}
				},
				1_0000, periodMillis, TimeUnit.MILLISECONDS);
		} catch (Exception e) {
			log.error("", e);
		}

	}

	private void onTimeoutMsg(PingObj pingObj) {
		if (!_mgr.isLoggedIn()) return;

		MadrigalSide side = (Math.random()>0.5) ? MadrigalSide.Buy : MadrigalSide.Sell;

		if (_contPhase == MadrigalInstrPhase.MATCHING) {
			double qty = (side == Buy) ? _askSideQty : _bidSideQty;
			if (Double.isNaN(qty) || qty==0.0) {
				return; // wait for the next cycle
			}
			qty = Math.ceil(qty * _tobFraction);
			if (qty<_minQty) {
				qty = _minQty;
			}
			addSniperOrder(side, IOC, qty, (side == Buy) ? _askSidePx : _bidSidePx);
		} else {
			double improvement = _wideSpreadTicks * _minPriceIncrement;
			double px = (side == Buy) ? 
				Utils.alignUp(_mid + improvement, _minPriceIncrement) : 
				Utils.alignDown(_mid - improvement, _minPriceIncrement);
			if (_openPhase == MadrigalInstrPhase.ONLY_NEW) {
				addSniperOrder(side, AtOpen, _minQty, px);
			}
			if (_closePhase == MadrigalInstrPhase.ONLY_NEW) {
				addSniperOrder(side, AtClose, _minQty, px);
			}
		}
	}

	private void addSniperOrder(MadrigalSide side, MadrigalTimeInForce tif, double size, double px) {
		_mgr.addOrder(SNIPER_ORDER_ID_PREFIX+_mgr.nextOrderId(), _instrId, side, LIMIT, tif, px, size, size);
	}
}
