# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

package(default_visibility = ["//visibility:public"])

load("@vaticle_dependencies//tool/checkstyle:rules.bzl", "checkstyle_test")

files = [
    "attribute-attachment.feature",
    "compound-queries.feature",
    "concept-inequality.feature",
    "negation.feature",
    "recursion.feature",
    "relation-inference.feature",
    "schema-queries.feature",
    "rule-interaction.feature",
    "type-hierarchy.feature",
    "variable-roles.feature",
]

filegroup(
    name = "features",
    srcs = files,
)

exports_files(files)

checkstyle_test(
    name = "checkstyle",
    include = glob(["*"]),
    license_type = "mpl-header",
)
