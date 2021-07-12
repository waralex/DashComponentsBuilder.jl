function create_or_update_pull_request(repo, params; auth=github_auth())
    try
        return GitHub.create_pull_request(repo; params=params, auth=auth)
    catch ex
        # If it was already created, search for it so we can update it:
        if Registrator.CommentBot.is_pr_exists_exception(ex)
            prs, _ = GitHub.pull_requests(repo; auth=auth, params=Dict(
                "state" => "open",
                "base" => params["base"],
                "head" => string(split(repo, "/")[1], ":", params["head"]),
            ))
            return GitHub.update_pull_request(repo, first(prs).number; auth=auth, params=params)
        else
            rethrow(ex)
        end
    end
end

function get_pull_request(pr_number; auth = github_auth())
    return gh_retry() do
        GitHub.pull_request(api, registry, pr_number; auth=auth)
    end
end

function get_changed_filenames(repo::GitHub.Repo, pull_request::GitHub.PullRequest)
    files = GitHub.pull_request_files(repo, pull_request; auth = github_auth())
    return [file.filename for file in files]
end

function get_changed_filenames(repo, pull_request; auth = github_auth())
    files = GitHub.pull_request_files(repo, pull_request; auth=auth)
    return [file.filename for file in files]
end
