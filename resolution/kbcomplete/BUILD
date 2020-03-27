exports_files(["completion_schema.gql"])

java_library(
    name = "kbcomplete",
    srcs = glob([
        "*.java",
        ]
    ),
    visibility = ["//visibility:public"],
    deps = [
        "//resolution/common:common",
        "@graknlabs_client_java//:client-java",
        "@graknlabs_graql//java:graql",
    ],
    data = [
        "//resolution/kbcomplete:completion_schema.gql",
    ],
)
