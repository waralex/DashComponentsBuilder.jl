function step_obtain_pypi!(state::WizardState)
    msg = "\t\t\t# Obtain the PyPi package\n\n"
    printstyled(msg, bold=true)
    info = nothing
    while isnothing(info)
        msg = "Please enter a name of PyPi package with dash components"
        pkg_name = nonempty_line_prompt("name", msg, force_identifier = true)
        println("getting information from pypi.org...")
        info = pypi_pkg_info(pkg_name)
        if isnothing(info)
            printstyled("Package ", color = :red)
            printstyled(pkg_name, color = :red, bold = true)
            printstyled(" not found\n", color = :red)
        end
    end
    printstyled("Package ", color = :green)
    printstyled(info.name, color = :green, bold = true)
    printstyled(" found\n", color = :green)
    println("Package author: ", info.author)
    menu = RadioMenu(string.(info.versions), pagesize=15)
    choice = request("Choose package version:", menu)
    selected_version = info.versions[choice]
    println("Checking package...")


    state.build_state.py_pkg_name = info.name
    state.build_state.py_pkg_version = string(selected_version)
    state.build_state.is_pypi = true

    make_docker_builder!(state)

    build_success = true
    try
        run_build_cmd(state.build_state, state.builder, verbose = true)
        try_fill_buildstate!(state.build_state)
    catch e
        showerror(stdout, e)
        println()
        build_success = false
    end
    if build_success
        printstyled("Package check passed\n", color = :green)
        state.next_step = step_make_recipe!
    else
        printstyled("Package check failed. Looks like it is not dash components package\n", color = :red, bold = true)
        state.is_done = true
    end
end