function try_fill_requirements!(state::BuildState)
    if isfile(source_path(state, "requirements-dev.txt"))
        state.requirements_file = "requirements-dev.txt"
        return true
    end
    if isfile(source_path(state, "requirements.txt"))
        state.requirements_file = "requirements.txt"
        return true
    end
    return false
end

function check_resources_dist(state::BuildState, dist_key)
    function check_file(file)
        path = source_path(state, state.py_pkg_name, file)
        isexists = isfile(path)
        isimportant = endswith(file, ".js") || endswith(file, ".css")
        return (name = file, exists = isexists, important = isimportant)
    end

    result = []
    dists = state.raw_pkg_meta[dist_key]
    for dist in dists
        if haskey(dist, :relative_package_path)
            push!(result, check_file(dist[:relative_package_path]))
        end
        if haskey(dist, :dev_package_path) && get(dist, :relative_package_path, "") != dist[:dev_package_path]
            push!(result, check_file(dist[:dev_package_path]))
        end
    end
    return result
end

function check_resources_exists(state::BuildState)
    package_meta = state.raw_pkg_meta
    files = []
    if haskey(package_meta, :js_dist)
        append!(files, check_resources_dist(state, :js_dist))
    end
    if haskey(package_meta, :css_dist)
        append!(files, check_resources_dist(state, :css_dist))
    end
    result = true
    for f in files
        if !f.exists && f.important
            result = false
            break
        end
    end
    return result, files
end
function try_fill_raw_meta!(state::BuildState, builder)
    cmds = String[]
    if has_requirements(state)
        push!(cmds, "pip install -r $(state.requirements_file)")
    end
    push!(cmds, extract_meta_cmd(builder))
    r = read(builder, `/bin/bash -c "$(join(cmds, ";"))"`; verbose = false)
    if !isnothing(r)
        meta = JSON3.read(
            read(dest_path(state, "package_meta.json"), String)
        )
        state.raw_pkg_meta = meta
    end
end
function try_fill_metadata_json!(state::BuildState)
    metadata_json_list = find_metadata_json(source_dir(state))
    if !isempty(metadata_json_list)
        state.metadata_json = metadata_json_list[1] #TODO maybe selector if more then 1 found
        return true
    end
    return false
end