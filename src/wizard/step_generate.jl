function step_generate!(state::WizardState)
    msg = "\t\t\t# Generate package \n\n"
    printstyled(msg, bold=true)

    fullpath = nothing
    while isnothing(fullpath)
        msg = "Enter the path to generate the package\n" *
            "Default: " * Pkg.devdir()
        path = line_prompt("path", msg)
        if isempty(path)
            path = Pkg.devdir()
        end
        fullpath = abspath(joinpath(path, state.recipe.name))
        if ispath(fullpath)
            rewrite =  yn_prompt("$fullpath already exists. Do you want to overwrite it?", :n)
            if rewrite == :n
                fullpath = nothing
                continue
            end
        end
    end
    generate_package(state.recipe, state.build_state, fullpath)
    print("Dev package `")
    printstyled(state.recipe.name, bold=true)
    print("` writed into `")
    printstyled(fullpath, bold=true)
    println("`")

    state.is_done = true
end