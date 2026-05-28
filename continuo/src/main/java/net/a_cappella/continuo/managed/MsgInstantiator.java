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

package net.a_cappella.continuo.managed;

import java.lang.reflect.Constructor;
import java.util.Arrays;
import java.util.List;

import net.a_cappella.continuo.ObjPriority;
import net.a_cappella.continuo.msg.ITypedMsg;
import net.a_cappella.continuo.obj.Coder;
import net.a_cappella.continuo.obj.Obj;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MsgInstantiator {
    private static final Logger log = LoggerFactory.getLogger(MsgInstantiator.class);

    private int _objType;
    public int getObjType() {
        return _objType;
    }
    private String _className;
    private Class<?>[] _argTypes;
    private List<String> _argClassNames;
    private Object[] _args;
    private Constructor<?> _ctor;

    private Class<?> _class;
    public Class<?> getMsgClass() {
        return _class;
    }

    private boolean _allGood = true;
    public boolean allGood() {
        return _allGood;
    }

    public <T> T newInstance() {
        if (!_allGood) throw new RuntimeException("Error creating new instance of type " + _objType + " and className " + _className);
        try {
            return (T) ((_args==null)?_ctor.newInstance():_ctor.newInstance(_args));
        } catch (Exception e) {
            String msg = "Error creating new instance of type " + _objType + " and className " + _className;
            log.error(msg, e);
            _allGood = false;
            throw new RuntimeException(msg, e);
        }
    }

    public MsgInstantiator(String className) throws Exception {
        this(className, null, ObjPriority.REG_PRI);
    }
    public MsgInstantiator(String className, String codClassName) throws Exception {
        this(className, codClassName, ObjPriority.REG_PRI);
    }
    public MsgInstantiator(String className, String codClassName, ObjPriority priority) {
        _className = className;
        _argClassNames = null;
        _argTypes = null;
        _args = null;

        try {
            _class = Class.forName(_className);
            _ctor = _class.getConstructor();

            Constructor<? extends Coder> coderConstructor = initCodCtor(codClassName);
            Object msg = newInstance(); // throw away instance; just check all is well
            if (_allGood) {
                if (msg instanceof ITypedMsg) _objType = ((ITypedMsg) msg).getMsgType();
                if (msg instanceof Obj) ((Obj) msg).setStaticFields(coderConstructor, priority);
            }
        } catch (Exception e) {
            log.error(className + " " + codClassName, e);
            _allGood = false;
        }
    }

    public MsgInstantiator(String className, List<String> argClassNames, List<Object> args) throws Exception {
        this(className, null, null, argClassNames, args);
    }
    public MsgInstantiator(String className, String codClassName, ObjPriority priority, List<String> argClassNames, List<Object> args) {
        if (argClassNames.size() != args.size()) {
            log.error("MsgInstantiator argClassNames="+argClassNames+" and args="+args+" do NOT have the SAME size; ignoring...");
            _allGood = false;
            return;
        }

        _className = className;
        _argClassNames = argClassNames;
        _argTypes = new Class<?>[argClassNames.size()];
        _args = new Object[argClassNames.size()];

        try {
            _class = Class.forName(_className);

            for (int i=0; i<argClassNames.size(); i++) {
                String argClassName = argClassNames.get(i);
                if ("int".equals(argClassName)) {
                    _argTypes[i] = int.class;
                    _args[i] = Integer.valueOf((String) args.get(i));
                } else if ("Integer".equals(argClassName) || "java.lang.Integer".equals(argClassName)) {
                    _argTypes[i] = Integer.class;
                    _args[i] = Integer.valueOf((String) args.get(i));
                } else {
                    _argTypes[i] = Class.forName(argClassName);
                    _args[i] = args.get(i);
                }
            }

            _ctor = _class.getConstructor(_argTypes);

            Constructor<? extends Coder> coderConstructor = initCodCtor(codClassName);
            Object msg = newInstance(); // throw away instance; just check all is well
            if (_allGood) {
                if (msg instanceof ITypedMsg) _objType = ((ITypedMsg) msg).getMsgType();
                if (msg instanceof Obj) ((Obj) msg).setStaticFields(coderConstructor, priority);
            }
        } catch (Exception e) {
            log.error(className + " " + codClassName, e);
            _allGood = false;
        }
    }


    private Constructor<? extends Coder> initCodCtor(String codClassName) throws Exception {
        if (codClassName == null) return null;
        Class<?> clazz = Class.forName(codClassName);
        return (Constructor<? extends Coder>) clazz.getConstructor();
    }

    @Override
    public String toString() {
        return _objType + ":" + _className+
                (_argClassNames==null?"":(" "+_argClassNames+" "+Arrays.toString(_args)));
    }
}
