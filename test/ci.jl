@testset "utils" begin
    env = Dict(
        "GITHUB_EVENT_NAME" => "pull_request"
    )
    @test DCB.is_pull_request(;env = env)
    env = Dict(
        "GITHUB_EVENT_NAME" => "merge"
    )
    @test !DCB.is_pull_request(;env = env)

    env = Dict(
        "GITHUB_EVENT_NAME" => "pull_request",
        "GITHUB_REF" => "refs/pull/10/merge"
    )
    @test DCB.pull_request_number(env = env) == 10
end