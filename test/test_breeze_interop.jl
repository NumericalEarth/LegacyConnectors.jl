using Test
using LegacyConnectors
using Breeze

@testset "Breeze interop: set!(Field, Sounding)" begin
    grid = RectilinearGrid(CPU();
        size = (1, 1, 16),
        x = (0, 1), y = (0, 1), z = (0, 16_000),
        topology = (Periodic, Periodic, Bounded))

    s = read_sounding(example_sounding(:weisman_klemp_1982))

    Nz = size(grid, 3)

    @testset "θ profile" begin
        θ = CenterField(grid)
        LegacyConnectors.set!(θ, s; profile = :θ)
        # Lowest grid level is above the surface; θ there should be above
        # the surface value (W-K θ increases monotonically with z).
        @test θ[1, 1, 1]  ≥ s.surface_θ
        # Topmost interior grid level should sit above the tropopause.
        @test θ[1, 1, Nz] > 343.0
        # Values monotone in z (W-K θ is monotone increasing).
        column = [θ[1, 1, k] for k in 1:Nz]
        @test issorted(column)
        @test all(isfinite, column)
    end

    @testset "qv profile" begin
        qv = CenterField(grid)
        LegacyConnectors.set!(qv, s; profile = :qv)
        # Lowest grid level qv should hit (or be near) the surface cap.
        @test qv[1, 1, 1] ≈ s.surface_qv atol = 1e-3
        # qv stays bounded by the surface cap and never goes negative.
        # (W-K qv is *not* monotone above the tropopause: T_tr is constant
        # while p drops, so qvs and therefore qv = RH·qvs can rise again.)
        column = [qv[1, 1, k] for k in 1:Nz]
        @test all(≥(0), column)
        @test maximum(column) ≤ s.surface_qv + 1e-12
    end

    @testset "u, v profiles" begin
        u = CenterField(grid); v = CenterField(grid)
        LegacyConnectors.set!(u, s; profile = :u)
        LegacyConnectors.set!(v, s; profile = :v)
        u_col = [u[1, 1, k] for k in 1:Nz]
        v_col = [v[1, 1, k] for k in 1:Nz]
        # u capped at 30 m/s; v is identically zero in the W-K bundle.
        @test maximum(u_col) ≤ 30.0 + 1e-9
        @test all(==(0.0), v_col)
    end

    @testset "errors" begin
        f = CenterField(grid)
        @test_throws ArgumentError LegacyConnectors.set!(f, s; profile = :nope)
    end
end

@testset "Breeze interop: reference_state scaffold" begin
    @test isdefined(LegacyConnectors, :reference_state)
    @test isempty(methods(LegacyConnectors.reference_state))
end
