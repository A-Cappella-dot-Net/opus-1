plugins {
    id("buildlogic.java-application-conventions")
    id("com.github.node-gradle.node") version "7.0.2"
}

dependencies {
    implementation(project(":madrigal"))

    implementation(libs.slf4j)
    implementation(libs.log4j)

    implementation(libs.apache.text)

    implementation(libs.java.websocket)
    implementation(libs.gson)
    implementation(libs.jetty.server)
    implementation(libs.jetty.server.websocket)
}

tasks.test {
    useJUnitPlatform()
}

// ============================================================
// React Build Configuration
// ============================================================

node {
    download = true
    version = "20.11.0"
    npmVersion = "10.2.4"
    workDir = file("${project.projectDir}/.gradle/nodejs")
    npmWorkDir = file("${project.projectDir}/.gradle/npm")
    nodeProjectDir = file("${project.projectDir}/frontend")
}

// The plugin automatically creates these tasks:
// - npmInstall (don't create it!)
// - npm_run_build (for "npm run build")

// Task: Build React application using the plugin's npm_run_build
val buildReact by tasks.registering(com.github.gradle.node.npm.task.NpmTask::class) {
    description = "Build React production bundle"
    group = "react"

    // Plugin's npmInstall is automatically a dependency
    dependsOn(tasks.named("npmInstall"))

    workingDir = file("${project.projectDir}/frontend")
    args = listOf("run", "build")

    inputs.dir("${project.projectDir}/frontend/src")
    inputs.dir("${project.projectDir}/frontend/public")
    inputs.file("${project.projectDir}/frontend/package.json")
    inputs.file("${project.projectDir}/frontend/package-lock.json")
    outputs.dir("${project.projectDir}/frontend/build")
}

// Task: Copy React build to resources
val copyReactBuild by tasks.registering(Copy::class) {
    description = "Copy React build to src/main/resources/static"
    group = "react"

    dependsOn(buildReact)
    from("${project.projectDir}/frontend/build")
    into("${project.projectDir}/src/main/resources/static")
}

// Task: Clean React build artifacts
val cleanReact by tasks.registering(Delete::class) {
    description = "Clean React build artifacts"
    group = "react"

    delete("${project.projectDir}/frontend/build")
    delete("${project.projectDir}/frontend/node_modules")
    delete("${project.projectDir}/src/main/resources/static")
}

// ============================================================
// Integrate React build with Java build process
// ============================================================

// Automatically build React when processing resources
tasks.processResources {
    dependsOn(copyReactBuild)
}

// Clean React when cleaning Java
tasks.clean {
    dependsOn(cleanReact)
}
