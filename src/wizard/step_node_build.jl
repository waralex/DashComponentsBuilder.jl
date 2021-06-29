function get_node_targets(state::BuildState)
    pkg_json_file = source_path(state, "package.json")
    !isfile(pkg_json_file) && return false
    pkg_meta = JSON3.read(
        read(pkg_json_file, String)
    )
    return sort(string.(keys(pkg_meta[:scripts])))
end
function step_node_build!(state::WizardState)
    msg = "\t\t\t# Building using nodeJS \n\n"
    printstyled(msg, bold=true)
    targets = get_node_targets(state.build_state)
    menu = RadioMenu(targets, pagesize = 10)
    choice = request("Choose node target:", menu)
    target = targets[choice]
    state.build_state.build_script =
    """npm install
    npm run $(target)
    """
    build_success = true
    try
        println("Trying to build using nodeJS...")
        run_build_cmd(state.build_state, state.builder, verbose = true)
        try_fill_buildstate!(state.build_state)
    catch e
        showerror(stdout, e)
        build_success = false
    end
    if build_success
        printstyled("Successfully built\n", color = :green)
        state.next_step = step_make_recipe!
    else
        printstyled("Build failed\n", color = :red, bold = true)
        menu = RadioMenu(["Choose another target", "Exit"], pagesize = 3)
        choice = request("Choose next action:", menu)
        if choice == 2
            state.is_done = true
        end
    end

end