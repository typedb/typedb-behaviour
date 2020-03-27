java_library(
    name = "grakn-for-test",
    srcs = ["GraknForTest.java"],
    deps = [
        "//dependencies/maven/artifacts/ch/qos/logback:logback-classic",
        "//dependencies/maven/artifacts/com/google/guava:guava",
        "//dependencies/maven/artifacts/org/slf4j:slf4j-api",
        "//dependencies/maven/artifacts/org/zeroturnaround:zt-exec",
    ],
    data = [
        "@graknlabs_grakn_core//:assemble-linux-targz",
        "//resolution/cases/case2:schema.gql",
        "//resolution/cases/case2:data.gql",
    ],
    visibility = ["//visibility:public"]
)

java_test(
    name = "ResolutionBuilderIT",
    srcs = [
        "ResolutionBuilderIT.java",
    ],
    test_class = "grakn.verification.resolution.test.ResolutionBuilderIT",
    deps = [
        "//resolution/common",
        "//resolution/kbtest",
        "//resolution/test:grakn-for-test",

        # External dependencies from @graknlabs
        "@graknlabs_client_java//:client-java",
        "@graknlabs_graql//java:graql",
    ],
    data = [
        "@graknlabs_grakn_core//:assemble-linux-targz", # Make sure to pass the path in args below
        "//resolution/cases/case4:schema.gql",
        "//resolution/cases/case4:data.gql",
    ],
    args = [ # The order of the arguments matter
        "grakn-core", # Keep at index 0, will be accessible at args[1]
        "$(location @graknlabs_grakn_core//:assemble-linux-targz)", # Keep at index 1, will be accessible at args[2]
    ],
    size="medium"
)

java_test(
    name = "TestResolutionBuilder",
    srcs = [
        "TestResolutionBuilder.java",
    ],
    test_class = "grakn.verification.resolution.test.TestResolutionBuilder",
    deps = [
        "//resolution/common",
        "//resolution/kbtest",
        "//dependencies/maven/artifacts/com/google/guava",

        # External dependencies from @graknlabs
        "@graknlabs_client_java//:client-java",
        "@graknlabs_graql//java:graql",
    ],
    size="small"
)

java_test(
    name = "TestSchemaManager",
    srcs = [
        "TestSchemaManager.java",
    ],
    test_class = "grakn.verification.resolution.test.TestSchemaManager",
    deps = [
        "//resolution/common",
        "//resolution/kbcomplete",
        "//resolution/test:grakn-for-test",

        # External dependencies from @graknlabs
        "@graknlabs_client_java//:client-java",
        "@graknlabs_graql//java:graql",
    ],
    data = [
        "@graknlabs_grakn_core//:assemble-linux-targz", # Make sure to pass the path in args below
    ],
    args = [ # The order of the arguments matter
        "grakn-core", # Keep at index 0, will be accessible at args[1]
        "$(location @graknlabs_grakn_core//:assemble-linux-targz)", # Keep at index 1, will be accessible at args[2]
    ],
    size="medium"
)