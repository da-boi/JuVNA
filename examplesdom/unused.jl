

# function move(booster::PhysicalBooster,newpos::Vector{Float64};
#         additive=false, info::Bool=false)
    
#     if additive
#         updatePos!(booster)

#         checkCollision(booster.pos,newpos,booster; additive=additive) &&
#             error("Discs are about to collide!")

#         commandMove(booster.devices.ids,pos2steps(newpos,booster; additive=additive))
#         commandWaitForStop(booster.devices.ids)

#         updatePos!(booster)
#     else
#         checkCollision(newpos,booster) && error("Discs are about to collide!")

#         booster.pos = copy(newpos)
        
#         commandMove(booster.devices.ids,pos2steps(newpos,booster; additive=additive))
#         commandWaitForStop(booster.devices.ids)
#     end
# end


# function steps2pos(steps::Vector{Tuple{Int,Int}},booster::PhysicalBooster;
#         outputunit=:m)

#     return @. steps2pos(steps,booster.devices.stagecals,
#         booster.devices.stagezeros; outputunit=outputunit)
# end



# function pos2steps(booster::PhysicalBooster; inputunit=:m)
#     return @. pos2steps(booster.pos,booster.devices.stagecals,
#         booster.devices.stagezeros; inputunit=inputunit)
# end

# mutable struct Boundaries <: BoundariesType
#     lo::Float64
#     hi::Float64

#     function Boundaries()
#         new(0,0)
#     end

#     function Boundaries(hi,lo)
#         new(hi,lo)
#     end
# end

# function checkBoundaries(b::Boundaries)
#     if b.hi < b.lo
#         error("Boundary failure: hi < lo!")
#     end
# end


