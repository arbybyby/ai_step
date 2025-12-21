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

// Fix for health plugin namespace issue
gradle.beforeProject {
    if (project.name == "health") {
        val healthBuildFile = project.projectDir.resolve("build.gradle")
        if (healthBuildFile.exists()) {
            var content = healthBuildFile.readText()
            if (!content.contains("namespace")) {
                content = content.replace(
                    "android {",
                    "android {\n    namespace 'cachet.plugins.health'"
                )
                healthBuildFile.writeText(content)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Force consistent JVM target for all subprojects after they are evaluated
gradle.projectsEvaluated {
    allprojects {
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
