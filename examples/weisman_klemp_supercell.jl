# # The Weisman & Klemp (1982) supercell sounding
#
# This example loads the canonical idealized supercell sounding of
# Weisman & Klemp (1982) — bundled with the package and generated
# analytically from the formulas in the paper — and plots its
# thermodynamic profile and hodograph.

using LegacyConnectors
using CairoMakie

# ## Load the bundled sounding
#
# `example_sounding` returns the absolute path to one of the soundings
# shipped in `data/soundings/`. `read_sounding` parses it into a
# [`Sounding`](@ref LegacyConnectors.Sounding) value.

path = example_sounding(:weisman_klemp_1982)
sounding = read_sounding(path)

# The struct's `show` method tells us the size and surface state at a glance:

sounding

# Surface state is exposed directly (in SI units — pascals and kg/kg):

(; sounding.surface_pressure, sounding.surface_θ, sounding.surface_qv)

# ## Thermodynamic profile
#
# Plot potential temperature and water-vapor mixing ratio vs height.

fig = Figure(size = (700, 500))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",     ylabel = "z (m AGL)", title = "Weisman & Klemp 1982")
ax_qv = Axis(fig[1, 2]; xlabel = "qv (g/kg)", ylabel = "z (m AGL)")
lines!(ax_θ,  sounding.θ,        sounding.z)
lines!(ax_qv, sounding.qv .* 1000, sounding.z)
fig

# The kink near 12 km is the prescribed tropopause: below it, θ grows
# as `(z/z_tr)^(5/4)`; above, the profile becomes isothermal in T (so θ
# rises exponentially in z).

# ## Hodograph
#
# The bundled W-K sounding pairs the analytic thermodynamic profile
# with a unidirectional half-circle wind profile (linear shear capped
# at 30 m/s above 6 km). Plotting `v(u)` and annotating heights makes
# the shear structure obvious.

fig2 = Figure(size = (500, 500))
ax = Axis(fig2[1, 1]; xlabel = "u (m/s)", ylabel = "v (m/s)",
          title = "Hodograph", aspect = DataAspect())
lines!(ax, sounding.u, sounding.v)
scatter!(ax, sounding.u, sounding.v; markersize = 4)
## Annotate every ~2 km
label_zs = (2000, 4000, 6000, 8000, 10000)
for zt in label_zs
    i = findmin(abs.(sounding.z .- zt))[2]
    text!(ax, sounding.u[i], sounding.v[i];
          text = string(round(Int, sounding.z[i] / 1000), " km"),
          offset = (6, 0), align = (:left, :center), fontsize = 11)
end
fig2

# Because the W-K wind profile here is unidirectional, the hodograph
# is a horizontal line. Curved hodographs (the original W-K paper
# explored both) can be obtained by editing
# `data/soundings/generate_weisman_klemp_1982.jl`.
