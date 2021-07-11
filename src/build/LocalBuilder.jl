
Base.@kwdef mutable struct LocalBuilder <: Builder
    py_pkg_name ::String = ""
    source_dir ::String = ""
    dest_dir ::String = ""
end

function LocalBuilder(state::BuildState)
    return LocalBuilder(
        py_pkg_name = state.py_pkg_name,
        source_dir = source_dir(state),
        dest_dir = dest_dir(state)
    )
end


local_cmd(builder::LocalBuilder, cmd) = Cmd(addenv(
        cmd,
         Dict(
            "PACKAGE_NAME" => builder.py_pkg_name,
            "SOURCE_DIR" => builder.source_dir,
            "DEST_DIR" => builder.dest_dir
        )
    ), dir = builder.source_dir)

function Base.run(builder::LocalBuilder, cmd, logger::IO=stdout; verbose=true)
    did_succeed = true
    dcmd = local_cmd(builder, cmd)
    @debug("About to run: $(dcmd)")

    try
        oc = OutputCollector(dcmd; verbose=verbose)
        did_succeed = wait(oc)

        println(logger, cmd)
        print(logger, merge(oc))
    finally
    end

    return did_succeed
end

function Base.read(builder::LocalBuilder, cmd; verbose=true)
    did_succeed = true
    dcmd = local_cmd(builder, cmd)
    @debug("About to run: $(dcmd)")

    local oc
    did_succeed = false
    try
        oc = OutputCollector(dcmd; verbose=verbose)
        did_succeed = wait(oc)
    finally
    end

    if !did_succeed
        print(stderr, collect_stderr(oc))
        return nothing
    end

    return collect_stdout(oc)
end
extract_meta_cmd(builder::LocalBuilder) = "python $(joinpath(DOCKER_PATH, "extract_meta.py"))"
extract_pypi_source_cmd(builder::LocalBuilder) = "python $(joinpath(DOCKER_PATH, "extract_pypi_source.py"))"