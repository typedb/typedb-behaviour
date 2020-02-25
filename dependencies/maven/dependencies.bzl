# Do not edit. bazel-deps autogenerates this file from dependencies/maven/dependencies.yaml.
def _jar_artifact_impl(ctx):
    jar_name = "%s.jar" % ctx.name
    ctx.download(
        output=ctx.path("jar/%s" % jar_name),
        url=ctx.attr.urls,
        sha256=ctx.attr.sha256,
        executable=False
    )
    src_name="%s-sources.jar" % ctx.name
    srcjar_attr=""
    has_sources = len(ctx.attr.src_urls) != 0
    if has_sources:
        ctx.download(
            output=ctx.path("jar/%s" % src_name),
            url=ctx.attr.src_urls,
            sha256=ctx.attr.src_sha256,
            executable=False
        )
        srcjar_attr ='\n    srcjar = ":%s",' % src_name

    build_file_contents = """
package(default_visibility = ['//visibility:public'])
java_import(
    name = 'jar',
    tags = ['maven_coordinates={artifact}'],
    jars = ['{jar_name}'],{srcjar_attr}
)
filegroup(
    name = 'file',
    srcs = [
        '{jar_name}',
        '{src_name}'
    ],
    visibility = ['//visibility:public']
)\n""".format(artifact = ctx.attr.artifact, jar_name = jar_name, src_name = src_name, srcjar_attr = srcjar_attr)
    ctx.file(ctx.path("jar/BUILD"), build_file_contents, False)
    return None

jar_artifact = repository_rule(
    attrs = {
        "artifact": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        "urls": attr.string_list(mandatory = True),
        "src_sha256": attr.string(mandatory = False, default=""),
        "src_urls": attr.string_list(mandatory = False, default=[]),
    },
    implementation = _jar_artifact_impl
)

def jar_artifact_callback(hash):
    src_urls = []
    src_sha256 = ""
    source=hash.get("source", None)
    if source != None:
        src_urls = [source["url"]]
        src_sha256 = source["sha256"]
    jar_artifact(
        artifact = hash["artifact"],
        name = hash["name"],
        urls = [hash["url"]],
        sha256 = hash["sha256"],
        src_urls = src_urls,
        src_sha256 = src_sha256
    )
    native.bind(name = hash["bind"], actual = hash["actual"])


