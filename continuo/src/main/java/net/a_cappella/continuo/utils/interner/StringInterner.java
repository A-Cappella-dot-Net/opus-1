/*
 * Copyright (c) 2026. Vladimir Ivanov
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
