package net.a_cappella.cembalo.generator;

import java.io.IOException;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import net.a_cappella.continuo.utils.Utils;
import org.agrona.generation.OutputManager;
import org.agrona.generation.PackageOutputManager;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.support.ClassPathXmlApplicationContext;

import gnu.trove.map.TCharObjectMap;
import gnu.trove.map.TIntObjectMap;
import gnu.trove.map.TLongObjectMap;
import gnu.trove.map.hash.TIntObjectHashMap;

public class Dictionary {
    private static final Logger log = LoggerFactory.getLogger(Dictionary.class);

    private static final String COMMENT_PREFIX = "//";

    public TIntObjectMap<FieldDef> _fieldsByTag = new TIntObjectHashMap<>();
    public Map<String, FieldDef> _fieldsByName = new HashMap<>();
    private final Map<String, List<FieldDef>> _blocksByName = new HashMap<>();
    public List<FieldDef> _groupsList = new ArrayList<>();
    public Map<String, MsgDef> _messagessByType = new HashMap<>();
    public Map<String, MsgDef> _messagessByName = new HashMap<>();

    private boolean _orderIdTagTypeOverride = false;
    public void setOrderIdTagTypeOverride(boolean orderIdTagTypeOverride) {
        _orderIdTagTypeOverride = orderIdTagTypeOverride;
    }
    public boolean isOrderIdTagTypeOverride() {
        return _orderIdTagTypeOverride;
    }

    public Dictionary() {}

    public Dictionary(List<String> fields, List<String> blocks, List<String> groups, List<String> messages) {
        for (String field : fields) {
            FieldDef fieldDef = null;
            String[] comps = field.split("\\|");
            char type = comps[1].charAt(0);
            switch (type) {
                case 'S':
                case 's':
                    fieldDef = new StringFieldDef(comps);
                    break;
                case 'C':
                    fieldDef = new CharFieldDef(comps);
                    break;
                case 'I':
                    fieldDef = new IntFieldDef(comps);
                    break;
                case 'F':
                    fieldDef = new FloatFieldDef(comps);
                    break;
                case 'T':
                    fieldDef = new TimeFieldDef(comps);
                    break;
                case 'D':
                    fieldDef = new DateFieldDef(comps);
                    break;
                default:
                    break;
            }
            if (fieldDef==null) {
                log.error("Could not parse "+field);
            } else {
                _fieldsByTag.put(fieldDef._tag, fieldDef);
                _fieldsByName.put(fieldDef._name, fieldDef);
            }
        }
//		log.info("{}", fields);
//		log.info("{}", Arrays.toString(_fieldsByTag.values()));

        for (String block : blocks) {
            String[] comps = block.split("\\|");
            String name = comps[0];
            String[] tags = comps[1].split(",");
            List<FieldDef> list = new ArrayList<>();
            for (String str : tags) {
                int tag = Integer.parseInt(str);
                FieldDef fieldDef = _fieldsByTag.get(tag);
                if (fieldDef==null) {
                    log.error("Undefined tag "+tag+" in block "+block+". Skipping...");
                } else {
                    list.add(fieldDef);
                }
            }
            _blocksByName.put(name, list);
        }
//		log.info("{}", blocks);
//		log.info("{}", _blocksByName);

        for (String group : groups) {
            String[] comps = group.split("\\|");
            int groupTag = Integer.parseInt(comps[0]);
            FieldDef groupFieldDef = _fieldsByTag.get(groupTag);
            if (groupFieldDef==null) {
                log.error("Undefined tag "+groupTag+" in group "+group+". Skipping...");
            } else {
                List<FieldDef> list = new ArrayList<>();
                groupFieldDef._group = list;

                String[] tagsOrBlocks = comps[1].split(",");
                for (String tagOrBlock : tagsOrBlocks) {
                    List<FieldDef> block = _blocksByName.get(tagOrBlock);
                    if (block!=null) {
                        list.addAll(block);
                    } else {
                        int tag = Integer.parseInt(tagOrBlock);
                        FieldDef fieldDef = _fieldsByTag.get(tag);
                        if (fieldDef==null) {
                            log.error("Undefined tag "+tag+" in group "+group+". Skipping...");
                        } else {
                            list.add(fieldDef);
                        }
                    }
                }
                _groupsList.add(groupFieldDef);
            }
        }
//		log.info("{}", groups);
//		log.info("{}", _groupsList);

        for (String message : messages) {
            String[] comps = message.split("\\|");
            String[] typeName = comps[0].split("=");
            String type = typeName[0];
            String name = typeName[1];
            List<FieldDef> list = new ArrayList<>();

            String[] tagsOrBlocks = comps[1].split(",");
            for (String tagOrBlock : tagsOrBlocks) {
                List<FieldDef> block = _blocksByName.get(tagOrBlock);
                if (block!=null) {
                    list.addAll(block);
                } else {
                    int tag = Integer.parseInt(tagOrBlock);
                    FieldDef fieldDef = _fieldsByTag.get(tag);
                    if (fieldDef==null) {
                        log.error("Undefined tag "+tag+" in message "+message+". Skipping...");
                    } else {
                        list.add(fieldDef);
                    }
                }
            }
            MsgDef msgDef = new MsgDef(type, name, list);
            _messagessByType.put(type, msgDef);
            _messagessByName.put(name, msgDef);
        }
        log.info("{}", messages);
        log.info("{}", _messagessByType.values());

    }


