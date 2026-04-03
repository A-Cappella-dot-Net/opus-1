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

package net.a_cappella.presto.ps.sql;

import net.a_cappella.continuo.datatypes.PDate;
import net.a_cappella.continuo.datatypes.PTime;
import net.a_cappella.continuo.utils.Utils;

import java.text.ParseException;

public class SqlTokenizer {
    private static final SqlToken TOKEN_SELECT = new SqlToken(SqlTokenEnum.SELECT);
    private static final SqlToken TOKEN_STAR = new SqlToken(SqlTokenEnum.STAR);
    private static final SqlToken TOKEN_FROM = new SqlToken(SqlTokenEnum.FROM);
    private static final SqlToken TOKEN_WHERE = new SqlToken(SqlTokenEnum.WHERE);
    private static final SqlToken TOKEN_LPAR = new SqlToken(SqlTokenEnum.LPAR);
    private static final SqlToken TOKEN_RPAR = new SqlToken(SqlTokenEnum.RPAR);
    private static final SqlToken TOKEN_COMMA = new SqlToken(SqlTokenEnum.COMMA);
    private static final SqlToken TOKEN_NE = new SqlToken(SqlTokenEnum.NE);
    private static final SqlToken TOKEN_GE = new SqlToken(SqlTokenEnum.GE);
    private static final SqlToken TOKEN_LE = new SqlToken(SqlTokenEnum.LE);
    private static final SqlToken TOKEN_GT = new SqlToken(SqlTokenEnum.GT);
    private static final SqlToken TOKEN_LT = new SqlToken(SqlTokenEnum.LT);
    private static final SqlToken TOKEN_EQ = new SqlToken(SqlTokenEnum.EQ);
    private static final SqlToken TOKEN_AND = new SqlToken(SqlTokenEnum.AND);
    private static final SqlToken TOKEN_OR = new SqlToken(SqlTokenEnum.OR);
    private static final SqlToken TOKEN_IN = new SqlToken(SqlTokenEnum.IN);
    private static final SqlToken TOKEN_IS = new SqlToken(SqlTokenEnum.IS);
    private static final SqlToken TOKEN_NOT = new SqlToken(SqlTokenEnum.NOT);
    private static final SqlToken TOKEN_NULL = new SqlToken(SqlTokenEnum.NULL);
    private static final SqlToken TOKEN_TRUE = new SqlToken(SqlTokenEnum.TRUE);
    private static final SqlToken TOKEN_FALSE = new SqlToken(SqlTokenEnum.FALSE);
    private static final SqlToken TOKEN_EOF = new SqlToken(SqlTokenEnum.EOF);

    private SqlToken cachedToken;
    private boolean nextTokenFromCache = false;
    private int currentPos;
    private int previousPos;
    private final char buffer[];


    public SqlTokenizer(String str) {
        buffer = (str+'\n').toCharArray();
        currentPos = 0;
        previousPos = 0;
    }

    public boolean hasMoreTokens() {
        return currentPos < buffer.length;
    }

    public String showError(String prefix) {
        int i;
        StringBuilder sb = new StringBuilder();
        sb.append(prefix).append(": ");
        for (i=0; i<previousPos; i++) {
            sb.append(buffer[i]);
        }
        sb.append(">>>");
        i = previousPos;
        while (buffer[i]!='\n') {
            sb.append(buffer[i++]);
        }
        return sb.toString();
    }
    private SqlToken errorToken(String prefix) {
        return new SqlToken(SqlTokenEnum.ERROR, showError(prefix));
    }

    public void rewindToken() {
        nextTokenFromCache = true;
    }

