# characterizations of stages in use

# stage name and their respective ordering in the devices vector
stagenames = Dict{String,Int}(
    "Motor 7" => 1,
    "Monica" => 2,
)

# (unit, steps per unit)
stagecals = Dict{String,Tuple{Symbol,Float64}}(
    "Motor 7" => (:mm,800),
    "Monica" => (:mm,-800),
)

# (unit, distance to zero point)
stagezeros = Dict{String,Tuple{Symbol,Float64}}(
    "Motor 7" => (:mm,-28),
    "Monica" => (:mm,66),
)

# (unit, left side boundary, right side boundary)
stagecols = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Motor 7" => (:mm,-2,4),
    "Monica" => (:mm,-4,2),
)

# (unit, left border, right border)
stageborders = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Motor 7" => (:mm,2,27),
    "Monica" => (:mm,16,66),
)

# (unit, home position)
stagehomes = Dict{String,Tuple{Symbol,Float64}}(
    "Motor 7" => (:mm,10),
    "Monica" => (:mm,20),
)
