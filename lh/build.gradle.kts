plugins {
    id("buildlogic.java-application-conventions")
}

dependencies {
    implementation(project(":madrigal"))

    implementation(project(":cembalo")) {
        exclude(group = "org.slf4j", module = "slf4j-log4j12")
        exclude(group = "org.apache.logging.log4j", module = "log4j-core")
    }

    implementation(libs.slf4j)
    implementation(libs.log4j)
}
