const DOCKER_IMAGE_NAME = "dbc/components_builder"
const DOCKER_IMAGE_VERSION = "latest"
const AnyRedirectable = Union{Base.AbstractCmd, Base.TTY, IOStream}

Base.@kwdef mutable struct DockerBuilder
    image_name ::String
    base_cmd ::Cmd
end

function docker_cmd(docker::DockerBuilder, cmd; flags = [])
    return `$(docker.base_cmd) $(flags) $(docker.image_name) $(cmd)`
end

docker_image(name, version) =  string(name, ":", version)

docker_image() = docker_image(DOCKER_IMAGE_NAME, DOCKER_IMAGE_VERSION)

remove_image() = success(`docker rmi -f $(docker_image())`)

is_image_exists(image = docker_image()) = success(`docker inspect --type=image $(image)`)

function build_image(image_name = DOCKER_IMAGE_NAME, image_version = DOCKER_IMAGE_VERSION)
    image = docker_image(image_name, image_version)
    if is_image_exists(image)
        @info("Docker image $(image) already exists, skipping image building...")
        return
    end

    @info "Building docker image..."
    docker_file = joinpath(DOCKER_PATH, "Dockerfile")
    cmd = `docker build -f $(docker_file) -t $(image_name) $(DOCKER_PATH)`

    try
        run(cmd)
        @info "Docker image $(image) built"
    catch
        error("Can't build docker image")
    end
end

function DockerBuilder(state::BuildState; cwd = nothing, envs = Dict())
    image_name = DOCKER_IMAGE_NAME
    build_image()
    docker_cmd = `docker run --rm `
    if !isnothing(cwd)
        docker_cmd = `$(docker_cmd) -w $(cwd) `
    end

    if !isnothing(state.workspace)
        docker_cmd = `$(docker_cmd) -v $(realpath(state.workspace)):/workspace:rw`
    end

    # Build up environment mappings
    for (k, v) in envs
        docker_cmd = `$docker_cmd -e $k=$v`
    end
    return DockerBuilder(image_name = DOCKER_IMAGE_NAME, base_cmd = docker_cmd)
end

function default_docker_builder(state::BuildState)
    return DockerBuilder(state,
        cwd = "/workspace/source/",
        envs = Dict(
            "PACKAGE_NAME" => state.py_pkg_name,
            "SOURCE_DIR" => "/workspace/source",
            "DEST_DIR" => "/workspace/dest",
        )
    )
end

function Base.run(docker::DockerBuilder, cmd, logger::IO=stdout; verbose=true)
    did_succeed = true
    dcmd = docker_cmd(docker, cmd)
    @debug("About to run: $(dcmd)")

    try
        oc = OutputCollector(dcmd; verbose=verbose)
        did_succeed = wait(oc)

        println(logger, cmd)
        print(logger, merge(oc))
    finally
    end

    return did_succeed
end

function Base.read(docker::DockerBuilder, cmd; verbose=true)
    did_succeed = true
    dcmd = docker_cmd(docker, cmd)
    @debug("About to run: $(dcmd)")

    local oc
    did_succeed = false
    try
        oc = OutputCollector(dcmd; verbose=verbose)
        did_succeed = wait(oc)
    finally
    end

    if !did_succeed
        print(stderr, collect_stderr(oc))
        return nothing
    end

    return collect_stdout(oc)
end

function run_interactive(docker::DockerBuilder, cmd::Cmd; in = Base.stdin, out = Base.stdout, err = Base.stderr, history_file = nothing)
    function is_tty(s)
        return typeof(s) <: Base.TTY
    end
    run_flags = all(is_tty.((in, out, err))) ? ["-ti"] : ["-i"]
    if !isnothing(history_file)
        push!(run_flags, "-v")
        push!(run_flags, "$(realpath(history_file)):/root/.bash_history")
    end
    dcmd = docker_cmd(docker, cmd.exec, flags = run_flags)
    if cmd.ignorestatus
        dcmd = ignorestatus(dcmd)
    end
    println(dcmd)
    @debug("About to run: $(dcmd)")

    try
        if stdout isa IOBuffer
            if !(stdin isa IOBuffer)
                stdin = devnull
            end
            process = open(dcmd, "r", stdin)
            @async begin
                while !eof(process)
                    write(stdout, read(process))
                end
            end
            wait(process)
            return success(process)
        else
            return success(run(dcmd))
        end
    finally
    end
end