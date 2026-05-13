# Adding a new sounding format

A new format `:my_format` needs three things:

1. **A parser** in `src/formats/my_format.jl` that returns a [`Sounding`](../soundings.jl).
   Convert all quantities to SI (Pa, K, kg/kg, m, m/s) at read time so
   downstream code does not need to know which format it came from.
2. **A dispatch entry** in `read_sounding` (`src/soundings.jl`): add an
   `elseif format === :my_format` branch and include the new file from
   `src/LegacyConnectors.jl`.
3. **Tests** in `test/test_my_format.jl`, ideally driven by a small
   example file bundled in `data/soundings/`.

If the format is a binary container (NetCDF, GRIB, …), make the
file-reading dependency a package extension under `ext/` rather than a
hard dep on the core package, so users who only need text formats stay
lightweight.
