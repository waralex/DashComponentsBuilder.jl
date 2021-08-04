function init_package_repo(dest_dir, deploy_repo)

    auth = github_auth(;allow_anonymous=false)
    gh_username = gh_get_json(DEFAULT_API, "/user"; auth=auth)["login"]
    try
        # This throws if it does not exist
        GitHub.repo(deploy_repo; auth=auth)
    catch e
        # If it doesn't exist, create it.
        # check whether gh_org might be a user, not an organization.
        gh_org = dirname(deploy_repo)
        isorg = GitHub.owner(gh_org; auth=auth).typ == "Organization"
        owner = GitHub.Owner(gh_org, isorg)
        @info("Creating new wrapper code repo at https://github.com/$(deploy_repo)")
        try
            GitHub.create_repo(owner, basename(deploy_repo), Dict("license_template" => "mit", "has_issues" => "false"); auth=auth)
        catch create_e
            # If creation failed, it could be because the repo was created in the meantime.
            # Check for that; if it still doesn't exist, then freak out.  Otherwise, continue on.
            try
                GitHub.repo(deploy_repo; auth=auth)
            catch
                rethrow(create_e)
            end
        end
    end

    if isdir(dest_dir)
        rm(dest_dir, force = true, recursive = true)
    end
    @info("Cloning wrapper code repo from https://github.com/$(deploy_repo) into $(dest_dir)")
    with_gitcreds(gh_username, auth.token) do creds
        LibGit2.clone("https://github.com/$(deploy_repo)", dest_dir; credentials=creds)
    end
end

is_package(dest_dir) = ispath(joinpath(dest_dir, "Project.toml"))

function exists_package_version(dest_dir)
    !is_package(dest_dir) && return nothing
    try
        project_data = TOML.parsefile(joinpath(dest_dir, "Project.toml"))
        version = VersionNumber(project_data["version"])
        return version
    catch e
        showerror(stdout, e)
        return nothing
    end
end

function deploy_repo(recipe::Recipe, user_or_org = DEPLOY_ORG, repo_name = nothing)
    name = isnothing(repo_name) ? "$(recipe.name).jl" : repo_name
    return "$(user_or_org)/$(name)"
end



deploy_tagname(recipe::Recipe, buildn) = string("v", version_with_build(recipe, buildn))

tarball_name(recipe::Recipe, buildn) = string(
    "$(recipe.name)Resources.", deploy_tagname(recipe, buildn), ".tar.gz"
)

function deploy_package(recipe_dir::AbstractString; user_or_org = DEPLOY_ORG, repo_name = nothing)
    recipe = load_recipe(recipe_dir; verbose = false)
    return deploy_package(recipe; user_or_org = user_or_org, repo_name = repo_name)

end

function deploy_package(recipe::Recipe; user_or_org = DEPLOY_ORG, repo_name = nothing)
    mktempdir() do tmp
        dest_dir = joinpath(tmp, "pkg_repo")
        tarball_dir = joinpath(tmp, "tarball")
        repo = deploy_repo(recipe, user_or_org, repo_name)
        init_package_repo(dest_dir, repo)

        old_version = exists_package_version(dest_dir)
        buildn = nothing
        @info "Checking versions..."
        if !isnothing(old_version)
            old_version_base = VersionNumber(old_version.major, old_version.minor, old_version.patch)
            if old_version_base > recipe.version
                error("Trying to deploy old version $(recipe.version) while version $(old_version) already deployed to $(repo)")
            end
            if old_version_base == recipe.version
                buildn = (isempty(old_version.build) ? 0 : old_version.build[1]) + 1
            end
        end
        @info "Deploying $(recipe.version)" * (isnothing(buildn) ? "" : " build number $(buildn)")
        build_state = build(recipe)
        generate_package_code(recipe, build_state, dest_dir, buildn = buildn)

        artifact_hash = make_artifact(recipe, build_state)
        @info "creating tagball..."
        tarball_hash = archive_artifact(artifact_hash, joinpath(tarball_dir, tarball_name(recipe, buildn)))
        @info "tagball created" tarball_hash

        @info "binding artifact..."
        download_info = (
            "https://github.com/$(repo)/releases/download/$(deploy_tagname(recipe, buildn))/$(tarball_name(recipe, buildn))",
            tarball_hash
        )
        make_artifacs_file(recipe, artifact_hash, dest_dir, download_info = [download_info])
        @info "artifact binding succefully"

        @info "pushing repo to https://github.com/$(repo)..."
        push_repo(repo, dest_dir, deploy_tagname(recipe, buildn))
        @info "repo pushed"
        #=
        TODO Registrator actions here
        =#

        @info "creating github release and uploading artifacts..."
        cd(tarball_dir) do
            upload_to_resleases(repo,
                deploy_tagname(recipe, buildn),
                tarball_name(recipe, buildn)
            )
        end
        @info "github release created"
    end
end


function push_repo(repo_name, deploy_dir, tag)
    gh_auth = github_auth(; allow_anonymous = false)
    gh_username = gh_get_json(DEFAULT_API, "/user"; auth = gh_auth)["login"]
    repo = LibGit2.GitRepo(deploy_dir)
    LibGit2.add!(repo, ".")
    sig = LibGit2.Signature(gh_username, "", round(time(), 0), 0)
    commit = LibGit2.commit(repo, "dash core resources build $(tag)"; author=sig, committer=sig)
    with_gitcreds(gh_username, gh_auth.token) do creds
        refspecs = ["refs/heads/main"]
        # Fetch the remote repository, to have the relevant refspecs up to date.
        LibGit2.fetch(repo; refspecs = refspecs, credentials = creds)
        LibGit2.branch!(repo, "main", string(LibGit2.GitHash(commit)); track = "main")
        LibGit2.push(
            repo;
            refspecs = refspecs,
            remoteurl = "https://github.com/$(repo_name).git",
            credentials = creds,
        )
    end
end
function upload_to_resleases(repo_name, tag, tarball_path; attempts = 3)
    gh_auth = github_auth(; allow_anonymous = false)
    for attempt = 1:attempts
        try
            ghr() do ghr_path
                run(
                    `$ghr_path -u $(dirname(repo_name)) -r $(basename(repo_name)) -t $(gh_auth.token) $(tag) $(tarball_path)`,
                )
            end
            return
        catch
            @info("`ghr` upload step failed, beginning attempt #$(attempt)...")
        end
    end
    error("Unable to upload $(tarball_path) to GitHub repo $(repo_name) on tag $(tag)")
end