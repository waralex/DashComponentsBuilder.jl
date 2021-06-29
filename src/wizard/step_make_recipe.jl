function default_julia_name(py_name)
    parts = split(py_name, "_")
    return join(
        uppercasefirst.(parts)
    )
end
function default_julia_prefix(py_name)
    parts = split(py_name, "_")
    if length(parts) > 1
        return String(first.(parts))
    end
    return lowercase(parts[1])
end
function step_make_recipe!(state::WizardState)
    msg = "\t\t\t# Generate recipe \n\n"
    printstyled(msg, bold=true)
    default_name = default_julia_name(state.build_state.py_pkg_name)
    msg = "Enter a name for the Julia package. (default: `$(default_name)`)"
    state.build_state.jl_pkg_name = nonempty_line_prompt("name", msg, force_identifier = true, default = default_name)

    default_prefix = default_julia_prefix(state.build_state.py_pkg_name)
    msg = "Enter a prefx for the Julia components function. (default: `$(default_prefix)`)"
    state.build_state.jl_prefix = nonempty_line_prompt("prefix", msg, force_identifier = true, default = default_prefix)

    msg = "## Test build \n\n"
    printstyled(msg, bold=true)

    recipe = Recipe(state.build_state)

    #build(recipe)

    r = yn_prompt("Do you want to save the build recipe locally?")
    if r == :y
        while true
            msg = "Enter the path to save the recipe\n" *
                "Default: " * pwd()
            path = line_prompt("path", msg)
            if isempty(path)
                path = pwd()
            end
            fullpath = abspath(joinpath(path, state.build_state.jl_pkg_name))
            if ispath(fullpath)
                rewrite =  yn_prompt("$fullpath already exists. Do you want to overwrite it?", :n)
                if rewrite == :n
                    continue
                else
                    rm(fullpath, force = true, recursive = true)
                end
            end
            mkpath(fullpath)
            write(joinpath(fullpath, "Recipe.yml"), recipe)
            printstyled("Recipe successfully saved to ")
            printstyled(fullpath,  bold = true)
            println()
            break
        end
    end

    state.recipe = recipe

    r = yn_prompt("Do you want to generate package locally?")
    if r == :y
        state.next_step = step_generate!
    else
        state.is_done = true
    end
end