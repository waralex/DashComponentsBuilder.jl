struct CIPullRequest
    pr ::GitHub.PullRequest
    pkg_name ::String
    version ::VersionNumber
    head_commit_sha ::Union{String, Nothing}
    repo ::GitHub.Repo
    pr_repo_dir ::String
    main_repo_dir ::String
end

function pull_request_opened_ci(;env = ENV)
    data = load_event_data(;env = env)
    pr_num = data["number"]
    pr = get_pull_request(pr_num)
    !is_recipe_pr(pr) && return

    pkg, version = parse_recipe_pr_title(pr)

    repo = gh_retry() do
        GitHub.repo(RECIPE_REGISTY)
    end
    main_repo_dir = clone_main_repo(repo)
    pr_repo_dir = pr_directory(env = env)
    pull_request = CIPullRequest(
        pr,
        pkg,
        version,
        pull_request_head_commit_sha(env = env),
        repo,
        pr_repo_dir,
        main_repo_dir
    )
    check_changed_files(pull_request)
    check_version(pull_request)
    check_build(pull_request)
    set_labels(pull_request)
end

function pull_request_merged_ci(;env = ENV)
    data = load_event_data(;env = env)
    pr_num = data["number"]
    pr = get_pull_request(pr_num)
    !is_recipe_pr(pr) && return

    pkg, version = parse_recipe_pr_title(pr)

    repo = gh_retry() do
        GitHub.repo(RECIPE_REGISTY)
    end
    main_repo_dir = clone_main_repo(repo)
    pr_repo_dir = pr_directory(env = env)
    pull_request = CIPullRequest(
        pr,
        pkg,
        version,
        pull_request_head_commit_sha(env = env),
        repo,
        pr_repo_dir,
  main_repo_dir
    )
    check_changed_files(pull_request)
    check_version(pull_request)
    deploy_package(recipe_dir(pull_request))
end