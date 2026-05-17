# Breeze interop for `Sounding`s built around Oceananigans `Field`s.
#
# A sounding profile is a `Field{Nothing, Nothing, Face}` on a column
# `RectilinearGrid` with `(Flat, Flat, Bounded)` topology. To fill a
# 3-D `Field` on a different (model) grid, users call
# `Oceananigans.Fields.interpolate!(target, sounding.X)` — this is
# native Oceananigans (≥ 0.107.5, via CliMA/Oceananigans.jl#5522),
# no extension method required from this package.
#
# See Breeze.jl discussion #672 for the motivating proposal.

import Breeze
using Breeze.Oceananigans.Fields: interpolate

"""
    LegacyConnectors.reference_state(sounding::Sounding, grid; kwargs...)

Build a `Breeze.ReferenceState` whose surface state and `(θ, qᵛ)`
profiles come from `sounding`. `kwargs` are forwarded to
`Breeze.ReferenceState`.

```julia
sounding = Sounding(:weisman_klemp_1982)
ref      = LegacyConnectors.reference_state(sounding, grid)
```
"""
function reference_state(sounding::Sounding, grid; kwargs...)
    θ_field  = sounding.potential_temperature
    qᵛ_field = sounding.specific_humidity

    # Breeze.ReferenceState wants z-callables for the θ and qᵛ profiles
    # (its Field-input docstring overstates what's implemented). Wrap
    # the sounding fields via Oceananigans' per-point interpolate.
    θ_of_z(z)  = interpolate((nothing, nothing, z), θ_field)
    qᵛ_of_z(z) = interpolate((nothing, nothing, z), qᵛ_field)

    return Breeze.ReferenceState(grid;
                                 surface_pressure      = sounding.surface_pressure,
                                 potential_temperature = θ_of_z,
                                 vapor_mass_fraction   = qᵛ_of_z,
                                 kwargs...)
end
