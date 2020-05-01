load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

def graknlabs_build_tools():
    git_repository(
        name = "graknlabs_build_tools",
        remote = "https://github.com/graknlabs/build-tools",
        commit = "6cf8cad67fa232d020869fde84e56984bf36d5e7", # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_build_tools
    )

def graknlabs_common():
    git_repository(
        name = "graknlabs_common",
        remote = "https://github.com/graknlabs/common",
        tag = "0.2.2",  # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_common
    )

def graknlabs_graql():
    git_repository(
        name = "graknlabs_graql",
        remote = "https://github.com/graknlabs/graql",
        commit = "1c573108b3ab8505ab0168f146071fe032d62a61",  # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_graql
    )

def graknlabs_client_java():
    git_repository(
        name = "graknlabs_client_java",
        remote = "https://github.com/graknlabs/client-java",
        commit = "18c4f726ce7b32ae1b9c151794d1eed937898e23",  # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_client_java
    )

def graknlabs_grakn_core():
    git_repository(
        name = "graknlabs_grakn_core",
        remote = "https://github.com/graknlabs/grakn",  # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_grakn
        commit = "a950ed90cac3e4cbd1d338b13f7f33e5a6616a35",
    )

def graknlabs_console():
    git_repository(
        name = "graknlabs_console",
        remote = "https://github.com/graknlabs/console",
        tag = "1.0.5", # sync-marker: do not remove this comment, this is used for sync-dependencies by @graknlabs_console
    )
