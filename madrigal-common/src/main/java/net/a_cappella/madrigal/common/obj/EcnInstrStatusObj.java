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

package net.a_cappella.madrigal.common.obj;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.utils.Utils;
import net.a_cappella.madrigal.common.constants.MadrigalConstants;
import net.a_cappella.madrigal.common.constants.MadrigalInstrPhase;
import net.a_cappella.madrigal.common.constants.MadrigalInstrStatus;
import net.a_cappella.madrigal.common.constants.MadrigalOrderBook;
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.reflect.Constructor;
import java.util.Arrays;

public class EcnInstrStatusObj extends ObjImpl {
    private static final Logger log = LoggerFactory.getLogger(EcnInstrStatusObj.class);

	@Override
	public int getMsgType() { return MadrigalConstants.TYPE_ECN_INSTR_STATUS; }
    @Override
	public String getDefaultSubject() { return MadrigalConstants.SUBJ_ECN_INSTR_STATUS; }

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
    		Arrays.asList(
                    new FieldMetaInfo("ecn"),
                    new FieldMetaInfo("securityID"),
                    new FieldMetaInfo("book")
            ),
            Arrays.asList(
                    new FieldMetaInfo("status"),
                    new FieldMetaInfo("phase"),
                    new FieldMetaInfo("ts", FieldType.TIMESTAMP)
            ),
            64);
    @Override
    public ObjMetaInfo getObjMetaInfo() {
        return _staticMetaInfo;
    }

    private String _ecn;
	private long _ts;

    private String _securityID; // cusip
    private MadrigalOrderBook _book;
    private MadrigalInstrStatus _status;
    private MadrigalInstrPhase _phase;

	@Override // IPoolable
	public void reset() {
		super.reset();
		_ecn = null;
		_ts = 0;
		_securityID = null;
		_book = null;
		_status = null;
		_phase = null;
	}

	public void set(String ecn, long ts, String securityID, MadrigalOrderBook book, MadrigalInstrStatus status, MadrigalInstrPhase phase) {
        _ecn = ecn;
        _ts = ts;
		_securityID = securityID;
		_book = book;
		_status = status;
		_phase = phase;
	}

    public String getEcn() {
		return _ecn;
	}
	public void setEcn(String ecn) {
		_ecn = ecn;
	}
	public long getTs() {
		return _ts;
	}
	public void setTs(long ts) {
		_ts = ts;
	}
    public String getSecurityID() {
		return _securityID;
	}
	public void setSecurityID(String securityID) {
		_securityID = securityID;
	}
    public MadrigalOrderBook getBook() {
		return _book;
	}
	public void setBook(MadrigalOrderBook book) {
		_book = book;
	}
	public MadrigalInstrStatus getStatus() {
		return _status;
	}
	public void setStatus(MadrigalInstrStatus status) {
		_status = status;
	}

	public MadrigalInstrPhase getPhase() {
		return _phase;
	}
	public void setPhase(MadrigalInstrPhase phase) {
		_phase = phase;
	}



	@Override
	public String getString(String fieldName) throws Exception {
		if ("securityID".equalsIgnoreCase(fieldName)) return _securityID;
		if ("ecn".equalsIgnoreCase(fieldName)) return _ecn;
		return super.getString(fieldName); // throws exception
	}
	@Override
	public void setString(String fieldName, String value) throws Exception {
		if ("securityID".equalsIgnoreCase(fieldName)) _securityID = value;
		else if ("ecn".equalsIgnoreCase(fieldName)) _ecn = value;
		else super.setString(fieldName, value); // throws exception
	}

	@Override
	public long getTimestamp(String fieldName) throws Exception {
		if ("ts".equalsIgnoreCase(fieldName)) return _ts;
		return super.getTimestamp(fieldName); // throws exception
	}
	@Override
	public void setTimestamp(String fieldName, long value) throws Exception {
		if ("ts".equalsIgnoreCase(fieldName)) _ts = value;
		else super.setTimestamp(fieldName, value); // throws exception
	}

	@Override
	public Enum<?> getEnum(String fieldName) throws Exception {
		if ("book".equalsIgnoreCase(fieldName)) return _book;
		if ("status".equalsIgnoreCase(fieldName)) return _status;
		if ("phase".equalsIgnoreCase(fieldName)) return _phase;
		return super.getEnum(fieldName); // throws exception
	}
	public void setEnum(String fieldName, Enum<?> value) throws Exception {
		if ("book".equalsIgnoreCase(fieldName)) _book = (MadrigalOrderBook) value;
		else if ("status".equalsIgnoreCase(fieldName)) _status = (MadrigalInstrStatus) value;
		else if ("phase".equalsIgnoreCase(fieldName)) _phase = (MadrigalInstrPhase) value;
		else super.setEnum(fieldName, value); // throws exception
	}

	public String toString() {
		return ((log.isDebugEnabled())?(super.toString()+" "):"")+"{"+_ecn+" "+_securityID+" "+_book+" "+_status+" "+_phase+" "+Utils.formatMillis(_ts)+"}";
	}
}
