"""Defines a repository created by a conda environment"""

load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//rules/directory:directory.bzl", "directory")
load("@rules_cc//cc:defs.bzl", "cc_import")
load("@rules_cc//cc/toolchains:args.bzl", "cc_args")
load("@rules_cc//cc/toolchains:tool.bzl", "cc_tool")
load("@rules_cc//cc/toolchains:tool_map.bzl", "cc_tool_map")
load("@rules_cc//cc/toolchains:toolchain.bzl", "cc_toolchain")
load("@rules_mojo//mojo:mojo_import.bzl", "mojo_import")
# load("@rules_cc//cc/toolchains/args:sysroot.bzl", "_DEFAULT_SYSROOT_ACTIONS")

load("@rules_mojo//mojo:toolchain.bzl", "mojo_toolchain")

_DEFAULT_SYSROOT_ACTIONS = [
    "@rules_cc//cc/toolchains/actions:assembly_actions",
    "@rules_cc//cc/toolchains/actions:c_compile",
    "@rules_cc//cc/toolchains/actions:objc_compile",
    "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    "@rules_cc//cc/toolchains/actions:link_actions",
]

_SYSROOT = "x86_64-conda-linux-gnu/sysroot"

# Okay! So it works if I use gcc's resource dir.
_RESOURCE_DIR = "lib/gcc/x86_64-conda-linux-gnu/15.2.0"
# _RESOURCE_DIR = "lib/clang/22"

directory(
    name = "sysroot_folder",
    srcs = glob([
        # "**",
        _SYSROOT + "/**",
        # symlinks into this dir
        _RESOURCE_DIR + "/**",
    ]),
)

cc_args(
    name = "resource_dir_args",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "-resource-dir={resource_dir}" + "/" + _RESOURCE_DIR,
    ],
    data = [":sysroot_folder"],
    format = {
        "resource_dir": ":sysroot_folder",
    },
)

cc_args(
    name = "sysroot_args",
    actions = _DEFAULT_SYSROOT_ACTIONS,
    args = ["--sysroot={sysroot}" + "/" + _SYSROOT],
    data = [":sysroot_folder"],
    format = {"sysroot": ":sysroot_folder"},
)

cc_tool(
    name = "clang",
    src = "bin/clang",
    data = [
        "bin/ld.lld",
    ],
)

cc_args(
    name = "no_canonical_prefixes",
    actions = [
        "@rules_cc//cc/toolchains/actions:compile_actions",
        "@rules_cc//cc/toolchains/actions:link_actions",
    ],
    args = [
        "-no-canonical-prefixes",
        # "--target=x86_64-unknown-linux-gnu",
        "-fno-autolink",
    ],
)

cc_tool_map(
    name = "tools",
    tools = {
        "@rules_cc//cc/toolchains/actions:c_compile_actions": ":clang",
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions": ":clang",
        "@rules_cc//cc/toolchains/actions:link_actions": ":clang",
    },
    visibility = ["//visibility:private"],
)

cc_args(
    name = "cpp_compile_args",
    actions = [
        "@rules_cc//cc/toolchains/actions:cpp_compile_actions",
    ],
    args = [
        "-stdlib=libstdc++",
    ],
)

cc_args(
    name = "link_args",
    actions = ["@rules_cc//cc/toolchains/actions:link_actions"],
    args = [
        "-fuse-ld=lld",
        # Or, I can use clang's resource dir like this
        # "--rtlib=compiler-rt",
    ],
)

cc_toolchain(
    name = "linux_x86_64_clang_toolchain",
    args = [
        # hopefully somewhere in here is the `.d` file stuff?
        ":sysroot_args",
        ":resource_dir_args",
        ":no_canonical_prefixes",
        ":link_args",
        ":cpp_compile_args",
    ],
    compiler = "clang",
    enabled_features = [
        # this is reeeeeeeeeeeeeeeeally important
        "@rules_cc//cc/toolchains/args:experimental_replace_legacy_action_config_features",
    ],
    tool_map = ":tools",
)

toolchain(
    name = "linux_x86_64_toolchain",
    toolchain = ":linux_x86_64_clang_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    visibility = ["//visibility:public"],
)

# Copied from
# https://github.com/modular/rules_mojo/blob/6357c3eb7b60d27c8da55247784aae121213109c/mojo/private/toolchain.BUILD
_INTERNAL_LIBRARIES = [
    (
        paths.split_extension(library)[0],
        library,
    )
    for library in glob(
        [
            # Globbed to allow .so or .dylib
            "lib/libAsyncRTMojoBindings.*",
            "lib/libAsyncRTRuntimeGlobals.*",
            "lib/libKGENCompilerRTShared.*",
            "lib/libMSupportGlobals.*",
        ],
        allow_empty = False,
    ) + glob(
        ["lib/libNVPTX.so"],  # buildifier: disable=constant-glob
        allow_empty = True,
    )
]

[
    cc_import(
        name = name,
        shared_library = library,
        visibility = ["//visibility:private"],
    )
    for name, library in _INTERNAL_LIBRARIES
]

mojo_import(
    name = "std",
    mojodeps = ["lib/mojo/std.mojoc"],
)

mojo_toolchain(
    name = "mojo_toolchain_decl",
    implicit_deps = [
        name
        for name, _ in _INTERNAL_LIBRARIES
    ] + [":std"],
    lld = "bin/lld",
    mojo = "bin/mojo",
)

toolchain(
    name = "mojo_toolchain",
    toolchain = ":mojo_toolchain_decl",
    toolchain_type = "@rules_mojo//:toolchain_type",
    visibility = ["//visibility:public"],
)
