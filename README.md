# DashComponentsBuilder

Package for generating and deploying components for Dash.

## Instalation
```julia-repl
pkg> add https://github.com/waralex/DashComponentsBuilder.jl
```

## Using

```julia-repl
julia> import DashComponentsBuilder as DCB

julia> DCB.run_wizard()
```

## Notes
At the time of testing, the component registry is locate here: https://github.com/waralex/DashComponentsRecipes
To check the resulting components, you need to install a test version of DashBase:

```julia-repl
pkg> add https://github.com/plotly/DashBase.jl.git#generate_components
```