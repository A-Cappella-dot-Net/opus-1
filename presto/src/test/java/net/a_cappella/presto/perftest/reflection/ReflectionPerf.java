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

package net.a_cappella.presto.perftest.reflection;

/**
 * This test is used to determine setting values in class objects via reflection vs via setters vs direct.
 *
 * The results show that setting values directly and via setters are equivalent performance wise.
 * And setting the value via Field reflection is twice as slow as via direct.
 *
 */
public class ReflectionPerf {
    // https://www.azul.com/presentation/the-art-of-java-benchmarking/
    private static final int N = 10_000_000;
    private static final Bean d = new Bean();

    static long testSet(Bench b) {
        long start = System.nanoTime();
        for (long i = 0; i < N; i++) {
            b.setValue(d, i);
        }
        return (System.nanoTime() - start) / 1_000_000;
    }

    static long testGet(Bench b) {
        long start = System.nanoTime();
        for (long i = 0; i < N; i++) {
            b.getValue(d);
        }
        return (System.nanoTime() - start) / 1_000_000;
    }

    public static void main(String[] args) {
        // warmup loop
        for (int i = 0; i < 10; i++) {
            testSet(new Bench1());
            testSet(new Bench2());
            testSet(new Bench3());
            testSet(new Bench13());
            testSet(new Bench23());
        }

        System.out.println(testSet(new Bench1()));
        System.out.println(testSet(new Bench2()));
        System.out.println(testSet(new Bench3()));
        System.out.println(testSet(new Bench13()));
        System.out.println(testSet(new Bench23()));

        // warmup loop
        for (int i = 0; i < 10; i++) {
            testGet(new Bench1());
            testGet(new Bench2());
            testGet(new Bench3());
            testGet(new Bench13());
            testGet(new Bench23());
        }

        System.out.println(testGet(new Bench1()));
        System.out.println(testGet(new Bench2()));
        System.out.println(testGet(new Bench3()));
        System.out.println(testGet(new Bench13()));
        System.out.println(testGet(new Bench23()));
    }
}
