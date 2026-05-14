# Breeze.jl interop for `Sounding` / `SoundingProfile` values.
#
# The methods here translate a format-neutral sounding into the shapes
# Breeze (and Oceananigans, underneath) expect. See Breeze.jl
# discussion #672 for the motivating proposal.

import Breeze
import Breeze: set!
using Breeze: Field, znodes

"""
    set!(field, profile::SoundingProfile)

Fill an Oceananigans `Field` with a single sounding profile, linearly
interpolated onto the field's z-coordinates. This extends
`Breeze.set!` (= `Oceananigans.set!`), so the same `set!` you use for
analytic profiles — `set!(field, (x, y, z) -> …)` — also takes a
[`SoundingProfile`](@ref):

```julia
sounding = Sounding(:weisman_klemp_1982)

θ = CenterField(grid)
set!(θ, sounding.θ)        # ← linearly interpolate sounding column
```

The surface value (at `z = 0`) anchors the lower end of the
interpolation; above the sounding's top level the top value is held
constant. `NaN`s in `profile.values` (e.g. mesospheric `qv` from a GFS
file) propagate to grid points that interpolate from a `NaN` source —
choose your extrapolation policy at call time, not in the parser.
"""
function set!(field::Field, profile::SoundingProfile)
    z_src = vcat(0.0, profile.z)
    f_src = vcat(profile.surface_value, profile.values)

    z_grid = znodes(field)
    Nx, Ny, Nz = size(field)
    for k in 1:Nz
        zk = z_grid[k]
        value = _linear_interp(z_src, f_src, zk)
        for j in 1:Ny, i in 1:Nx
            field[i, j, k] = value
        end
    end
    return field
end

function _linear_interp(xs::AbstractVector, ys::AbstractVector, x::Real)
    x ≤ xs[1]   && return ys[1]
    x ≥ xs[end] && return ys[end]
    i = searchsortedfirst(xs, x)
    x0, x1 = xs[i-1], xs[i]
    y0, y1 = ys[i-1], ys[i]
    t = (x - x0) / (x1 - x0)
    return (1 - t) * y0 + t * y1
end

"""
    LegacyConnectors.reference_state(sounding::Sounding, grid; kwargs...)

Build a Breeze `ReferenceState` whose surface state and `(θ, qv)`
profiles come from `sounding`. `kwargs` are forwarded to
`Breeze.ReferenceState`.

```julia
sounding = Sounding(:weisman_klemp_1982)
ref      = LegacyConnectors.reference_state(sounding, grid)
```
"""
function reference_state(sounding::Sounding, grid; kwargs...)
    θ_p  = sounding.θ
    qv_p = sounding.qv
    z_src = vcat(0.0, θ_p.z)
    θ_src = vcat(θ_p.surface_value,  θ_p.values)
    q_src = vcat(qv_p.surface_value, qv_p.values)

    θ_of_z(z)  = _linear_interp(z_src, θ_src, z)
    qv_of_z(z) = _linear_interp(z_src, q_src, z)

    return Breeze.ReferenceState(grid;
                                 surface_pressure      = sounding.surface_pressure,
                                 potential_temperature = θ_of_z,
                                 vapor_mass_fraction   = qv_of_z,
                                 kwargs...)
end
