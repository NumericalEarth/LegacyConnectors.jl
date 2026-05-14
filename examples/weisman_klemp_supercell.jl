# # Weisman & Klemp (1982): analytic forms vs sounding file
#
# The Weisman & Klemp (1982) sounding is *defined analytically*. The
# package ships a `weisman_klemp_1982.txt` file that was generated
# from those formulas — convenient when you want a CM1/WRF-format
# artifact — but if you're already in Julia, you don't need the file.
# Define the profiles as Julia functions and `set!` a Breeze `Field`
# directly. This example does both and shows the results agree.
#
# **Take-away:** when you have analytic forms, prefer
# `set!(field, (x, y, z) -> θ(z))` over routing through a text file.
# The analytic path:
#
#   - skips the discretization stored in the `.txt`,
#   - avoids the parser and the LegacyConnectors interpolation step,
#   - and reads as the math it is.
#
# Sounding files come into their own when there is no analytic form —
# real radiosondes, GFS point profiles, etc. The other examples cover
# those cases.

using LegacyConnectors
using Breeze
using CairoMakie

# ## The analytic profiles
#
# Below are the W&K 1982 formulas verbatim. Constants follow the
# canonical "wet" run (surface qv cap at 14 g/kg, tropopause at 12 km).

const θ₀   = 300.0     # K, surface potential temperature
const θ_tr = 343.0     # K, potential temperature at tropopause
const T_tr = 213.0     # K, isothermal-stratosphere temperature
const z_tr = 12_000.0  # m
const qv_max = 14.0e-3 # kg/kg

const g_const  = 9.81
const cp_const = 1004.0

θ_wk(z)  = z ≤ z_tr ?
    θ₀ + (θ_tr - θ₀) * (z / z_tr)^(5//4) :
    θ_tr * exp(g_const * (z - z_tr) / (cp_const * T_tr))

RH_wk(z) = z ≤ z_tr ? 1.0 - 0.75 * (z / z_tr)^(5//4) : 0.25

# For simplicity in this example we use a fixed-qv profile rather than
# inverting hydrostatic balance for `RH·qvs(T, p)`. That's what the
# generator in `data/soundings/generate_weisman_klemp_1982.jl` does;
# it's straightforward but distracts from the point here.

qv_wk(z) = min(qv_max, qv_max * RH_wk(z))

# Wind: unidirectional linear shear, capped at 30 m/s above 6 km.
const U_s = 30.0
const z_s = 6_000.0
u_wk(z) = z ≤ z_s ? U_s * z / z_s : U_s
v_wk(z) = 0.0

# ## Build Fields from the analytic forms

grid = RectilinearGrid(CPU(); size = (1, 1, 128),
                       x = (0, 1), y = (0, 1), z = (0, 16_000),
                       topology = (Periodic, Periodic, Bounded))

θ_a  = CenterField(grid)
qv_a = CenterField(grid)
u_a  = CenterField(grid)

set!(θ_a,  (x, y, z) -> θ_wk(z))
set!(qv_a, (x, y, z) -> qv_wk(z))
set!(u_a,  (x, y, z) -> u_wk(z))

# Three calls. No file, no parser, no interpolation table.

# ## Build the same Fields by reading the bundled sounding

sounding = Sounding(:weisman_klemp_1982)

θ_s  = CenterField(grid)
qv_s = CenterField(grid)
u_s  = CenterField(grid)

set!(θ_s,  sounding.θ)
set!(qv_s, sounding.qv)
set!(u_s,  sounding.u)

# ## Plot them on top of each other

fig = Figure(size = (1000, 450))
ax_θ  = Axis(fig[1, 1]; xlabel = "θ (K)",     ylabel = "z (m AGL)",
             title = "Analytic vs sounding file")
ax_qv = Axis(fig[1, 2]; xlabel = "qv (g/kg)", ylabel = "z (m AGL)")
ax_u  = Axis(fig[1, 3]; xlabel = "u (m/s)",   ylabel = "z (m AGL)")

lines!(ax_θ,  θ_a;        label = "set!(field, fn)",   linewidth = 2)
lines!(ax_θ,  θ_s;        label = "from sounding",     linestyle = :dash)
lines!(ax_qv, qv_a * 1000;                            linewidth = 2)
lines!(ax_qv, qv_s * 1000;                            linestyle = :dash)
lines!(ax_u,  u_a;                                    linewidth = 2)
lines!(ax_u,  u_s;                                    linestyle = :dash)

axislegend(ax_θ; position = :rb)
fig

# The two paths agree on θ and u to plotting tolerance. The qv panel
# shows a small offset because the bundled `.txt` was generated with
# real `qvs(T, p)` (Bolton 1980 saturation vapor pressure plus
# hydrostatic pressure integration), while the in-script `qv_wk(z)`
# above uses the simplified form `qv_max · RH(z)` for brevity. The
# generator script `data/soundings/generate_weisman_klemp_1982.jl`
# has the full version if you want a one-for-one match.
