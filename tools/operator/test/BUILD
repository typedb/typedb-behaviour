load("@graknlabs_build_tools//checkstyle:rules.bzl", "checkstyle_test")

package(default_visibility = ["//visibility:public"])

java_test(
    name = "operator-it",
    size = "small",
    srcs = glob(["*.java"]),
    test_class = "grakn.verification.tools.operator.test.OperatorTest",
    visibility = ["//visibility:public"],
    deps = [
        "//dependencies/maven/artifacts/com/google/guava",
        "//tools:operator",
        "@graknlabs_graql//java:graql",
    ],
)

checkstyle_test(
    name = "checkstyle",
    targets = [
        ":operator-it",
    ],
)
