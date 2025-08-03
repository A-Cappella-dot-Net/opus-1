package net.a_cappella.continuo;

import net.openhft.affinity.AffinityLock;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.lang.management.GarbageCollectorMXBean;
import java.lang.management.ManagementFactory;
import java.lang.management.RuntimeMXBean;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

public class ProcessInfo {
    private static final Logger log = LoggerFactory.getLogger(ProcessInfo.class);

    private boolean isEnvVarOfInterest(String env) {
        return "LD_PRELOAD".equals(env) || env.startsWith("EF_");
    }

    public void logProcessInfo() {
        log.info(getCpuInfo());
        log.info(getOsInfo());

        for (Map.Entry<String, String> entry : System.getenv().entrySet())
            if (isEnvVarOfInterest(entry.getKey()))
                log.info("ENV: " + entry.getKey() + "=" + entry.getValue());

        log.info("JAVA VERSION: " + getJavaVersion());
        log.info("VM VERSION: " + getVmVersion());
        for (String vmarg : getVmArgs()) {
            log.info("VM ARG: " + vmarg);
        }
        log.info("PROGRAM ARGS: " + getProgramArgs());
        for (String gcEntry : getGcArgs()) {
            log.info(gcEntry);
        }

        for (String cpEntry : getClassPath()) {
            log.info("CP: " + cpEntry);
        }
        log.info("PID: " + getProcessId());
        log.info("MAX HEAP: " + getMaxHeapSize());
    }

    private String getCpuInfo() {
        return "CPU layout:\n" + AffinityLock.cpuLayout();
    }
    private String getOsInfo() {
        return
                "OS name: " + System.getProperty("os.name") + ", " +
                        "Architecture: " + System.getProperty("os.arch") + ", " +
                        "Version: " + System.getProperty("os.version");
    }
    private String getJavaVersion() {
        return System.getProperty("java.version");
    }
    private String getVmVersion() {
        return ManagementFactory.getRuntimeMXBean().getSpecVersion();
    }
    private String getProgramArgs() {
        return System.getProperty("sun.java.command");
    }
    private List<String> getVmArgs() {
        RuntimeMXBean bean = ManagementFactory.getRuntimeMXBean();
        return bean.getInputArguments();
    }
    private List<String> getGcArgs() {
        List<GarbageCollectorMXBean> beans = ManagementFactory.getGarbageCollectorMXBeans();
        return beans.stream().map(bean -> "GC: "+bean.getName()+" count="+bean.getCollectionCount()+" time="+bean.getCollectionTime()).collect(Collectors.toList());
    }


    private String getProcessId() {
        String pid = ManagementFactory.getRuntimeMXBean().getName();
        if (pid.contains("@")) pid = pid.substring(0, pid.indexOf("@"));
        return pid;
    }
    private List<String> getClassPath() {
        String classpath = System.getProperty("java.class.path");
        String[] classpathArr = new String[0];
        if (classpath.contains(";")) {
            classpathArr = classpath.split(";");
        } else if (classpath.contains(":")) {
                classpathArr = classpath.split(":");
        }
        return Arrays.asList(classpathArr);
    }

    private String getMaxHeapSize() {
        long heapMaxSize = Runtime.getRuntime().maxMemory();
        return formatSize(heapMaxSize);
    }

    public static String formatSize(long v) {
        if (v < 1024) return v + " B";
        int z = (63 - Long.numberOfLeadingZeros(v)) / 10;
        return String.format("%.1f %sB", (double)v / (1L << (z*10)), " KMGTPE".charAt(z));
    }
}
