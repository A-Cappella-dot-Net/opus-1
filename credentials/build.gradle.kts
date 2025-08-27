plugins {
    id("buildlogic.java-application-conventions")
}

dependencies {
    implementation(project(":madrigal"))

    implementation(libs.slf4j)
    implementation(libs.log4j) // why exclude and then include back???
}
