module RuntimeUnits

export UnitSystem, dimension_names, dimension_name, base_unit_names, base_unit_name, defined_units, defined_unit, define_unit!, define_prefix!
export Quantity, value, dimension, unit_string, compare_dimensions, realfunc

struct Quantity{V, E} <: Real
    value::V
    dimension::Vector{E}
end

struct UnitSystem{V, E}
    dimension_names::Vector{String}
    base_unit_names::Vector{String}
    defined_units::Dict{String, Quantity{V, E}}
end

dimension_names(u::UnitSystem) = u.dimension_names
dimension_name(u::UnitSystem, dim) = dimension_names(u)[dim]
base_unit_names(u::UnitSystem) = u.base_unit_names
base_unit_name(u::UnitSystem, dim) = base_unit_names(u)[dim]
defined_units(u::UnitSystem) = u.defined_units
defined_unit(u::UnitSystem, name) = defined_units(u)[name]

define_unit!(u::UnitSystem, name, unit::Quantity) = defined_units(u)[name] = unit
define_prefix!(u::UnitSystem, basename, prefix, factor) = define_unit!(u, prefix * basename, defined_unit(u, basename) * factor)

SI = begin
    u = UnitSystem(["length", "mass", "time", "current", "temperature", "luminosity", "amount"], ["m", "kg", "s", "A", "K", "cd", "mol"], Dict{String, Quantity{Int, Int}}())
    for dim in eachindex(base_unit_names(u))
        basename = base_unit_name(u, dim)
        define_unit!(u, basename, Quantity(1, setindex!(fill(0, dim), 1, dim)))
    end
    u
end

unit_string(u::UnitSystem, dim, ex) = ex == 0 ? "" : (base_unit_name(u, dim) * (ex == 1 ? "" : "^" * string(ex)))
unit_string(u::UnitSystem, dims) = join(Iterators.filter(!isempty, unit_string(u, i, dims[i]) for i in eachindex(dims)), '*')
unit_string(u::UnitSystem, q::Quantity) = string(value(q)) * unit_string(u, dimension(q))

(u::UnitSystem)(value, unitname) = defined_unit(u, unitname) * value
(u::UnitSystem)(unitname) = defined_unit(u, unitname)
Quantity(u::UnitSystem, value, unitname) = defined_unit(u, unitname) * value

unit_string(q::Quantity) = unit_string(SI, q)

value(q::Quantity) = q.value
dimension(q::Quantity) = q.dimension

basetype(q::Quantity) = typeof(value(q))
exptype(q::Quantity) = eltype(dimension(q))

checked_value(q::Quantity) = (assert_dimension_match(q, zero(typeof(q))); value(q))
value(q::Quantity, unit::Quantity) = checked_value(q / unit)

zero_val(q::Quantity) = zero(value(q))
one_val(q::Quantity) = one(value(q))
zero_dim(q::Quantity) = zero(eltype(dimension(q)))

Base.zero(q::Quantity) = Quantity(zero_val(q), dimension(q))
Base.zero(::Type{Quantity{V, E}}) where {V, E} = Quantity(zero(V), E[])
Base.one(q::Quantity) = Quantity(one_val(q), dimension(q))
Base.one(::Type{Quantity{V, E}}) where {V, E} = Quantity(one(V), E[])

getindex_default(x, i, def) = i in eachindex(x) ? x[i] : def

function defaulting_broadcast(f, x1, x2, def1, def2)
    (f(getindex_default(x1, i, def1), getindex_default(x2, i, def2))
            for i in min(firstindex(x1), firstindex(x2)):max(lastindex(x1), lastindex(x2)))
end

compare_dimensions(q1::Quantity, q2::Quantity) = !any(defaulting_broadcast(!=, dimension(q1), dimension(q2), zero_dim(q1), zero_dim(q2)))

assert_dimension_match(q1::Quantity, q2::Quantity) = compare_dimensions(q1, q2) || error("dimension mismatch: $(dimension(q1)) ≠ $(dimension(q2))")
            
function combine(f_val::Function, f_dim::Function, q1::Quantity, q2::Quantity)
    Quantity(f_val(value(q1), value(q2)), collect(defaulting_broadcast(f_dim, dimension(q1), dimension(q2), zero_dim(q1), zero_dim(q2))))
end

promote_first_value(d1...) = first(promote(d1...))

function linear_combine(f, q1::Quantity, q2::Quantity)
    assert_dimension_match(q1, q2)
    combine(f, promote_first_value, q1, q2)
end

Base.convert(T::Type{Quantity}, v) = T(v, dimension(zero(T)))
Base.convert(T::Type{<:Number}, v::Quantity) = (assert_dimension_match(v, zero(typeof(v))); convert(T, value(v)))
Base.convert(T::Type{Quantity{V, E}}, v::Quantity) where {V, E} = Quantity{V, E}(value(v), dimension(v))
Base.AbstractFloat(q::Quantity) = AbstractFloat(checked_value(q))

(Base. +)(q1::Quantity, q2::Quantity) = linear_combine(+, q1, q2)
(Base. -)(q1::Quantity, q2::Quantity) = linear_combine(-, q1, q2)
(Base. *)(q1::Quantity, q2::Quantity) = combine(*, +, q1, q2)
(Base. /)(q1::Quantity, q2::Quantity) = combine(/, -, q1, q2)
(Base. //)(q1::Quantity, q2::Quantity) = combine(//, -, q1, q2)
(Base. ^)(q1::Quantity, q2::Quantity) = q1 ^ checked_value(q2)

(Base. *)(q::Quantity, f::Real) = Quantity(value(q) * f, dimension(q))
(Base. *)(f::Real, q::Quantity) = Quantity(f * value(q), dimension(q))
(Base. /)(q::Quantity, d::Real) = Quantity(value(q) / d, dimension(q))
(Base. /)(d::Real, q::Quantity) = Quantity(d / value(q), .-dimension(q))
(Base. //)(q::Quantity, d::Real) = Quantity(value(q) // d, dimension(q))
(Base. //)(d::Real, q::Quantity) = Quantity(d // value(q), .-dimension(q))
(Base. ^)(q::Quantity, ex::Real) = Quantity(value(q) ^ ex, dimension(q) .* ex)
(Base. ^)(q::Quantity, ex::Integer) = Quantity(value(q) ^ ex, dimension(q) .* ex)
(Base. ^)(b::Real, q::Quantity) = b ^ checked_value(q)

realfunc(f, q::Quantity...) = Quantity(f(checked_value.(q)...), promote_type(exptype.(q)...)[])

end
