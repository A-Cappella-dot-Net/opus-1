plugins {
    id("buildlogic.java-library-conventions")
    id("maven-publish")
}

val mockitoAgent = configurations.create("mockitoAgent")

dependencies {
    api(project(":presto")) {
        exclude(group = "org.slf4j", module = "slf4j-log4j12")
        exclude(group = "org.apache.logging.log4j", module = "log4j-core")
    }

    implementation(libs.slf4j)
    implementation(libs.log4j) // why exclude and then include back???

    implementation(libs.guava)

    implementation(libs.spring.framework)

    testImplementation(platform("org.junit:junit-bom:5.10.0"))
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
            artifactId = "madrigal-common"

            from(components["java"]) // Or "kotlin" for Kotlin projects
        }
    }
}
