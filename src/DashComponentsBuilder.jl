module DashComponentsBuilder
    using ProgressMeter
    import LibGit2
    import TOML
    using OrderedCollections
    using Conda
    using PyCall
    import YAML
    using Pkg
    using Pkg.Artifacts
    import GitHub
    import GitHub: gh_get_json, DEFAULT_API
    using HTTP
    import JSON
    using ghr_jll
    using JSON3
    using OutputCollectors
    import REPL
    using REPL.TerminalMenus
    import MD5
    using UUIDs
    import SHA:sha256
    import Registrator
    using ghr_jll

    const DOCKER_PATH = realpath(joinpath(@__DIR__, "..", "docker"))
    const DEFAULT_JULIA_COMPAT = "1.5"
    const DASH_BASE_COMPAT = "0.1.1"
    const RECIPE_REGISTY = "waralex/DashComponentsRecipes"
    const DEPLOY_ORG = "waralex"
    include("git/_git.jl")
    include("build/_build.jl")
    include("deploy/_deploy.jl")
    include("generator/_generator.jl")
    include("wizard/_wizard.jl")
    include("ci/_ci.jl")
end
