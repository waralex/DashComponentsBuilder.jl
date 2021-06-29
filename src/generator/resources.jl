function convert_deps_part(relative, external)
    result = Dict{Symbol, String}[]
    for i in eachindex(relative)
        d = OrderedDict{Symbol, String}()
        d[:relative_package_path] = relative[i]
        if !isnothing(external)
            d[:external_url] = external[i]
        end
        push!(result, d)
    end
    return result
end
function convert_deps(pyresources)
    relative_paths = pyresources["relative_package_path"]
    external_urls = get(pyresources, "external_url", nothing)
    result = OrderedDict{Symbol, Any}()
    result[:namespace] = pyresources["namespace"]
    if haskey(relative_paths, "prod")
        result[:prod] = convert_deps_part(
            relative_paths["prod"],
            isnothing(external_urls) ? nothing : external_urls["prod"]
            )
    end
    if haskey(relative_paths, "dev")
        result[:dev] = convert_deps_part(
            relative_paths["dev"],
            isnothing(external_urls) ? nothing : external_urls["dev"]
            )
    end
    return result
end

function _process_dist_part!(dict, resource, type)
    ns_symbol = Symbol(resource["namespace"])
    if !haskey(dict, ns_symbol)
        dict[ns_symbol] = OrderedDict(
            :namespace => resource["namespace"],
            :resources => Dict[]
        )
    end
    data = filter(v->v.first != "namespace", resource)
    data[:type] = type
    push!(
        dict[ns_symbol][:resources], data
        )
end
function convert_resources(js_dist, css_dist)
    result = OrderedDict{Symbol, Any}()
    _process_dist_part!.(Ref(result), js_dist, :js)
    _process_dist_part!.(Ref(result), css_dist, :css)
    return collect(values(result))
end

function deps_files(pyresources)
    relative_paths = pyresources["relative_package_path"]
    result = String[]
    if haskey(relative_paths, "prod")
        append!(result, relative_paths["prod"])
    end
    if haskey(relative_paths, "dev")
        append!(result, relative_paths["dev"])
    end
    return result
end

function resources_files(pyresources)
    result = String[]
    for res in pyresources
        if haskey(res, "relative_package_path")
            push!(result, res["relative_package_path"])
        end
        if haskey(res, "dev_package_path")
            push!(result, res["dev_package_path"])
        end
    end
    return result
end