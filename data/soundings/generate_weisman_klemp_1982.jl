#!/usr/bin/env julia
#
# Generate the canonical Weisman & Klemp (1982) analytic sounding in the
# CM1/WRF "input_sounding" text format.
#
# Reference:
#   Weisman, M. L., and J. B. Klemp, 1982: The dependence of numerically
#   simulated convective storms on vertical wind shear and buoyancy.
#   Mon. Wea. Rev., 110, 504–520.
#
# Analytic profile (W-K 1982, §2a):
#   θ(z) = θ₀ + (θ_tr - θ₀) (z/z_tr)^(5/4)         for 0 ≤ z ≤ z_tr
#   θ(z) = θ_tr exp[g (z - z_tr) / (cp T_tr)]      for z > z_tr
#   RH(z) = 1 - 3/4 (z/z_tr)^(5/4)                 for 0 ≤ z ≤ z_tr
#   RH(z) = 0.25                                   for z > z_tr
#
# Surface mixing ratio is capped at qv_max = 14 g/kg (the canonical "wet"
# value; W-K also use 11, 12, 13, 15 g/kg in their suite). qv(z) is then:
#   qv(z) = min(qv_max, RH(z) · qvs(T(z), p(z)))
#
# Winds: unidirectional half-circle shear, common companion to the W-K
# thermodynamic profile in CM1 base.F (iwnd=2):
#   u(z) = U_s · z / z_s   for z ≤ z_s
#   u(z) = U_s             for z > z_s
#   v(z) = 0
# with U_s = 30 m/s, z_s = 6000 m.
#
# Surface pressure is taken as 1000 mb (W-K standard). Hydrostatic
# integration with virtual temperature gives p(z), which we use only to
# compute qv(z) via RH; the .txt file itself does not store p(z).
#
# Run from this directory:
#   julia generate_weisman_klemp_1982.jl

using Printf

# ---- Physical constants (W-K 1982 paper values) ----------------------------
const g     = 9.81        # m/s²
const Rd    = 287.04       # J/(kg·K), dry air
const Rv    = 461.50       # J/(kg·K), water vapor
const cp    = 1004.0       # J/(kg·K), dry air
const p0ref = 100000.0     # Pa, reference pressure for θ
const eps_  = Rd / Rv      # ≈ 0.622

# ---- W-K analytic-sounding parameters --------------------------------------
const θ_0   = 300.0    # K, surface potential temperature
const θ_tr  = 343.0    # K, potential temperature at tropopause
const T_tr  = 213.0    # K, temperature at tropopause
const z_tr  = 12000.0  # m, tropopause height
const qv_max = 14.0e-3 # kg/kg, surface mixing ratio cap

# Wind (iwnd=2 in CM1 base.F: unidirectional linear shear capped at z_s)
const U_s = 30.0       # m/s
const z_s = 6000.0     # m

# ---- Analytic profiles -----------------------------------------------------
θ_wk(z)  = z ≤ z_tr ?
    θ_0 + (θ_tr - θ_0) * (z / z_tr)^(5//4) :
    θ_tr * exp(g * (z - z_tr) / (cp * T_tr))

RH_wk(z) = z ≤ z_tr ? 1.0 - 0.75 * (z / z_tr)^(5//4) : 0.25

u_wk(z)  = z ≤ z_s ? U_s * z / z_s : U_s
v_wk(z)  = 0.0

# Bolton (1980) saturation vapor pressure over water, Pa (T in K)
e_sat(T) = 611.2 * exp(17.67 * (T - 273.15) / (T - 29.65))

# Saturation mixing ratio (kg/kg)
qv_sat(T, p) = eps_ * e_sat(T) / (p - e_sat(T))

# ---- Hydrostatic integration to get p(z), then qv(z) -----------------------
# Vertical grid: dense near the surface, coarser aloft. ~60 levels to 20 km.
zs = vcat(0:50:500, 600:100:2000, 2200:200:6000, 6500:500:12000, 13000:1000:20000)

p_sfc = 100000.0  # Pa = 1000 mb

# RK2 (midpoint) integration of dp/dz = -p g / (Rd T_v)
function tv(θ, qv, p)
    T  = θ * (p / p0ref)^(Rd / cp)
    return T * (1 + 0.61 * qv), T
end

function qv_at(θ, RH, p)
    # iterate once: estimate T from θ,p with qv=0; refine with qv
    T0 = θ * (p / p0ref)^(Rd / cp)
    qv = min(qv_max, RH * qv_sat(T0, p))
    return qv
end

ps = zeros(length(zs))
ps[1] = p_sfc
for i in 2:length(zs)
    z0, z1 = zs[i-1], zs[i]
    dz = z1 - z0
    p  = ps[i-1]
    θ0i = θ_wk(z0); θ1i = θ_wk(z1)
    RH0 = RH_wk(z0); RH1 = RH_wk(z1)
    # Predictor at z0
    qv0 = qv_at(θ0i, RH0, p)
    Tv0, _ = tv(θ0i, qv0, p)
    p_mid = p - 0.5dz * p * g / (Rd * Tv0)
    # Corrector at midpoint
    z_mid = 0.5 * (z0 + z1)
    θm = θ_wk(z_mid); RHm = RH_wk(z_mid)
    qvm = qv_at(θm, RHm, p_mid)
    Tvm, _ = tv(θm, qvm, p_mid)
    ps[i] = p - dz * p_mid * g / (Rd * Tvm)
end

# ---- Build the input_sounding columns --------------------------------------
θs  = θ_wk.(zs)
qvs = [qv_at(θs[i], RH_wk(zs[i]), ps[i]) for i in eachindex(zs)]
us  = u_wk.(zs)
vs  = v_wk.(zs)

# Surface line uses (p_sfc[mb], θ_sfc, qv_sfc[g/kg]). The level lines that
# follow start *above* the surface; convention varies, but CM1 expects level
# 1 to be the first model height above ground. We therefore drop zs[1]==0
# from the level block and let it be implied by the surface line.
p_sfc_mb   = ps[1] / 100.0
θ_sfc      = θs[1]
qv_sfc_gkg = qvs[1] * 1000.0

outfile = joinpath(@__DIR__, "weisman_klemp_1982.txt")
open(outfile, "w") do io
    @printf(io, "%14.6f %14.6f %14.6f\n", p_sfc_mb, θ_sfc, qv_sfc_gkg)
    for i in 2:length(zs)
        @printf(io, "%14.6f %14.6f %14.6f %14.6f %14.6f\n",
                zs[i], θs[i], qvs[i] * 1000.0, us[i], vs[i])
    end
end

println("Wrote ", outfile, " with ", length(zs) - 1, " levels.")
