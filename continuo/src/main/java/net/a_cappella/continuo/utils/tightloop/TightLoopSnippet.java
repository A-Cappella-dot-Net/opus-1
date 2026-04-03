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

package net.a_cappella.continuo.utils.tightloop;

public interface TightLoopSnippet {
    /**
     * Snippet logic.
     * @return workCount (>=0 how much work has been done)
     *         or <0 if the snippet wants to stop participating in the tight loop
     * @throws Exception
     */
    int executeSnippet() throws Exception;
}
