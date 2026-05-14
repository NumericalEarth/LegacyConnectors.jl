# Breeze interop for `Sounding`s built around Oceananigans `Field`s.
#
# The four sounding profile fields are `Field{Nothing, Nothing, Center}`
# on a column grid. To fill a 3-D `Field` on a different (model) grid,
# users call `Oceananigans.Fields.interpolate!(target, sounding.X)` —
# we extend `interpolate!` here with a method that handles the
# column-source case explicitly (linear in z, broadcast across x, y),
# which Oceananigans' generic `interpolate!` does not yet cover for
# `Nothing` horizontal locations.
#
# See Breeze.jl discussion #672 for the motivating proposal.

import Breeze
import Breeze.Oceananigans.Fields: interpolate!
using Breeze: Field, Face, znodes

"""
    interpolate!(target::Field, source::Field{Nothing, Nothing, Face})

Fill `target` by linearly interpolating the column `source` onto the
target's z-coordinates and broadcasting across `x`, `y`. The bottom
face value (at `z = 0`) anchors the lower end of the interpolation;
above the top face the top value is held constant. `NaN`s in `source`
propagate to interpolated points without filling.

```julia
sounding = Sounding(:weisman_klemp_1982)
θ = CenterField(grid)
interpolate!(θ, sounding.potential_temperature)
```
"""
function interpolate!(target::Field, source::Field{Nothing, Nothing, Face})
    z_src      = collect(znodes(source))
    src_values = [source[1, 1, k] for k in 1:size(source, 3)]
    z_tgt      = znodes(target)

    Nx, Ny, Nz = size(target)
    @inbounds for k in 1:Nz
        v = _linear_interp(z_src, src_values, z_tgt[k])
        for j in 1:Ny, i in 1:Nx
            target[i, j, k] = v
        end
    end
    return target
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
