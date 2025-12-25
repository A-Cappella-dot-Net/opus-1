package net.a_cappella.presto.ps;

import gnu.trove.impl.hash.THash;
import gnu.trove.map.TIntObjectMap;
import gnu.trove.map.hash.TIntObjectHashMap;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.PubType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.presto.obj.AeronCoderImpl;
import net.a_cappella.presto.obj.MapObj;
import org.agrona.DirectBuffer;
import org.agrona.sbe.MessageDecoderFlyweight;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import sbe.generated.CombinedSbePrestoHeaderDecoder;

import static net.a_cappella.continuo.PrestoConstants.TYPE_MAP;

public class AeronObjCoder {
    private static final Logger log = LoggerFactory.getLogger(AeronObjCoder.class);

    private static final CombinedSbePrestoHeaderDecoder HEADER_DECODER = new CombinedSbePrestoHeaderDecoder();

    private final SharedAeronCoders _readSharedCoders = new SharedAeronCoders();
    private static final ThreadLocal<SharedAeronCoders> _threadLocalWriteSharedCoders = ThreadLocal.withInitial(SharedAeronCoders::new);

    private final TIntObjectMap<Obj> _reusableObjsByMsgType = new TIntObjectHashMap<>();

    private final String _myClientId;

    public AeronObjCoder(String myClientId) {
        _myClientId = myClientId;
        // this map is relatively small and does not need to be shrunk and rehashed.
        // rehashing (THashMap.rehash) produces garbage which needs to be collected.
        // setting the auto compaction factor to 0 marks this map as non shrinkable.
        ((THash) _reusableObjsByMsgType).setAutoCompactionFactor(0);
    }

    public SharedAeronCoders encode(Obj obj) {
        SharedAeronCoders sharedCoders = _threadLocalWriteSharedCoders.get();
        AeronCoder cod = (AeronCoder) sharedCoders.getCoder(obj.getMsgType());
        cod.setObj(obj);
        int len = cod.encodeObj(sharedCoders.getBuffer(), 0);
        sharedCoders.setLen(len);
        cod.setObj(null);
        return sharedCoders;
    }

    public Obj acquireObj(AeronCoder cod) {
        int objType = cod.getObjType();
        String subject = cod.getSubject();
        boolean backPressured = cod.isBackPressured();
        boolean onLoopback = cod.isOnLoopback();
        PubType pubType = cod.getPubType();
        long requestId = cod.getRequestId();
        String originClient = cod.getOriginClient();
        short mine = cod.getMine();
        long tsNanos = cod.getTsNanos();
        long serialId = cod.getSerialId();
        long seqNo = cod.getSeqNo();

        Obj obj = _reusableObjsByMsgType.remove(objType);
        if (obj != null) {
            obj.reset(); // re-using...
        } else {
            obj = ObjectManager.getInstance().acquire(objType);
            if (obj == null) return null;
        }

        obj.setSubject(subject);
        obj.setBackPressured(backPressured);
        obj.setOnLoopback(onLoopback);
        obj.setPubType(pubType);
        obj.setRequestId(requestId);
        obj.getRtg().setOriginClient(originClient);
        obj.setMine(mine);
        obj.setTsNanos(tsNanos);
        obj.setSerialId(serialId);
        obj.setSeqNo(seqNo);
        cod.setObj(obj);

        if (objType == TYPE_MAP) {
            ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
            obj.setObjMetaInfo(metaInfo);
        }

        return obj;
    }

    public void reUseObj(Obj obj) {
        _reusableObjsByMsgType.put(obj.getMsgType(), obj);
    }

    public AeronCoder decodeHeader(DirectBuffer directBuffer, int offset, int length, int stream) {
        HEADER_DECODER.wrap(directBuffer, offset);

        final int blockLength = HEADER_DECODER.blockLength();
        final int version = HEADER_DECODER.version();
        final int objType = HEADER_DECODER.templateId();
        if (log.isDebugEnabled()) log.debug("decode stream={} objType={} offset={}, length={}, blockLength={}", stream, objType, offset, length, blockLength);

        AeronCoderImpl<?> cod = (AeronCoderImpl<?>) _readSharedCoders.getCoder(objType);
        cod.setObjType(objType);

        cod.decodeHeader(HEADER_DECODER); // decode the Presto header

        String subject = cod.getSubject();
        PubType pubType = cod.getPubType();
        long requestId = cod.getRequestId();
        String originClient = cod.getOriginClient();
        short mine = cod.getMine();
        long tsNanos = cod.getTsNanos();
        long serialId = cod.getSerialId();
        long seqNo = cod.getSeqNo();

        if (pubType==PubType.UNK) {
            log.error("Unknown pubType " + pubType);
            log.info("read header {}:{} {} [{} {}] ({} {}) {} {}", objType, subject, pubType, requestId, originClient, mine, tsNanos, serialId, seqNo);
            log.error(net.a_cappella.presto.ps.Utils.hexDump(directBuffer, offset, length));
            return null;
        } else {
            if (log.isDebugEnabled())
                log.debug("read header {}:{} {} [{} {}] ({} {}) {} {}", objType, subject, pubType, requestId, originClient, mine, tsNanos, serialId, seqNo);
        }

        if (pubType==PubType.SNP_BEGIN || pubType==PubType.SNP_END || pubType==PubType.SNP_MSG || pubType==PubType.SNP_HWM) {
            // is this RPL not for this client?
            if (!_myClientId.equals(originClient)) {
                log.debug("Not my RPL message {} {}", originClient, _myClientId);
                return null;
            }
        }

        // prepare to decode the remaining fields
        offset += HEADER_DECODER.encodedLength();
        MessageDecoderFlyweight decoder = cod.getDecoder();
        if (log.isDebugEnabled()) log.debug("{} sbeBlockLength={} (size of all the fixed length fields)", decoder.getClass().getName(), decoder.sbeBlockLength());
        decoder.wrap(directBuffer, offset, decoder.sbeBlockLength(), version);

        return cod;
    }

}
