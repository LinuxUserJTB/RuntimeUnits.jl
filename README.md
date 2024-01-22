# RuntimeUnits.jl

`RuntimeUnits.jl` provides a dynamic unit system that stores dimensional information along with values.
Although this is slow compared to type-based approaches like `Unitful.jl`, it is necessary if evaluated
expressions are user input and can therefore not be type-stable. `RuntimeUnits.jl` is type-stable as far
as possible (i. e. for number and exponent types).

The package provides two types:
- `UnitSystem` just for storing descriptive strings about dimensions and pretty-printing of units.
- `Quantity{V, E}` for representing quantities that have a value of type `V` and unit exponents of
    type `E`.

`Quantity` supports `+`, `-` with other `Quantity`s; `*`, `/`, `//` with `Quantity`s and scalars and
`^` with scalars. `V` and `E` are expected to support `+`, `-`, `*`. `V` should additionally support
`/`, `//` and `^`.

Note:
- `+` and `-` throw errors if called with different dimensions. Dimensions can be checked with `compare_dimensions`
- The unit dimension vector is assumed to be infinitely large. Indices `i > lastindex(…)` are implicitly set to `0`
  so a universal scalar `Quantity` with dimension `E[]` can be used for arithmetic.
