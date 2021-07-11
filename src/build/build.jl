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

function pypi_cmds(state::BuildState, builder)
    cmds = String[]
    push!(cmds, "pip3 install $(state.py_pkg_name)==\"$(state.py_pkg_version)\"")
    push!(cmds, extract_pypi_source_cmd(builder))
    push!(cmds, extract_meta_cmd(builder))
    return cmds
end
function build_cmds(state::BuildState, builder)
    cmds = String[]
    has_requirements(state) && push!(cmds, "pip3 install -r $(state.requirements_file)")

    !isnothing(state.build_script) && append!(cmds, split(state.build_script, "\n", keepempty = false))

    push!(cmds, extract_meta_cmd(builder))
    return cmds
end
function run_build_cmd(state::BuildState, builder; verbose = false)
    cmds = state.is_pypi ? pypi_cmds(state, builder) : build_cmds(state, builder)
    r = read(builder, `/bin/bash -c "$(join(cmds, ";"))"`; verbose = verbose)
    isnothing(r) && error("Build failed")
end

function try_fill_buildstate!(state::BuildState)

    state.raw_pkg_meta = JSON3.read(
        read(dest_path(state, "package_meta.json"), String)
    )



    !try_fill_metadata_json!(state) && error("metadata.json not found")

    result, files = check_resources_exists(state)
    if !result
        failed_files = filter(files) do f
            return !f.exists && f.important
        end
        error("resources not found: \n $(join(failed_files, "\n"))")
    end
end
function build(recipe::Recipe; verbose = false)
    state = init_buildstate(recipe)

    if state.is_pypi
        mkpath(source_dir(state))
    else
        clone_repo(state)
    end

    try_fill_requirements!(state)
    builder = default_builder(state)

    run_build_cmd(state, builder, verbose = verbose)
    try_fill_buildstate!(state)

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

    py_version = VersionNumber(state.raw_pkg_meta[:version])
    recipe.version != py_version &&
        error("Recipe version `$(recipe.version)` don't match python package version `$(py_version)`")
    return state
end