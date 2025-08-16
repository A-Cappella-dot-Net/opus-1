plugins {
    id("buildlogic.java-library-conventions")
    id("maven-publish")
}

val mockitoAgent = configurations.create("mockitoAgent")

val sbeOutputDir = layout.buildDirectory.dir("generated-sources")

sourceSets["main"].java.srcDir(sbeOutputDir)

val generateSbeSources by tasks.registering(JavaExec::class) {
    group = "code generation"
    description = "Generates Java sources from SBE schema"

    classpath = configurations.runtimeClasspath.get()
    mainClass.set("uk.co.real_logic.sbe.SbeTool")
    jvmArgs = listOf(
        "-Dsbe.output.dir=${sbeOutputDir.get()}",
        "-Dsbe.xinclude.aware=true",
        "-Dsbe.java.generate.interfaces=true"
    )
    args = listOf(
        "$projectDir/src/main/resources/sbe/schema.xml"
    )

    outputs.upToDateWhen { false }
}

tasks.compileJava {
    dependsOn(generateSbeSources)
}

dependencies {
    api(project(":presto")) {
        exclude(group = "org.slf4j", module = "slf4j-log4j12")
        exclude(group = "org.apache.logging.log4j", module = "log4j-core")
    }

    implementation(libs.slf4j)
    implementation(libs.log4j) // why exclude and then include back???

    implementation(libs.trove)

    implementation(libs.affinity)
    implementation(libs.sbe)
    implementation(libs.aeron)

    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")

    testImplementation(libs.mockito)
    mockitoAgent(libs.mockito) { isTransitive = false }
}



tasks {
    test {
        useJUnitPlatform()
        jvmArgs(
            "--add-opens", "java.base/sun.nio.ch=ALL-UNNAMED"
        )
        testLogging {
            events("passed", "skipped", "failed")
            showStandardStreams = true // To see Cucumber output
        }
        jvmArgs("-javaagent:${mockitoAgent.asPath}")
        jvmArgs("-Xshare:off")
    }
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            groupId = "net.a-cappella"
            artifactId = "presto-aeron"
            version = "1.0.0-SNAPSHOT" // or dynamic version as above

            from(components["java"]) // Or "kotlin" for Kotlin projects
        }
    }
}
