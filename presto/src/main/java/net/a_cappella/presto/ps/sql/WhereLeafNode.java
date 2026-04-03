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

import net.a_cappella.continuo.obj.Obj;
import net.a_cappella.continuo.obj.meta.FieldMetaInfo;
import net.a_cappella.continuo.obj.meta.FieldType;
import net.a_cappella.continuo.obj.meta.ObjMetaInfo;
import net.a_cappella.continuo.obj.meta.TypeMetaInfo;
import net.a_cappella.presto.obj.ObjImpl;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.ArrayList;
import java.util.List;
import java.util.function.Predicate;

public class WhereLeafNode extends WhereNode {
    private static final Logger log = LoggerFactory.getLogger(WhereLeafNode.class);

    private static final boolean OPTIMIZE_EVAL = true;
    // On Windows
    // OPTIMIZE_EVAL = false => tot=1000000 min=0 50%=100 90%=101 99%=101 99.9%=200 max=22111
    // OPTIMIZE_EVAL = true  => tot=1000000 min=0 50%=100 90%=101 99%=101 99.9%=300 max=33215

    private static final FieldMetaInfo _unknownFieldMetaInfo = new FieldMetaInfo(null, FieldType.UNKNOWN);

    private final SqlTokenEnum _leafOp;
    private final String _fieldName;
    private final List<SqlToken> _leafValues;

    private FieldMetaInfo _fieldMetaInfo;
    private Predicate<Obj> _evalPredicate = null;

    public WhereLeafNode(SqlTokenEnum leafOp, String fieldName, List<SqlToken> leafValues) {
        _leafOp = leafOp;
        _fieldName = fieldName;
        _leafValues = leafValues;
    }

    public String toString() {
        String leafType;
        if (_leafOp == SqlTokenEnum.IN || _leafOp == SqlTokenEnum.NOTIN || _leafOp == SqlTokenEnum.IS || _leafOp == SqlTokenEnum.ISNOT)
            leafType = " "+_leafOp+" ";
        else
            leafType = _leafOp.toString();
        return "{"+((_fieldMetaInfo==null)?_fieldName:((_fieldMetaInfo.getName()==null)?_fieldName+":"+_fieldMetaInfo:_fieldMetaInfo))+leafType+_leafValues+"}";
    }

    public List<Object> getFilter(String fieldName) {
        List<Object> list = new ArrayList<>();
        if (_fieldName.equals(fieldName) && (_leafOp==SqlTokenEnum.EQ || _leafOp==SqlTokenEnum.IN)) {
            for (int i=0; i<_leafValues.size(); i++) {
                SqlToken token = _leafValues.get(i);
                list.add(token.getValue());
            }
        }
        return list;
    }

