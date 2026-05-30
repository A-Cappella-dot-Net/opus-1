plugins {
    id("buildlogic.java-library-conventions")
    id("com.gradleup.shadow") version "8.3.5"
}

dependencies {
    compileOnly(project(":presto-test-agent-rt"))
    compileOnly(libs.byte.buddy)
    compileOnly(libs.byte.buddy.agent)
}

tasks.shadowJar {
    configurations = listOf(project.configurations.compileClasspath.get())
    archiveClassifier.set("agent")
    mergeServiceFiles()
    relocate("net.bytebuddy", "net.a_cappella.presto.testagent.shaded.bytebuddy")

    dependencies {
        exclude(project(":presto-test-agent-rt"))
    }

    manifest {
        attributes(
            "Premain-Class"            to "net.a_cappella.presto.testagent.ProxyAgent",
            "Agent-Class"              to "net.a_cappella.presto.testagent.ProxyAgent",
            "Can-Redefine-Classes"     to "true",
            "Can-Retransform-Classes"  to "true"
        )
    }
}

// Make `build` produce the shaded jar and nothing else.
tasks.assemble {
    dependsOn(tasks.shadowJar)
}