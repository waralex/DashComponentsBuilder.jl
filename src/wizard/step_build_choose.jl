function check_is_node_pkg(state::BuildState)
    try
        pkg_json_file = source_path(state, "package.json")
        !isfile(pkg_json_file) && return false
        pkg_meta = JSON3.read(
            read(pkg_json_file, String)
        )
        return haskey(pkg_meta, :scripts)
    catch
    end
    return false
end
function step_build_choose!(state::WizardState)
    msg = "\t\t\t# Choosing the build method \n\n"
    printstyled(msg, bold=true)
    make_docker_builder!(state)
    msg = "## Checking if repo is prebuilt \n"
    printstyled(msg)
    if try_fill_requirements!(state.build_state)
        printstyled("requirements.txt", bold=true)
        println(" found")
    end

    is_prebuilt = true
    if try_fill_metadata_json!(state.build_state)
        printstyled(state.build_state.metadata_json, bold=true)
        println(" found")
    else
        printstyled("metadata.json", bold=true, color = :red)
        printstyled(" not found. Package build required\n", color = :red)
        is_prebuilt = false
    end

    if is_prebuilt
        println("Trying to obtain infomation from Python module...")
        try_fill_raw_meta!(state.build_state, state.builder)
        if has_raw_pkg_meta(state.build_state)
            print("Information obtained from Python module. Module version is ")
            printstyled(state.build_state.raw_pkg_meta[:version], bold = true)
            println()
        else
            printstyled("Error while obtaing information from Python module. Package build required", color = :red)
            println()
            is_prebuilt = false
        end
    end

    if is_prebuilt
        r, files = check_resources_exists(state.build_state)
        if r
            println("All the required resources were found")
        else
            printstyled("Missed required resources files: \n", bold = true, color = :red)
            for f in files
                if !f.exists && f.important
                    printstyled("* ", f, "\n", color = :red)
                end
            end
            is_prebuilt
        end
    end

    if is_prebuilt
        msg = "The package looks prebuilt. Publication is available without additional building"
        printstyled(msg, "\n", color=:green)
    end

    is_node_pkg = check_is_node_pkg(state.build_state)
    if is_node_pkg
        msg = "The package is nodeJS package. Building using nodeJS is available"
        printstyled(msg, "\n", color=:green)
    end

    build_options = String[]
    possible_steps = Function[]
    if is_prebuilt
        push!(build_options, "Use prebuilt resources")
        push!(possible_steps, step_make_recipe!)
    end
    if is_node_pkg
        push!(build_options, "Build using nodeJS")
        push!(possible_steps, step_node_build!)
    end
    #push!(build_options, "Write custom build script")
    #push!(possible_steps, step_custom_build!)

    if length(build_options) > 1
        build_options[1] = build_options[1] * " (recommended)"
        menu = RadioMenu(build_options, pagesize=3)
        choice = request("Choose build method:", menu)
        state.next_step = possible_steps[choice]
        return
    end
    state.next_step = possible_steps[1]

end