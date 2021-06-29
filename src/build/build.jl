function clone_repo(state::BuildState)
    @info "cloning repo $(state.source.url)..."
    repo = clone(state.source.url, source_dir(state))
    hash = state.source.hash
    obj = try
        LibGit2.GitObject(repo, hash)
    catch
        LibGit2.GitObject(repo, "origin/$hash")
    end
    @assert hash == LibGit2.string(LibGit2.GitHash(obj))
    LibGit2.checkout!(repo, hash)
    close(repo)
end

function run_build_cmd(state::BuildState, build_script, builder)
    cmds = String[]
    has_requirements(state) && push!(cmds, "pip install -r $(state.requirements_file)")

    !isnothing(build_script) && push!(cmds, build_script)

    push!(cmds, "python /misc/extract_meta.py")

    r = read(builder, `/bin/bash -c "$(join(cmds, "\n"))"`; verbose = false)
    isnothing(r) && error("Build failed")
end

function build(recipe::Recipe)
    state = init_buildstate()
    state.source = recipe.source
    state.py_pkg_name = recipe.py_package
    state.jl_pkg_name = recipe.name
    clone_repo(state)

    try_fill_requirements!(state)

    builder = default_docker_builder(state)
    run_build_cmd(state, recipe.build_script, builder)

    state.raw_pkg_meta = JSON3.read(
        read(dest_path(state, "package_meta.json"), String)
    )

    py_version = VersionNumber(state.raw_pkg_meta[:version])
    recipe.version != py_version &&
        error("Recipe version `$(recipe.version)` don't match python package version `$(py_version)`")


    !try_fill_metadata_json!(state) && error("metadata.json not found")

    result, files = check_resources_exists(state)
    if !result
        failed_files = filter(files) do f
            return !f.exists && f.important
        end
        error("resources not found: \n $(join(failed_files, "\n"))")
    end
    return state
end