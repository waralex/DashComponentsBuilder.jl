function is_pull_request(;env=ENV)
    return get(env, "GITHUB_EVENT_NAME", nothing) == "pull_request"
end
function pull_request_number(;env=ENV)
    m = match(r"^refs\/pull\/(\d+)\/merge$", get(env, "GITHUB_REF", ""))
    isnothing(m) && error("Can't parse PR number")
    return parse(Int, m.captures[1])
end
function load_event_data(;env=ENV)
    JSON.parsefile(env["GITHUB_EVENT_PATH"])
end
function pull_request_head_commit_sha(;env=ENV)
    !is_pull_request(;env = env) && error("it is not PR")
    file = get(env, "GITHUB_EVENT_PATH", nothing)
    file === nothing && return nothing
    content = JSON.parsefile(file)
    return content["pull_request"]["head"]["sha"]
end
function pr_directory(;env=ENV)
    return get(env, "GITHUB_WORKSPACE", nothing)
end

const parse_title_regex = r"^Dash components recipe: (\w*?)-v(\S*?)$"

function is_recipe_pr_title(name::AbstractString)
    return occursin(parse_title_regex, name)
end

is_recipe_pr(pr::GitHub.PullRequest) = is_recipe_pr_title(pr.title)

function parse_recipe_pr_title(title::AbstractString)
    parse_title_regex = r"^Dash components recipe: (\w*?)-v(\S*?)$"
    m = match(parse_title_regex, title)
    pkg = convert(String, m.captures[1])
    version = VersionNumber(m.captures[2])
    return pkg, version
end

parse_recipe_pr_title(pr::GitHub.PullRequest) = parse_recipe_pr_title(pr.title)

clone_main_repo(repo::GitHub.Repo) = clone_main_repo(repo.html_url.uri)

function clone_main_repo(url::AbstractString)
    parent_dir = mktempdir(; cleanup=true)
    repo_dir = joinpath(parent_dir, "REPO")
    LibGit2.clone(url, repo_dir)
    @info("Clone was successful")
    return repo_dir
end

function load_old_recipe(pr::CIPullRequest)
    old_recipe_dir = joinpath(pr.main_repo_dir, pr.pkg_name)
    if isdir(old_recipe_dir)
        return read(joinpath(old_recipe_dir, "Recipe.yml"), Recipe)
    end
    return nothing
end

function load_new_recipe(pr::CIPullRequest)
    return read(joinpath(pr.pr_repo_dir, pr.pkg_name, "Recipe.yml"), Recipe)
end