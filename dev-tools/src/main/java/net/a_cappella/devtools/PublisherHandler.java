package net.a_cappella.devtools;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PNanos;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.datatypes.PTimestamp;
import net.a_cappella.continuo.managed.ObjectManager;
import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.presto.obj.MapObj;
import net.a_cappella.presto.ps.PrestoClient;
import org.apache.commons.text.StringEscapeUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class PublisherHandler {
    private static final Logger log = LoggerFactory.getLogger(PublisherHandler.class);

    public static String NL = "\n";

    public final PrestoClient _client;

    private final SessionHandler sessionHandler;
    private final String remote;

    public PublisherHandler(SessionHandler sessionHandler, PrestoClient client) {
        this.sessionHandler = sessionHandler;
        this.remote = sessionHandler._remote;
        this._client = client;
    }

    public void resetTabs() {

    }

    public void handleAuthenticatedMessage(JsonObject msg) {
        String type = msg.get("type").getAsString();
        switch (type) {
            case "init_publisher_tab":
                handleInitPublisherTab(msg);
                break;
            case "request_template":
                handleRequestTemplate(msg);
                break;
            case "publish":
                handlePublish(msg);
                break;
            case "publish_all":
                handlePublishAll(msg);
                break;

            default:
                log.error("{} Unknown message type: {}", remote, type);
        }
    }

    private void handleInitPublisherTab(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();
        sendTabLabel(tabId, "Publisher " + tabId);
    }

    private void handleRequestTemplate(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();
        String subject = msg.get("subject").getAsString();
        sendTabLabel(tabId, subject);
        sendTemplate(tabId, generateTemplate(tabId, subject));
    }

    private void handlePublish(JsonObject msg) {
        String tabId = msg.get("tabId").getAsString();
        String subject = msg.get("subject").getAsString();
        sendTabLabel(tabId, subject);
        publish(subject, msg.get("message").getAsString(), tabId);
    }

    private void handlePublishAll(JsonObject msg) {
        JsonArray tabs = msg.getAsJsonArray("tabs");
        for (int i = 0; i < tabs.size(); i++) {
            JsonObject tab = tabs.get(i).getAsJsonObject();

            String tabId = tab.get("tabId").getAsString();
            String subject = msg.get("subject").getAsString();
            sendTabLabel(tabId, subject);
            publish(subject, tab.get("message").getAsString(), tabId);
        }
    }

    private void updateStatusBar(String tabId, String status) {
        JsonObject response = new JsonObject();
        response.addProperty("type", "update_status");
        response.addProperty("tabId", tabId);
        response.addProperty("mode", "publisher");
        response.addProperty("status", status);
        sessionHandler.sendMessage(response);
    }

    private void sendTabLabel(String tabId, String label) {
        JsonObject response = new JsonObject();
        response.addProperty("type", "update_tab_label");
        response.addProperty("tabId", tabId);
        response.addProperty("mode", "publisher");
        response.addProperty("label", label);
        sessionHandler.sendMessage(response);
    }

    private void sendTemplate(String tabId, String template) {
        JsonObject response = new JsonObject();
        response.addProperty("type", "template_response");
        response.addProperty("tabId", tabId);
        response.addProperty("mode", "publisher");
        response.addProperty("template", template);
        sessionHandler.sendMessage(response);
    }






    private void publish(String subject, String fieldsText, String tabId) {
        log.info("{} Publishing message:\n  Subject: {}\n  Message: {}\n  Tab: {}", remote, subject, fieldsText, tabId);
        String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
        try {
            Map<String, Object> fieldsMap = parseText(fieldsText, subject);
            if (subject==null || "".equals(subject)) {
                updateStatusBar(tabId, now+" Invalid subject '"+subject+"'");
            } else {
                ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);
                Obj obj;
                if (metaInfo == null) {
                    MapObj map = new MapObj();
                    map.setSubject(subject);
                    obj = map;
                } else {
                    obj = ObjectManager.getInstance().acquire(metaInfo.getObjType());
                }
                obj.set(fieldsMap);
                _client.publish(obj);
                updateStatusBar(tabId, now+" Published successfully on '"+subject+"'");
            }
        } catch (Exception e) {
            log.error("", e);
            updateStatusBar(tabId, now+" Publication on '"+subject+"' failed. "+e.getMessage());
        }
    }

    private Map<String, Object> parseText(String fieldsText, String subject) throws Exception {
        if (fieldsText==null || "".equals(fieldsText)) return null;

        ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);

        Map<String, Object> map = new HashMap<>();
        String[] entries = fieldsText.split(NL);
        for (int i=0; i<entries.length; i++) {
            String entry = entries[i];
            int pos = entry.indexOf('=');
            if (pos>0) {
                String key = entry.substring(0, pos).trim();
                String rawValue = entry.substring(pos+1).trim();
                Object value = covertToProperType(rawValue, (metaInfo==null) ? null : metaInfo.getFieldMetaInfo(key));
                map.put(key, value);
            }
        }
        return map;
    }

    private Object covertToProperType(String str, FieldMetaInfo fmi) throws Exception {
        if (fmi!=null) {
            switch (fmi.getType()) {
                case CHAR:
                    str = (str.startsWith("\'") && str.endsWith("\'")) ? StringEscapeUtils.unescapeJava(str.substring(1, str.length()-1)) : str;
                    return str.charAt(0);
                case STRING: return (str.startsWith("\"") && str.endsWith("\"")) ? str.substring(1, str.length()-1) : str;
                case SHORT: return Short.parseShort(str);
                case INT: return Integer.parseInt(str);
                case LONG: return Long.parseLong(str);
                case FLOAT: return parseFloat(str);
                case DOUBLE: return parseDouble(str);
                case BOOLEAN: return Boolean.parseBoolean(str);
                case TIMESTAMP: return PTimestamp.parsePTimestamp(str);
                case NANOS: return PNanos.parsePNanos(str);
                case TIME: return PTime.parsePTime(str);
                case DATE: return PDate.parsePDate(str);
                case ENUM: return parseEnum(str);
                default: return "Unknown Type";
            }
        }
        // ad hoc fields
        if ("now".equals(str)) {
            return PTimestamp.parsePTimestamp(str);
        }
        if (str.startsWith("\'") && str.endsWith("\'")) {
            return StringEscapeUtils.unescapeJava(str.substring(1, str.length()-1)).charAt(0);
        }
        if (str.startsWith("\"") && str.endsWith("\"")) {
            str = str.substring(1, str.length()-1);
        }
        try {
            return Long.parseLong(str);
        } catch(NumberFormatException ignore) {}
        try {
            return Double.parseDouble(str);
        } catch(NumberFormatException ignore) {}
        try {
            return new PTimestamp(str);
        } catch (ParseException ignore) {}
        try {
            return new PDate(str);
        } catch (ParseException ignore) {}
        try {
            return new PTime(str);
        } catch (ParseException ignore) {}
        if ("true".equalsIgnoreCase(str)) {
            Boolean.parseBoolean(str);
            return Boolean.TRUE;
        } else if ("false".equalsIgnoreCase(str)) {
            return Boolean.FALSE;
        }
        return str;
    }

    private double parseDouble(String str) {
        if (str == null) return Double.NaN;
        try {
            return Double.parseDouble(str);
        } catch (NumberFormatException x) {
            if ("Inf".equalsIgnoreCase(str)) return Double.POSITIVE_INFINITY;
            if ("-Inf".equalsIgnoreCase(str)) return Double.NEGATIVE_INFINITY;
            return Double.NaN;
        }
    }

    private float parseFloat(String str) {
        if (str == null) return Float.NaN;
        try {
            return Float.parseFloat(str);
        } catch (NumberFormatException x) {
            if ("Inf".equalsIgnoreCase(str)) return Float.POSITIVE_INFINITY;
            if ("-Inf".equalsIgnoreCase(str)) return Float.NEGATIVE_INFINITY;
            return Float.NaN;
        }
    }

    private <T extends Enum<T>> T parseEnum(String str) throws Exception {
        int pos = str.lastIndexOf(".");
        String enumClass = str.substring(0, pos);
        String enumValue = str.substring(pos+1);
        Class<T> clazz = (Class<T>) Class.forName(enumClass);
        return Enum.valueOf(clazz, enumValue);
    }



















    private String generateTemplate(String tabId, String subject) {
        String now = new SimpleDateFormat("[hh:mm:ss.SSS]").format(new Date());
        ObjMetaInfo metaInfo = ObjectManager.getInstance().getSubjectMetaInfo(subject);

        String template;
        if (metaInfo == null) {
            template = "----- " + now + " Unknown subject '" + subject + "' -----\n";
        } else {
            template = "----- keys -----\n";
            for (FieldMetaInfo fmi : metaInfo.getKeys()) {
                template += fieldTemplate(fmi);
            }
            template += "----- non keys -----\n";
            for (FieldMetaInfo fmi : metaInfo.getNonKeys()) {
                template += fieldTemplate(fmi);
            }
        }
        template += "----- ad hocs -----\n";
        updateStatusBar(tabId, now+" Template for '"+subject+"'");
        return template;
    }

    private String fieldTemplate(FieldMetaInfo fieldMetaInfo) {
        return fieldMetaInfo.getName()+" = "+typedValue(fieldMetaInfo)+"\n";
    }

    private String typedValue(FieldMetaInfo fieldMetaInfo) {
        FieldType fieldType = fieldMetaInfo.getType();

        switch (fieldType) {
            case CHAR: return "' '";
            case STRING: return "";
            case SHORT:
            case INT:
            case LONG: return "0";
            case FLOAT:
            case DOUBLE: return "0.0";
            case BOOLEAN: return "false";
            case TIMESTAMP:
            case NANOS:
            case TIME:
            case DATE: return "now";
            case ENUM: {
                String className = fieldMetaInfo.getField().getGenericType().getTypeName();
                String enumValue = "";
                try {
                    enumValue = Class.forName(className).getEnumConstants()[0].toString();
                } catch (Exception x) {}
                return className+"."+enumValue;
            }
            default: return "Unknown Type";
        }
    }
}
