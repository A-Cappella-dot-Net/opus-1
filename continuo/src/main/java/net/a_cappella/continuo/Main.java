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

package net.a_cappella.continuo;

import org.springframework.context.support.ClassPathXmlApplicationContext;

public class Main {
    private static ClassPathXmlApplicationContext ctx;

    public static void main(String args[]) {
        String springFile = "app-spring.xml";
        if (args.length>=1) {
            springFile = args[0];
        }

        try {
            ctx = new ClassPathXmlApplicationContext(springFile);
            ShutdownHook.registerShutdownAction(() -> ctx.close());
        } catch (Exception x) {
            x.printStackTrace();
        }
    }
}
