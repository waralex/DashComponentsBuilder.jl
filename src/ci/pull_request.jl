function pull_request_ci(;env = ENV)
    println("is pull request ", is_pull_request(env = env))
    println("pull request number ", pull_request_number(env = env))
end