# LegacyConnectors.jl

[![CI](https://github.com/NumericalEarth/LegacyConnectors.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/NumericalEarth/LegacyConnectors.jl/actions/workflows/CI.yml)
[![Docs (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://numericalearth.github.io/LegacyConnectors.jl/stable)
[![Docs (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://numericalearth.github.io/LegacyConnectors.jl/dev)
[![codecov](https://codecov.io/gh/NumericalEarth/LegacyConnectors.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/NumericalEarth/LegacyConnectors.jl)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

🏛️ Readers and adapters that connect legacy systems like CM1 and WRF to
NumericalEarth packages, like [Breeze.jl](https://github.com/NumericalEarth/Breeze.jl) .

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/NumericalEarth/LegacyConnectors.jl")
```

## Quickstart

Read a sounding and plot its profiles directly — they're Oceananigans
`Field`s on a column grid, so the Makie extension knows how to draw
them:

![Quickstart: θ, qᵛ, u profiles from the Weisman–Klemp 1982 sounding](docs/src/assets/readme_quickstart.png)

```julia
using LegacyConnectors, Breeze, CairoMakie

sounding = Sounding(:weisman_klemp_1982)   # or Sounding("/path/to/input_sounding")

fig = Figure(size = (900, 400))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",     ylabel = "z (m)")
ax_qᵛ = Axis(fig[1, 2]; xlabel = "qᵛ (g/kg)", ylabel = "z (m)")
ax_u  = Axis(fig[1, 3]; xlabel = "u (m/s)",   ylabel = "z (m)")
lines!(ax_θ,  sounding.potential_temperature)
lines!(ax_qᵛ, sounding.specific_humidity * 1000)
lines!(ax_u,  sounding.x_momentum)
fig
```

`Sounding` is concretely typed: each profile field is a
`Field{Nothing, Nothing, Face}` on a column grid whose z-faces are
exactly the file's z-levels (with `0.0` prepended for the surface).

## Filling a model grid

When you're ready to initialize a Breeze simulation, fill its
prognostic `Field`s with `Oceananigans.Fields.interpolate!`. The
package extends `interpolate!` for the column-source case (linear in
z, broadcast in x, y), so this works across any model grid:

```julia
import Breeze.Oceananigans.Fields: interpolate!

grid = RectilinearGrid(CPU(); size = (64, 64, 64),
                       x = (0, 10_000), y = (0, 10_000), z = (0, 16_000),
                       topology = (Periodic, Periodic, Bounded))

θ = CenterField(grid)
interpolate!(θ, sounding.potential_temperature)
```

To go further and build the hydrostatic base state Breeze uses for
its anelastic / compressible split, pass the same sounding to
`LegacyConnectors.reference_state`:

```julia
ref = LegacyConnectors.reference_state(sounding, grid)
# ref.pressure, ref.density, ref.temperature are Fields you can plot
# or pass straight to a Breeze model.
```

The literated examples walk through both paths in detail — and the
Weisman & Klemp example makes the case for skipping the file entirely
when you have analytic forms:

- [Weisman & Klemp 1982: analytic vs sounding](https://numericalearth.github.io/LegacyConnectors.jl/dev/literated/weisman_klemp_supercell/)
- [Loading a real sounding into Breeze (KABQ + ReferenceState)](https://numericalearth.github.io/LegacyConnectors.jl/dev/literated/breeze_field/)

## Bundled example soundings

| Name | Source |
|---|---|
| `:weisman_klemp_1982` | Analytic supercell sounding, regenerable from `data/soundings/generate_weisman_klemp_1982.jl`. |
| `:kabq_radiosonde`    | KABQ radiosonde, 2025-07-15 00Z. |
| `:abudhabi_gfs`       | Abu Dhabi GFS point forecast, 2025-07-15 12Z. |

Adding your own is a one-line method on `example_sounding` (see its
docstring) — `Val(symbol)` dispatch keeps the table extensible.

See [`data/soundings/README.md`](data/soundings/README.md) for full
provenance.

## License

Apache-2.0 — see [LICENSE](LICENSE).