def list_dependencies():
    return [
    {"artifact": "com.google.code.findbugs:jsr305:1.3.9", "lang": "java", "sha1": "40719ea6961c0cb6afaeb6a921eaa1f6afd4cfdf", "sha256": "905721a0eea90a81534abb7ee6ef4ea2e5e645fa1def0a5cd88402df1b46c9ed", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/code/findbugs/jsr305/1.3.9/jsr305-1.3.9.jar", "name": "com-google-code-findbugs-jsr305", "actual": "@com-google-code-findbugs-jsr305//jar", "bind": "jar/com/google/code/findbugs/jsr305"},
    {"artifact": "com.google.errorprone:error_prone_annotations:2.0.18", "lang": "java", "sha1": "5f65affce1684999e2f4024983835efc3504012e", "sha256": "cb4cfad870bf563a07199f3ebea5763f0dec440fcda0b318640b1feaa788656b", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.0.18/error_prone_annotations-2.0.18.jar", "source": {"sha1": "220c1232fa6d13b427c10ccc1243a87f5f501d31", "sha256": "dbe7b49dd0584704d5c306b4ac7273556353ea3c0c6c3e50adeeca8df47047be", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/errorprone/error_prone_annotations/2.0.18/error_prone_annotations-2.0.18-sources.jar"} , "name": "com-google-errorprone-error_prone_annotations", "actual": "@com-google-errorprone-error_prone_annotations//jar", "bind": "jar/com/google/errorprone/error-prone-annotations"},
    {"artifact": "com.google.guava:guava:23.0", "lang": "java", "sha1": "c947004bb13d18182be60077ade044099e4f26f1", "sha256": "7baa80df284117e5b945b19b98d367a85ea7b7801bd358ff657946c3bd1b6596", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/guava/guava/23.0/guava-23.0.jar", "source": {"sha1": "ed233607c5c11e1a13a3fd760033ed5d9fe525c2", "sha256": "37fe8ba804fb3898c3c8f0cbac319cc9daa58400e5f0226a380ac94fb2c3ca14", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/guava/guava/23.0/guava-23.0-sources.jar"} , "name": "com-google-guava-guava", "actual": "@com-google-guava-guava//jar", "bind": "jar/com/google/guava/guava"},
    {"artifact": "com.google.j2objc:j2objc-annotations:1.1", "lang": "java", "sha1": "ed28ded51a8b1c6b112568def5f4b455e6809019", "sha256": "2994a7eb78f2710bd3d3bfb639b2c94e219cedac0d4d084d516e78c16dddecf6", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/j2objc/j2objc-annotations/1.1/j2objc-annotations-1.1.jar", "source": {"sha1": "1efdf5b737b02f9b72ebdec4f72c37ec411302ff", "sha256": "2cd9022a77151d0b574887635cdfcdf3b78155b602abc89d7f8e62aba55cfb4f", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/com/google/j2objc/j2objc-annotations/1.1/j2objc-annotations-1.1-sources.jar"} , "name": "com-google-j2objc-j2objc-annotations", "actual": "@com-google-j2objc-j2objc-annotations//jar", "bind": "jar/com/google/j2objc/j2objc-annotations"},
    {"artifact": "net.bytebuddy:byte-buddy-agent:1.6.4", "lang": "java", "sha1": "f6e414aa655ae1649eb642f70ea67e2c52b196c4", "sha256": "14e602e74e8c1a072a71eb75184f45eb8014221bf4981896b8686c2034a29ef5", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy-agent/1.6.4/byte-buddy-agent-1.6.4.jar", "source": {"sha1": "609e1f88a35606b8db4afcc35959b52bc099b7ba", "sha256": "a53d298ccc3670bce09632be32778479462abf7a37fe80b301ed569f1d8e593f", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy-agent/1.6.4/byte-buddy-agent-1.6.4-sources.jar"} , "name": "net-bytebuddy-byte-buddy-agent", "actual": "@net-bytebuddy-byte-buddy-agent//jar", "bind": "jar/net/bytebuddy/byte-buddy-agent"},
    {"artifact": "net.bytebuddy:byte-buddy:1.6.4", "lang": "java", "sha1": "682e791335dede35d628f26465b66ccd5ba7b443", "sha256": "3798336d61857087a0c5970f9c5afae2c340939913a3a7dc98e2813387405ca8", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy/1.6.4/byte-buddy-1.6.4.jar", "source": {"sha1": "073154e2215a8e09cdbf39b8914e750d3b28fc7d", "sha256": "22429809c08d608d87afdea50bdf4ad1c654887b1f6a94509102f54204ce57bf", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/net/bytebuddy/byte-buddy/1.6.4/byte-buddy-1.6.4-sources.jar"} , "name": "net-bytebuddy-byte-buddy", "actual": "@net-bytebuddy-byte-buddy//jar", "bind": "jar/net/bytebuddy/byte-buddy"},
    {"artifact": "org.codehaus.mojo:animal-sniffer-annotations:1.14", "lang": "java", "sha1": "775b7e22fb10026eed3f86e8dc556dfafe35f2d5", "sha256": "2068320bd6bad744c3673ab048f67e30bef8f518996fa380033556600669905d", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/org/codehaus/mojo/animal-sniffer-annotations/1.14/animal-sniffer-annotations-1.14.jar", "source": {"sha1": "886474da3f761d39fcbb723d97ecc5089e731f42", "sha256": "d821ae1f706db2c1b9c88d4b7b0746b01039dac63762745ef3fe5579967dd16b", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/org/codehaus/mojo/animal-sniffer-annotations/1.14/animal-sniffer-annotations-1.14-sources.jar"} , "name": "org-codehaus-mojo-animal-sniffer-annotations", "actual": "@org-codehaus-mojo-animal-sniffer-annotations//jar", "bind": "jar/org/codehaus/mojo/animal-sniffer-annotations"},
    {"artifact": "org.mockito:mockito-core:2.6.4", "lang": "java", "sha1": "b0fa48f9f385948a1e067dd94ab813318abb0a9e", "sha256": "21c5536a3facfe718baa802609b0c38311fedf6660430da3fd29cce1cb00dbb0", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/org/mockito/mockito-core/2.6.4/mockito-core-2.6.4.jar", "source": {"sha1": "aa6a259b1917e2b964b87cc902058d14347e0409", "sha256": "f3ce9f4978692345ce09f9c28674279475577122cbf6cae8aca21a7e08b8195b", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/org/mockito/mockito-core/2.6.4/mockito-core-2.6.4-sources.jar"} , "name": "org-mockito-mockito-core", "actual": "@org-mockito-mockito-core//jar", "bind": "jar/org/mockito/mockito-core"},
    {"artifact": "org.objenesis:objenesis:2.5", "lang": "java", "sha1": "612ecb799912ccf77cba9b3ed8c813da086076e9", "sha256": "293328e1b0d31ed30bb89fca542b6c52fac00989bb0e62eb9d98d630c4dd6b7c", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/org/objenesis/objenesis/2.5/objenesis-2.5.jar", "source": {"sha1": "e2b450699731118d1498645e36577371afced20f", "sha256": "727eaf4bece2f9587702b3d64a7e091afb98ab38c87b3f36728e4fe456bdd6cb", "repository": "https://repo.maven.apache.org/maven2/", "url": "https://repo.maven.apache.org/maven2/org/objenesis/objenesis/2.5/objenesis-2.5-sources.jar"} , "name": "org-objenesis-objenesis", "actual": "@org-objenesis-objenesis//jar", "bind": "jar/org/objenesis/objenesis"},
    ]

def maven_dependencies(callback = jar_artifact_callback):
    for hash in list_dependencies():
        callback(hash)
