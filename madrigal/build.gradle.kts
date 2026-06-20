plugins {
    id("buildlogic.java-library-conventions")
    id("maven-publish")
}

val mockitoAgent = configurations.create("mockitoAgent")

dependencies {
    api(project(":madrigal-aeron")) {
        exclude(group = "org.slf4j", module = "slf4j-log4j12")
        exclude(group = "org.apache.logging.log4j", module = "log4j-core")
    }

    implementation(libs.slf4j)
    implementation(libs.log4j) // why exclude and then include back???

    implementation(libs.guava)

    implementation(libs.trove)

    implementation(libs.spring.framework)

    testImplementation(platform(libs.cucumber.bom))
    testImplementation("io.cucumber:cucumber-java")
    testImplementation("io.cucumber:cucumber-junit-platform-engine")

    testImplementation(platform(libs.junit.bom))
    testImplementation("org.junit.platform:junit-platform-suite-engine")
    testImplementation("org.junit.jupiter:junit-jupiter")

    testImplementation(libs.mockito)
    mockitoAgent(libs.mockito) { isTransitive = false }
}

tasks {
    test {
        useJUnitPlatform()
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
            artifactId = "madrigal"
            version = "1.0.0-SNAPSHOT" // or dynamic version as above

            from(components["java"]) // Or "kotlin" for Kotlin projects
        }
    }
}
