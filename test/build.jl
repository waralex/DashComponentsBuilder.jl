@testset "Recipe IO" begin
    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        :githab,
        DCB.BuildSource("http://gitgit", "aacccddd"),
        "dt",
        """
        npm init
        npm install
        npm build
        """
    )
    io = PipeBuffer()
    write(io, rec)
    rec2 = read(io, DCB.Recipe)
    @test rec.name == rec2.name
    @test rec.version == rec2.version
    @test rec.py_package == rec2.py_package
    @test rec.source == rec2.source
    @test rec.prefix == rec2.prefix
    @test rec.build_script == rec2.build_script

    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        :pypi,
        nothing,
        "dt",
        nothing
    )
    write("test_rec.yml", rec)

    rec2 = read("test_rec.yml", DCB.Recipe)
    @test rec == rec2
end

@testset "init buildstate" begin
    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        :pypi,
        nothing,
        "dt",
        nothing
    )
    state = DCB.init_buildstate(rec)
    @test !isnothing(state.workspace)
    @test ispath(DCB.dest_dir(state))
    @test isnothing(state.source)
    @test state.py_pkg_name == rec.py_package
    @test state.py_pkg_version == string(rec.version)
    @test state.jl_pkg_name == rec.name
    @test state.jl_prefix == rec.prefix
    @test state.is_pypi

    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        :githab,
        DCB.BuildSource("http://gitgit", "aacccddd"),
        "dt",
        """
        npm init
        npm install
        npm build
        """
    )

    state = DCB.init_buildstate(rec)
    @test !isnothing(state.workspace)
    @test ispath(DCB.dest_dir(state))
    @test state.source == rec.source
    @test state.py_pkg_name == rec.py_package
    @test state.py_pkg_version == string(rec.version)
    @test state.jl_pkg_name == rec.name
    @test state.jl_prefix == rec.prefix
    @test !state.is_pypi
end

@testset "default builder" begin
    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        :githab,
        DCB.BuildSource("http://gitgit", "aacccddd"),
        "dt",
        """
        npm init
        npm install
        npm build
        """
    )

    state = DCB.init_buildstate(rec)
    builder = DCB.default_builder(state)
    @test builder isa DCB.DockerBuilder
    ENV["BUILDER"] = "local"
    builder = DCB.default_builder(state)
    @test builder isa DCB.LocalBuilder
    ENV["BUILDER"] = "docker"
end

@testset "build $type" for type in ["local", "docker"]
    ENV["BUILDER"] = type
    @testset "build pypi" begin
        recipe = read("test_recipes/DashDaq/Recipe.yml", DCB.Recipe)
        @test recipe.name == "DashDaq"
        state = DCB.build(recipe; verbose = true)
        @test !isnothing(state.metadata_json) && !isempty(state.metadata_json)
        @test ispath(DCB.source_path(state, recipe.py_package))
        @test !isnothing(state.raw_pkg_meta)
        @test state.py_pkg_version == string(recipe.version)
        @test state.raw_pkg_meta[:version] == string(recipe.version)
    end

    @testset "build repo" begin
        recipe = read("test_recipes/DashEditorComponents/Recipe.yml", DCB.Recipe)
        @test recipe.name == "DashEditorComponents"
        state = DCB.build(recipe)
        @test !isnothing(state.metadata_json) && !isempty(state.metadata_json)
        @test ispath(DCB.source_path(state, recipe.py_package))
        @test !isnothing(state.raw_pkg_meta)
        @test state.py_pkg_version == string(recipe.version)
        @test state.raw_pkg_meta[:version] == string(recipe.version)
    end
    @testset "build repo npm" begin
        recipe = read("test_recipes/DashBootstrapComponents/Recipe.yml", DCB.Recipe)
        @test recipe.name == "DashBootstrapComponents"
        state = DCB.build(recipe; verbose = true)
        @test !isnothing(state.metadata_json) && !isempty(state.metadata_json)
        @test ispath(DCB.source_path(state, recipe.py_package))
        @test !isnothing(state.raw_pkg_meta)
        @test state.py_pkg_version == string(recipe.version)
        @test state.raw_pkg_meta[:version] == string(recipe.version)
    end
end