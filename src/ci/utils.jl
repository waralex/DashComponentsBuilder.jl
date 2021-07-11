function is_pull_request(;env=ENV)
    return get(env, "GITHUB_EVENT_NAME", nothing) == "pull_request"
end
function pull_request_number(;env=ENV)
    m = match(r"^refs\/pull\/(\d+)\/merge$", get(env, "GITHUB_REF", ""))
    isnothing(m) && error("Can't parse PR number")
    return parse(Int, m.captures[1])
end
function current_pr_head_commit_sha(;env=ENV)
    !is_pull_request(;env = env) && error("it is not PR")
    file = get(env, "GITHUB_EVENT_PATH", nothing)
    file === nothing && return nothing
    content = JSON.parsefile(file)
    return content["pull_request"]["head"]["sha"]
end
function directory_of_cloned_registry(;env=ENV)
    return get(env, "GITHUB_WORKSPACE", nothing)
end

