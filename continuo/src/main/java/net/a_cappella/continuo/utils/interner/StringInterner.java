package net.a_cappella.continuo.utils.interner;

public class StringInterner extends HashMap<String, CharSequence> {

    public StringInterner() {
        super();
    }

    public StringInterner(int initialCapacity) {
        super(initialCapacity);
    }

    public StringInterner(int initialCapacity, float loadFactor) {
        super(initialCapacity, loadFactor);
    }

    public String intern(CharSequence value) {
        if (value.length() == 0) return null;
        if (table == EMPTY_TABLE) {
            inflateTable(threshold);
        }
        int hash = hash(value);
        int i = indexFor(hash, table.length);
        for (Entry<String, CharSequence> e = table[i]; e != null; e = e.next) {
            String k = e.key;
            if (k.contentEquals(value)) {
                String oldValue = (String) e.value;
                return oldValue;
            }
        }

        modCount++;
//      https://shipilev.net/jvm/anatomy-quarks/10-string-intern/
//      String internedString = value.toString().intern();
        String internedString = value.toString();
        addEntry(hash, internedString, internedString, i);
        return internedString;
    }
}
