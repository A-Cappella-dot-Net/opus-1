/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package net.a_cappella.presto.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.PrestoConstants;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class SeqNoObj extends ObjImpl {

    @Override
    public int getMsgType() { return PrestoConstants.TYPE_SEQ_NO; }
    @Override
    public String getDefaultSubject() { return PrestoConstants.SUBJ_SEQ_NO; }

    @Override
    public void setStaticFields(Constructor<? extends Coder> codCtor, ObjPriority priority) throws Exception {
        _codCtor = codCtor;
        _priority = priority;
        _staticMetaInfo.updateMetaInfoFromInstance(this);
    }

    private static Constructor<? extends Coder> _codCtor;
    @Override
    public Constructor<? extends Coder> getCoderConstructor() {
        return _codCtor;
    }

    private static ObjPriority _priority;
    @Override
    public ObjPriority getPriority() {
        return _priority;
    }

    private static final ObjMetaInfo _staticMetaInfo = new ObjMetaInfo(
            Arrays.asList(),
            Arrays.asList(
//           		new FieldMetaInfo("seqNo")
            ));
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

//    private long _seqNo;

    public SeqNoObj() {}

    public SeqNoObj(SeqNoObj obj) {
        super(obj);
//		_seqNo = obj._seqNo;
    }

    public SeqNoObj set(long seqNo) {
//		_seqNo = seqNo;
        super.setSeqNo(seqNo);
        return this;
    }

    @Override // IPoolable
    public void reset() {
        super.reset();
//		_seqNo = 0L;
    }

//    public long getSeqNo() {
//		return _seqNo;
//	}
//	public void setSeqNo(long seqNo) {
//		_seqNo = seqNo;
//	}

//	public String toString() {
//		return super.toString()+" {"+_seqNo+"} ";
//	}

//	@Override
//	public long getLong(String fieldName) throws Exception {
//		if ("seqNo".equalsIgnoreCase(fieldName)) return _seqNo;
//		return super.getLong(fieldName); // throws exception
//	}

//	@Override
//	public void setLong(String fieldName, long value) throws Exception {
//		if ("seqNo".equalsIgnoreCase(fieldName)) _seqNo = value;
//		else super.setLong(fieldName, value); // throws exception
//	}
}
