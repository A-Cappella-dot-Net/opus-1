plugins {
    id("buildlogic.java-library-conventions")
    id("maven-publish")
}

val mockitoAgent = configurations.create("mockitoAgent")

evaluationDependsOn(":presto-test-agent")
evaluationDependsOn(":presto-test-agent-rt")

val proxyAgentJar    = files(project(":presto-test-agent").tasks.named("shadowJar"))
val proxyAgentRtJar  = files(project(":presto-test-agent-rt").tasks.named("jar"))

dependencies {
    api(project(":continuo")) {
        exclude(group = "org.slf4j", module = "slf4j-log4j12")
        exclude(group = "org.apache.logging.log4j", module = "log4j-core")
    }

    implementation(libs.slf4j)
    implementation(libs.log4j) // why exclude and then include back???

    implementation(libs.guava)
    implementation(libs.agrona)

    implementation(libs.trove)
    implementation(libs.jctools)

    testImplementation(libs.hdrhistogram)

    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")

    testImplementation(libs.mockito)
    mockitoAgent(libs.mockito) { isTransitive = false }

    testImplementation(project(":presto-test-agent-rt"))
}

tasks {
    test {
        useJUnitPlatform() {
            excludeTags("proxy-agent")
        }
        testLogging {
            events("passed", "skipped", "failed")
            showStandardStreams = true // To see Cucumber output
        }
        jvmArgs("-javaagent:${mockitoAgent.asPath}")
        jvmArgs("-Xshare:off")
    }
}

val proxyAgentTest = tasks.register<Test>("proxyAgentTest") {
    description = "Runs tests that require the socket-redirect Java agent."
    group = "verification"

    testClassesDirs = sourceSets["test"].output.classesDirs
    classpath       = sourceSets["test"].runtimeClasspath

    useJUnitPlatform {
        includeTags("proxy-agent")
    }

    dependsOn(proxyAgentJar, proxyAgentRtJar)

    // Order matters: install the proxy agent BEFORE Mockito's, so its
    // transformer is registered first. Byte Buddy's AgentBuilder is
    // additive, so this is mostly about deterministic ordering when both
    // touch the same class.
    jvmArgs("-javaagent:${proxyAgentJar.singleFile.absolutePath}")
    jvmArgs("-javaagent:${mockitoAgent.asPath}")
    jvmArgs("-Xbootclasspath/a:${proxyAgentRtJar.singleFile.absolutePath}")
    jvmArgs("-Xshare:off")

    // Byte Buddy needs to peek into sun.nio.ch to instrument SocketChannelImpl.
    jvmArgs(
        "--add-opens", "java.base/sun.nio.ch=ALL-UNNAMED",
        "--add-opens", "java.base/java.net=ALL-UNNAMED",
    )

    testLogging {
        showStandardStreams = true
        showExceptions = true
        showCauses = true
        showStackTraces = true
        exceptionFormat = org.gradle.api.tasks.testing.logging.TestExceptionFormat.FULL
        events("started", "passed", "skipped", "failed", "standardOut", "standardError")
    }

    shouldRunAfter(tasks.test)
}

tasks.check {
    dependsOn(proxyAgentTest)
}


publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            groupId = "net.a-cappella"
            artifactId = "presto"

            from(components["java"]) // Or "kotlin" for Kotlin projects
        }
    }
}
