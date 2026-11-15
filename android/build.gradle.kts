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

// Funzione sicura per forzare compileSdk = 36 su tutti i sotto-progetti (plugin)
fun forceCompileSdk36(proj: Project) {
    proj.extensions.findByName("android")?.let { extension ->
        try {
            val method = extension.javaClass.getMethod("compileSdk", Int::class.javaPrimitiveType)
            method.invoke(extension, 36)
        } catch (e: Exception) {
            try {
                val method = extension.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(extension, 36)
            } catch (ignored: Exception) {}
        }
    }
}

subprojects {
    try {
        afterEvaluate {
            forceCompileSdk36(this)
        }
    } catch (e: Exception) {
        // Se il progetto è già stato valutato, lo applica subito
        forceCompileSdk36(this)
    }
}