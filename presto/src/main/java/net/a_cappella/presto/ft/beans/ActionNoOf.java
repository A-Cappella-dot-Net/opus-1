package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.ft.constants.FtMsgOp;

public class ActionNoOf {
    public FtMsgOp _op;
    public int _sliceNo;
    public int _ofSlices;

    public ActionNoOf(FtMsgOp op, int sliceNo, int ofSlices) {
        _op = op;
        _sliceNo = sliceNo;
        _ofSlices = ofSlices;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + _ofSlices;
        result = prime * result + ((_op == null) ? 0 : _op.hashCode());
        result = prime * result + _sliceNo;
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;
        if (obj == null) return false;
        if (getClass() != obj.getClass()) return false;
        ActionNoOf other = (ActionNoOf) obj;
        if (_ofSlices != other._ofSlices) return false;
        if (_op != other._op) return false;
        if (_sliceNo != other._sliceNo) return false;
        return true;
    }

    @Override
    public String toString() {
        return "{"+_op+" "+_sliceNo+"/"+_ofSlices+"}";
    }

}
