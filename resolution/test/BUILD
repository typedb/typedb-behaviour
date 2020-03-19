java_test(
    name = "ResolutionBuilderIT",
    srcs = [
        "ResolutionBuilderIT.java",
    ],
    test_class = "grakn.verification.resolution.test.ResolutionBuilderIT",
    deps = [
        "//resolution/common",
        "//resolution/kbtest",

        # External dependencies from @graknlabs
        "@graknlabs_client_java//:client-java",
#        "@graknlabs_client_java//test/setup:grakn-setup", # TODO Error:(1, 1) in java_test rule //resolution/test:ResolutionBuilderIT: target '@graknlabs_client_java//test/setup:grakn-setup' is not visible from target '//resolution/test:ResolutionBuilderIT'. Check the visibility declaration of the former target if you think the dependency is legitimate
        "@graknlabs_graql//java:graql",

        # External dependencies from Maven
#        "//dependencies/maven/artifacts/org/hamcrest:hamcrest",
    ],
    data = [
            "@graknlabs_grakn_core//:assemble-linux-targz", # Make sure to pass the path in args below
        ],
        args = [ # The order of the arguments matter
            "grakn-core", # Keep at index 0, will be accessible at args[1]
            "$(location @graknlabs_grakn_core//:assemble-linux-targz)", # Keep at index 1, will be accessible at args[2]
        ],
    size="small"
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

        # External dependencies from @graknlabs
        "@graknlabs_client_java//:client-java",
#        "@graknlabs_client_java//test/setup:grakn-setup", # TODO Error:(1, 1) in java_test rule //resolution/test:TestResolutionBuilder: target '@graknlabs_client_java//test/setup:grakn-setup' is not visible from target '//resolution/test:TestResolutionBuilder'. Check the visibility declaration of the former target if you think the dependency is legitimate
        "@graknlabs_graql//java:graql",

        # External dependencies from Maven
#        "//dependencies/maven/artifacts/org/hamcrest:hamcrest",
    ],
    data = [
            "@graknlabs_grakn_core//:assemble-linux-targz", # Make sure to pass the path in args below
        ],
        args = [ # The order of the arguments matter
            "grakn-core", # Keep at index 0, will be accessible at args[1]
            "$(location @graknlabs_grakn_core//:assemble-linux-targz)", # Keep at index 1, will be accessible at args[2]
        ],
    size="small"
)