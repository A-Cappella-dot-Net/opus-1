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

package net.a_cappella.presto.testagent;

import java.lang.instrument.Instrumentation;
import net.bytebuddy.agent.builder.AgentBuilder;
import net.bytebuddy.asm.Advice;
import net.bytebuddy.matcher.ElementMatchers;

public final class ProxyAgent {

    public static void premain(String args, Instrumentation inst) {
        install(inst);
    }

    public static void agentmain(String args, Instrumentation inst) {
        install(inst);
    }

    private static void install(Instrumentation inst) {
        new AgentBuilder.Default()
                .disableClassFormatChanges()
                .with(AgentBuilder.RedefinitionStrategy.RETRANSFORMATION)
                .ignore(ElementMatchers.none())   // do NOT ignore JDK classes
                .type(ElementMatchers.named("sun.nio.ch.SocketChannelImpl"))
                .transform((builder, type, cl, module, pd) ->
                        builder.visit(
                                Advice.to(ConnectRedirectAdvice.class)
                                        .on(ElementMatchers.named("connect")
                                                .and(ElementMatchers.takesArguments(java.net.SocketAddress.class)))
                        )
                )
                .installOn(inst);
    }

    private ProxyAgent() {}
}