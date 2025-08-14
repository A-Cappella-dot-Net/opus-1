package net.a_cappella.presto.ps.sql;

import net.a_cappella.continuo.managed.MsgInstantiator;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.managed.Pool;
import net.a_cappella.continuo.msg.Msg;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.presto.obj.TestObj;
import org.HdrHistogram.Histogram;
import org.junit.jupiter.api.Test;

import java.util.Arrays;
import java.util.concurrent.TimeUnit;

public class WhereNodePerf {

    static {
        try {
            MsgInstantiator testInstantiator = new MsgInstantiator(TestObj.class.getName());

            ObjectManager _objectManager = ObjectManager.getInstance();
            _objectManager.setMsgInstantiators(Arrays.asList(testInstantiator));
            _objectManager.setMsgPools(Arrays.asList(new Pool<Msg>(testInstantiator, 10, 10)));

        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    private final Histogram _h = new Histogram(TimeUnit.MILLISECONDS.toNanos(200), 3);

    private final char[] _chars = new char[] {'a', 'b', 'c', 'd'};

    @Test
    public void testParseEval1() throws Exception {
        Obj obj = new TestObj();
        String sql = "select * from test where aChar='c'";
        SqlParserResult res = SqlParser.parseSql(sql);
        String subject = res.getFromTable();
        res.getEvalTree().updateEvalSupportingFields(subject, ObjectManager.getInstance().getSubjectMetaInfo(subject));

        for (int i = 0; i< 1_000_000; i++) { // wup
            obj.setChar("aChar", _chars[i % 4]);
            res.getEvalTree().satisfiesWhereClause(obj);
        }

        for (int i = 0; i< 1_000_000; i++) {
            obj.setChar("aChar", _chars[i % 4]);
            long start = System.nanoTime();
            res.getEvalTree().satisfiesWhereClause(obj);
            _h.recordValue(System.nanoTime() - start);
        }

        long cnt = _h.getTotalCount();
        long min = (cnt==0) ? 0 : _h.getMinValue();
        long at50 = (cnt==0) ? 0 : _h.getValueAtPercentile(50);
        long at90 = (cnt==0) ? 0 : _h.getValueAtPercentile(90);
        long at99 = (cnt==0) ? 0 : _h.getValueAtPercentile(99);
        long at99_9 = (cnt==0) ? 0 : _h.getValueAtPercentile(99.9);
        long max = (cnt==0) ? 0 : _h.getMaxValue();

        System.out.println(String.format("tot=%d min=%d 50%%=%d 90%%=%d 99%%=%d 99.9%%=%d max=%d", cnt, min, at50, at90, at99, at99_9, max));
    }

}
