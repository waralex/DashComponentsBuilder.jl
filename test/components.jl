import JSON3

@testset "extract_component_name" begin
    @test  DCB.extract_component_name("src/componets/A.react.js") == "A"
    @test  DCB.extract_component_name("src/componets/A.js") == "A"
    @test  DCB.extract_component_name("A.js") == "A"
    @test  DCB.extract_component_name("/asss/ddd/ffff/A.r.w.rjs") == "A"
end
@testset "filter arg" begin
    props = JSON3.read(
        read("testprops.json", String)
    )["test.js"]["props"]
    filtered = filter(DCB.filter_arg, props)
    @test keys(filtered) == Set([:type_string, :flow_signature, :flow_string])
end
@testset "component meta" begin
    test_meta = JSON3.read(
        read("testmetadata.json", String)
    )
    result = DCB.process_components_meta(test_meta)

    @test length(result) == 2
    @test result[1][:name] == :A
    @test result[2][:name] == :Abbr

    a = result[1]
    @test sort(a[:args]) == sort(
        [:id, :children, :key, :hidden, :style, :loading_state]
    )
    @test sort(a[:wild_args]) == sort(
        [:aria, :data]
    )
end