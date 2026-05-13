# # KABQ radiosonde, 2025-07-15 00Z
#
# A real observed sounding from the Albuquerque, NM upper-air station
# (KABQ). Posted in NumericalEarth/Breeze.jl#672 by @willoughby-convective.
#
# This example is mostly a sanity check that real-world data flows
# through the parser unchanged.

using LegacyConnectors
using CairoMakie

sounding = read_sounding(example_sounding(:kabq_radiosonde))

# ## Surface state and the "elevated surface" gotcha
#
# KABQ sits at about 1620 m above sea level, so the surface pressure
# in the file (~839 mb) is well below 1000 mb even though the level
# block starts a few hundred metres further up:

(p_sfc_mb = sounding.surface_pressure / 100,
 first_level_z = sounding.z[1])

# The `z` column in `input_sounding` is **above ground level (AGL)**,
# not MSL. That convention is what lets one parser handle high-altitude
# stations like KABQ and sea-level stations identically — no per-file
# offset bookkeeping needed.

# ## Plot the profile

fig = Figure(size = (900, 400))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",        ylabel = "z (m AGL)",
             title = "KABQ radiosonde 2025-07-15 00Z")
ax_qv = Axis(fig[1, 2]; xlabel = "qv (g/kg)",    ylabel = "z (m AGL)")
ax_w  = Axis(fig[1, 3]; xlabel = "wind (m/s)",   ylabel = "z (m AGL)")
lines!(ax_θ,  sounding.θ,           sounding.z)
lines!(ax_qv, sounding.qv .* 1000, sounding.z)
lines!(ax_w,  sounding.u, sounding.z; label = "u")
lines!(ax_w,  sounding.v, sounding.z; label = "v")
axislegend(ax_w; position = :rb)
fig

# A couple of qualitative features worth noting: the moisture profile
# dries out rapidly above ~5 km AGL, and the wind backs from southerly
# at the surface to westerly aloft — consistent with summer afternoon
# storms drawing on Gulf moisture in a southwesterly jet.
