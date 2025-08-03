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
