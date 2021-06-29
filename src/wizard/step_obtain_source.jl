
function step_obtain_source!(state::WizardState)
    msg = "\t\t\t# Obtain the source code\n\n"
    printstyled(msg, bold=true)
    url = nothing
    while isnothing(url)
        # First, ask the user where this is all coming from
        msg = flat"""
        Please enter a URL of git repository  containing the
        source code of components package:
        """
        new_url = nonempty_line_prompt("URL", msg)

        # Early-exit for invalid URLs, using HTTP.URIs.parse_uri() to ensure
        # it is a valid URL
        try
            HTTP.URIs.parse_uri(new_url; strict=true)
            url = canonicalize_source_url(new_url)

            !is_like_git_url(url) && error("$(url) is not a git repository url")
            if url != new_url
                print("The entered URL has been canonicalized to\n")
                printstyled(url, bold=true)
                println()
                println()
            end

        catch e
            printstyled(e.msg, color=:red, bold=true)
            println()
            println()
            url = nothing
            continue
        end
    end

    cleanup_source_dir(state.build_state)

    source_path = source_dir(state.build_state)
    repo = clone(url, source_path)

    msg = "Please enter a branch, commit or tag to use.\n" *
    "Please note that for reproducibility, the exact commit will be recorded"

    local treeish = nothing
    local obj
    while isnothing(treeish)
        treeish = nonempty_line_prompt("git reference", msg)

        try
            obj = try
                LibGit2.GitObject(repo, treeish)
            catch
                LibGit2.GitObject(repo, "origin/$treeish")
            end
        catch
            printstyled("Can't find `$(treeish)` branch, commit or tag", color = :red, bold=true)
            println()
            println()
            treeish = nothing
        end
    end
    source_hash = LibGit2.string(LibGit2.GitHash(obj))

    # Tell the user what we recorded the current commit as
    print("Recorded as ")
    printstyled(source_hash, bold=true)
    println()
    LibGit2.checkout!(repo, source_hash)
    close(repo)
    state.build_state.source = BuildSource(url, source_hash)

    default_py_pkg = default_py_pkg_name(url)
    msg = "Please enter a python package name corresponded to the repo if it differs from `$(default_py_pkg)`"
    py_pkg_name = line_prompt("name", msg, force_identifier = true, default = default_py_pkg)
    state.build_state.py_pkg_name = py_pkg_name
    state.next_step = step_build_choose!
end