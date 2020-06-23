#
# Copyright (C) 2020 Grakn Labs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

package(default_visibility = ["//visibility:public"])

load("@graknlabs_dependencies//tools/checkstyle:rules.bzl", "checkstyle_test")

java_test(
    name = "semantic-set-validity",
    srcs = glob([
        "SemanticSets.java",
    ]),
    test_class = "grakn.verification.tools.integrity.SemanticSets",
    deps = [
        "//tools/integrity:integrity",
        "@graknlabs_client_java//:client-java",
        "@graknlabs_common//:common",
        "//dependencies/maven/artifacts/com/google/guava",
        "//dependencies/maven/artifacts/org/mockito:mockito-core",
    ],
)

java_test(
    name = "validator-set-construction",
    srcs = glob([
        "ValidatorSetConstruction.java",
    ]),
    test_class = "grakn.verification.tools.integrity.ValidatorSetConstruction",
    deps = [
        "//tools/integrity:integrity",
        "@graknlabs_client_java//:client-java",
        "@graknlabs_common//:common",
        "//dependencies/maven/artifacts/com/google/guava",
        "//dependencies/maven/artifacts/org/mockito:mockito-core",
        "//dependencies/maven/artifacts/org/slf4j:slf4j-api",
    ],
    runtime_deps = [
        "//dependencies/maven/artifacts/ch/qos/logback:logback-classic",
        "//dependencies/maven/artifacts/ch/qos/logback:logback-core",
    ],
)

java_test(
    name = "validator-it",
    srcs = glob([
        "ValidatorIT.java",
    ]),
    test_class = "grakn.verification.tools.integrity.ValidatorIT",
    deps = [
        "//tools/integrity:integrity",
        "@graknlabs_client_java//:client-java",
        "@graknlabs_graql//java:graql",
        "//dependencies/maven/artifacts/com/google/guava",
        "//dependencies/maven/artifacts/org/mockito:mockito-core",
        "//dependencies/maven/artifacts/org/slf4j:slf4j-api",
    ],
    runtime_deps = [
        "//dependencies/maven/artifacts/ch/qos/logback:logback-classic",
        "//dependencies/maven/artifacts/ch/qos/logback:logback-core",
    ],
    classpath_resources = [
        "//tools/integrity/test:logback.xml",
    ],
)

exports_files([
    "logback.xml"
])

checkstyle_test(
    name = "checkstyle",
    targets = [
        ":semantic-set-validity",
        ":validator-set-construction",
        ":validator-it"
    ],
)
