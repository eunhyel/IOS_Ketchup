import com.android.build.gradle.LibraryExtension

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
// isar_flutter_libs 는 compileSdkVersion 30 고정 → androidx 리소스의 android:attr/lStar 링크 실패.
// Groovy apply plugin 이라 plugins.withId 타이밍으로는 안 올라가므로 afterEvaluate 로 덮어씀.
subprojects {
    afterEvaluate {
        val androidLib = project.extensions.findByType(LibraryExtension::class.java) ?: return@afterEvaluate
        val cur = androidLib.compileSdk
        if (cur != null && cur < 34) {
            androidLib.compileSdk = 34
        } else if (cur == null) {
            androidLib.compileSdk = 34
        }
        if (project.name == "isar_flutter_libs") {
            val ns = androidLib.namespace
            if (ns.isNullOrEmpty()) {
                androidLib.namespace = "dev.isar.isar_flutter_libs"
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
