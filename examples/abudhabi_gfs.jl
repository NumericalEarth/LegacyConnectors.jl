# # Abu Dhabi GFS point profile — handling missing moisture aloft
#
# This example loads the GFS point forecast for Abu Dhabi on
# 2025-07-15 12Z and shows how LegacyConnectors handles `NaN` values
# that appear in the moisture column at very high altitudes (the GFS
# product does not extend `qᵛ` into the mesosphere).

using LegacyConnectors
using Breeze
using CairoMakie

sounding = Sounding(:abudhabi_gfs)

# ## `NaN` is a first-class value here
#
# Unlike the other two bundled soundings, this file contains a literal
# `nan` token in the `qᵛ` column at its highest level. The parser
# preserves it rather than silently filling or dropping the row:

qᵛ_col = [sounding.specific_humidity[1, 1, k] for k in 1:length(sounding)]
zc     = znodes(sounding.specific_humidity)

last_finite = findlast(isfinite, qᵛ_col)
first_nan   = findfirst(isnan,    qᵛ_col)
(last_finite, first_nan,
 z_last_finite = zc[last_finite],
 z_first_nan   = zc[first_nan])

# This is important because the right thing to do with mesospheric
# missing moisture depends on the downstream consumer — a Breeze
# simulation that only extends to 30 km doesn't care; one that extends
# higher will need an extrapolation policy. By preserving `NaN` we
# leave that choice to the consumer.

# ## Plot the profile, masking NaN for the qᵛ axis

θ_col = [sounding.potential_temperature[1, 1, k] for k in 1:length(sounding)]
u_col = [sounding.x_momentum[1, 1, k]            for k in 1:length(sounding)]
v_col = [sounding.y_momentum[1, 1, k]            for k in 1:length(sounding)]
finite = isfinite.(qᵛ_col)

fig = Figure(size = (900, 450))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",      ylabel = "z (m AGL)",
             title = "Abu Dhabi GFS 2025-07-15 12Z")
ax_qᵛ = Axis(fig[1, 2]; xlabel = "qᵛ (g/kg)",  ylabel = "z (m AGL)")
ax_w  = Axis(fig[1, 3]; xlabel = "wind (m/s)", ylabel = "z (m AGL)")
lines!(ax_θ,  θ_col, zc)
lines!(ax_qᵛ, qᵛ_col[finite] .* 1000, zc[finite])
lines!(ax_w,  u_col, zc; label = "u")
lines!(ax_w,  v_col, zc; label = "v")
axislegend(ax_w; position = :rb)
fig

# Note the profile reaches ~48 km — well above the tropopause — with
# strongly easterly winds aloft and a near-isothermal stratosphere
# (θ rising exponentially in z above the tropopause).
