using Test
using LegacyConnectors

@testset "LegacyConnectors" begin
    include("test_input_sounding.jl")
    include("test_breeze_interop.jl")
end
