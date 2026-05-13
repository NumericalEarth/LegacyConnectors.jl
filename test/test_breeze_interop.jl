using Test
using LegacyConnectors

# Breeze interop is a v0.1 scaffold: `set!` and `reference_state` are
# declared but have no methods yet. We assert their presence so we
# notice if they get removed, and we exercise the no-method path so
# downstream code gets a clear MethodError until the implementation
# lands.

@testset "Breeze interop scaffold" begin
    @test isdefined(LegacyConnectors, :set!)
    @test isdefined(LegacyConnectors, :reference_state)

    # Functions exist but currently have no methods.
    @test isempty(methods(LegacyConnectors.set!))
    @test isempty(methods(LegacyConnectors.reference_state))
end
