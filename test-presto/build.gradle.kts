plugins {
    id("buildlogic.java-application-conventions")
}

dependencies {
    implementation(project(":presto-aeron"))

    implementation(libs.slf4j)
    implementation(libs.log4j) // why exclude and then include back???

    implementation(libs.guava)
    implementation(libs.hdrhistogram)
}
