flat_string(s::AbstractString) = replace(strip(s), "\n"=>" ")

macro flat_str(s::String)
    return flat_string(s)
end

function canonicalize_source_url(url)
    repo_regex = r"(https:\/\/)?github.com\/([^\/]+)\/([^\/]+)\/?$"

    m = match(repo_regex, url)
    if m !== nothing
        _, user, repo = m.captures
        if !endswith(repo, ".git")
            return "https://github.com/$user/$repo.git"
        end
    end
    url
end

function parse_git_url(url)
    repo_regex = r"(https:\/\/)?github.com\/([^\/]+)\/([^\/]+)\.git?$"
    m = match(repo_regex, url)
    isnothing(m) && return nothing
    _, user, repo = m.captures
    return (user, repo)
end

function default_py_pkg_name(url)
    _, repo = parse_git_url(url)
    return replace(repo, "-"=>"_")
end

is_like_git_url(url) = !isnothing(parse_git_url(url))

function line_prompt(name, msg; ins=stdin, outs=stdout, force_identifier=false, echo=true, default = nothing)
    while true
        print(outs, msg, "\n", name, isnothing(default) ? "" : string(" [", default, "]") ,"> ")
        if echo
            val = strip(readline(ins))
        else
            val = strip(read(_getpass(ins), String))
        end
        if !isopen(ins)
            throw(InterruptException())
        end
        println(outs)
        if isempty(val) && !isnothing(default)
            val = default
        end
        if !isempty(val) && force_identifier && !Base.isidentifier(val)
            printstyled(outs, "$(name) must be an identifier!\n", color=:red)
            continue
        end
        return val
    end
end

function nonempty_line_prompt(name, msg; outs=stdout, kwargs...)
    while true
        val = line_prompt(name, msg; outs=outs, kwargs...)
        if isempty(val)
            printstyled(outs, "$(name) may not be empty!\n", color=:red)
            continue
        end
        return val
    end
end

function yn_prompt(question::AbstractString, default = :y; outs = stdout)
    @assert default in (:y, :n)
    ynstr = default == :y ? "[Y/n]" : "[y/N]"
    while true
        print(outs, question, " ", ynstr, ": ")
        answer = lowercase(strip(readline(stdin)))
        if isempty(answer)
            return default
        elseif answer == "y" || answer == "yes"
            return :y
        elseif answer == "n" || answer == "no"
            return :n
        else
            println(outs, "Unrecognized answer. Answer `y` or `n`.")
        end
    end
end

function find_file(file::AbstractString, dir::AbstractString = pwd(); exclude = [])
    function check_exclude(name)
        for e in exclude
            occursin(e, name) && return false
        end
        return true
    end
    result = String[]
    content = readdir(dir)
    append!(result, joinpath.(Ref(dir), filter(x->x==file, content)))
    for f in content
        full_path = joinpath(dir, f)
        if isdir(full_path) && check_exclude(f)
            r = find_file(file, full_path; exclude = exclude)
            append!(result,
             r
            )
        end
    end
    return result
end

function find_metadata_json(repo_dir)
    return relpath.(
        find_file("metadata.json", repo_dir; exclude = [r"__.*", r"\..*"]),
        Ref(repo_dir)
    )
end

function make_docker_builder!(state::WizardState; force = false)
    if force || isnothing(state.builder)
        state.builder = default_docker_builder(state.build_state)
    end
end