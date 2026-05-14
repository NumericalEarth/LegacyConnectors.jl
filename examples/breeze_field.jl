# # Loading a real sounding into Breeze: `Field` and `ReferenceState`
#
# This example covers the path you'll usually take when initializing
# a Breeze simulation from an observed (or model-output) sounding —
# i.e. one where there is no analytic form to set! against directly.
# We use the KABQ radiosonde bundled with the package.
#
# Two Breeze objects come out of this:
#
#   1. **Prognostic `Field`s** (θ, qv, u, v) on the model grid,
#      filled by [`LegacyConnectors.set!`](@ref) via linear
#      interpolation onto the field's z-nodes.
#   2. A **`Breeze.ReferenceState`** — the hydrostatic base state
#      (pressure, density, temperature) used for the anelastic /
#      compressible split — built from the same sounding by
#      [`LegacyConnectors.reference_state`](@ref), which delegates
#      to `Breeze.ReferenceState(grid; …)` with θ and qv passed in
#      as `z`-callables that interpolate the sounding's column.
#
# Compare this to the [analytic example](weisman_klemp_supercell.md),
# which prefers `set!(field, (x, y, z) -> θ(z))` and skips the file
# round-trip entirely.

using LegacyConnectors
using Breeze
using CairoMakie

sounding = Sounding(:kabq_radiosonde)

# ## Build the grid
#
# A 1×1×Nz column is enough to see the structure. In a real simulation
# the same calls work on a full 3-D grid: `set!` broadcasts each
# horizontally-uniform sounding column across (x, y); `ReferenceState`
# is `(Nothing, Nothing, Center)`-located and so is naturally 1-D in z.
#
# KABQ's surface is well above sea level, but the sounding's `z`
# column is above ground level — so we set the grid to start at 0.

grid = RectilinearGrid(CPU(); size = (1, 1, 96),
                       x = (0, 1), y = (0, 1), z = (0, 15_000),
                       topology = (Periodic, Periodic, Bounded))

# ## Prognostic Fields

θ  = CenterField(grid)
qv = CenterField(grid)
u  = CenterField(grid)
v  = CenterField(grid)

set!(θ,  sounding.θ)
set!(qv, sounding.qv)
set!(u,  sounding.u)
set!(v,  sounding.v)

# ## Reference state
#
# A single call gives us a Breeze `ReferenceState` anchored at the
# sounding's surface pressure, with `θ(z)` and `qv(z)` interpolated
# from the sounding's column. Breeze takes it from there — hydrostatic
# integration for `p(z)`, ρ from the ideal gas law, T from the Exner
# function.

ref = LegacyConnectors.reference_state(sounding, grid)

# `ref.pressure`, `ref.density`, and `ref.temperature` are all
# Oceananigans `Field`s, so we can `lines!` them just like the
# prognostic ones.

# ## Plot both layers side by side

fig = Figure(size = (1100, 700))

ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",      ylabel = "z (m AGL)",
             title = "Prognostic fields")
ax_qv = Axis(fig[1, 2]; xlabel = "qv (g/kg)",  ylabel = "z (m AGL)")
ax_w  = Axis(fig[1, 3]; xlabel = "wind (m/s)", ylabel = "z (m AGL)")
lines!(ax_θ,  θ)
lines!(ax_qv, qv * 1000)
lines!(ax_w,  u; label = "u")
lines!(ax_w,  v; label = "v")
axislegend(ax_w; position = :rb)

ax_p = Axis(fig[2, 1]; xlabel = "p_ref (mb)",    ylabel = "z (m AGL)",
            title = "ReferenceState")
ax_ρ = Axis(fig[2, 2]; xlabel = "ρ_ref (kg/m³)", ylabel = "z (m AGL)")
ax_T = Axis(fig[2, 3]; xlabel = "T_ref (K)",     ylabel = "z (m AGL)")
lines!(ax_p, ref.pressure / 100)
lines!(ax_ρ, ref.density)
lines!(ax_T, ref.temperature)

fig

# Top row: prognostic Fields filled from the sounding. Bottom row: the
# hydrostatic base state Breeze derived from the same surface pressure
# and θ(z) / qv(z) profiles. These two together are everything Breeze
# needs to start a simulation from this sounding.
