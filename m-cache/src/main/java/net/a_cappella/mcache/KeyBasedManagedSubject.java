package net.a_cappella.mcache;

public class KeyBasedManagedSubject extends ManagedSubject {
    public KeyBasedManagedSubject(String sql) throws Exception {
    	super(sql);
    }

    public void initializeAndMaintainSubjectCache() throws Exception {
    	_objCache = new KeyBasedObjCache();
        _client.snapSubscribe(_sql, this);
    }

}
