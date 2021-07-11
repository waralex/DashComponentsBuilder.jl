struct Recipe
    name ::String
    version ::VersionNumber
    py_package ::String
    type ::Symbol #"pypi" or "github"
    source ::Union{BuildSource, Nothing}
    prefix ::String
    build_script ::Union{String, Nothing}
end

function Recipe(state::BuildState)
    return Recipe(
        state.jl_pkg_name,
        VersionNumber(state.raw_pkg_meta[:version]),
        state.py_pkg_name,
        state.is_pypi ? :pypi : :github,
        !state.is_pypi ? state.source : nothing,
        state.jl_prefix,
        (!isnothing(state.build_script) && !isempty(state.build_script)) ? state.build_script : nothing
    )
end

function init_buildstate(recipe::Recipe;kwargs...)
    state = init_buildstate(;kwargs...)
    state.source = recipe.source
    state.py_pkg_name = recipe.py_package
    state.jl_pkg_name = recipe.name
    state.build_script = recipe.build_script
    state.is_pypi = recipe.type == :pypi
    state.py_pkg_version = string(recipe.version)
    state.jl_prefix = recipe.prefix
    return state
end

function Base.write(io::IO, recipe::Recipe)
    dict = OrderedDict(
        :name => recipe.name,
        :version => string(recipe.version),
        :py_package => recipe.py_package,
        :type => recipe.type,
        :prefix => recipe.prefix
    )
    if !isnothing(recipe.build_script)
        dict[:build_script] = recipe.build_script
    end
    if !isnothing(recipe.source)
        dict[:source] = OrderedDict(
            :url => recipe.source.url,
            :hash => recipe.source.hash
        )
    end
    write(io, YAML.write(dict))
end

Base.print(io::IO, recipe::Recipe) = write(io, recipe)


function Base.read(io::IO, ::Type{Recipe})
    dict = YAML.load(read(io, String))
    source = haskey(dict, "source") ?
        BuildSource(dict["source"]["url"], dict["source"]["hash"]) :
        nothing

    return Recipe(
        dict["name"],
        VersionNumber(dict["version"]),
        dict["py_package"],
        dict["type"] == "pypi" ? :pypi : :github,
        source,
        dict["prefix"],
        haskey(dict, "build_script") ? dict["build_script"] : nothing
    )

end
