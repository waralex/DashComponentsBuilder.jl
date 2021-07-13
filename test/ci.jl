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

@testset "utils" begin
    @test !DCB.is_recipe_pr_title("Dash components recipe: DashDaq")
    @test DCB.is_recipe_pr_title("Dash components recipe: DashDaq-v10.2.1")
    pkg, version = DCB.parse_recipe_pr_title("Dash components recipe: DashDaq-v10.2.1")
    @test pkg == "DashDaq"
    @test version == v"10.2.1"
end