function get_registry()
    registry_dir = abspath(
        joinpath(@__DIR__, "..", "..", "deps", "Registry")
    )
    if !isdir(registry_dir)
        @info( "Cloning bare Registry into deps/Registry...")
        LibGit2.clone("https://github.com/$(RECIPE_REGISTY).git", registry_dir; isbare=true)
    else
        @info("Updating bare Registry clone in deps/Registry...")
        repo = LibGit2.GitRepo(registry_dir)
        LibGit2.fetch(repo)
        origin_master_oid = LibGit2.GitHash(LibGit2.lookup_branch(repo, "origin/main", true))
        LibGit2.reset!(repo, origin_master_oid, LibGit2.Consts.RESET_SOFT)
    end
    return registry_dir
end

function auto_branch_name(recipe::Recipe)
    io = PipeBuffer()
    write(io, recipe)
    recipe_content = read(io, String)
    hash = bytes2hex(sha256(recipe_content)[end-3:end])
    return "autodeploy/$(recipe.name)-v$(recipe.version)_$(hash)"
end

function deploy_recipe(recipe_dir::AbstractString; no_build_check = false,make_pr = false, branch_name = nothing)
    recipe = load_recipe(recipe_dir; verbose = false)
    deploy_recipe(recipe; no_build_check = no_build_check, make_pr = make_pr, branch_name = branch_name)
end

function deploy_recipe(recipe::Recipe; no_build_check = false, make_pr = false, branch_name = nothing)
    if !no_build_check
        build(recipe, verbose = false)
    end
    gh_auth = github_auth(;allow_anonymous=false)
    gh_username = gh_get_json(DEFAULT_API, "/user"; auth=gh_auth)["login"]

    fork = GitHub.create_fork(RECIPE_REGISTY; auth = gh_auth)

    mktempdir() do tmp
        repo = LibGit2.clone(get_registry(), tmp)
        if isnothing(branch_name)
            branch_name = auto_branch_name(recipe)
        end
        LibGit2.branch!(repo, branch_name)
        dest_dir = joinpath(tmp, recipe.name)
        println("isdir ", isdir(dest_dir))
        mkpath(dest_dir)
        write(
            joinpath(dest_dir, "Recipe.yml"),
            recipe
        )
        @info("Committing and pushing to $(fork.full_name)#$(branch_name)...")
        LibGit2.add!(repo, recipe.name)
        LibGit2.commit(repo, "New Recipe: $(recipe.name) v$(recipe.version)")
        with_gitcreds(gh_username, gh_auth.token) do creds
            LibGit2.push(
                repo,
                refspecs=["+HEAD:refs/heads/$(branch_name)"],
                remoteurl="https://github.com/$(fork.full_name).git",
                credentials=creds,
            )
        end
        close(repo)
    end
    if make_pr
        # Open a pull request against recipe registry
        @info("Opening a pull request against $(RECIPE_REGISTY)...")
        params = Dict(
            "base" => "main",
            "head" => "$(dirname(fork.full_name)):$(branch_name)",
            "maintainer_can_modify" => true,
            "title" => "Dash components recipe: $(recipe.name)-v$(recipe.version)",
            "body" => """
            This pull request contains a new build recipe I built using the DashComponentsBuilder.jl:

            * Package name: $(recipe.name)
            * Base Python package name: $(recipe.py_package)
            * Version: v$(recipe.version)

            """
        )
        pr = create_or_update_pull_request(RECIPE_REGISTY, params, auth=gh_auth)
        @info("Pull request created: $(pr.html_url)")
    else
        println("Open the pull request by going to: ")
        println("https://github.com/$(fork.full_name)/pull/new/$(HTTP.escapeuri(branch_name))?expand=1")
    end

end