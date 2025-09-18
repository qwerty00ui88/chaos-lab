plugins {
    java
    // TODO: add Spring Boot plugin when services are implemented.
}

allprojects {
    group = "org.chaoslab"
    version = "0.0.1-SNAPSHOT"

    repositories {
        mavenCentral()
    }
}

subprojects {
    apply(plugin = "java")

    tasks.withType<JavaCompile>().configureEach {
        sourceCompatibility = "17"
        targetCompatibility = "17"
    }
}
