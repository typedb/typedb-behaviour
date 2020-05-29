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
        remote = "https://github.com/flyingsilverfin/graql",
        commit = "4a18ef735004c1a7c82c6dddff5cc79dfd557070",
    )

def graknlabs_client_java():
    git_repository(
        name = "graknlabs_client_java",
        remote = "https://github.com/flyingsilverfin/client-java",
        commit = "232fa6085fca01b7c96f4efdcfbe56a8be0c1a88",
    )

def graknlabs_grakn_core():
    git_repository(
        name = "graknlabs_grakn_core",
        remote = "https://github.com/flyingsilverfin/grakn",
        commit = "03eba7eaf1ac0c5859ca649b4e0e94542867226b",
    )
