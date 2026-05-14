using Test
using LegacyConnectors
using Breeze

@testset "Breeze interop: set!(Field, SoundingProfile)" begin
    grid = RectilinearGrid(CPU();
        size = (1, 1, 16),
        x = (0, 1), y = (0, 1), z = (0, 16_000),
        topology = (Periodic, Periodic, Bounded))

    s = Sounding(:weisman_klemp_1982)

    Nz = size(grid, 3)

    @testset "θ profile" begin
        θ = CenterField(grid)
        set!(θ, s.θ)
        @test θ[1, 1, 1]  ≥ s.surface_θ
        @test θ[1, 1, Nz] > 343.0
        column = [θ[1, 1, k] for k in 1:Nz]
        @test issorted(column)
        @test all(isfinite, column)
    end

    @testset "qv profile" begin
        qv = CenterField(grid)
        set!(qv, s.qv)
        @test qv[1, 1, 1] ≈ s.surface_qv atol = 1e-3
        # qv is *not* monotone above the tropopause (T_tr constant, p drops,
        # so qvs and RH·qvs can rise) — just check bounded and nonnegative.
        column = [qv[1, 1, k] for k in 1:Nz]
        @test all(≥(0), column)
        @test maximum(column) ≤ s.surface_qv + 1e-12
    end

    @testset "u, v profiles" begin
        u = CenterField(grid); v = CenterField(grid)
        set!(u, s.u)
        set!(v, s.v)
        u_col = [u[1, 1, k] for k in 1:Nz]
        v_col = [v[1, 1, k] for k in 1:Nz]
        @test maximum(u_col) ≤ 30.0 + 1e-9
        @test all(==(0.0), v_col)
    end

    @testset "still works for analytic forms" begin
        # The whole point of extending Breeze.set! rather than shadowing
        # is so set!(field, fn) also works through the same function.
        θ = CenterField(grid)
        set!(θ, (x, y, z) -> 300 + 0.01z)
        @test θ[1, 1, 1]  ≈ 300 + 0.01 * znodes(θ)[1] atol = 1e-9
        @test θ[1, 1, Nz] ≈ 300 + 0.01 * znodes(θ)[Nz] atol = 1e-9
    end
end

@testset "Breeze interop: reference_state" begin
    grid = RectilinearGrid(CPU();
        size = (1, 1, 32),
        x = (0, 1), y = (0, 1), z = (0, 16_000),
        topology = (Periodic, Periodic, Bounded))

    s   = Sounding(:weisman_klemp_1982)
    ref = LegacyConnectors.reference_state(s, grid)

    @test ref.surface_pressure      ≈ s.surface_pressure rtol = 1e-12
    @test ref.potential_temperature ≈ s.surface_θ         rtol = 1e-12

    p_col = [ref.pressure[1, 1, k]    for k in 1:size(grid, 3)]
    ρ_col = [ref.density[1, 1, k]     for k in 1:size(grid, 3)]
    T_col = [ref.temperature[1, 1, k] for k in 1:size(grid, 3)]
    @test issorted(p_col; rev = true)
    @test issorted(ρ_col; rev = true)
    @test all(isfinite, T_col)
    @test minimum(T_col) > 150 && maximum(T_col) < 320
end
