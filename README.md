# JuXIMC (WIP)
Julia wrapper for XIMC motor control package by Standa (www.standa.lt).  
The standard wrapper has been expanded for ease of use and to conform more to Julian standards.  
Included is a file to control Keysight PNA 5224B with Julia, suited to our specific needs.

### Installation
Clone directly into directory of your choice. Not installable via package manager (yet).

To use package run
```julia
julia> using Pkg
julia> Pkg.add("https://github.com/mppmu/BoostFractor.jl.git")
julia> Pkg.add("Plots")
julia> Pkg.add("https://github.com/bergermann/Dragoon.jl.git")
```
in your working directory

## Usage
[Examples](./examples) contains scripts for our set-up at RWTH.  
Shoot me an email (dominik.bergermann@rwth-aachen.de) if you need help with your own set-up.  
Proper guides perhaps in the future.