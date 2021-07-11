struct BuildSource
    url ::String
    hash ::String
end
Base.@kwdef mutable struct BuildState
    workspace ::Union{String, Nothing} = nothing
    source ::Union{BuildSource, Nothing} = nothing
    metadata_json ::Union{String,Nothing} = nothing
    requirements_file::Union{String, Nothing} = nothing
    py_pkg_name ::Union{String, Nothing} = nothing
    py_pkg_version ::Union{String, Nothing} = nothing
    jl_pkg_name ::Union{String, Nothing} = nothing
    jl_prefix ::Union{String, Nothing} = nothing
    is_pypi ::Bool = false
    raw_pkg_meta = nothing
    build_script ::Union{String, Nothing} = nothing
end

function init_buildstate(;kwargs...)
    workspace = mktempdir()
    mkpath(joinpath(workspace, "dest"))
    return BuildState(;kwargs..., workspace = workspace)
end


source_dir(state::BuildState) = abspath(joinpath(state.workspace, "source"))

dest_dir(state::BuildState) = abspath(joinpath(state.workspace, "dest"))

source_path(state::BuildState, args...) = joinpath(source_dir(state), args...)
dest_path(state::BuildState, args...) = joinpath(dest_dir(state), args...)

cleanup_source_dir(state::BuildState) = rm(source_dir(state), force = true, recursive = true)

has_metadata_json(state::BuildState) = !isnothing(state.metadata_json)

has_requirements(state::BuildState) = !isnothing(state.requirements_file)

has_raw_pkg_meta(state::BuildState) = !isnothing(state.raw_pkg_meta)