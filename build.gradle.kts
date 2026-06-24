plugins {
    id("pl.allegro.tech.build.axion-release") version "1.21.2"
}

scmVersion {
    tag {
        prefix.set("v")
    }
}

version = scmVersion.version
group = "net.a-cappella"

subprojects {
    version = rootProject.version
    group = rootProject.group
}
