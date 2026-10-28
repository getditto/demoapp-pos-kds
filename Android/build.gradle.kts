// Top-level build file where you can add configuration options common to all sub-projects/modules.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.google.dagger.hilt.android) apply false
    alias(libs.plugins.ktlint) apply false
    alias(libs.plugins.android.legacy.kapt) apply false
    alias(libs.plugins.kotlin.plugin.compose) apply false
}

val deletePreviousGitHOok = tasks.register<Delete>("deletePreviousGitHOok") {
    group = "utils"
    description = "Deleting previous githook"

    val preCommit = "${rootProject.rootDir}/../.git/hooks/pre-commit"
    if (file(preCommit).exists()) {
        delete(preCommit)
    }
}

tasks.register<Copy>("installGitHook") {
    dependsOn(deletePreviousGitHOok)

    from(File(rootProject.rootDir, "git_hooks/pre-commit").absolutePath)
    into(File(rootProject.rootDir, "../.git/hooks").absolutePath)
    filePermissions { unix("rwxr-xr-x") }
}

tasks.getByPath(":app:preBuild").dependsOn(":installGitHook")
