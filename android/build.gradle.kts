allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// flutter_jailbreak_detection 1.10.0 (root/jailbreak check at visit start)
// pulls com.github.scottyab:rootbeer:0.1.0 from JitPack (declared `strictly`
// inside the plugin's own Gradle module). That AAR bundles a native
// libtoolChecker.so aligned to 4 KB, which trips Android 15's 16 KB page-size
// compatibility check ("ELF alignment check failed").
//
// The official Maven Central artifact com.scottyab:rootbeer-lib:0.1.2 is built
// from the same source (identical com.scottyab.rootbeer.* API) but ships a
// 16 KB-aligned native lib. The plugin is unmaintained (last release 1.10.0),
// so substitute the JitPack module for the aligned Maven Central one across
// every subproject. dependencySubstitution overrides even the `strictly`
// constraint, which a plain resolutionStrategy.force would not.
subprojects {
    configurations.all {
        resolutionStrategy.dependencySubstitution {
            substitute(module("com.github.scottyab:rootbeer"))
                .using(module("com.scottyab:rootbeer-lib:0.1.2"))
                .because("rootbeer 0.1.0 ships a 4 KB-aligned libtoolChecker.so; rootbeer-lib 0.1.2 is 16 KB aligned (Android 15)")
        }
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
