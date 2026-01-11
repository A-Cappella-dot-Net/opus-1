package net.a_cappella.continuo.managed;

import java.lang.reflect.Constructor;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Consumer;

import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import gnu.trove.map.TIntObjectMap;
import gnu.trove.map.hash.TIntObjectHashMap;
import gnu.trove.set.TIntSet;
import gnu.trove.set.hash.TIntHashSet;

public class ObjectManager {
    private static final Logger log = LoggerFactory.getLogger(ObjectManager.class);

    private final Map<Class<?>, Pool<?>> _poolsByClass = new HashMap<>();
    private final Map<Class<?>, MsgInstantiator> _instantiatorsByClass = new HashMap<>();
    private final Set<Class<?>> _reportedBadClasses = new HashSet<>();

    private final TIntObjectMap<Pool<?>> _poolsByObjType = new TIntObjectHashMap<>();
    public final TIntObjectMap<MsgInstantiator> _instantiatorsByObjType = new TIntObjectHashMap<>();
    private final TIntSet _reportedBadTypes = new TIntHashSet();

    private final Map<String, ObjMetaInfo> _metaInfoBySubject = new HashMap<>();
    private final TIntObjectMap<Constructor<? extends Coder>> _codConstructorsByObjType = new TIntObjectHashMap<>();



    private static ObjectManager _instance = new ObjectManager();
    public static ObjectManager getInstance() {
        return _instance;
    }

    public void setMsgInstantiators(List<MsgInstantiator> instantiatorsList) {
        log.info("setMsgInstantiators "+instantiatorsList);
        Set<String> subjectsSet = new HashSet<>();
        if (!instantiatorsList.isEmpty()) {
            for (int i=0; i<instantiatorsList.size(); i++) {
                MsgInstantiator instantiator = instantiatorsList.get(i);
                int objType = instantiator.getObjType();
                Class<?> clazz = instantiator.getMsgClass();
                if (instantiator.allGood()) {
                    MsgInstantiator instByObjType = _instantiatorsByObjType.get(objType);
                    MsgInstantiator instByClass = _instantiatorsByClass.get(clazz);
                    if (instByObjType != instByClass) {
                        String err = "Instantiators map already contains key "+objType+" and/or "+clazz+" for "+instantiator;
                        log.error(err);
                        System.out.println(err);
                        try {Thread.sleep(100);} catch (InterruptedException x) {}
                        System.exit(-1);
                    } else {
                        _instantiatorsByObjType.put(objType, instantiator);
                        _instantiatorsByClass.put(clazz, instantiator);
                        Object msg = instantiator.newInstance();
                        if (msg instanceof Obj) {
                            Obj obj = (Obj) msg;
                            String subject = obj.getSubject();
                            verifySubjects(subject, subjectsSet);
                            ObjMetaInfo metaInfo = obj.getObjMetaInfo();
                            if (subject != null && metaInfo != null) {
                                _metaInfoBySubject.put(subject, metaInfo);
                            }
                            Constructor<? extends Coder> objCoderConstructor = obj.getCoderConstructor();
                            if (objCoderConstructor==null) {
                                String err = "No coder constructor defined for Obj type "+objType+" and/or "+clazz+". Such objects will not be instantiable.";
                                log.error(err);
                            } else {
                                _codConstructorsByObjType.put(objType, obj.getCoderConstructor());
                            }
                        }
                    }
                }
            }
            log.info("metaInfoBySubject = "+_metaInfoBySubject);
            log.info("subjects = "+subjectsSet);
            log.info("instantiatorsByObjType = "+_instantiatorsByObjType.keySet());
        }
    }
    private void verifySubjects(String subject, Set<String> subjectsSet) {
        boolean added = subjectsSet.add(subject);
        if (!added) {
            String err = "Subject already defined "+subject;
            log.error(err);
            System.out.println(err);
            try {Thread.sleep(100);} catch (InterruptedException x) {}
            System.exit(-1);
        }
    }