    private String _baseDirName = "./src/main/java";
    public void setBaseDirName(String baseDirName) {
        _baseDirName = Utils.parseAsString("baseDirName", baseDirName, _baseDirName);
    }

    private String _packageName = "net.a_cappella.cembalo.generated";
    public void setPackageName(String packageName) {
        _packageName = Utils.parseAsString("packageName", packageName, _packageName);
    }

    private String _className = "FixConstants";
    public void setClassName(String className) {
        _className = className;
    }


    public static void main(String args[]) {
        System.out.println("args="+Arrays.asList(args));
        String springFile = "gen-spring.xml";
        if (args.length>=1) {
            springFile = args[0];
        }
        try (ClassPathXmlApplicationContext ctx = new ClassPathXmlApplicationContext(springFile)) {
        } catch (Exception x) {
            x.printStackTrace();
        }
    }

    public void generate() {
        OutputManager outputManager = new PackageOutputManager(_baseDirName, _packageName);
        try (Writer out = outputManager.createOutput(_className)) {
            out.append("package "+_packageName+";\n");
            out.append("\n");

            out.write(COMMENT_PREFIX+" File: "+_packageName+"."+_className+" was machine generated on "+new Date()+". Do not modify."); out.append("\n");
            out.append("\n");

            out.append("public class "+_className+" {\n");

            out.append("\n");
            String[] messageTypes = new String[_messagessByType.size()];
            _messagessByType.keySet().toArray(messageTypes);
            Arrays.sort(messageTypes);
            for (int i=0; i<messageTypes.length; i++) {
                String messageType = messageTypes[i];
                MsgDef msgDef = _messagessByType.get(messageType);
                out.append("\tpublic static final String MsgType_"+msgDef.getName()+" = \""+messageType+"\";\n");
            }


            out.append("\n");
            int[] tags = _fieldsByTag.keys();
            Arrays.sort(tags);
            for (int i=0; i<tags.length; i++) {
                int tag = tags[i];
                FieldDef fieldDef = _fieldsByTag.get(tag);
                String fieldName = fieldDef._name;

                Map<String, String> stringFieldValues = stringFieldValues(fieldDef);
                TCharObjectMap<String> charFieldValues = charFieldValues(fieldDef);
                TLongObjectMap<String> intFieldValues = intFieldValues(fieldDef);

                if (stringFieldValues!=null || charFieldValues!=null  || intFieldValues!=null) out.append("\n");
                out.append("\tpublic static final int Tag_"+fieldName+" = "+tag+";\n");

                if (stringFieldValues!=null) {
                    String[] stringFieldValuesKeys = new String[stringFieldValues.size()];
                    stringFieldValues.keySet().toArray(stringFieldValuesKeys);
                    Arrays.sort(stringFieldValuesKeys);
                    for (int j=0; j<stringFieldValuesKeys.length; j++) {
                        String key = stringFieldValuesKeys[j];
                        out.append("\tpublic static final String Val_"+fieldName+"_"+camelCase(stringFieldValues.get(key))+" = \""+key+"\";\n");
                    }
                }
                if (charFieldValues!=null) {
                    char[] charFieldValuesKeys = charFieldValues.keys();
                    Arrays.sort(charFieldValuesKeys);
                    for (int j=0; j<charFieldValuesKeys.length; j++) {
                        char key = charFieldValuesKeys[j];
                        out.append("\tpublic static final char Val_"+fieldName+"_"+camelCase(charFieldValues.get(key))+" = '"+key+"';\n");
                    }
                }
                if (intFieldValues!=null) {
                    long[] intFieldValuesKeys = intFieldValues.keys();
                    Arrays.sort(intFieldValuesKeys);
                    for (int j=0; j<intFieldValuesKeys.length; j++) {
                        long key = intFieldValuesKeys[j];
                        out.append("\tpublic static final int Val_"+fieldName+"_"+camelCase(intFieldValues.get(key))+" = "+key+";\n");
                    }
                }

                if (stringFieldValues!=null || charFieldValues!=null  || intFieldValues!=null) out.append("\n");
            }

            out.append("\n");
            out.append("}\n");
        } catch (IOException x) {
            log.error("{}", x);
        }

    }

    private String camelCase(String value) {
        String[] comps = value.split(" ");
        value = "";
        for (int i=0; i<comps.length; i++) {
            String comp = comps[i];
            if (comp.length()>0) {
                comp = comp.substring(0, 1).toUpperCase()+comp.substring(1);
            }
            value += comp;
        }
        return value;
    }

    private Map<String, String> stringFieldValues(FieldDef fieldDef) {
        if (fieldDef._type == 'S' || fieldDef._type == 's') {
            StringFieldDef stringFieldDef = (StringFieldDef) fieldDef;
            return stringFieldDef._values;
        }
        return null;
    }

    private TCharObjectMap<String> charFieldValues(FieldDef fieldDef) {
        if (fieldDef._type == 'C') {
            CharFieldDef charFieldDef = (CharFieldDef) fieldDef;
            return charFieldDef._values;
        }
        return null;
    }

    private TLongObjectMap<String> intFieldValues(FieldDef fieldDef) {
        if (fieldDef._type == 'I') {
            IntFieldDef intFieldDef = (IntFieldDef) fieldDef;
            return intFieldDef._values;
        }
        return null;
    }

    public boolean isInternable(int tag) {
        FieldDef fieldDef = _fieldsByTag.get(tag);
        if (fieldDef!=null && fieldDef._type=='s') {
            return true;
        }
        return false;
    }
}
