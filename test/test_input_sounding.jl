using Test
using LegacyConnectors

@testset "input_sounding parser" begin

    @testset "Weisman-Klemp 1982 (bundled, generated)" begin
        s = read_sounding(example_sounding(:weisman_klemp_1982))
        @test s.format === :input_sounding
        @test s.surface_pressure ≈ 100_000.0 atol = 1.0       # 1000 mb
        @test s.surface_θ        ≈ 300.0     atol = 1e-6
        @test s.surface_qv       ≈ 14.0e-3   atol = 1e-9
        @test length(s) == 65                                 # see generator
        @test issorted(s.z)
        @test all(isfinite, s.θ)
        @test all(isfinite, s.qv)
        # u capped at 30 m/s above 6 km, zero at surface, linear in between
        @test maximum(s.u) ≈ 30.0 atol = 1e-6
        @test all(==(0.0), s.v)
        # θ at the tropopause (~12 km) is the W-K value of 343 K
        i_tr = findfirst(z -> z ≈ 12_000.0, s.z)
        @test i_tr !== nothing
        @test s.θ[i_tr] ≈ 343.0 atol = 0.5
    end

    @testset "KABQ radiosonde 2025-07-15 00Z" begin
        s = read_sounding(example_sounding(:kabq_radiosonde))
        @test s.format === :input_sounding
        @test s.surface_pressure ≈ 83_900.0 atol = 1.0         # 839 mb → Pa
        @test s.surface_θ        ≈ 322.737875 atol = 1e-5
        @test s.surface_qv       ≈ 5.998407e-3 atol = 1e-9
        @test length(s) == 95
        @test issorted(s.z)
        @test all(isfinite, s.qv)                              # no NaNs here
        @test s.z[1]   ≈ 210.0 atol = 1e-6                     # first level AGL
    end

    @testset "Abu Dhabi GFS 2025-07-15 12Z (NaN qv aloft)" begin
        s = read_sounding(example_sounding(:abudhabi_gfs))
        @test s.format === :input_sounding
        @test s.surface_pressure ≈ 99_110.6953 atol = 1.0      # 991.10... mb
        @test length(s) == 32
        @test any(isnan, s.qv)                                 # mesospheric NaN preserved
        # Levels with finite qv must come before NaN levels (qv truncates aloft)
        last_finite = findlast(isfinite, s.qv)
        first_nan   = findfirst(isnan,    s.qv)
        @test last_finite !== nothing && first_nan !== nothing
        @test last_finite < first_nan
    end

    @testset "error handling" begin
        @test_throws ArgumentError read_sounding("/tmp/does-not-exist.txt")
        @test_throws ArgumentError read_sounding(example_sounding(:weisman_klemp_1982);
                                                 format = :unknown_format)
        @test_throws ArgumentError example_sounding(:not_a_real_one)
    end

    @testset "malformed input" begin
        mktemp() do path, io
            write(io, "1000.0 300.0 14.0\n")
            write(io, "100.0 not_a_number 14.0 0.0 0.0\n")
            close(io)
            @test_throws ArgumentError read_sounding(path)
        end
        mktemp() do path, io
            # Surface line with only 2 columns
            write(io, "1000.0 300.0\n")
            close(io)
            @test_throws ArgumentError read_sounding(path)
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
            s = read_sounding(path)
            @test length(s) == 2
            @test s.surface_pressure ≈ 100_000.0
            @test s.z == [100.0, 200.0]
        end
    end

end
