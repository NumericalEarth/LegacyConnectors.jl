# LegacyConnectors.jl

[![CI](https://github.com/NumericalEarth/LegacyConnectors.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/NumericalEarth/LegacyConnectors.jl/actions/workflows/CI.yml)
[![Docs (stable)](https://img.shields.io/badge/docs-stable-blue.svg)](https://numericalearth.github.io/LegacyConnectors.jl/stable)
[![Docs (dev)](https://img.shields.io/badge/docs-dev-blue.svg)](https://numericalearth.github.io/LegacyConnectors.jl/dev)
[![codecov](https://codecov.io/gh/NumericalEarth/LegacyConnectors.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/NumericalEarth/LegacyConnectors.jl)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)

Readers and adapters that let [Breeze.jl](https://github.com/NumericalEarth/Breeze.jl)
ingest initial conditions from legacy atmospheric modeling formats —
starting with the CM1/WRF/ERF `input_sounding` text format.

This package exists so Breeze.jl itself can stay focused on its
dynamical core. See [NumericalEarth/Breeze.jl#672](https://github.com/NumericalEarth/Breeze.jl/discussions/672)
for the motivating discussion.

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/NumericalEarth/LegacyConnectors.jl")
```

## Quickstart

```julia
using LegacyConnectors

# Load one of the three bundled example soundings…
sounding = read_sounding(example_sounding(:weisman_klemp_1982))

# …or your own input_sounding file.
sounding = read_sounding("/path/to/input_sounding")

@show sounding.surface_pressure  # in Pa
@show length(sounding)           # number of above-surface levels
```

## Bundled example soundings

| Name | Source |
|---|---|
| `:weisman_klemp_1982` | Analytic supercell sounding, regenerable from `data/soundings/generate_weisman_klemp_1982.jl`. |
| `:kabq_radiosonde`    | KABQ radiosonde, 2025-07-15 00Z. |
| `:abudhabi_gfs`       | Abu Dhabi GFS point forecast, 2025-07-15 12Z. |

See [`data/soundings/README.md`](data/soundings/README.md) for full
provenance.

## License

Apache-2.0 — see [LICENSE](LICENSE).
