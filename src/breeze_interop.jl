# Breeze.jl interop for `Sounding` values.
#
# The functions here translate a format-neutral `Sounding` into the
# shapes Breeze (and Oceananigans, underneath) expect. See Breeze.jl
# discussion #672 for the motivating proposal.

import Breeze
import Breeze: set!
using Breeze: Field, znodes

"""
    LegacyConnectors.set!(field, sounding::Sounding; profile::Symbol)

Fill an Oceananigans `Field` (column or 3-D) with a profile from
`sounding`, linearly interpolated onto the field's z-coordinates.

`profile` selects which sounding variable to use:

- `:θ` — potential temperature (K)
- `:qv` — water-vapor mixing ratio (kg/kg)
- `:u`, `:v` — horizontal wind components (m/s)

The surface line of the sounding is treated as the value at `z = 0`
(AGL). Above the top of the sounding, the highest level's value is
held constant; below the surface, the surface value is held constant.

`NaN` values in the source profile (e.g. mesospheric `qv` from a GFS
file) propagate to grid points that interpolate from a `NaN` source —
this is intentional: the consumer chooses an extrapolation policy.

# Example

```julia
using Breeze, LegacyConnectors

grid = RectilinearGrid(CPU(); size = (1, 1, 64),
                       x = (0, 1), y = (0, 1), z = (0, 16_000),
                       topology = (Periodic, Periodic, Bounded))

θ = CenterField(grid)
sounding = read_sounding(example_sounding(:weisman_klemp_1982))
set!(θ, sounding; profile = :θ)
```

This method *extends* `Breeze.set!` (i.e. `Oceananigans.set!`), so the
same `set!` you use for analytic profiles — `set!(field, (x, y, z) -> …)` —
also accepts a [`Sounding`](@ref).
"""
function set!(field::Field, sounding::Sounding; profile::Symbol = :θ)
    surface, column = _surface_and_column(sounding, profile)

    # Extend the sounding column with the surface value at z = 0 AGL so
    # interpolation handles below-lowest-level grid points correctly.
    z_src = vcat(0.0, sounding.z)
    f_src = vcat(surface, column)

    z_grid = znodes(field)
    _, _, Nz = size(field)
    Nx, Ny, _ = size(field)
    for k in 1:Nz
        zk = z_grid[k]
        value = _linear_interp(z_src, f_src, zk)
        for j in 1:Ny, i in 1:Nx
            field[i, j, k] = value
        end
    end
    return field
end

function _surface_and_column(sounding::Sounding, profile::Symbol)
    if profile === :θ
        return sounding.surface_θ,  sounding.θ
    elseif profile === :qv
        return sounding.surface_qv, sounding.qv
    elseif profile === :u
        # u, v have no separate surface column in input_sounding; treat the
        # lowest-level value as the surface value (standard CM1 convention).
        return sounding.u[1], sounding.u
    elseif profile === :v
        return sounding.v[1], sounding.v
    else
        throw(ArgumentError(
            "profile must be one of :θ, :qv, :u, :v (got $(repr(profile)))"))
    end
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

Build a Breeze `ReferenceState` whose surface state and `(θ, qv)` profiles
come from `sounding`. The sounding's `surface_pressure` anchors the
hydrostatic integration; θ and qv are passed to Breeze as `z`-callables
that linearly interpolate the sounding's column.

`kwargs` are forwarded to `Breeze.ReferenceState`, so any of its other
options (`standard_pressure`, `discrete_hydrostatic_balance`,
`liquid_mass_fraction`, `ice_mass_fraction`, …) can be set here.

# Example

```julia
using Breeze, LegacyConnectors

grid = RectilinearGrid(CPU(); size = (1, 1, 64),
                       x = (0, 1), y = (0, 1), z = (0, 16_000),
                       topology = (Periodic, Periodic, Bounded))

sounding = read_sounding(example_sounding(:weisman_klemp_1982))
ref      = LegacyConnectors.reference_state(sounding, grid)
```
"""
function reference_state(sounding::Sounding, grid; kwargs...)
    z_src = vcat(0.0, sounding.z)
    θ_src = vcat(sounding.surface_θ,  sounding.θ)
    q_src = vcat(sounding.surface_qv, sounding.qv)

    θ_of_z(z)  = _linear_interp(z_src, θ_src, z)
    qv_of_z(z) = _linear_interp(z_src, q_src, z)

    return Breeze.ReferenceState(grid;
                                 surface_pressure      = sounding.surface_pressure,
                                 potential_temperature = θ_of_z,
                                 vapor_mass_fraction   = qv_of_z,
                                 kwargs...)
end
