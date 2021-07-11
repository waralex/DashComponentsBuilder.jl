function load_recipe(recipe_dir::AbstractString; verbose = false)
    !isdir(recipe_dir) && error("$recipe_dir is not dir")
    recipe_file = joinpath(recipe_dir, "Recipe.yml")
    !isfile(recipe_file) && error("Recipe file don't exists in $(recipe_dir)")
    recipe = read(recipe_file, Recipe)
    if verbose
        print("Recipe for package ")
        printstyled(recipe.name, bold = true)
        println(" found")
    end
    return recipe
end

"""
    generate(recipe::Recipe, destpath::AbstractString; force = false, verbose = false)
    generate(recipe_dir::AbstractString, destpath::AbstractString; force = false, verbose = false)

Generate Julia package from `recipe` into `destpath`. Use `force` to overwrite recipe existing in `distpath`
"""
function generate(recipe::Recipe, destpath::AbstractString; force = false, verbose = false)
    fullpath = abspath(joinpath(destpath, recipe.name))
    if ispath(fullpath,)
       !force && error("`$(fullpath)` already exists, user `furce=true` to overwrite it")
       rm(fullpath, recursive = true, force = true)
    end
    state = build(recipe, verbose = verbose)
    generate_package(recipe, state, fullpath)
    if verbose
        println("Package `$(recipe.name)` generated into dir `$(fullpath)`")
        print("Dev package `")
        printstyled(recipe.name, bold=true)
        print("` writed into `")
        printstyled(fullpath, bold=true)
        println("`")
    end
    return true
end

function generate(recipe_dir::AbstractString, destpath::AbstractString; force = false, verbose = false)
    recipe = load_recipe(recipe_dir; verbose = verbose)
    return generate(recipe, destpath::AbstractString; force = force, verbose = verbose)
end