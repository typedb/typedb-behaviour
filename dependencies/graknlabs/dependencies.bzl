load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def graknlabs_dependencies():
    git_repository(
        name = "graknlabs_dependencies",
        remote = "https://github.com/lolski/dependencies",
        commit = "79c216d01b370efef02aaf31b087adeb26f1854c", # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_build_tools
    )

def graknlabs_common():
    git_repository(
        name = "graknlabs_common",
        remote = "https://github.com/lolski/common",
        commit = "60c5f9b2929452ba3011e6bc2f8e67da645eeee1",  # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_common
    )

def graknlabs_graql():
    git_repository(
        name = "graknlabs_graql",
        remote = "https://github.com/lolski/graql",
        commit = "0a46b5da5fb09756299057010d65f6d563bb5210",
    )

def graknlabs_client_java():
    git_repository(
        name = "graknlabs_client_java",
        remote = "https://github.com/graknlabs/client-java",
        commit = "a94e7eaa96795f515598321ad23ac9b59b03aefa",
    )

def graknlabs_grakn_core():
    git_repository(
        name = "graknlabs_grakn_core",
        remote = "https://github.com/graknlabs/grakn",
        commit = "5bdba205c4cc6cdc06ee76c5177d9386c6431d84",
    )
