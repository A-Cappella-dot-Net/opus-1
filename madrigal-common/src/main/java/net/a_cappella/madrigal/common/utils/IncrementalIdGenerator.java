package net.a_cappella.madrigal.common.utils;

import com.google.common.util.concurrent.ThreadFactoryBuilder;
import net.a_cappella.madrigal.common.interfaces.IIdGenerator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.GregorianCalendar;
import java.util.concurrent.ScheduledThreadPoolExecutor;
import java.util.concurrent.ThreadFactory;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicLong;

public class IncrementalIdGenerator implements IIdGenerator {
    private static final Logger log = LoggerFactory.getLogger(IncrementalIdGenerator.class);

    private static final ThreadFactory _threadFactory = new ThreadFactoryBuilder()
			.setNameFormat(IncrementalIdGenerator.class.getSimpleName() + "-%d").setDaemon(true).build();

    private static final boolean TEST = false;

    private final int _persistFreq;
	private final String _prefix;
	private final String _fmt;
	private String _date;
	private final AtomicLong _seqNo = new AtomicLong();
	private final ScheduledThreadPoolExecutor _scheduler = new ScheduledThreadPoolExecutor(1, _threadFactory);
	private final DateChangeRunnable _dateChangeRunnable = new DateChangeRunnable();
	private final String _fileName;
	private RandomAccessFile _raf;

	public IncrementalIdGenerator(String dir, String prefix, String fmt, int persistFreq) {
		_prefix = prefix;
		_fileName = dir+"idGen-"+prefix+".dat";
		_fmt = fmt;
		SimpleDateFormat sdf = new SimpleDateFormat(fmt);
		_date = sdf.format(new Date());
		_persistFreq = persistFreq;
		// schedule the timer for midnight
		_scheduler.schedule(_dateChangeRunnable, millisToMidnight(), TimeUnit.MILLISECONDS);
		try {
		    File file = new File(_fileName);
		    boolean newFile = !file.exists();
		    _raf = new RandomAccessFile(file, "rw");

		    String line;
		    if (!newFile) {
			    line = _raf.readLine();
			    String[] comps = line.split(" ");
			    String oldDate = comps[0];
			    String newSeqNo = comps[1];
			    if (!oldDate.equals(_date)) {
			    	_seqNo.getAndSet(0);
			    } else {
			    	_seqNo.getAndSet(Long.valueOf(newSeqNo));
			    }
		    }
		    saveState(_seqNo.get());
		} catch (IOException e) {
			log.error("", e);
		}
	}

	public void stop() {
		_scheduler.shutdown();
		log.info("Thread pool "+_scheduler+" shut down...");
	}

	public String nextId() {
		long longid = _seqNo.incrementAndGet();
		if (longid%_persistFreq==0) {
			saveState(longid);
		}
		return String.format("%s%s%08d", _prefix, _date, longid);
	}

	private long millisToMidnight() {
		Calendar now = new GregorianCalendar();

		Calendar midnight = new GregorianCalendar();
		if (TEST) {
			midnight.set(Calendar.SECOND, now.get(Calendar.SECOND)+10);
		} else {
			midnight.set(Calendar.HOUR_OF_DAY, 24);
			midnight.set(Calendar.MINUTE, 0);
			midnight.set(Calendar.SECOND, 0);
			midnight.set(Calendar.MILLISECOND, 500);
		}

		long millisNow = now.getTimeInMillis();
		long millisMidnight = midnight.getTimeInMillis();
		long diffMillis = millisMidnight-millisNow;
		log.info("scheduling dataChange for "+(new Date(millisMidnight)));
		return diffMillis;
	}

	private class DateChangeRunnable implements Runnable {
		public void run() {
			// triggered by the timer at midnight
			log.info("executing dataChange "+(new Date()));
			// new date
			SimpleDateFormat sdf = new SimpleDateFormat(_fmt);
			_date = sdf.format(new Date());
			// reset seqNo
			_seqNo.set(0);
			// write new value to the file
			saveState(_seqNo.get());
			// re-schedule itself for next midnight
			_scheduler.schedule(_dateChangeRunnable, millisToMidnight(), TimeUnit.MILLISECONDS);
		}
	}

	private void saveState(long crtId) {
    	String line = _date+" "+((crtId/_persistFreq)+1)*_persistFreq+" ";
	    try {
			_raf.seek(0);
		    _raf.writeBytes(line);
		    // DO NOT CLOSE; will be available anyways
		} catch (IOException e) {
			log.error("", e);
		}
	}

	public static void main(String[] args) {
		IncrementalIdGenerator idGen = new IncrementalIdGenerator("", "H", "yyMMdd", 5);

		for (int i=0; i<40; i++) {
			log.info(idGen.nextId());
			try {Thread.sleep(1000);} catch (InterruptedException e) {}
		}
	}
}
