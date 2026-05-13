# # Loading a sounding into a Breeze `Field`
#
# This example shows the full path from a legacy `input_sounding`
# file to an Oceananigans/Breeze `Field` on a model grid — which is
# the shape Breeze's prognostic variables live in. The Field is then
# plotted via Oceananigans' Makie extension (loaded automatically when
# CairoMakie is available).

using LegacyConnectors
using Breeze
using CairoMakie

# ## Read the sounding

sounding = read_sounding(example_sounding(:weisman_klemp_1982))

# ## Build a small column grid
#
# A 1×1×64 grid spanning 0–16 km is enough to see the structure of the
# sounding. In a real simulation we'd use a 3-D grid; the procedure is
# identical because [`LegacyConnectors.set!`](@ref) interpolates the
# 1-D sounding profile and broadcasts it across the horizontal extent.

grid = RectilinearGrid(CPU();
                       size = (1, 1, 64),
                       x = (0, 1), y = (0, 1), z = (0, 16_000),
                       topology = (Periodic, Periodic, Bounded))

# ## Allocate prognostic Fields and fill them from the sounding

θ  = CenterField(grid)
qv = CenterField(grid)
u  = CenterField(grid)
v  = CenterField(grid)

LegacyConnectors.set!(θ,  sounding; profile = :θ)
LegacyConnectors.set!(qv, sounding; profile = :qv)
LegacyConnectors.set!(u,  sounding; profile = :u)
LegacyConnectors.set!(v,  sounding; profile = :v)

# `set!` does linear interpolation onto the field's z-coordinates
# (returned by `znodes(field)`) and replicates across the horizontal
# extent. The surface line of the sounding anchors the profile at
# `z = 0`; the topmost level is held constant above the sounding's top
# (no extrapolation).

# ## Plot the Fields
#
# Oceananigans ships a Makie extension that knows how to draw a Field
# directly — no manual unpacking required.

fig = Figure(size = (1000, 450))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",      ylabel = "z (m AGL)",
             title = "Sounding → Field (W-K 1982)")
ax_qv = Axis(fig[1, 2]; xlabel = "qv (g/kg)",  ylabel = "z (m AGL)")
ax_w  = Axis(fig[1, 3]; xlabel = "wind (m/s)", ylabel = "z (m AGL)")
lines!(ax_θ,  θ)
lines!(ax_qv, qv * 1000)
lines!(ax_w,  u; label = "u")
lines!(ax_w,  v; label = "v")
axislegend(ax_w; position = :rb)
fig

# Each line above is a single `Field`. The Oceananigans Makie
# extension picks up the field's z-coordinates automatically — the
# same code works for a 1×1×Nz column field or a slice through a 3-D
# field. From here, the Fields are ready to be used as Breeze model
# initial conditions.
