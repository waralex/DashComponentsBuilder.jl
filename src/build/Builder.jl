abstract type Builder end

function default_builder(state::BuildState)
    builder_env = lowercase(get(ENV, "BUILDER", "docker"))

    builder_env == "docker" && return DockerBuilder(state)
    builder_env == "local" && return LocalBuilder(state)

    error("undefined builder type $(builder_env)")
end