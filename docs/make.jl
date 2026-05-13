using Documenter
using LegacyConnectors

DocMeta.setdocmeta!(LegacyConnectors, :DocTestSetup, :(using LegacyConnectors); recursive=true)

makedocs(
    sitename = "LegacyConnectors.jl",
    modules  = [LegacyConnectors],
    authors  = "NumericalEarth organization and contributors",
    format   = Documenter.HTML(;
        canonical = "https://numericalearth.github.io/LegacyConnectors.jl",
        edit_link = "main",
        assets    = String[],
    ),
    pages = [
        "Home"                  => "index.md",
        "Sounding format"       => "format.md",
        "Bundled examples"      => "examples.md",
        "API reference"         => "api.md",
    ],
    warnonly = [:missing_docs],   # tighten in a follow-up PR
)

deploydocs(
    repo          = "github.com/NumericalEarth/LegacyConnectors.jl.git",
    devbranch     = "main",
    push_preview  = true,
)
