# # Abu Dhabi GFS point profile — handling missing moisture aloft
#
# This example loads the GFS point forecast for Abu Dhabi on
# 2025-07-15 12Z and shows how LegacyConnectors handles `NaN` values
# that appear in the moisture column at very high altitudes (the GFS
# product does not extend `qv` into the mesosphere).

using LegacyConnectors
using CairoMakie

sounding = Sounding(:abudhabi_gfs)

# ## `NaN` is a first-class value here
#
# Unlike the other two bundled soundings, this file contains a literal
# `nan` token in the `qv` column at its highest level. The parser
# preserves it rather than silently filling or dropping the row:

last_finite = findlast(isfinite, sounding.qv)
first_nan   = findfirst(isnan,    sounding.qv)
(last_finite, first_nan,
 z_last_finite = sounding.z[last_finite],
 z_first_nan   = sounding.z[first_nan])

# This is important because the right thing to do with mesospheric
# missing moisture depends on the downstream consumer — a Breeze
# simulation that only extends to 30 km doesn't care; one that extends
# higher will need an extrapolation policy. By preserving `NaN` we
# leave that choice to the consumer.

# ## Plot the profile, masking NaN for the qv axis

qv_gkg = sounding.qv .* 1000
finite = isfinite.(qv_gkg)

fig = Figure(size = (900, 450))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",       ylabel = "z (m AGL)",
             title  = "Abu Dhabi GFS 2025-07-15 12Z")
ax_qv = Axis(fig[1, 2]; xlabel = "qv (g/kg)",   ylabel = "z (m AGL)")
ax_w  = Axis(fig[1, 3]; xlabel = "wind (m/s)",  ylabel = "z (m AGL)")
lines!(ax_θ,  sounding.θ, sounding.z)
lines!(ax_qv, qv_gkg[finite], sounding.z[finite])
lines!(ax_w,  sounding.u, sounding.z; label = "u")
lines!(ax_w,  sounding.v, sounding.z; label = "v")
axislegend(ax_w; position = :rb)
fig

# Note the profile reaches ~48 km — well above the tropopause — with
# strongly easterly winds aloft and a near-isothermal stratosphere
# (θ rising exponentially in z above the tropopause).
