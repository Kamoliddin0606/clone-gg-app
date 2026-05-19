allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// AGP 8.x requires every Android library to declare `namespace` in its
// build.gradle. A handful of pub packages still ship pre-AGP-8 manifests
// (notably `flutter_jailbreak_detection` 1.10.0, which only sets the
// legacy `<manifest package=...>` attribute). Until those packages cut
// a fix release we synthesise the namespace from the package's group so
// `flutter build apk` doesn't fail with `Namespace not specified`.
//
// Registered before `evaluationDependsOn(":app")` because Gradle forbids
// `afterEvaluate` once a project has already been evaluated.
subprojects {
    afterEvaluate {
        if (extensions.findByName("android") != null) {
            extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                if (namespace.isNullOrBlank()) {
                    namespace = group.toString()
                }
                // Pin every Android module to Java 17 + Kotlin JVM 17.
                // `flutter_jailbreak_detection` 1.10.0 ships Kotlin
                // targeting JVM 21 while AGP defaults Java to 1.8,
                // which fails the JVM-target consistency check. Forcing
                // 17 across the board keeps Flutter's own Java 17
                // toolchain happy and stops one straggler package from
                // breaking the assemble.
                compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
            tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