    @Override
    public boolean satisfiesWhereClause(Obj obj) {
        if (_fieldMetaInfo==null) {
            log.warn("No metaInfo is available for field '{}' for {}. Not including record in the result set: {}", _fieldName, obj.getClass().getName(), obj);
            return false;
        }

        if (OPTIMIZE_EVAL) {
            return (_evalPredicate == null) ? false : _evalPredicate.test(obj);
        }

        try {
            switch (_fieldMetaInfo.getType()) {
                case CHAR:
                    return satisfiesWhereClause(obj.getChar(_fieldName));
                case STRING:
                    return satisfiesWhereClause(obj.getString(_fieldName));
                case SHORT:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName));
                case INT:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName));
                case LONG:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName));
                case FLOAT:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName));
                case DOUBLE:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName));
                case TIMESTAMP:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName));
                case TIME:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName));
                case DATE:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName));
                case BOOLEAN:
                    return satisfiesWhereClause(TypeMetaInfo.TYPE_BOOLEAN, obj.getBoolean(_fieldName));
                case ENUM:
                    return satisfiesWhereClause(obj.getEnum(_fieldName).toString());
                default:
                    log.warn("Unhandled messageType {} for '{}'. Not including record in the result set: {}", _fieldMetaInfo.getType(), _fieldName, obj);
                    return false;
            }
        } catch (Exception x) {
            log.warn("", x);
        }
        return false;
    }

    private boolean satisfiesWhereClause(int type, double fieldValue) throws Exception {
        switch (_leafOp) {
            case EQ:
                return cmp(type, fieldValue, _leafValues.get(0))==0;
            case NE:
                return cmp(type, fieldValue, _leafValues.get(0))!=0;
            case LT:
                return cmp(type, fieldValue, _leafValues.get(0))<0;
            case LE:
                return cmp(type, fieldValue, _leafValues.get(0))<=0;
            case GT:
                return cmp(type, fieldValue, _leafValues.get(0))>0;
            case GE:
                return cmp(type, fieldValue, _leafValues.get(0))>=0;
            case IS: // is null
                return false;
            case ISNOT: // is not null
                return true;
            case IN:
                return contains(_leafValues, type, fieldValue);
            case NOTIN:
                return !contains(_leafValues, type, fieldValue);
            default:
                return false;
        }
    }
    private int cmp(int type, double d1, SqlToken token) throws Exception {
        double d2;
        if (token._type==SqlTokenEnum.NUMBER &&
                (type==TypeMetaInfo.TYPE_SHORT ||
                        type==TypeMetaInfo.TYPE_INT ||
                        type==TypeMetaInfo.TYPE_LONG ||
                        type==TypeMetaInfo.TYPE_FLOAT ||
                        type==TypeMetaInfo.TYPE_DOUBLE)) {
            d2 = token._nValue;
        } else if (token._type==SqlTokenEnum.TIMESTAMP && type==TypeMetaInfo.TYPE_TIMESTAMP) {
            d2 = token._tsValue;
        } else if (token._type==SqlTokenEnum.TIME && type==TypeMetaInfo.TYPE_TIME) {
            d2 = token._tsValue;
        } else if (token._type==SqlTokenEnum.DATE && type==TypeMetaInfo.TYPE_DATE) {
            d2 = token._tsValue;
        } else {
            throw new Exception("Incompatible object types: <short/int/long> and <"+token._type+"> "+token);
        }
        if (d1==d2) return 0;
        if (d1>d2) return 1;
        return -1;
    }
    private boolean contains(List<SqlToken> list, int type, double d) throws Exception {
        for (int i=0; i<list.size(); i++) {
            if (cmp(type, d, list.get(i))==0) return true;
        }
        return false;
    }

    private boolean satisfiesWhereClause(char fieldValue) throws Exception {
        switch (_leafOp) {
            case EQ:
                return cmp(fieldValue, _leafValues.get(0))==0;
            case NE:
                return cmp(fieldValue, _leafValues.get(0))!=0;
            case LT:
                return cmp(fieldValue, _leafValues.get(0))<0;
            case LE:
                return cmp(fieldValue, _leafValues.get(0))<=0;
            case GT:
                return cmp(fieldValue, _leafValues.get(0))>0;
            case GE:
                return cmp(fieldValue, _leafValues.get(0))>=0;
            case IS: // is null
                return false;
            case ISNOT: // is not null
                return true;
            case IN:
                return contains(_leafValues, fieldValue);
            case NOTIN:
                return !contains(_leafValues, fieldValue);
            default:
                return false;
        }
    }
    private int cmp(char c1, SqlToken token) throws Exception {
        if (token._type==SqlTokenEnum.STRING) {
            String str2 = token._sValue;
            if (str2.length()==1) {
                char c2 = str2.charAt(0);
                if (c1==c2) return 0;
                if (c1>c2) return 1;
                return -1;
            }
            throw new Exception("Incompatible object types: <char> and <"+token._type+"> "+token);
        }
        throw new Exception("Unhandled object type: <"+token._type+"> "+token);
    }
    private boolean contains(List<SqlToken> list, char c) throws Exception {
        for (int i=0; i<list.size(); i++) {
            if (cmp(c, list.get(i))==0) return true;
        }
        return false;
    }

    private boolean satisfiesWhereClause(String fieldValue) throws Exception {
        switch (_leafOp) {
            case EQ:
                return fieldValue!=null && cmp(fieldValue, _leafValues.get(0))==0;
            case NE:
                return fieldValue!=null && cmp(fieldValue, _leafValues.get(0))!=0;
            case LT:
                return fieldValue!=null && cmp(fieldValue, _leafValues.get(0))<0;
            case LE:
                return fieldValue!=null && cmp(fieldValue, _leafValues.get(0))<=0;
            case GT:
                return fieldValue!=null && cmp(fieldValue, _leafValues.get(0))>0;
            case GE:
                return fieldValue!=null && cmp(fieldValue, _leafValues.get(0))>=0;
            case IS: // is null
                return fieldValue==null;
            case ISNOT: // is not null
                return fieldValue!=null;
            case IN:
                return fieldValue!=null && contains(_leafValues, fieldValue);
            case NOTIN:
                return fieldValue!=null && !contains(_leafValues, fieldValue);
            default:
                return false;
        }
    }
    private int cmp(Object obj1, SqlToken token) throws Exception {
        if (obj1 instanceof String) {
            if (token._type==SqlTokenEnum.STRING) {
                String str2 = token._sValue;
                return ((String)obj1).compareTo(str2);
            }
            throw new Exception("Incompatible object types: <"+obj1+"> and <"+token._type+">");
        }
        throw new Exception("Unhandled object type: <"+obj1+">");
    }
    private boolean contains(List<SqlToken> list, String str) throws Exception {
        for (int i=0; i<list.size(); i++) {
            if (cmp(str, list.get(i))==0) return true;
        }
        return false;
    }
    private int cmpAdHoc(Object obj1, SqlToken token) throws Exception { // TODO cmp2
        switch (token._type) {
            case STRING:
                if (obj1 instanceof String) {
                    String str2 = token._sValue;
                    return ((String)obj1).compareTo(str2);
                } else if (obj1 instanceof Character) {
                    String str2 = token._sValue;
                    return ((Character)obj1).compareTo(str2.charAt(0));
                }
                break;
            case NUMBER:
                if (obj1 instanceof Number) {
                    double d2 = token._nValue;
                    return Double.compare(((Number)obj1).doubleValue(), d2);
                }
                break;
            case BOOLEAN:
                if (obj1 instanceof Boolean) {
                    boolean bool2 = token._bValue;
                    return ((Boolean)obj1==bool2)?0:(bool2)?-1:1;
                }
                break;
            case TIMESTAMP:
                if (obj1 instanceof Long) {
                    long long2 = token._tsValue;
                    return Long.compare(((Long)obj1), long2);
                }
                break;
            case DATE:
                if (obj1 instanceof Integer) {
                    int int2 = (int) token._tsValue;
                    return Integer.compare(((Integer)obj1), int2);
                }
                break;
            case TIME:
                if (obj1 instanceof Integer) {
                    int int2 = (int) token._tsValue;
                    return Integer.compare(((Integer)obj1), int2);
                }
                break;
            default:
                log.info(obj1.getClass().getName());
                break;
        }
        throw new Exception("Incompatible object types: <"+obj1+"> and <"+token._type+">");
    }
    private boolean containsAdHoc(List<SqlToken> list, Object obj1) throws Exception {
        for (int i=0; i<list.size(); i++) {
            if (cmpAdHoc(obj1, list.get(i))==0) return true;
        }
        return false;
    }

    private boolean satisfiesWhereClause(int type, boolean fieldValue) throws Exception {
        switch (_leafOp) {
            case EQ:
                return cmp(fieldValue, _leafValues.get(0));
            case NE:
                return !cmp(fieldValue, _leafValues.get(0));
            case LT:
                return false;
            case LE:
                return false;
            case GT:
                return false;
            case GE:
                return false;
            case IS: // is null
                return false;
            case ISNOT: // is not null
                return true;
            case IN:
                return false;
            case NOTIN:
                return false;
            default:
                return false;
        }
    }
    private boolean cmp(boolean bool1, SqlToken token) {
        boolean bool2 = token._bValue;
        return bool1==bool2;
    }

    protected boolean evalWhereClauseRequiresOnlyHeaderOrKeyFields(List<FieldMetaInfo> keys) {
        for (int i=0; i<keys.size(); i++) {
            if (keys.get(i).getName().equals(_fieldName)) return true;
        }
        for (int i = 0; i< ObjImpl._headerFields.size(); i++) {
            if (ObjImpl._headerFields.get(i).getName().equals(_fieldName)) return true;
        }
        return false;
    }
    protected boolean evalWhereClauseRequiresOnlyHeaderFields() {
        for (int i=0; i<ObjImpl._headerFields.size(); i++) {
            if (ObjImpl._headerFields.get(i).getName().equals(_fieldName)) return true;
        }
        return false;
    }


    protected void setMetaInfo(ObjMetaInfo metaInfo) {
        if (metaInfo==null) {
            _fieldMetaInfo = _unknownFieldMetaInfo;
        } else {
            _fieldMetaInfo = metaInfo.getFieldMetaInfo(_fieldName);
            if (_fieldMetaInfo==null)
                _fieldMetaInfo = _unknownFieldMetaInfo;
        }
        switch (_fieldMetaInfo.getType()) {
            case CHAR:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getChar(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getChar(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getChar(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getChar(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getChar(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getChar(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, obj.getChar(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, obj.getChar(_fieldName)), this); break;
                    default:
                }
                break;
            case STRING:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null && cmp(obj.getString(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null && cmp(obj.getString(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null && cmp(obj.getString(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null && cmp(obj.getString(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null && cmp(obj.getString(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null && cmp(obj.getString(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)==null, this); break;
                    case ISNOT: // is not null
                        _evalPredicate = predicateWrapper((obj) -> obj.getString(_fieldName)!=null, this); break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, obj.getString(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, obj.getString(_fieldName)), this); break;
                    default:
                }
                break;
            case SHORT:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_SHORT, obj.getShort(_fieldName)), this); break;
                    default:
                }
                break;
            case INT:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_INT, obj.getInt(_fieldName)), this); break;
                    default:
                }
                break;
            case LONG:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_LONG, obj.getLong(_fieldName)), this); break;
                    default:
                }
                break;
            case FLOAT:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_FLOAT, obj.getFloat(_fieldName)), this); break;
                    default:
                }
                break;
            case DOUBLE:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_DOUBLE, obj.getDouble(_fieldName)), this); break;
                    default:
                }
                break;
            case TIMESTAMP:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName), _leafValues.get(0))>=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_TIMESTAMP, obj.getTimestamp(_fieldName)), this); break;
                    default:
                }
                break;
            case NANOS:
                _evalPredicate = (obj) -> false; break; // NANOS fields are not supported in SQL expressions
            case TIME:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_TIME, obj.getTime(_fieldName)), this); break;
                    default:
                }
                break;
            case DATE:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> cmp(TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, TypeMetaInfo.TYPE_DATE, obj.getDate(_fieldName)), this); break;
                    default:
                }
                break;
            case BOOLEAN:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> cmp(obj.getBoolean(_fieldName), _leafValues.get(0)), this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> !cmp(obj.getBoolean(_fieldName), _leafValues.get(0)), this); break;
                    case LT:
                        _evalPredicate = (obj) -> false; break;
                    case LE:
                        _evalPredicate = (obj) -> false; break;
                    case GT:
                        _evalPredicate = (obj) -> false; break;
                    case GE:
                        _evalPredicate = (obj) -> false; break;
                    case IS: // is null
                        _evalPredicate = (obj) -> false; break;
                    case ISNOT: // is not null
                        _evalPredicate = (obj) -> true; break;
                    case IN:
                        _evalPredicate = (obj) -> false; break;
                    case NOTIN:
                        _evalPredicate = (obj) -> false; break;
                    default:
                }
                break;
            case ENUM:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null && cmp(obj.getEnum(_fieldName).toString(), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null && cmp(obj.getEnum(_fieldName).toString(), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null && cmp(obj.getEnum(_fieldName).toString(), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null && cmp(obj.getEnum(_fieldName).toString(), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null && cmp(obj.getEnum(_fieldName).toString(), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null && cmp(obj.getEnum(_fieldName).toString(), _leafValues.get(0))<=0, this); break;
                    case IS: // is null
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)==null, this); break;
                    case ISNOT: // is not null
                        _evalPredicate = predicateWrapper((obj) -> obj.getEnum(_fieldName)!=null, this); break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> contains(_leafValues, obj.getEnum(_fieldName).toString()), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !contains(_leafValues, obj.getEnum(_fieldName).toString()), this); break;
                    default:
                }
                break;
            case UNKNOWN:
                switch (_leafOp) {
                    case EQ:
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null && cmpAdHoc(obj.getAdHoc(_fieldName), _leafValues.get(0))==0, this); break;
                    case NE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null && cmpAdHoc(obj.getAdHoc(_fieldName), _leafValues.get(0))!=0, this); break;
                    case LT:
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null && cmpAdHoc(obj.getAdHoc(_fieldName), _leafValues.get(0))<0, this); break;
                    case LE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null && cmpAdHoc(obj.getAdHoc(_fieldName), _leafValues.get(0))<=0, this); break;
                    case GT:
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null && cmpAdHoc(obj.getAdHoc(_fieldName), _leafValues.get(0))>0, this); break;
                    case GE:
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null && cmpAdHoc(obj.getAdHoc(_fieldName), _leafValues.get(0))>=0, this); break;
                    case IS: // is null
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)==null, this); break;
                    case ISNOT: // is not null
                        _evalPredicate = predicateWrapper((obj) -> obj.getAdHoc(_fieldName)!=null, this); break;
                    case IN:
                        _evalPredicate = predicateWrapper((obj) -> containsAdHoc(_leafValues, obj.getAdHoc(_fieldName)), this); break;
                    case NOTIN:
                        _evalPredicate = predicateWrapper((obj) -> !containsAdHoc(_leafValues, obj.getAdHoc(_fieldName)), this); break;
                    default:
                }
                break;
        }
    }
}
