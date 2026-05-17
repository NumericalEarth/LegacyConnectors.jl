using Test
using LegacyConnectors
using Breeze

@testset "Sounding constructor + input_sounding parser" begin

    @testset "constructor variants" begin
        s_path = Sounding(example_sounding(:weisman_klemp_1982))
        s_name = Sounding(:weisman_klemp_1982)
        @test s_path.surface_pressure == s_name.surface_pressure
        @test all(s_path.potential_temperature[1, 1, k] ==
                  s_name.potential_temperature[1, 1, k] for k in 1:length(s_path))
        @test s_path.source == s_name.source
    end

    @testset "Weisman-Klemp 1982 (bundled, generated)" begin
        s = Sounding(:weisman_klemp_1982)
        @test s.format === :input_sounding
        @test s.surface_pressure ≈ 100_000.0 atol = 1.0       # 1000 mb
        # Surface values live at index 1 (z = 0)
        @test s.potential_temperature[1, 1, 1] ≈ 300.0   atol = 1e-6
        @test s.specific_humidity[1, 1, 1]     ≈ 14.0e-3 atol = 1e-9
        # 1 surface cell + 65 above-surface levels = 66 z-cells
        @test length(s) == 66
        # Cell centers should sit exactly at [0, sounding_z...]
        zc = znodes(s.potential_temperature)
        @test zc[1] == 0.0
        @test zc[2] ≈ 50.0   atol = 1e-9
        @test issorted(zc)
        # Field types are concrete and identical across all four profiles
        @test typeof(s.potential_temperature) ==
              typeof(s.specific_humidity) ==
              typeof(s.x_momentum) ==
              typeof(s.y_momentum)
        # u capped at 30 m/s above 6 km, v ≡ 0
        u_col = [s.x_momentum[1, 1, k] for k in 1:length(s)]
        v_col = [s.y_momentum[1, 1, k] for k in 1:length(s)]
        @test maximum(u_col) ≈ 30.0 atol = 1e-6
        @test all(==(0.0), v_col)
        # θ at the tropopause (~12 km) is the W-K value of 343 K
        i_tr = findfirst(z -> z ≈ 12_000.0, zc)
        @test i_tr !== nothing
        @test s.potential_temperature[1, 1, i_tr] ≈ 343.0 atol = 0.5
    end

    @testset "KABQ radiosonde 2025-07-15 00Z" begin
        s = Sounding(:kabq_radiosonde)
        @test s.format === :input_sounding
        @test s.surface_pressure ≈ 83_900.0 atol = 1.0
        @test s.potential_temperature[1, 1, 1] ≈ 322.737875 atol = 1e-5
        @test s.specific_humidity[1, 1, 1]     ≈ 5.998407e-3 atol = 1e-9
        @test length(s) == 96                              # surface + 95 levels
        zc = znodes(s.potential_temperature)
        @test zc[1] == 0.0
        @test zc[2] ≈ 210.0 atol = 1e-6                    # first level AGL
        # No NaNs in qᵛ for this profile
        @test all(isfinite, [s.specific_humidity[1, 1, k] for k in 1:length(s)])
    end

    @testset "Abu Dhabi GFS 2025-07-15 12Z (NaN qᵛ aloft)" begin
        s = Sounding(:abudhabi_gfs)
        @test s.format === :input_sounding
        @test s.surface_pressure ≈ 99_110.6953 atol = 1.0
        @test length(s) == 33                              # surface + 32 levels
        qᵛ_col = [s.specific_humidity[1, 1, k] for k in 1:length(s)]
        @test any(isnan, qᵛ_col)
        last_finite = findlast(isfinite, qᵛ_col)
        first_nan   = findfirst(isnan,    qᵛ_col)
        @test last_finite !== nothing && first_nan !== nothing
        @test last_finite < first_nan
    end

    @testset "error handling" begin
        @test_throws ArgumentError Sounding("/tmp/does-not-exist.txt")
        @test_throws ArgumentError Sounding(example_sounding(:weisman_klemp_1982);
                                            format = :unknown_format)
        @test_throws ArgumentError example_sounding(:not_a_real_one)
    end

    @testset "malformed input" begin
        mktemp() do path, io
            write(io, "1000.0 300.0 14.0\n")
            write(io, "100.0 not_a_number 14.0 0.0 0.0\n")
            close(io)
            @test_throws ArgumentError Sounding(path)
        end
        mktemp() do path, io
            write(io, "1000.0 300.0\n")
            close(io)
            @test_throws ArgumentError Sounding(path)
        end
    end

    @testset "comments and blank lines" begin
        mktemp() do path, io
            write(io, "# leading comment\n")
            write(io, "\n")
            write(io, "1000.0 300.0 14.0 # surface\n")
            write(io, "100.0 301.0 14.0 0.5 0.0\n")
            write(io, "; another comment style\n")
            write(io, "200.0 302.0 13.8 1.0 0.0\n")
            close(io)
            s = Sounding(path)
            @test length(s) == 3                           # surface + 2 levels
            @test s.surface_pressure ≈ 100_000.0
            @test znodes(s.potential_temperature) ≈ [0.0, 100.0, 200.0] atol = 1e-9
        end
    end

end
