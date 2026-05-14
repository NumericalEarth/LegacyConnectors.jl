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

A [`Sounding`](@ref) holds the surface pressure plus four
[`SoundingProfile`](@ref)s — `θ`, `qv`, `u`, `v` — each of which
subtypes `AbstractVector{Float64}` (so it indexes/iterates/broadcasts
like a normal vector) but also carries its `z` column and surface
value, which is what makes

```julia
set!(field, sounding.θ)
```

dispatch correctly onto Breeze's `set!`.

## Status

- ✅ `:input_sounding` reader.
- ✅ Breeze interop: `set!(::Field, ::SoundingProfile)` and
  [`LegacyConnectors.reference_state`](@ref) (both real, not scaffold).
- ⏳ Additional formats (WRF namelists, GFS point profiles in their
  native form, …): scaffolding lives in `src/formats/`; see that
  directory's README to add one.
