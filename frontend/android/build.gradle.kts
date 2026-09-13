buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath(files("kotlin-gradle-plugin-2.0.20-gradle85.jar"))
        classpath(files("kotlin-compiler-embeddable-2.0.20.jar"))
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}