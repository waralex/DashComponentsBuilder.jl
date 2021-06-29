using UUIDs
@testset "uuid" begin
    #let's check that the generator works the same way as in python, i.e. it gives the same uuids
    dash_core_uuid_str = "1b08a953-4be3-4667-9a23-9da06441d987"
    dash_html_uuid_str = "1b08a953-4be3-4667-9a23-24100242a84a"
    @test UUID(dash_core_uuid_str) == DCB.package_uuid("DashCoreComponents")
    @test UUID(dash_html_uuid_str) == DCB.package_uuid("DashHtmlComponents")
end