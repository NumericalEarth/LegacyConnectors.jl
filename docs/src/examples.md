# Bundled example soundings

Three soundings ship with the package. Each one is small enough to live
in the repo (under `data/soundings/`) and to be loaded by tests and
docs.

```@setup soundings
using LegacyConnectors
using CairoMakie
CairoMakie.activate!(type = "png")

function plot_sounding(s; title)
    fig = Figure(size = (900, 360))
    ax1 = Axis(fig[1, 1]; xlabel = "θ (K)",      ylabel = "z (m AGL)", title = title)
    ax2 = Axis(fig[1, 2]; xlabel = "qv (g/kg)",  ylabel = "z (m AGL)")
    ax3 = Axis(fig[1, 3]; xlabel = "wind (m/s)", ylabel = "z (m AGL)")
    lines!(ax1, s.θ, s.z)
    # mask NaN qv levels for the plot only; the data itself preserves them
    qv_gkg = s.qv .* 1000
    finite = isfinite.(qv_gkg)
    lines!(ax2, qv_gkg[finite], s.z[finite])
    lines!(ax3, s.u, s.z; label = "u")
    lines!(ax3, s.v, s.z; label = "v")
    axislegend(ax3; position = :rb)
    fig
end
```

## Weisman & Klemp (1982)

The canonical idealized supercell sounding: surface θ = 300 K with
qv capped at 14 g/kg, tropopause at 12 km, unidirectional linear shear
to 30 m/s at z = 6 km. Generated reproducibly from the analytic
formulas in W-K 1982; see
[`data/soundings/generate_weisman_klemp_1982.jl`](https://github.com/NumericalEarth/LegacyConnectors.jl/blob/main/data/soundings/generate_weisman_klemp_1982.jl).

```@example soundings
s = read_sounding(example_sounding(:weisman_klemp_1982))
plot_sounding(s; title = "Weisman & Klemp 1982")
```

## KABQ radiosonde — 2025-07-15 00Z

Observed radiosonde from Albuquerque, NM. The station sits at ~1620 m
MSL, so the surface pressure is well below 1000 mb even though the
level column starts near the ground (AGL).

```@example soundings
s = read_sounding(example_sounding(:kabq_radiosonde))
plot_sounding(s; title = "KABQ radiosonde 2025-07-15 00Z")
```

## Abu Dhabi GFS point forecast — 2025-07-15 12Z

GFS forecast vertical profile. The native data extends well into the
mesosphere; moisture is not defined that high, and the file records
`nan` for `qv` at those levels. LegacyConnectors preserves the `NaN`s
in the parsed `Sounding`; the plot below masks them.

```@example soundings
s = read_sounding(example_sounding(:abudhabi_gfs))
plot_sounding(s; title = "Abu Dhabi GFS 2025-07-15 12Z")
```
