import org.apache.tools.ant.filters.FixCrLfFilter

plugins {
    // Apply the common convention plugin for shared build configuration between library and application projects.
    id("buildlogic.java-common-conventions")

    // Apply the application plugin to add support for building a CLI application in Java.
    // application

    id("maven-publish")
}

version = "1.0.0-SNAPSHOT"
group = "net.a-cappella"

fun octalToHexMode(octal: Int): Int {
    return Integer.parseInt(octal.toString(), 8)
}

val zipAssembly by tasks.registering(Zip::class) {
    archiveBaseName.set(project.name)
    archiveVersion.set(project.version.toString())
    destinationDirectory.set(layout.buildDirectory.dir("dist"))

    from("README")

    from("bin") {
        include("*.cmd")
        into("bin")
        filter(FixCrLfFilter::class, "eol" to FixCrLfFilter.CrLf.newInstance("crlf"))
    }
    from("app") {
        into("app")
    }
    from("config") {
        into("config")
    }
    from(tasks.jar.flatMap { it.archiveFile }) {
        into("lib")
    }
    from({
        configurations.runtimeClasspath.get().filter { it.name.endsWith(".jar") }
    }) {
        into("lib/dependencies")
    }
//    from("target/boot") {
//        include("**/*")
//        into("lib/boot")
//    }
}

val tarAssembly by tasks.registering(Tar::class) {
    archiveBaseName.set(project.name)
    archiveVersion.set(project.version.toString())
    archiveExtension.set("tar.gz")
    destinationDirectory.set(layout.buildDirectory.dir("dist"))
    compression = Compression.GZIP

    into (project.name+"-"+project.version) {

        from("README")

        from("bin") {
            include("*.sh")
            into("bin")
            filter(FixCrLfFilter::class, "eol" to FixCrLfFilter.CrLf.newInstance("lf"))
            fileMode = octalToHexMode(755)
        }
        from("app") {
            into("app")
        }
        from("config") {
            into("config")
        }
        from(tasks.jar.flatMap { it.archiveFile }) {
            into("lib")
        }
        from({
            configurations.runtimeClasspath.get().filter { it.name.endsWith(".jar") }
        }) {
            into("lib/dependencies")
        }
//        from("target/boot") {
//            include("**/*")
//            into("lib/boot")
//        }
    }

 }

artifacts {
    add("archives", zipAssembly)
    add("archives", tarAssembly)
}

publishing {
    publications {
        create<MavenPublication>("assemblyZip") {
            artifact(zipAssembly.get().archiveFile.get()) {
                classifier = "zip-assembly"
                extension = "zip"
            }
        }
        create<MavenPublication>("assemblyTar") {
            artifact(tarAssembly.get().archiveFile.get()) {
                classifier = "tar-assembly"
                extension = "tar.gz"
            }
        }
    }
    repositories {
        mavenLocal()
    }
}

tasks.named("publishAssemblyZipPublicationToMavenLocal") {
    dependsOn(tasks.named("zipAssembly"))
}

tasks.named("publishAssemblyTarPublicationToMavenLocal") {
    dependsOn(tasks.named("tarAssembly"))
}
