allprojects {
    repositories {
        google()
        mavenCentral()
        
        // ХАК ДЛЯ KOTLIN DSL: Перехватываем запросы к умершему jcenter() 
        // и принудительно перенаправляем их на рабочее зеркало MavenCentral
        maven {
            url = uri("https://repo.maven.apache.org/maven2/")
            // Говорим Gradle, что этот репозиторий заменяет собой jcenter
            metadataSources {
                mavenPom()
                artifact()
            }
        }
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