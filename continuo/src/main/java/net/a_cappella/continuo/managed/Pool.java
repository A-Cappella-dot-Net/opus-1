package net.a_cappella.continuo.managed;

import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class Pool<T extends IPoolable> {
    private static final Logger log = LoggerFactory.getLogger(Pool.class);

    private final AtomicInteger _atomicInt;

    private MsgInstantiator _instantiator;
    public MsgInstantiator getInstantiator() {
        return _instantiator;
    }

    private int _initialSize;
    private int _incrementSize;
    private int _currentSize = 0;
    public int getCurrentSize() {
        return _currentSize;
    }

    public Class<?> getMsgClass() {
        return _instantiator.getMsgClass();
    }

    private int _availableCnt;
    public int getAvailableObjectsCount() {
        return _availableCnt;
    }
    private ListCell<T> _availableObjects;
    public ListCell<T> getAvailableObjects() {
        return _availableObjects;
    }

    private int _usedCnt;
    public int getUsedCellsCount() {
        return _usedCnt;
    }
    private ListCell<T> _usedCells;
    public ListCell<T> getUsedCells() {
        return _usedCells;
    }

    public Pool(MsgInstantiator instantiator, int initialSize, int incrementSize) {
        init(instantiator, initialSize, incrementSize);
        _atomicInt = new AtomicInteger();
    }
    public Pool(boolean useCas, MsgInstantiator instantiator, int initialSize, int incrementSize) {
        init(instantiator, initialSize, incrementSize);
        _atomicInt = (useCas) ? new AtomicInteger() : null;
    }

    public T acquire() {
        T obj;
        if (_atomicInt == null) {
            synchronized (this) {
                ListCell<T> cell = _availableObjects;
                _availableObjects = _availableObjects._next;
                if (_availableObjects==null) augment(_incrementSize);
                cell._next = _usedCells;
                _usedCells = cell;
                obj = cell._obj;
                cell._obj = null;

                _availableCnt--;
                _usedCnt++;
            }
        } else {
            while(!_atomicInt.compareAndSet(0, 1));
            ListCell<T> cell = _availableObjects;
            _availableObjects = _availableObjects._next;
            if (_availableObjects==null) augment(_incrementSize);
            cell._next = _usedCells;
            _usedCells = cell;
            obj = cell._obj;
            cell._obj = null;

            _availableCnt--;
            _usedCnt++;
            _atomicInt.set(0);
        }

        obj.acquire();

        return obj;
    }

    public void release(T obj) {
        if (_atomicInt == null) {
            synchronized (this) {
                checkDups(obj.getIdentityHashCode(), "release");

                ListCell<T> cell = _usedCells;
                _usedCells = _usedCells._next;
                cell._obj = obj;
                cell._next = _availableObjects;
                _availableObjects = cell;

                _availableCnt++;
                _usedCnt--;
            }
        } else {
            while(!_atomicInt.compareAndSet(0, 1));
            ListCell<T> cell = _usedCells;
            _usedCells = _usedCells._next;
            cell._obj = obj;
            cell._next = _availableObjects;
            _availableObjects = cell;

            _availableCnt++;
            _usedCnt--;
            _atomicInt.set(0);
        }
    }

    public void freeOneUsedCell() {
        if (_atomicInt == null) {
            synchronized (this) {
                ListCell<T> cell = _usedCells;
                _usedCells = _usedCells._next;
                cell._next = null;
//				cell._obj.resetPooled(); // let cell be collected

                _usedCnt--;
                _currentSize--;
            }
        } else {
            while(!_atomicInt.compareAndSet(0, 1));
            ListCell<T> cell = _usedCells;
            _usedCells = _usedCells._next;
            cell._next = null;
//				cell._obj.resetPooled(); // let cell be collected
            _currentSize--;

            _usedCnt--;
            _atomicInt.set(0);
        }
    }

    public String dump() {
        return this+"\n\t"+getAvailableObjects()+"\n\t"+getUsedCells();
    }
    private int[] _availableCntArr;
    private int[] _usedCntArr;
    private int _statsIx;
    public void initPoolStats(int statsSize) {
        _availableCntArr = new int[statsSize];
        _usedCntArr = new int[statsSize];
        _statsIx = statsSize;
    }
    public void recordPoolStats() {
        if (_statsIx>0) {
            _statsIx--;
            if (_atomicInt == null) {
                synchronized (this) {
                    _availableCntArr[_statsIx] = _availableCnt;
                    _usedCntArr[_statsIx] = _usedCnt;
                }
            } else {
                while(!_atomicInt.compareAndSet(0, 1));
                _availableCntArr[_statsIx] = _availableCnt;
                _usedCntArr[_statsIx] = _usedCnt;
                _atomicInt.set(0);
            }
        }
    }
    public String getPoolStats() {
        if (_atomicInt == null) {
            synchronized (this) {
                return this+" "+poolStats();
            }
        } else {
            String stats;
            while(!_atomicInt.compareAndSet(0, 1));
            stats = this+" "+poolStats();
            _atomicInt.set(0);
            return stats;
        }
    }
    private String poolStats() {
        String str = "";
        for (int i=_availableCntArr.length-1; i>=0; i--) {
            str += _availableCntArr[i] + "/" + _usedCntArr[i] + "/" + (_availableCntArr[i] + _usedCntArr[i]) + " ";
        }
        return "[ " + str + "]";
    }

    public String toString() {
        return _instantiator+" "+_initialSize+"/"+_incrementSize+" "+_currentSize+"c="+_availableCnt+"a+"+_usedCnt+"u";
    }


    private void init(MsgInstantiator instantiator, int initialSize, int incrementSize) {
        _initialSize = initialSize;
        _incrementSize = incrementSize;
        _instantiator = instantiator;
        if (_instantiator.allGood()) {
            augment(_initialSize);
        }
    }

    private void augment(int size) {
        for (int i=0; i<size; i++) {
            T obj = newInstance();
            int identityHashCode = obj.getIdentityHashCode();
            checkDups(identityHashCode, "augment");
            _availableObjects = new ListCell<>(obj, _availableObjects);

//			String info = "===> augment "+_instantiator.getObjType()+" "+identityHashCode;
//        	log.info(info);
//        	System.out.println(info);
        }
        _currentSize += size;

        _availableCnt += size;
    }

    private T newInstance() {
        T msg = _instantiator.newInstance();
        msg.setPooled(true);
        return msg;
    }

    private void checkDups(int identityHashCode, String ctx) {
        ListCell<T> currentEntry = _availableObjects;
        while (currentEntry!=null) {
            if (currentEntry._obj.getIdentityHashCode() == identityHashCode) {
                String info = "===> duplicate "+ctx+" "+_instantiator.getObjType()+" "+identityHashCode;
                log.warn(info);
                System.out.println(info);

//	        	try {Thread.sleep(500);} catch(Exception x) {}
//	        	System.exit(-1);
            }
            currentEntry = currentEntry._next;
        }
    }




    public static class ListCell<T extends IPoolable> {
        private T _obj;
        private ListCell<T> _next;

        public ListCell(T obj, ListCell<T> next) {
            _obj = obj;
            _next = next;
        }

        public T getObj() {
            return _obj;
        }
        public ListCell<T> getNext() {
            return _next;
        }

        public String toString() {
            String str = _obj.toString();
            ListCell<T> next = _next;
            while (next!=null) {
                str += ","+next._obj;
                next = next._next;
            }
            return "<"+str+">";
        }
    }
}