    public static boolean isLetter(char c) {
        return (((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')));
    }

    public static boolean isDigit(char c) {
        return ((c >= '0') && (c <= '9'));
    }

    public static boolean isAlpha(char c) {
        return isLetter(c) || isDigit(c) || c=='_' || c=='.';
    }

    public static boolean isSpace(char c) {
        return ((c == ' ') || (c == '\t') || (c == '\r') || (c == '\n'));
    }

    private SqlToken parseTimeStamp(String str) {
        try {
            long ts = Utils.parse("yyyy-MM-dd HH:mm:ss.SSS", str).getTime();
            return new SqlToken(SqlTokenEnum.TIMESTAMP, ts);
        } catch (ParseException ignore) {}

        try {
            long ts = PTime.fromMillis(Utils.parse("HH:mm:ss.SSS", str).getTime());
            return new SqlToken(SqlTokenEnum.TIME, ts);
        } catch (ParseException ignore) {}

        try {
            long ts = PDate.fromMillis(Utils.parse("yyyy-MM-dd", str).getTime());
            return new SqlToken(SqlTokenEnum.DATE, ts);
        } catch (ParseException ignore) {}

        return null;
    }

    private SqlToken parseNumber() {
        double m = 0; // integral part
        double f = 0; // fractional part
        int startingPos = currentPos;
        boolean wasNeg = false;
        boolean isNumber = false;

        if (buffer[currentPos] == '-') {
            wasNeg = true;
            currentPos++;
        } else if (buffer[currentPos] == '+') {
            currentPos++;
        }

        while (isDigit(buffer[currentPos])) {
            isNumber = true;
            m = (m * 10.0) + (buffer[currentPos++] - '0');
        }

        if (buffer[currentPos] == '.') {
            currentPos++;
            double t = .1;
            while (isDigit(buffer[currentPos])) {
                isNumber = true;
                f = f + (t * (buffer[currentPos++] - '0'));
                t = t / 10.0;
            }
        }

        m += f;
        if (wasNeg) m = -m;

        if (!isNumber) {
            currentPos = startingPos;
            return null;
        }

        if ((buffer[currentPos] != 'E') && (buffer[currentPos] != 'e')) {
            return new SqlToken(m);
        }

        currentPos++;

        int p = 0;
        double e;
        wasNeg = false;

        if (buffer[currentPos] == '-') {
            wasNeg = true;
            currentPos++;
        } else if (buffer[currentPos] == '+') {
            currentPos++;
        }

        while (isDigit(buffer[currentPos])) {
            p = (p * 10) + (buffer[currentPos++] - '0');
        }

        try {
            e = Math.pow(10, p);
        } catch (ArithmeticException x) {
            return new SqlToken(SqlTokenEnum.ERROR, "Illegal numeric constant.");
        }

        if (wasNeg)	e = 1/e;
        m *= e;

        return new SqlToken(m);
    }

    public SqlToken nextToken() {
        if (nextTokenFromCache) {
            nextTokenFromCache = false;
            return cachedToken;
        }

        previousPos = currentPos;

        StringBuilder sb;

        if (currentPos >= buffer.length) {
            return cachedToken = TOKEN_EOF;
        }

        while (isSpace(buffer[currentPos])) {
            currentPos++;
            if (currentPos >= buffer.length) {
                return cachedToken = TOKEN_EOF;
            }
        }

        switch (buffer[currentPos]) {

            case '*':
                currentPos++;
                return cachedToken = TOKEN_STAR;
            case '(':
                currentPos++;
                return cachedToken = TOKEN_LPAR;
            case ')':
                currentPos++;
                return cachedToken = TOKEN_RPAR;
            case ',':
                currentPos++;
                return cachedToken = TOKEN_COMMA;
            case '!':
                if (buffer[currentPos + 1] == '=') {
                    currentPos += 2;
                    return cachedToken = TOKEN_NE;
                }
                currentPos++;
                return cachedToken = errorToken("Unexpected character");
            case '<':
                if (buffer[currentPos + 1] == '=') {
                    currentPos += 2;
                    return cachedToken = TOKEN_LE;
                }
                currentPos++;
                return cachedToken = TOKEN_LT;
            case '>':
                if (buffer[currentPos + 1] == '=') {
                    currentPos += 2;
                    return cachedToken = TOKEN_GE;
                }
                currentPos++;
                return cachedToken = TOKEN_GT;
            case '=':
                currentPos++;
                return cachedToken = TOKEN_EQ;
            case '+':
            case '-':
            case '.':
            case '0':
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
                cachedToken = parseNumber();
                if (cachedToken != null) return cachedToken;
                return cachedToken = errorToken("Could not parse number");
            case '\'':
                sb = new StringBuilder();
                currentPos++;
                while (true) {
                    switch (buffer[currentPos]) {
                        case '\n':
                            return cachedToken = errorToken("Missing end quote");
                        case '\'':
                            if (buffer[currentPos + 1] == '\'') {
                                currentPos++;
                                sb.append('\'');
                            } else {
                                currentPos++;
                                String str = sb.toString();
                                cachedToken = parseTimeStamp(str);
                                if (cachedToken==null) {
                                    cachedToken = new SqlToken(str);
                                }
                                return cachedToken;
                            }
                            break;
                        default:
                            sb.append(buffer[currentPos]);
                    }
                    currentPos++;
                    if (currentPos >= buffer.length) {
                        return cachedToken = errorToken("Missing end quote");
                    }
                }
            case '"':
                sb = new StringBuilder();
                currentPos++;
                while (true) {
                    switch (buffer[currentPos]) {
                        case '\n':
                            return cachedToken = errorToken("Missing end quote");
                        case '"':
                            if (buffer[currentPos + 1] == '"') {
                                currentPos++;
                                sb.append('"');
                            } else {
                                currentPos++;
                                String str = sb.toString();
                                cachedToken = parseTimeStamp(str);
                                if (cachedToken==null) {
                                    cachedToken = new SqlToken(str);
                                }
                                return cachedToken;
                            }
                            break;
                        default:
                            sb.append(buffer[currentPos]);
                    }
                    currentPos++;
                    if (currentPos >= buffer.length) {
                        return cachedToken = errorToken("Missing end quote");
                    }
                }
            default:
                break;
        }

        if (!isLetter(buffer[currentPos])) {
            return cachedToken = errorToken("Unexpected character");
        }

        sb = new StringBuilder();
        while (isAlpha(buffer[currentPos])) {
            sb.append(buffer[currentPos]);
            currentPos++;
        }
        String str = sb.toString();
        if ("select".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_SELECT;
        } else if ("from".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_FROM;
        } else if ("where".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_WHERE;
        } else if ("and".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_AND;
        } else if ("or".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_OR;
        } else if ("in".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_IN;
        } else if ("is".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_IS;
        } else if ("not".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_NOT;
        } else if ("null".equalsIgnoreCase(str)) {
            return cachedToken = TOKEN_NULL;
        } else if ("true".equals(str)) {
            return cachedToken = TOKEN_TRUE;
        } else if ("false".equals(str)) {
            return cachedToken = TOKEN_FALSE;
        }
        return cachedToken = new SqlToken(str);
    }

    public static void main(String[] args) {
        String str = "(key1.2=val1 and key2=2) or key3='y and space' and ts = '2013-01-12'";
//		String str = "id1!=val1 and id2=123 and id3 in (1, 2, 3)";
        SqlTokenizer st = new SqlTokenizer(str);
        SqlToken tk = st.nextToken();
        while (tk.getType() != SqlTokenEnum.EOF) {
            System.out.println(tk);
            tk = st.nextToken();
        }
    }
}
