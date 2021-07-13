#checking of changed files
function check_changed_files(pr::CIPullRequest)
    @info "checking changed files..."
    files = get_changed_filenames(pr.repo, pr.pr)
    isempty(files) && return #Allowing empty PR is a debatable question
    if length(files) != 1 || files[1] != "$(pr.pkg_name)/Recipe.yml"
        error("PR does not look like a recipe for a package of components ")
    end
end

function check_version(pr::CIPullRequest)
    @info "checking versions..."
    old_recipe = load_old_recipe(pr)
    new_recipe = load_new_recipe(pr)

    if new_recipe.version != pr.version
        error("Version in Recipe.yml ($(new_recipe.version)) don't match version in PR title ($(pr.version))")
    end
    if !isnothing(old_recipe) && old_recipe.version > new_recipe.version
        error("Version in Recipe.yml $(new_recipe.version), but version $(old_recipe.version) already exists in registry")
    end
end

function check_build(pr::CIPullRequest)
    @info "trying to build package..."
    ENV["BUILDER"] = "local"
    recipe = load_recipe(joinpath(pr.pr_repo_dir, pr.pkg_name))
    build(recipe, verbose = false)
end

function set_labels(pr::CIPullRequest)
    old_recipe = load_old_recipe(pr)
    new_recipe = load_new_recipe(pr)
    labels = []
    if isnothing(old_recipe)
        push!(labels, "new package")
    elseif old_recipe.version == new_recipe.version
        push!(labels, "no version changes")
    else
        push!(labels, "new version")
    end

    if new_recipe.type == :pypi
        push!(labels, "pypi")
    else
        push!(labels, "gitrepo")
        !isnothing(new_recipe.build_script) && push!(labels, "custom build")
    end
    gh_set_labels(pr.repo, pr.pr, labels)
end
