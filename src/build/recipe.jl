struct Recipe
    name ::String
    version ::VersionNumber
    py_package ::String
    source ::BuildSource
    prefix ::String
    build_script ::Union{String, Nothing}
end

function Recipe(state::BuildState)
    return Recipe(
        state.jl_pkg_name,
        VersionNumber(state.raw_pkg_meta[:version]),
        state.py_pkg_name,
        state.source,
        state.jl_prefix,
        !isnothing(state.build_script) && !isempty(state.build_script) ? state.build_script : nothing
    )
end

function Base.write(io::IO, recipe::Recipe)
    dict = OrderedDict(
        :name => recipe.name,
        :version => string(recipe.version),
        :py_package => recipe.py_package,
        :source => OrderedDict(
            :url => recipe.source.url,
            :hash => recipe.source.hash,
        ),
        :prefix => recipe.prefix
    )
    if !isnothing(recipe.build_script)
        dict[:build_script] = recipe.build_script
    end
    write(io, YAML.write(dict))
end

Base.print(io::IO, recipe::Recipe) = write(io, recipe)


function Base.read(io::IO, ::Type{Recipe})
    dict = YAML.load(read(io, String))
    return Recipe(
        dict["name"],
        VersionNumber(dict["version"]),
        dict["py_package"],
        BuildSource(dict["source"]["url"], dict["source"]["hash"]),
        dict["prefix"],
        haskey(dict, "build_script") ? dict["build_script"] : nothing
    )

end
