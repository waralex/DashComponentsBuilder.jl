using UUIDs
import Pkg
@testset "uuid" begin
    #let's check that the generator works the same way as in python, i.e. it gives the same uuids
    dash_core_uuid_str = "1b08a953-4be3-4667-9a23-9da06441d987"
    dash_html_uuid_str = "1b08a953-4be3-4667-9a23-24100242a84a"
    @test UUID(dash_core_uuid_str) == DCB.package_uuid("DashCoreComponents")
    @test UUID(dash_html_uuid_str) == DCB.package_uuid("DashHtmlComponents")
end

@testset "generate pypi" begin
    recipe = read("test_recipes/DashDaq/Recipe.yml", DCB.Recipe)
    @test recipe.name == "DashDaq"
    rm("test_pkgs", force = true, recursive = true)
    mkdir("test_pkgs")
    DCB.generate(recipe, "test_pkgs")
    pkg_path = joinpath("test_pkgs", "DashDaq")
    @test ispath(pkg_path)
    Pkg.add(url = "https://github.com/plotly/DashBase.jl.git", rev = "generate_components")
    using DashBase
    Pkg.develop(url = pkg_path)
    using DashDaq
    c = @test_nowarn daq_colorpicker(id = "ffff")
    @test c isa DashBase.Component
    Pkg.rm("DashDaq")
    Pkg.rm("DashBase")
end

@testset "generate repo" begin
    recipe = read("test_recipes/DashEditorComponents/Recipe.yml", DCB.Recipe)
    @test recipe.name == "DashEditorComponents"
    rm("test_pkgs", force = true, recursive = true)
    mkdir("test_pkgs")
    DCB.generate(recipe, "test_pkgs")
    pkg_path = joinpath("test_pkgs", "DashEditorComponents")
    @test ispath(pkg_path)
    Pkg.add(url = "https://github.com/plotly/DashBase.jl.git", rev = "generate_components")
    using DashBase
    Pkg.develop(url = pkg_path)
    using DashEditorComponents
    c = @test_nowarn dec_pythoneditor(id = "ffff")
    @test c isa DashBase.Component
    Pkg.rm("DashEditorComponents")
    Pkg.rm("DashBase")
end

@testset "generate pypi by dir" begin
    rm("test_pkgs", force = true, recursive = true)
    mkdir("test_pkgs")
    DCB.generate(joinpath("test_recipes","DashDaq"), "test_pkgs")
    pkg_path = joinpath("test_pkgs", "DashDaq")
    @test ispath(pkg_path)
    Pkg.add(url = "https://github.com/plotly/DashBase.jl.git", rev = "generate_components")
    using DashBase
    Pkg.develop(url = pkg_path)
    using DashDaq
    c = @test_nowarn daq_colorpicker(id = "ffff")
    @test c isa DashBase.Component
    Pkg.rm("DashDaq")
    Pkg.rm("DashBase")
end