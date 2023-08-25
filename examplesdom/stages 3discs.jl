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
    "Monica" => (:mm,80),
    "Alexanderson" => (:mm,278),
    "Motor 7" => (:mm,624),
)

# (unit, left side boundary, right side boundary)
stagecols = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Monica" => (:mm,-1,1),
    "Alexanderson" => (:mm,-1,1),
    "Motor 7" => (:mm,-1,1),
)

# (unit, left border, right border)
stageborders = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Monica" => (:mm,70,130),
    "Alexanderson" => (:mm,270,335),
    "Motor 7" => (:mm,600,700),
)
