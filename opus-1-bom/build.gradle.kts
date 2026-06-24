plugins {
    `java-platform`
    `maven-publish`
}

group = rootProject.group
version = rootProject.version as String

javaPlatform {
    allowDependencies()
}

dependencies {
    constraints {
        api(project(":continuo"))
        api(project(":cembalo"))
        api(project(":presto"))
        api(project(":presto-aeron"))
        api(project(":madrigal-common"))
        api(project(":madrigal-aeron"))
        api(project(":madrigal"))
    }
}

publishing {
    publications {
        create<MavenPublication>("mavenBom") {
            groupId = rootProject.group as String
            artifactId = "opus-1-bom"
            from(components["javaPlatform"])
        }
    }
}
