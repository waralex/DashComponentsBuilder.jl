using UUIDs
# uuid of Dash.jl package. Used as base for component package uuid
const dash_uuid = UUID("1b08a953-4be3-4667-9a23-3db579824955")

dev_dir(recipe::Recipe) = joinpath(Pkg.devdir(), recipe.name)
function cleanup_code_dir(dir)
    !isdir(dir) && return
    rm(joinpath(dir, "src"), force =true, recursive = true)
    rm(joinpath(dir, "Project.toml"), force =true)
    rm(joinpath(dir, "Manifest.toml"), force =true)
    rm(joinpath(dir, "Artifacts.toml"), force =true)
end
function generate_package(recipe::Recipe, state::BuildState, dir = dev_dir(recipe))
    cleanup_code_dir(dir)
    mkpath(dir)
    mkpath(joinpath(dir, "src"))
    make_project_toml(recipe, dir)
    make_project_source(recipe, dir)
    hash = make_artifact(recipe, state, dir)
    make_artifacs_file(recipe, hash, dir)
end

function package_uuid(name)
    base_bytes = reinterpret(UInt8, [bswap(dash_uuid.value)])
    pkg_bytes = MD5.md5(name)
    result_bytes = vcat(base_bytes[1:10], pkg_bytes[11:end])
    result_value = bswap(
        reinterpret(UInt128, result_bytes)[1]
    )
    return UUID(result_value)
end

function project_dict(recipe)
    project = Dict(
        "name" => recipe.name,
        "uuid" => string(package_uuid(recipe.name)),
        "version" => string(recipe.version),
        "deps" => Dict{String,Any}(),
        "compat" => Dict{String,Any}("DashBase" => "0.1.1",
                                     "julia" => DEFAULT_JULIA_COMPAT)
    )
    project["deps"]["Pkg"] = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
    project["deps"]["Artifacts"] = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"
    project["deps"]["DashBase"] = "03207cf0-e2b3-4b91-9ca8-690cf0fb507e"

    return project
end
function make_project_toml(recipe::Recipe, dir = dev_dir(recipe))
    open(joinpath(dir, "Project.toml"), "w") do io
        TOML.print(io, project_dict(recipe))
    end
end

function make_project_source(recipe::Recipe, dir = dev_dir(recipe))
    open(joinpath(dir, "src", recipe.name * ".jl"), "w") do io
        body = """module $(recipe.name)

        using DashBase
        import Pkg
        using Pkg.Artifacts

        DashBase.@generate_wrapper()
        @generate_components

        end
        """
        print(io, body)
    end
end

function make_artifact(recipe::Recipe, state::BuildState, dir = dev_dir(recipe))
    metadata_json = JSON3.read(
        read(
            source_path(state, state.metadata_json),
            String
        )
        )
    components_meta = process_components_meta(metadata_json)
    js_dist = haskey(state.raw_pkg_meta, :js_dist) ? state.raw_pkg_meta[:js_dist] : []
    css_dist = haskey(state.raw_pkg_meta, :css_dist) ? state.raw_pkg_meta[:css_dist] : []
    meta = OrderedDict(
        :version => recipe.version,
        :name => recipe.py_package,
        :deps => convert_resources(js_dist, css_dist),
        :prefix => recipe.prefix,
        :components => components_meta
    )
    files = vcat(resources_files(js_dist), resources_files(css_dist))
    artifact_hash = create_artifact() do dir
        YAML.write_file(joinpath(dir, "meta.yml"), meta)

        mkpath(joinpath(dir, "deps"))
        for f in files
            src_path = source_path(state, state.py_pkg_name, f)
            if !isfile(src_path)
                @warn "$(f) don't exists, skiped"
                continue
            end
            rel_dir, _ = splitdir(f)
            !isempty(rel_dir) && mkpath(joinpath(dir, "deps", rel_dir))
            cp(src_path, joinpath(dir, "deps", f), force = true)
        end
    end
    return artifact_hash
end
function make_artifacs_file(recipe::Recipe, hash, dir = dev_dir(recipe))
    artifact_file = joinpath(dir, "Artifacts.toml")
    bind_artifact!(artifact_file, "resources", hash, force = true)
end