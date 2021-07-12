function pull_request_ci(;env = ENV)
    println("is pull request ", is_pull_request(env = env))
    println("pull request number ", pull_request_number(env = env))
    pr_num = pull_request_number(env = env)
    pr = get_pull_request(pr_num)
    repo = gh_retry() do
        GitHub.repo(RECIPE_REGISTY)
    end
    files = get_changed_filenames(repo, pr)
    println(files)
end