@testset "Recipe IO" begin
    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        DCB.BuildSource("http://gitgit", "aacccddd"),
        "dt",
        raw"""
        npm init
        npm install
        npm build
        """
    )
    io = PipeBuffer()
    write(io, rec)
    rec2 = read(io, DCB.Recipe)
    @test rec == rec2

    rec = DCB.Recipe(
        "DashTest",
        VersionNumber("1.2.0"),
        "dash_test",
        DCB.BuildSource("http://gitgit", "aacccddd"),
        "dt",
        nothing
    )
    write("test_rec.yml", rec)

    rec2 = read("test_rec.yml", DCB.Recipe)
    @test rec == rec2
end