# LegacyConnectors.jl

[![CI](https://github.com/NumericalEarth/LegacyConnectors.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/NumericalEarth/LegacyConnectors.jl/actions/workflows/CI.yml)
[![Docs (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://numericalearth.github.io/LegacyConnectors.jl/stable)
[![Docs (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://numericalearth.github.io/LegacyConnectors.jl/dev)
[![codecov](https://codecov.io/gh/NumericalEarth/LegacyConnectors.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/NumericalEarth/LegacyConnectors.jl)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Readers and adapters that let [Breeze.jl](https://github.com/NumericalEarth/Breeze.jl)
ingest initial conditions from legacy atmospheric modeling formats —
starting with the CM1/WRF/ERF `input_sounding` text format.

This package exists so Breeze.jl itself can stay focused on its
dynamical core. See [NumericalEarth/Breeze.jl#672](https://github.com/NumericalEarth/Breeze.jl/discussions/672)
for the motivating discussion.

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/NumericalEarth/LegacyConnectors.jl")
```

## Quickstart

Read a sounding, load it onto a Breeze grid as Oceananigans `Field`s,
and plot with the Oceananigans Makie extension:

```julia
using LegacyConnectors, Breeze, CairoMakie

# 1. Read one of the three bundled example soundings (or your own file).
sounding = read_sounding(example_sounding(:weisman_klemp_1982))

# 2. Build a small column grid and allocate Fields for θ, qv, u, v.
grid = RectilinearGrid(CPU(); size = (1, 1, 64),
                       x = (0, 1), y = (0, 1), z = (0, 16_000),
                       topology = (Periodic, Periodic, Bounded))
θ, qv, u, v = (CenterField(grid) for _ in 1:4)

# 3. Linearly interpolate sounding profiles onto each Field.
for (f, p) in ((θ, :θ), (qv, :qv), (u, :u), (v, :v))
    LegacyConnectors.set!(f, sounding; profile = p)
end

# 4. Plot — Oceananigans' Makie ext renders Fields directly.
fig = Figure(size = (900, 400))
lines(fig[1, 1], θ;        axis = (; xlabel = "θ (K)",      ylabel = "z (m)"))
lines(fig[1, 2], qv * 1000; axis = (; xlabel = "qv (g/kg)", ylabel = "z (m)"))
lines(fig[1, 3], u;        axis = (; xlabel = "u (m/s)",    ylabel = "z (m)"))
fig
```

See the rendered version of this in the
[Sounding → Breeze Field example](https://numericalearth.github.io/LegacyConnectors.jl/dev/literated/breeze_field/).

If you only need the raw profile (no Breeze dep on the rendered side):

```julia
using LegacyConnectors
sounding = read_sounding(example_sounding(:weisman_klemp_1982))
@show sounding.surface_pressure, length(sounding)
```

## Bundled example soundings

| Name | Source |
|---|---|
| `:weisman_klemp_1982` | Analytic supercell sounding, regenerable from `data/soundings/generate_weisman_klemp_1982.jl`. |
| `:kabq_radiosonde`    | KABQ radiosonde, 2025-07-15 00Z. |
| `:abudhabi_gfs`       | Abu Dhabi GFS point forecast, 2025-07-15 12Z. |

See [`data/soundings/README.md`](data/soundings/README.md) for full
provenance.

## License

Apache-2.0 — see [LICENSE](LICENSE).
