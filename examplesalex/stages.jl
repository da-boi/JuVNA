# characterizations of stages in use

# stage name and their respective ordering in the devices vector
stagenames = Dict{String,Int}(
    "Monica" => 1,
    "Alexanderson" => 2,
    "Big Chungus" => 3,
    "Bigger Chungus" => 4,
)

# (unit, steps per unit)
stagecals = Dict{String,Tuple{Symbol,Float64}}(
    "Monica" => (:mm,800),
    "Alexanderson" => (:mm,800),
    "Big Chungus" => (:mm,80),
    "Bigger Chungus" => (:mm,80),
)

# (unit, distance to zero point)
stagezeros = Dict{String,Tuple{Symbol,Float64}}(
    "Monica" => (:mm,275),
    "Alexanderson" => (:mm,524),
    "Big Chungus" => (:mm,0),
    "Bigger Chungus" => (:mm,0),
)

# (unit, left side boundary, right side boundary)
stagecols = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Monica" => (:mm,-10,10),
    "Alexanderson" => (:mm,-10,10),
    "Big Chungus" => (:mm,-10,10),
    "Bigger Chungus" => (:mm,-10,10),
)

# (unit, left border, right border)
stageborders = Dict{String,Tuple{Symbol,Float64,Float64}}(
    "Monica" => (:mm,0,0),
    "Alexanderson" => (:mm,0,0),
    "Big Chungus" => (:mm,0,0),
    "Bigger Chungus" => (:mm,0,0),
)