# LegacyConnectors.jl

Readers and adapters that let [Breeze.jl](https://github.com/NumericalEarth/Breeze.jl)
ingest initial conditions from legacy atmospheric modeling formats —
starting with the CM1/WRF/ERF `input_sounding` text format.

## Motivation

The proposal in
[NumericalEarth/Breeze.jl#672](https://github.com/NumericalEarth/Breeze.jl/discussions/672)
is to support idealized convection studies in Breeze by reading the
same sounding files that CM1, WRF (`em_ideal`), and ERF accept. This
package owns the legacy-format plumbing so Breeze itself stays focused
on the dynamical core.

## Quickstart

```julia
using Pkg
Pkg.add(url = "https://github.com/NumericalEarth/LegacyConnectors.jl")

using LegacyConnectors

# Load one of the three bundled example soundings…
sounding = Sounding(:weisman_klemp_1982)

# …or your own file.
sounding = Sounding("/path/to/input_sounding")
```

A [`Sounding`](@ref) is concretely typed. Its profile fields —
`potential_temperature`, `specific_humidity`, `x_momentum`,
`y_momentum` — are all Oceananigans `Field{Nothing, Nothing, Face}`
columns whose face positions sit exactly at the file's z-levels (with
the surface prepended at z = 0). To fill a 3-D Breeze `Field` from one,
use `Oceananigans.Fields.interpolate!` — handled natively for
column-source fields in Oceananigans ≥ 0.107.5:

```julia
import Breeze.Oceananigans.Fields: interpolate!

θ = CenterField(grid)
interpolate!(θ, sounding.potential_temperature)
```

## Status

- ✅ `:input_sounding` reader.
- ✅ Breeze interop: `interpolate!(::Field, ::sounding-column)` and
  [`LegacyConnectors.reference_state`](@ref) (both real, not scaffold).
- ⏳ Additional formats (WRF namelists, GFS point profiles in their
  native form, …): scaffolding lives in `src/formats/`; see that
  directory's README to add one.
