package net.a_cappella.presto.ft.upgrade;

import net.a_cappella.presto.msg.VersionedStringMsg;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class VersionedParamsCache {
    private static final Logger log = LoggerFactory.getLogger(VersionedParamsCache.class);

    private static final String COMMENT_PREFIX = "#";
    private static final String UPGRADED_PROPERTIES_LIST = "upgraded.properties";
    private static final String VERSION_SUFFIX = ".version";

    private final String _filePathName;
    public Map<String, VersionedStringMsg> _map;

    public VersionedParamsCache(String filePathName) {
        log.info("Current dir is "+new File(".").getAbsolutePath());
        _filePathName = filePathName;
        _map = new HashMap<>();
    }

    public void start() {
        File fin = new File(_filePathName);
        if (fin.exists() && !fin.isDirectory()) {
            BufferedReader in = null;
            try {
                FileInputStream fis = new FileInputStream(fin);
                in = new BufferedReader(new InputStreamReader(fis));
                String line;
                while ((line = in.readLine()) != null) {
                    if (line.trim().isEmpty() || line.startsWith(COMMENT_PREFIX)) {
                        // ignore empty lines and comments
                    } else if (line.startsWith(UPGRADED_PROPERTIES_LIST)) {
                        int pos = line.indexOf('=');
                        String upgradedPropertiesList = line.substring(pos+1).trim();
                        String[] upgradedProperties = upgradedPropertiesList.split(",");
                        for (String upgradedProperty : upgradedProperties) {
                            _map.put(upgradedProperty, new VersionedStringMsg(upgradedProperty));
                        }
                    } else {
                        int pos = line.indexOf('=');
                        String key = line.substring(0, pos).trim();
                        String value = line.substring(pos+1).trim();
                        if (key.endsWith(VERSION_SUFFIX)) {
                            key = key.substring(0, key.lastIndexOf(VERSION_SUFFIX));
                            VersionedStringMsg vsm = _map.get(key);
                            if (vsm==null) {
                                log.error(key+" not in "+UPGRADED_PROPERTIES_LIST+". Ignoring...");
                            } else {
                                vsm._version = Integer.parseInt(value);
                            }
                        } else {
                            VersionedStringMsg vsm = _map.get(key);
                            if (vsm==null) {
                                log.error(key+" not in "+UPGRADED_PROPERTIES_LIST+". Ignoring...");
                            } else {
                                vsm._string = value;
                            }
                        }
                    }
                }
                log.info(_filePathName+" contains "+_map);
            } catch (IOException x) {
                log.error(_filePathName, x);
            } finally {
                try {
                    if (in!=null) in.close();
                } catch (IOException x) {
                    log.error(_filePathName, x);
                }
            }

        } else {
            log.info("File "+_filePathName+" does not exist...");
        }
    }

    public void add(VersionedStringMsg vsm) {
        _map.put(vsm._name, vsm);

        try {
            BufferedWriter out = new BufferedWriter(new FileWriter(_filePathName));
            out.write(COMMENT_PREFIX+" File: "+_filePathName+" was machine generated on "+new Date()+". Do not modify."); out.newLine();
            out.write(COMMENT_PREFIX); out.newLine();
            out.write(UPGRADED_PROPERTIES_LIST+"="+getUpgradedPropertiesNamesAsList()); out.newLine();
            out.write(COMMENT_PREFIX); out.newLine();

            for (Map.Entry<String, VersionedStringMsg> entry : _map.entrySet()) {
                entry.getValue().format(out);
                out.write(COMMENT_PREFIX); out.newLine();
            }
            out.close();
        } catch (IOException x) {
            log.error(_filePathName, x);
        }
    }
    private String getUpgradedPropertiesNamesAsList() {
        String list = null;
        for (Map.Entry<String, VersionedStringMsg> entry : _map.entrySet()) {
            if (list==null) {
                list = entry.getKey();
            } else {
                list += ","+entry.getKey();
            }
        }
        return list;
    }
}
