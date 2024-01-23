# RuntimeUnits.jl

`RuntimeUnits.jl` provides a dynamic unit system that stores dimensional information along with values.
Although this is slow compared to type-based approaches like `Unitful.jl`, it is necessary if evaluated
expressions are user input and can therefore not be type-stable. `RuntimeUnits.jl` is type-stable as far
as possible (i. e. for number and exponent types).

The package provides two types:
- `UnitSystem` for storing descriptive strings about dimensions,
  pretty-printing of units and storing defined units as `Quantities`.
- `Quantity{V, E}` for representing quantities that have a value of
  type `V` and unit exponents of type `E`.

`Quantity` supports `+`, `-` with other `Quantity`s; `*`, `/`, `//` with `Quantity`s and scalars and
`^` with scalars. `V` and `E` are expected to support `+`, `-`, `*`. `V` should additionally support
`/`, `//` and `^`.

Note:
- `+` and `-` throw errors if called with different dimensions. Dimensions can be checked with `compare_dimensions`
- The unit dimension vector is assumed to be infinitely large. Indices `i > lastindex(…)` are implicitly set to `0`
  so a universal scalar `Quantity` with dimension `E[]` can be used for arithmetic.

## Example

```
using RuntimeUnits;
import RuntimeUnits.SI;
Base.show(io::IO, ::MIME"text/plain", q::Quantity) = print(unit_string(SI, q));

# define some SI units
define_unit!(SI, "Bq", Quantity(1, [0, 0, -1]));
define_unit!(SI, "Hz", Quantity(1, [0, 0, -1]));
define_unit!(SI, "Sv", Quantity(1, [2, 0, -2]));
define_unit!(SI, "J", Quantity(1, [2, 1, -2]));
define_unit!(SI, "Pa", Quantity(1, [-1, 1, -2]));
define_unit!(SI, "rad", Quantity(1, []));
define_unit!(SI, "F", Quantity(1, [-2, -1, 4, 2]));
define_unit!(SI, "C", Quantity(1, [0, 0, 1, 1]));
define_unit!(SI, "V", Quantity(1, [2, 1, -3, -1]));
define_unit!(SI, "Ω", Quantity(1, [2, 1, -3, -2]));
define_unit!(SI, "Gy", Quantity(1, [2, 0, -2]));
define_unit!(SI, "H", Quantity(1, [2, 1, -2, -2]));
define_unit!(SI, "N", Quantity(1, [1, 1, -2]));
define_unit!(SI, "W", Quantity(1, [2, 1, -3]));
define_unit!(SI, "T", Quantity(1, [0, 1, -2, -1]));
define_unit!(SI, "Wb", Quantity(1, [2, 1, -2, -1]));

r = SI(5, "m"); # prints as 5m
typeof(r) # Quantity{Int64, Int64}()
m = SI(10, "kg") # 10kg
ω = SI(π, "Hz") # 3.141592653589793s^-1
ω = Quantity(π, dimension(SI(1, "Hz"))) # πs^-1
typeof(ω) # Quantity{Irrational{:π}, Int64}
a = r*ω^2
F = m*a

# try to get float values of F in Newton and Joule…
value(F, SI(1, "N")) # 1973.9208802178716
value(F, SI(1, "J")) # error: dimension mismatch
```
