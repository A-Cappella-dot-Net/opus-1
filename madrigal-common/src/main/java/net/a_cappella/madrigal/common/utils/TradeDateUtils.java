package net.a_cappella.madrigal.common.utils;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.madrigal.common.interfaces.IDateRollListener;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.util.Date;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;

public class TradeDateUtils {
    private static final Logger log = LoggerFactory.getLogger(TradeDateUtils.class);

    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(TradeDateUtils.class.getSimpleName() + "-%d").setDaemon(true).build();

	private final String _timeZone;
    private final int _rollHour;
    private final int _rollMinute;
    private final int _rollSecond;

	private Instant _tradeDate;
	private final ScheduledThreadPoolExecutor _scheduler = new ScheduledThreadPoolExecutor(1, _threadFactory);
	private final DateRollRunnable _dateRollRunnable = new DateRollRunnable();

	private final CopyOnWriteArrayList<IDateRollListener> _dateRollListeners =
		new CopyOnWriteArrayList<>();
	public void addListener(IDateRollListener dateRollListener) {
		_dateRollListeners.add(dateRollListener);
	}
	public void removeListener(IDateRollListener dateRollListener) {
		_dateRollListeners.add(dateRollListener);
	}

	public TradeDateUtils(String rollTime, String timeZone) {
		String[] rollComps = rollTime.split(":");
		_rollHour = Integer.parseInt(rollComps[0]);
		_rollMinute = Integer.parseInt(rollComps[1]);
		_rollSecond = Integer.parseInt(rollComps[2]);
		_timeZone = timeZone;

		// schedule the timer for the specified roll time
		_scheduler.schedule(_dateRollRunnable, millisToNextRollTime(), TimeUnit.MILLISECONDS);
	}

	private class DateRollRunnable implements Runnable {
		public void run() {
			// triggered by the timer
			log.info("executing dataChange "+(new Date()));
			notifyDateRollListeners();
			try {Thread.sleep(1000);} catch(InterruptedException x) {}
			// re-schedule itself for next midnight
			_scheduler.schedule(_dateRollRunnable, millisToNextRollTime(), TimeUnit.MILLISECONDS);
		}
	}

	public Instant getTradeDate() {
		return _tradeDate;
	}

	private void notifyDateRollListeners() {
		for (IDateRollListener dateRollListener : _dateRollListeners) {
			dateRollListener.onDateRoll(_tradeDate);
		}
	}

	private long millisToNextRollTime() {
		ZoneId zoneId = ZoneId.of(_timeZone);
		ZonedDateTime now = ZonedDateTime.now(zoneId);
		ZonedDateTime todayStart = now.toLocalDate().atStartOfDay( zoneId );
		ZonedDateTime nextRoll = todayStart.plusHours(_rollHour).plusMinutes(_rollMinute).plusSeconds(_rollSecond);
		if (now.isBefore(nextRoll)) {
			_tradeDate = todayStart.toInstant();
		} else {
			nextRoll = nextRoll.plusDays(1);
			_tradeDate = todayStart.plusDays(1).toInstant();
		}

		long nowMillis = now.toInstant().toEpochMilli();
		long rollMillis = nextRoll.toInstant().toEpochMilli();
		log.info("scheduling dateRoll for "+nextRoll);
		return rollMillis-nowMillis;
	}

	public String toString() {
		return "{"+_tradeDate+"}";
	}
}
