using Agents, Random, Distributions

@enum TreeStatus green burning burnt

@agent struct TreeAgent(GridAgent{2})
    status::TreeStatus = green
end

function forest_step(tree::TreeAgent, model)
    if tree.status == burning
        # Propagación normal a vecinos adyacentes
        for neighbor in nearby_agents(tree, model)
            if neighbor.status == green
                dx = neighbor.pos[1] - tree.pos[1]
                dy = neighbor.pos[2] - tree.pos[2]
                
                adjusted_probability = model.probability_of_spread
                
                if dx > 0
                    adjusted_probability += model.west_wind_speed
                elseif dx < 0
                    adjusted_probability -= model.west_wind_speed
                end
                
                if dy > 0
                    adjusted_probability += model.south_wind_speed
                elseif dy < 0
                    adjusted_probability -= model.south_wind_speed
                end
                
                adjusted_probability = clamp(adjusted_probability, 0.0, 100.0)
                random_value = rand(abmrng(model)) * 100
                
                if random_value < adjusted_probability
                    neighbor.status = burning
                end
            end
        end
        
        # Big jumps
        if model.big_jumps
            scale_factor = 15
            jump_x = round(Int, model.west_wind_speed / scale_factor)
            jump_y = round(Int, model.south_wind_speed / scale_factor)
            
            target_pos = (tree.pos[1] + jump_x, tree.pos[2] + jump_y)
            
            if target_pos[1] >= 1 && target_pos[1] <= size(abmspace(model))[1] &&
               target_pos[2] >= 1 && target_pos[2] <= size(abmspace(model))[2]
                
                if !isempty(target_pos, model)
                    agent_id = id_in_position(target_pos, model)
                    if agent_id !== nothing
                        distant_tree = model[agent_id]
                        if distant_tree.status == green
                            distant_tree.status = burning
                        end
                    end
                end
            end
        end
        
        tree.status = burnt
    end
end

function forest_fire(; 
    density = 0.45, 
    griddims = (5, 5), 
    probability_of_spread = 100.0,
    south_wind_speed = 0.0,
    west_wind_speed = 0.0,
    big_jumps = false
)
    space = GridSpaceSingle(griddims; periodic = false, metric = :chebyshev)
    
    properties = Dict(
        :probability_of_spread => probability_of_spread,
        :south_wind_speed => south_wind_speed,
        :west_wind_speed => west_wind_speed,
        :big_jumps => big_jumps
    )
    
    forest = StandardABM(
        TreeAgent, 
        space; 
        agent_step! = forest_step, 
        scheduler = Schedulers.ByID(),
        properties = properties
    )

    for pos in positions(forest)
        if rand(abmrng(forest)) < density
            tree = add_agent!(pos, TreeAgent, forest)
            if pos[1] == 1
                tree.status = burning
            end
        end
    end
    return forest
end