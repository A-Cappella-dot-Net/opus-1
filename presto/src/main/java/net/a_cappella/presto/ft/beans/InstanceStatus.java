package net.a_cappella.presto.ft.beans;

import net.a_cappella.presto.ft.constants.FtStatus;

import static net.a_cappella.presto.ft.constants.FtStatus.UNINITIALIZED;

public class InstanceStatus {
    private final int _instance;
    private FtStatus _ftStatus = UNINITIALIZED;
    private int _sliceNo;
    private int _ofSlices;

    public InstanceStatus(int instance) {
        _instance = instance;
    }

    public int getInstance() {
        return _instance;
    }

    public void set(FtStatus ftStatus, int sliceNo, int ofSlices) {
        _ftStatus = ftStatus;
        _sliceNo = sliceNo;
        _ofSlices = ofSlices;
    }
    public boolean already(FtStatus ftStatus, int sliceNo, int ofSlices) {
        return _ftStatus == ftStatus && _sliceNo == sliceNo && _ofSlices == ofSlices;
    }
    public FtStatus getStatus() {
        return _ftStatus;
    }

    public String toString() {
        return String.format("{%s %s %d/%d}", _ftStatus, _instance, _sliceNo, _ofSlices);
    }
}
