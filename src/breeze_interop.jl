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
using Breeze: znodes

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

    z_src = collect(znodes(θ_field))
    θ_src = [θ_field[1, 1, k]  for k in 1:size(θ_field, 3)]
    q_src = [qᵛ_field[1, 1, k] for k in 1:size(qᵛ_field, 3)]

    θ_of_z(z)  = _linear_interp(z_src, θ_src, z)
    qᵛ_of_z(z) = _linear_interp(z_src, q_src, z)

    return Breeze.ReferenceState(grid;
                                 surface_pressure      = sounding.surface_pressure,
                                 potential_temperature = θ_of_z,
                                 vapor_mass_fraction   = qᵛ_of_z,
                                 kwargs...)
end

function _linear_interp(xs::AbstractVector, ys::AbstractVector, x::Real)
    x ≤ xs[1]   && return ys[1]
    x ≥ xs[end] && return ys[end]
    i = searchsortedfirst(xs, x)
    x0, x1 = xs[i - 1], xs[i]
    y0, y1 = ys[i - 1], ys[i]
    t = (x - x0) / (x1 - x0)
    return (1 - t) * y0 + t * y1
end
