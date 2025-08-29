plugins {
    id("buildlogic.java-application-conventions")
}

dependencies {
    implementation(project(":madrigal"))

    implementation(libs.slf4j)
    implementation(libs.log4j)

    implementation(libs.spring.framework)
}
