clean_test_ws() = rm("test_workspace", force = true, recursive = true)
function make_test_ws()
    clean_test_ws()
    mkpath("test_workspace")
end

@testset "build image" begin
    DCB.remove_image()
    @test !DCB.is_image_exists()
    @test_logs (:info, "Building docker image...") (:info, r"Docker image .* built") match_mode=:any DCB.build_image()
    @test DCB.is_image_exists()
    @test_logs (:info, r"Docker image .* already exists.*") match_mode=:any DCB.build_image()
    DCB.remove_image()
end

@testset "DockerBuilder" begin
    DCB.remove_image()
    state = DCB.BuildState()
    docker = @test_logs (:info, "Building docker image...") (:info, r"Docker image .* built") match_mode=:any  DCB.DockerBuilder(state)
    @test docker.base_cmd == `docker run --rm `

    docker = DCB.DockerBuilder(state, cwd = "/source")
    @test docker.base_cmd == `docker run --rm -w /source `

    make_test_ws()
    state.workspace = realpath("test_workspace")

    docker = DCB.DockerBuilder(state, cwd = "/source")
    @test docker.base_cmd == `docker run --rm -w /source -v $(realpath("test_workspace")):/workspace:rw `
    clean_test_ws()
end
@testset "simple run" begin
    state = DCB.BuildState()
    docker = DCB.DockerBuilder(state)
    buff = IOBuffer()
    run(docker, `/bin/bash -c "echo hello"`, buff)
    seek(buff, 0)
    s = String(read(buff))
    @test split(s, "\n")[2] == "hello"

    make_test_ws()
    state.workspace = realpath("test_workspace")
    docker = DCB.DockerBuilder(state, cwd = "/workspace")
    write("test_workspace/1.txt", "hello")
    buff = IOBuffer()
    res = read(docker, `/bin/bash -c "cat 1.txt"`)
    @test res == "hello"
end