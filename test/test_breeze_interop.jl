using Test
using LegacyConnectors
using Breeze
import Breeze.Oceananigans.Fields: interpolate!

@testset "Breeze interop: interpolate!(Field, sounding column)" begin
    grid = RectilinearGrid(CPU();
        size = (1, 1, 16),
        x = (0, 1), y = (0, 1), z = (0, 16_000),
        topology = (Periodic, Periodic, Bounded))

    s = Sounding(:weisman_klemp_1982)
    Nz = size(grid, 3)

    @testset "potential_temperature" begin
        θ = CenterField(grid)
        interpolate!(θ, s.potential_temperature)
        @test θ[1, 1, 1]  ≥ s.potential_temperature[1, 1, 1]
        @test θ[1, 1, Nz] > 343.0
        column = [θ[1, 1, k] for k in 1:Nz]
        @test issorted(column)
        @test all(isfinite, column)
    end

    @testset "specific_humidity" begin
        qᵛ = CenterField(grid)
        interpolate!(qᵛ, s.specific_humidity)
        @test qᵛ[1, 1, 1] ≈ s.specific_humidity[1, 1, 1] atol = 1e-3
        column = [qᵛ[1, 1, k] for k in 1:Nz]
        @test all(≥(0), column)
        @test maximum(column) ≤ s.specific_humidity[1, 1, 1] + 1e-12
    end

    @testset "x_momentum, y_momentum" begin
        u = CenterField(grid); v = CenterField(grid)
        interpolate!(u, s.x_momentum)
        interpolate!(v, s.y_momentum)
        u_col = [u[1, 1, k] for k in 1:Nz]
        v_col = [v[1, 1, k] for k in 1:Nz]
        @test maximum(u_col) ≤ 30.0 + 1e-9
        @test all(==(0.0), v_col)
    end

    @testset "horizontal broadcast" begin
        grid_h = RectilinearGrid(CPU();
            size = (3, 3, 8),
            x = (0, 1), y = (0, 1), z = (0, 16_000),
            topology = (Periodic, Periodic, Bounded))
        θ = CenterField(grid_h)
        interpolate!(θ, s.potential_temperature)
        for k in 1:8
            @test θ[1, 1, k] == θ[2, 2, k] == θ[3, 3, k]
        end
    end
end

@testset "Breeze interop: reference_state" begin
    grid = RectilinearGrid(CPU();
        size = (1, 1, 32),
        x = (0, 1), y = (0, 1), z = (0, 16_000),
        topology = (Periodic, Periodic, Bounded))

    s   = Sounding(:weisman_klemp_1982)
    ref = LegacyConnectors.reference_state(s, grid)

    @test ref.surface_pressure      ≈ s.surface_pressure                 rtol = 1e-12
    @test ref.potential_temperature ≈ s.potential_temperature[1, 1, 1]   rtol = 1e-12

    p_col = [ref.pressure[1, 1, k]    for k in 1:size(grid, 3)]
    ρ_col = [ref.density[1, 1, k]     for k in 1:size(grid, 3)]
    T_col = [ref.temperature[1, 1, k] for k in 1:size(grid, 3)]
    @test issorted(p_col; rev = true)
    @test issorted(ρ_col; rev = true)
    @test all(isfinite, T_col)
    @test minimum(T_col) > 150 && maximum(T_col) < 320
end
