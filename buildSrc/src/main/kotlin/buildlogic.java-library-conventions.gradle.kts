plugins {
    // Apply the common convention plugin for shared build configuration between library and application projects.
    id("buildlogic.java-common-conventions")

    // Apply the java-library plugin for API and implementation separation.
    `java-library`
}

version = "1.0.0-SNAPSHOT"
group = "net.a-cappella"

