package net.a_cappella.presto.ps.sql;

public enum SqlTokenEnum {
    SELECT("select"), STAR("*"), FROM("from"), WHERE("where"),
    AND("and"), OR("or"), NOT("not"),
    IN("in"), NOTIN("not in"), IS("is"), ISNOT("is not"), NULL("null"),
    TRUE("true"), FALSE("false"), BOOLEAN("boolean"),
    LPAR("("), RPAR(")"), COMMA(","),
    NE("!="), LE("<="), GE(">="), LT("<"), GT(">"), EQ("="),
    STRING("string"), NUMBER("number"), TIMESTAMP("timestamp"), TIME("time"), DATE("date"),
    ERROR("error"), LEAF("leaf"), EOF("eof"),
    ;

    final String id;

    SqlTokenEnum(String id) {
        this.id = id;
    }

    public String toString() {
        return this.id;
    }

    public static SqlTokenEnum getEnumFromName(String name) {
        if ("SELECT".equalsIgnoreCase(name)) {
            return SqlTokenEnum.SELECT;
        } else if ("*".equalsIgnoreCase(name)) {
            return SqlTokenEnum.STAR;
        } else if ("FROM".equalsIgnoreCase(name)) {
            return SqlTokenEnum.FROM;
        } else if ("WHERE".equalsIgnoreCase(name)) {
            return SqlTokenEnum.WHERE;
        } else if ("AND".equalsIgnoreCase(name)) {
            return SqlTokenEnum.AND;
        } else if ("OR".equalsIgnoreCase(name)) {
            return SqlTokenEnum.OR;
        } else if ("NOT".equalsIgnoreCase(name)) {
            return SqlTokenEnum.NOT;
        } else if ("IN".equalsIgnoreCase(name)) {
            return SqlTokenEnum.IN;
        } else if ("NOT IN".equalsIgnoreCase(name)) {
            return SqlTokenEnum.NOTIN;
        } else if ("IS".equalsIgnoreCase(name)) {
            return SqlTokenEnum.IS;
        } else if ("IS NOT".equalsIgnoreCase(name)) {
            return SqlTokenEnum.ISNOT;
        } else if ("NULL".equalsIgnoreCase(name)) {
            return SqlTokenEnum.NULL;
        } else if ("(".equalsIgnoreCase(name)) {
            return SqlTokenEnum.LPAR;
        } else if (")".equalsIgnoreCase(name)) {
            return SqlTokenEnum.RPAR;
        } else if (",".equalsIgnoreCase(name)) {
            return SqlTokenEnum.COMMA;
        } else if ("!=".equalsIgnoreCase(name)) {
            return SqlTokenEnum.NE;
        } else if ("<=".equalsIgnoreCase(name)) {
            return SqlTokenEnum.LE;
        } else if (">=".equalsIgnoreCase(name)) {
            return SqlTokenEnum.GE;
        } else if ("<".equalsIgnoreCase(name)) {
            return SqlTokenEnum.LT;
        } else if (">".equalsIgnoreCase(name)) {
            return SqlTokenEnum.GT;
        } else if ("=".equalsIgnoreCase(name)) {
            return SqlTokenEnum.EQ;
        } else if ("STRING".equalsIgnoreCase(name)) {
            return SqlTokenEnum.STRING;
        } else if ("NUMBER".equalsIgnoreCase(name)) {
            return SqlTokenEnum.NUMBER;
        } else if ("TRUE".equalsIgnoreCase(name)) {
            return SqlTokenEnum.TRUE;
        } else if ("FALSE".equalsIgnoreCase(name)) {
            return SqlTokenEnum.FALSE;
        } else if ("BOOLEAN".equalsIgnoreCase(name)) {
            return SqlTokenEnum.BOOLEAN;
        } else if ("TIMESTAMP".equalsIgnoreCase(name)) {
            return SqlTokenEnum.TIMESTAMP;
        } else if ("TIME".equalsIgnoreCase(name)) {
            return SqlTokenEnum.TIME;
        } else if ("DATE".equalsIgnoreCase(name)) {
            return SqlTokenEnum.DATE;
        } else if ("ERROR".equalsIgnoreCase(name)) {
            return SqlTokenEnum.ERROR;
        } else if ("LEAF".equalsIgnoreCase(name)) {
            return SqlTokenEnum.LEAF;
        } else if ("EOF".equalsIgnoreCase(name)) {
            return SqlTokenEnum.EOF;
        }
        return null;
    }
}
