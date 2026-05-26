"""Defines a Bazel repo from a Conda environment"""

def _conda_repo_impl(rctx):
    env_root = str(rctx.workspace_root) + "/" + rctx.attr.path + "/"

    for src in rctx.path(env_root).readdir(watch = "no"):
        rctx.symlink(str(src), str(src).split("/")[-1])

    rctx.template(
        "BUILD.bazel",
        Label(":conda_repo.BUILD"),
        substitutions = {
            "{TEMPLATE_SYSROOT}": rctx.attr.cc_sysroot,
            "{TEMPLATE_RESOURCE_DIR}": rctx.attr.cc_resource_dir,
        },
        executable = False,
    )

conda_repo = repository_rule(
    implementation = _conda_repo_impl,
    attrs = {
        "path": attr.string(
            mandatory = True,
        ),
        "cc_sysroot": attr.string(),
        "cc_resource_dir": attr.string(),
    },
)
