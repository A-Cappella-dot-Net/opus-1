plugins {
    id("buildlogic.java-library-conventions")
}

dependencies {
    implementation(libs.slf4j) // TODO CVE-2019-17571 9.8
    implementation(libs.log4j)
    implementation(libs.spring.framework)

    implementation(libs.hdrhistogram)
    implementation(libs.affinity) {
        exclude(group = "org.slf4j", module = "slf4j-api")
    }
    implementation(libs.agrona)
    implementation(libs.trove)
}
