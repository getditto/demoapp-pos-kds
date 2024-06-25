// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.jetbrains.kotlin.android) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.google.dagger.hilt.android) apply false
    alias(libs.plugins.jetbrains.kotlin.kapt) apply false
    alias(libs.plugins.ktlint) apply false

}

val deletePreviousGitHOok by tasks.registering(Delete::class) {
    group = "utils"
    description = "Deleting previous githook"

    val preCommit = "${rootProject.rootDir}/../.git/hooks/pre-commit"
    if (file(preCommit).exists()) {
        delete(preCommit)
    }
}

task("installGitHook", Copy::class) {
    dependsOn(deletePreviousGitHOok)

    from(File(rootProject.rootDir, "git_hooks/pre-commit").absolutePath)
    into(File(rootProject.rootDir, "../.git/hooks").absolutePath)
    fileMode = 0b111101101 // 0777
}

tasks.getByPath(":app:preBuild").dependsOn(":installGitHook")