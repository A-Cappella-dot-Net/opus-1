package net.a_cappella.madrigal.common.beans;

public class EcnCredentials {
    private final String _uid;
    private final String _ecn;
    private final String _ecnUid;
    private final String _ecnPwd;
    private final String _acct; // only for CME

    public EcnCredentials(String uid, String ecn, String ecnUid, String ecnPwd, String acct) {
        _uid = uid;
        _ecn = ecn;
        _ecnUid = ecnUid;
        _ecnPwd = ecnPwd;
        _acct = acct;
    }

    public String getUid() {
        return _uid;
    }
    public String getEcn() {
        return _ecn;
    }
    public String getEcnUid() {
        return _ecnUid;
    }
    public String getEcnPwd() {
        return _ecnPwd;
    }
    public String getAcct() {
        return _acct;
    }
}
