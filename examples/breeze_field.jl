# # Loading a real sounding into Breeze: `Field` and `ReferenceState`
#
# This example covers the path you'll usually take when initializing
# a Breeze simulation from an observed (or model-output) sounding —
# i.e. one where there is no analytic form to `set!` against directly.
# We use the KABQ radiosonde bundled with the package.
#
# Two Breeze objects come out of this:
#
#   1. **Prognostic `Field`s** (θ, qᵛ, u, v) on the model grid, filled
#      by `Oceananigans.Fields.interpolate!`, which the package
#      extends with a column-source method that does broadcast in
#      `x, y` and linear interpolation in `z`.
#   2. A **`Breeze.ReferenceState`** — the hydrostatic base state
#      (pressure, density, temperature) used for the anelastic /
#      compressible split — built from the same sounding by
#      [`LegacyConnectors.reference_state`](@ref).
#
# Compare this to the [analytic example](weisman_klemp_supercell.md),
# which prefers `set!(field, (x, y, z) -> θ(z))` and skips the file
# round-trip entirely.

using LegacyConnectors
using Breeze
import Breeze.Oceananigans.Fields: interpolate!
using CairoMakie

sounding = Sounding(:kabq_radiosonde)

# ## Build the model grid

grid = RectilinearGrid(CPU(); size = (1, 1, 96),
                       x = (0, 1), y = (0, 1), z = (0, 15_000),
                       topology = (Periodic, Periodic, Bounded))

# ## Prognostic Fields

θ  = CenterField(grid)
qᵛ = CenterField(grid)
u  = CenterField(grid)
v  = CenterField(grid)

interpolate!(θ,  sounding.potential_temperature)
interpolate!(qᵛ, sounding.specific_humidity)
interpolate!(u,  sounding.x_momentum)
interpolate!(v,  sounding.y_momentum)

# ## Reference state

ref = LegacyConnectors.reference_state(sounding, grid)

# `ref.pressure`, `ref.density`, and `ref.temperature` are all
# Oceananigans `Field`s, so we `lines!` them just like the prognostic
# ones.

# ## Plot both layers side by side

fig = Figure(size = (1100, 700))

ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",      ylabel = "z (m AGL)",
             title = "Prognostic fields")
ax_qᵛ = Axis(fig[1, 2]; xlabel = "qᵛ (g/kg)",  ylabel = "z (m AGL)")
ax_w  = Axis(fig[1, 3]; xlabel = "wind (m/s)", ylabel = "z (m AGL)")
lines!(ax_θ,  θ)
lines!(ax_qᵛ, qᵛ * 1000)
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
# and θ(z) / qᵛ(z) profiles. These two together are everything Breeze
# needs to start a simulation from this sounding.
