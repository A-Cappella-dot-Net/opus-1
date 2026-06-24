pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

plugins {
    // Apply the foojay-resolver plugin to allow automatic download of JDKs
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.10.0"
}

rootProject.name = "opus-1"

include("opus-1-bom")
include("continuo")
include("cembalo")
include("exchange")
include("presto")
include("presto-aeron")
include("daemons-aeron")
include("madrigal-common")
include("madrigal-aeron")
include("madrigal")
include("credentials")
include("data-subscriber")
include("data-publisher")
include("m-cache")
include("test-presto")
include("test-madrigal")
include("sys")
include("serializer")
include("mid-feed")
include("market-maker")
include("lh")
include("dev-tools")
include("presto-test-agent")
include("presto-test-agent-rt")