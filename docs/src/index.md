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
sounding = read_sounding(example_sounding(:weisman_klemp_1982))

# …or your own file.
sounding = read_sounding("/path/to/input_sounding")
```

A [`Sounding`](@ref) holds the surface state (`surface_pressure`,
`surface_θ`, `surface_qv` in SI units) and the above-surface profile
vectors (`z`, `θ`, `qv`, `u`, `v`).

## Status

- ✅ `:input_sounding` reader (this is what the discussion asked for).
- 🚧 Breeze interop helpers (`set!`, `reference_state`): scaffolded for
  v0.1, real implementation tracked alongside Breeze's `ReferenceState`
  refactor — see `src/breeze_interop.jl`.
- ⏳ Additional formats (WRF namelists, GFS point profiles in their
  native form, …): scaffolding lives in `src/formats/`; see that
  directory's README to add one.
