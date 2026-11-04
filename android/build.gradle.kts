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

// 👇 THIS IS THE NEW FIX 👇
subprojects {
    // We use the 'plugins.withId' block so it only runs if the Android plugin is actually applied
    plugins.withId("com.android.library") {
        val androidExtension = extensions.getByName("android") as com.android.build.gradle.LibraryExtension
        if (androidExtension.namespace == null) {
            androidExtension.namespace = "com.example.${project.name}"
        }
    }
    plugins.withId("com.android.application") {
        val androidExtension = extensions.getByName("android") as com.android.build.gradle.AppExtension
        if (androidExtension.namespace == null) {
            androidExtension.namespace = "com.example.${project.name}"
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}