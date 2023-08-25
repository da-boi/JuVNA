# characterizations of stages in use

# stage name and their respective ordering in the devices vector
stagenames = Dict{String,Int}(
    "Monica" => 1,
    "Alexanderson" => 2,
    "Motor 7" => 3,
)

# (unit, steps per unit)
stagecals = Dict{String,Tuple{Symbol,Float64}}(
    "Monica" => (:mm,800),
    "Alexanderson" => (:mm,800),
    "Motor 7" => (:mm,800),
)

# (unit, distance to zero point)
stagezeros = Dict{String,Tuple{Symbol,Float64}}(
    "Monica" => (:mm,39),
    "Alexanderson" => (:mm,524),
    "Motor 7" => (:mm,624),
)

# (unit, left side boundary, right side boundary)
stagecols = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Monica" => (:mm,-10,9),
    "Alexanderson" => (:mm,-10,10),
    "Motor 7" => (:mm,-10,10),
)

# (unit, left border, right border)
stageborders = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Monica" => (:mm,38,140),
    "Alexanderson" => (:mm,500,600),
    "Motor 7" => (:mm,600,700),
)
