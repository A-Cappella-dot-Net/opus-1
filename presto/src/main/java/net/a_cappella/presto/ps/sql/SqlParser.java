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

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class SqlParser {
    private final String _sql;
    private final SqlTokenizer _tokenizer;

    private SqlParser(String sql) {
        _sql = sql;
        _tokenizer = new SqlTokenizer(sql);
    }

    private SqlParserResult selectStatement() throws Exception {
        SqlToken token = _tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.SELECT) {
            List<String> list = new ArrayList<>();
            listOfStrings(list);
            token = _tokenizer.nextToken();
            if (token.getType()==SqlTokenEnum.FROM) {
                token = _tokenizer.nextToken();
                if (token.getType()==SqlTokenEnum.STRING) {
                    String table = token.getString();
                    token = _tokenizer.nextToken();
                    if (token.getType()==SqlTokenEnum.EOF) {
                        return new SqlParserResult(_sql, list, table, null);
                    } else {
                        WhereNode whereNode = whereClause(SqlTokenEnum.NULL, null);
                        token = _tokenizer.nextToken();
                        if (token.getType()==SqlTokenEnum.EOF) {
                            return new SqlParserResult(_sql, list, table, whereNode);
                        } else {
                            throw new Exception(_tokenizer.showError("Malformed SQL"));
                        }
                    }
                } else {
                    throw new Exception(_tokenizer.showError("Expecting string"));
                }
            } else {
                throw new Exception(_tokenizer.showError("Expecting 'from'"));
            }
        } else {
            throw new Exception(_tokenizer.showError("Expecting 'select'"));
        }
    }

    private void listOfStrings(List<String> list) throws Exception {
        SqlToken token = _tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.STRING || token.getType()==SqlTokenEnum.STAR) {
            if (token.getType()==SqlTokenEnum.STRING) {
                list.add(token.getString());
            } else {
                list.add("*");
            }
            token = _tokenizer.nextToken();
            if (token.getType()==SqlTokenEnum.COMMA) {
                listOfStrings(list);
            } else {
                _tokenizer.rewindToken();
            }
        } else {
            throw new Exception(_tokenizer.showError("Expecting a list string value"));
        }
    }

    private static void listOfKeys(SqlTokenizer tokenizer, List<String> list) throws Exception {
        SqlToken token = tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.STRING) {
            list.add(token.getString());
            token = tokenizer.nextToken();
            if (token.getType()==SqlTokenEnum.COMMA) {
                listOfKeys(tokenizer, list);
            } else {
                tokenizer.rewindToken();
            }
        } else {
            throw new Exception(tokenizer.showError("Expecting a list string value"));
        }
    }

    public static List<String> parseListOfKeys(String str) throws Exception {
        if (str==null || "".equals(str.trim())) return null;
        SqlTokenizer tokenizer = new SqlTokenizer(str);
        List<String> list = new ArrayList<>();
        listOfKeys(tokenizer, list);
        return list;
    }




    private WhereNode whereClause(SqlTokenEnum nodeType, WhereNode leftSubTree) throws Exception {
        WhereNode result;
        SqlToken token = _tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.LPAR) {
            result = whereClause(SqlTokenEnum.NULL, null);
            if (leftSubTree!=null) {
                result = new WhereInternalNode(nodeType, leftSubTree, result);
            }
            token = _tokenizer.nextToken();
            if (token.getType()!=SqlTokenEnum.RPAR) {
                throw new Exception(_tokenizer.showError("Mismatched parenthesis"));
            }
            token = _tokenizer.nextToken();
            if (token.getType()==SqlTokenEnum.AND || token.getType()==SqlTokenEnum.OR) {
                result = whereClause(token.getType(), result);
                return result;
            }
            _tokenizer.rewindToken();
            return result;
        }
        _tokenizer.rewindToken();
        result = atomicExpression();
        if (leftSubTree!=null) {
            result = new WhereInternalNode(nodeType, leftSubTree, result);
        }
        token = _tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.AND || token.getType()==SqlTokenEnum.OR) {
            result = whereClause(token.getType(), result);
            return result;
        }
        _tokenizer.rewindToken();
        return result;
    }

    private WhereNode atomicExpression() throws Exception {
        WhereNode result;
        SqlToken token = _tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.STRING) {
            String key = token.getString();
            token = _tokenizer.nextToken();
            if (token.getType()==SqlTokenEnum.IN) {
                token = _tokenizer.nextToken();
                if (token.getType()==SqlTokenEnum.LPAR) {
                    List<SqlToken> list = new ArrayList<>();
                    listOfValues(list);
                    token = _tokenizer.nextToken();
                    if (token.getType()==SqlTokenEnum.RPAR) {
                        result = new WhereLeafNode(SqlTokenEnum.IN, key, list);
                    } else {
                        throw new Exception(_tokenizer.showError("Expecting ')' or ','"));
                    }
                } else {
                    throw new Exception(_tokenizer.showError("Expecting '('"));
                }
            } else if (token.getType()==SqlTokenEnum.NOT) {
                token = _tokenizer.nextToken();
                if (token.getType()==SqlTokenEnum.IN) {
                    token = _tokenizer.nextToken();
                    if (token.getType()==SqlTokenEnum.LPAR) {
                        List<SqlToken> list = new ArrayList<>();
                        listOfValues(list);
                        token = _tokenizer.nextToken();
                        if (token.getType()==SqlTokenEnum.RPAR) {
                            result = new WhereLeafNode(SqlTokenEnum.NOTIN, key, list);
                        } else {
                            throw new Exception(_tokenizer.showError("Expecting ')' or ','"));
                        }
                    } else {
                        throw new Exception(_tokenizer.showError("Expecting '('"));
                    }
                } else {
                    throw new Exception(_tokenizer.showError("Expecting 'in'"));
                }
            } else if (token.getType()==SqlTokenEnum.NE ||
                    token.getType()==SqlTokenEnum.GE ||
                    token.getType()==SqlTokenEnum.LE ||
                    token.getType()==SqlTokenEnum.GT ||
                    token.getType()==SqlTokenEnum.LT ||
                    token.getType()==SqlTokenEnum.EQ) {
                SqlTokenEnum op = token.getType();
                token = _tokenizer.nextToken();
                if (token.getType()==SqlTokenEnum.NUMBER ||
                        token.getType()==SqlTokenEnum.TIMESTAMP ||
                        token.getType()==SqlTokenEnum.TIME ||
                        token.getType()==SqlTokenEnum.DATE ||
                        token.getType()==SqlTokenEnum.STRING) {
                    result = new WhereLeafNode(op, key, Arrays.asList(token));
                } else {
                    if (op==SqlTokenEnum.EQ || op==SqlTokenEnum.NE) {
                        if (token.getType()==SqlTokenEnum.BOOLEAN) {
                            result = new WhereLeafNode(op, key, Arrays.asList(token));
                        } else {
                            throw new Exception(_tokenizer.showError("Expecting value and got "+token.getType()));
                        }
                    } else {
                        throw new Exception(_tokenizer.showError("Expecting value and got "+token.getType()));
                    }
                }
            } else if (token.getType()==SqlTokenEnum.IS) {
                token = _tokenizer.nextToken();
                if (token.getType()==SqlTokenEnum.NULL) {
                    result = new WhereLeafNode(SqlTokenEnum.IS, key, null);
                } else if (token.getType()==SqlTokenEnum.NOT) {
                    token = _tokenizer.nextToken();
                    if (token.getType()==SqlTokenEnum.NULL) {
                        result = new WhereLeafNode(SqlTokenEnum.ISNOT, key, null);
                    } else {
                        throw new Exception(_tokenizer.showError("Expecting 'null'"));
                    }
                } else {
                    throw new Exception(_tokenizer.showError("Expecting 'not' or 'null'"));
                }
            } else {
                throw new Exception(_tokenizer.showError("Expecting op or 'in' or 'not' or 'is'"));
            }
        } else {
            throw new Exception(_tokenizer.showError("Expecting id"));
        }

        return result;
    }

    private void listOfValues(List<SqlToken> list) throws Exception {
        SqlToken token = _tokenizer.nextToken();
        if (token.getType()==SqlTokenEnum.NUMBER ||
                token.getType()==SqlTokenEnum.TIMESTAMP ||
                token.getType()==SqlTokenEnum.TIME ||
                token.getType()==SqlTokenEnum.DATE ||
                token.getType()==SqlTokenEnum.STRING) {
            list.add(token);
            token = _tokenizer.nextToken();
            if (token.getType()==SqlTokenEnum.COMMA) {
                listOfValues(list);
            } else {
                _tokenizer.rewindToken();
            }
        } else {
            throw new Exception(_tokenizer.showError("Expecting a list value"));
        }
    }

    public static SqlParserResult parseSql(String sql) throws Exception {
        return new SqlParser(sql).selectStatement();
    }

    public static WhereNode parseWhereClause(String whereClause) throws Exception {
        return new SqlParser(whereClause).whereClause(SqlTokenEnum.NULL, null);
    }
}
