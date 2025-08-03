package net.a_cappella.continuo.obj.meta;

import java.lang.reflect.Field;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import static net.a_cappella.continuo.obj.meta.FieldType.*;

public class FieldMetaInfo {
    private static final Logger log = LoggerFactory.getLogger(FieldMetaInfo.class);

    private final String _name;
    private FieldType _type;
    private Field _field;

    public FieldMetaInfo(String name, FieldType type) {
        _name = name;
        _type = type;
    }

    public FieldMetaInfo(String name) {
        _name = name;
        _type = UNKNOWN;
    }

    public String getName() {
        return _name;
    }

    public FieldType getType() {
        return _type;
    }

    public Field getField() {
        return _field;
    }
    public void setField(Object obj) throws Exception {
        String fieldName = '_' + _name;

        Class<?> clazz = obj.getClass();
        while (clazz != null) {
            try {
                _field = clazz.getDeclaredField(fieldName);
                if (!checkTypeMatches()) {
                    String err = "Type mismatch for field '"+_name+"'. Expected: "+_type+" Actual: "+_field.getGenericType();
                    log.error(err);
                    throw new TypeMismatchException(err);
                }
                _field.setAccessible(true);
                return;
            } catch (NoSuchFieldException e) {
                clazz = clazz.getSuperclass();
            } catch (TypeMismatchException x) {
                throw x;
            }
        }
        throw new NoSuchFieldException(fieldName+" in "+obj.getClass().getCanonicalName()+" or any subclasses");
    }
    private boolean checkTypeMatches() {
        boolean match = true;
        String actualType = _field.getGenericType().getTypeName();

        switch (_type) {
            // these types do not need to be explicitly specified
            case SHORT:		if (!"short".equals(actualType)) match = false; break;
            case BOOLEAN:	if (!"boolean".equals(actualType)) match = false; break;
            case CHAR:		if (!"char".equals(actualType)) match = false; break;
            case DOUBLE:	if (!"double".equals(actualType)) match = false; break;
            case FLOAT:		if (!"float".equals(actualType)) match = false; break;
            case INT:		if (!"int".equals(actualType)) match = false; break;
            case LONG:		if (!"long".equals(actualType)) match = false; break;

            case ENUM:		if (!isEnum(actualType)) match = false; break;
            case STRING:	if (!"java.lang.String".equals(actualType)) match = false; break;

            // these types do need to be explicitly specified
            case DATE:		if (!"int".equals(actualType)) match = false; break;
            case NANOS:		if (!"long".equals(actualType)) match = false; break;
            case TIME:		if (!"int".equals(actualType)) match = false; break;
            case TIMESTAMP:	if (!"long".equals(actualType)) match = false; break;

            case UNKNOWN:
                match = true;
                if ("short".equals(actualType)) _type = SHORT;
                else if ("boolean".equals(actualType)) _type = BOOLEAN;
                else if ("char".equals(actualType)) _type = CHAR;
                else if ("double".equals(actualType)) _type = DOUBLE;
                else if ("float".equals(actualType)) _type = FLOAT;
                else if ("int".equals(actualType)) _type = INT;
                else if ("long".equals(actualType)) _type = LONG;
                else if ("java.lang.String".equals(actualType)) _type = STRING;
                else if (isEnum(actualType)) _type = ENUM;
                else match = false;
                break;
        }

        return match;
    }

    private boolean isEnum(String type) {
        try {
            return Class.forName(type).isEnum();
        } catch (ClassNotFoundException e) {
            return false;
        }
    }

    public String toString() {
        return "{"+_name+","+_type+"}";
    }
}