    public void setMsgPools(List<Pool<?>> poolsList) {
        log.info("setMsgPools "+poolsList);
        if (!poolsList.isEmpty()) {
            for (int i=0; i<poolsList.size(); i++) {
                Pool<?> pool = poolsList.get(i);
                int objType = pool.getInstantiator().getObjType();
                Class<?> clazz = pool.getInstantiator().getMsgClass();
                if (_poolsByObjType.containsKey(objType) || _poolsByClass.containsKey(clazz)) {
                    log.warn("Pools map aready contains key "+objType+" and/or "+clazz.getCanonicalName()+". Ignoring "+pool);
                } else {
                    _poolsByObjType.put(objType, pool);
                    _poolsByClass.put(clazz, pool);
                }
            }
            log.info("poolsByObjType = "+_poolsByObjType.keySet());
        }
    }

    public void dumpPoolStats() {
        int[] keys = _poolsByObjType.keys();
        for (int i=0; i<keys.length; i++) {
            int key = keys[i];
            Pool<?> pool = _poolsByObjType.get(key);
            if (key>=100) log.info("=> "+pool);
        }
    }

    public void verifyPoolSize(int objType, int expectedCurrentSize) {
        Pool<?> pool = _poolsByObjType.get(objType);
        if (pool.getCurrentSize()!=expectedCurrentSize) {
            log.info("!!! expectedCurrentSize!=actualCurrentSize => "+pool);
        }
    }

    public <T extends IPoolable> T acquire(int objType) {
        T msg = null;

        Pool<T> pool = (Pool<T>) _poolsByObjType.get(objType);
        if (pool == null) {
            MsgInstantiator msgInstantiator = _instantiatorsByObjType.get(objType);
            if (msgInstantiator != null) {
                msg = msgInstantiator.newInstance();
            }
        } else {
            msg = pool.acquire();
        }

        if (msg == null) {
            if (!_reportedBadTypes.contains(objType)) {
                _reportedBadTypes.add(objType);
                log.error("Error instantiating type "+objType+". Skipping this and all future messages of this type...");
            }
        }
        return msg;
    }

    public <T extends IPoolable> T acquire(Class<T> clazz) {
        T poolable = null;

        Pool<T> pool = (Pool<T>) _poolsByClass.get(clazz);
        if (pool == null) {
            MsgInstantiator msgInstantiator = _instantiatorsByClass.get(clazz);
            if (msgInstantiator != null) {
                poolable = msgInstantiator.newInstance();
            }
        } else {
            poolable = pool.acquire();
        }

        if (poolable == null) {
            if (!_reportedBadClasses.contains(clazz)) {
                _reportedBadClasses.add(clazz);
                log.error("Error instantiating type "+clazz+". Skipping this and all future messages of this type...");
            }
        }
        return poolable;
    }

    public <T extends IPoolable> void release(T obj) {
        Class<T> clazz = (Class<T>) obj.getClass();
        Pool<T> pool = (Pool<T>) _poolsByClass.get(clazz);
        if (pool!=null) pool.release(obj);
    }

    public void forEachPool(Consumer<Pool<?>> consumer) {
        for (int i = 0; i < _poolsByObjType.size(); i++) {
            Pool<?> pool = _poolsByObjType.get(i);
            consumer.accept(pool);
        }
    }

    public ObjMetaInfo getSubjectMetaInfo(String subject) {
        return _metaInfoBySubject.get(subject);
    }

    public Constructor<? extends Coder> getCoderConstructor(int objType) {
        return _codConstructorsByObjType.get(objType);
    }

    public String toString() {
        return
            "poolsByObjType="+_poolsByObjType+"\n"+
            "poolsByClass="+_poolsByClass+"\n"+
            "instantiatorsByObjType="+_instantiatorsByObjType+"\n"+
            "instantiatorsByClass="+_instantiatorsByClass+"\n";
    }
}
