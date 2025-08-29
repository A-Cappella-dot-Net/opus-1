plugins {
    // Apply the foojay-resolver plugin to allow automatic download of JDKs
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.10.0"
}

rootProject.name = "opus-1"

include("continuo")
include("cembalo")
include("exchange")
include("presto")
include("presto-aeron")
include("daemons-aeron")
include("test-presto")
include("madrigal-common")
include("madrigal-aeron")
include("madrigal")
include("credentials")
include("data-subscriber")
include("data-publisher")
include("m-cache")