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

subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val android = project.property("android")
            try {
                val method = android?.javaClass?.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                method?.invoke(android, 34)
            } catch (_: Throwable) {
                try {
                    val method = android?.javaClass?.getMethod("compileSdkVersion", String::class.java)
                    method?.invoke(android, "android-34")
                } catch (_: Throwable) {}
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
