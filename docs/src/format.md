# The `input_sounding` format

`input_sounding` is the de-facto text format for idealized vertical
profiles in CM1, WRF (`em_ideal`), and ERF. It is whitespace-separated
and has two record types:

| Line       | Columns                                                                 |
|------------|-------------------------------------------------------------------------|
| **Surface** (line 1) | `p_sfc[mb]   θ_sfc[K]   qv_sfc[g/kg]`                          |
| **Level**            | `z[m]   θ[K]   qv[g/kg]   u[m/s]   v[m/s]`                     |

- `z` is **above ground level** (AGL), not MSL. Files for elevated
  stations (KABQ at ~1620 m, for example) still start their level block
  near `z = 0`.
- Levels are listed in ascending `z`. The reader will refuse a file
  whose `z` column is not monotonically non-decreasing.
- LegacyConnectors converts to SI on read: millibars → pascals, g/kg →
  kg/kg. Wind and height columns are already SI.
- `NaN` is a legal `qv` value and is preserved (some GFS point
  profiles have no moisture above the mesopause).
- Lines starting with `#` or `;`, and blank lines, are skipped.
  Inline `#`/`;` comments at end-of-line are also stripped.

## Worked example

```
1000.000000     300.000000      14.000000
   50.000000     300.045520      14.000000       0.250000       0.000000
  100.000000     300.108266      14.000000       0.500000       0.000000
  ...
```

This is the first three lines of the bundled Weisman–Klemp 1982
sounding. The surface line says: 1000 mb (= 100 000 Pa), θ = 300 K,
qv = 14 g/kg (= 0.014 kg/kg). The level lines that follow each give
height in metres, potential temperature in kelvin, mixing ratio in
g/kg, and the two horizontal wind components in m/s.

## References

- Weisman, M. L., and J. B. Klemp, 1982: *The dependence of numerically
  simulated convective storms on vertical wind shear and buoyancy.*
  Mon. Wea. Rev., **110**, 504–520.
- Bryan, G. H., and J. M. Fritsch, 2002: *A benchmark simulation for
  moist nonhydrostatic numerical models.* Mon. Wea. Rev., **130**,
  2917–2928. (CM1 origin.)
- WRF Users' Guide, *ideal.exe* section (`em_quarter_ss`, `em_les`).
