@program agent_waypoint_model() begin
    
    # assumed scene
    scene = Scene(0, 100, 0, 100) # the scene spans the square [0, 100] x [0, 100]
    add!(scene, Tree(Point(30, 20))) # place a tree at x=30, y=20
    add!(scene, Tree(Point(83, 80)))
    add!(scene, Tree(Point(80, 40)))
    
    wall_height = 30.
    walls = @e([
        Wall(Point(20., 40.), 1, 40., 2., wall_height)
        Wall(Point(60., 40.), 2, 40., 2., wall_height)
        Wall(Point(60.-15., 80.), 1, 15. + 2., 2., wall_height)
        Wall(Point(20., 80.), 1, 15., 2., wall_height)
        Wall(Point(20., 40.), 2, 40., 2., wall_height) ], "walls")
    for wall in walls
        add!(scene, wall)
    end
    
    # time points at which we observe the agent's location
    observation_times = @e(collect(linspace(0.0, 200.0, 20)), "times")
    
    # assumed speed of the agent
    speed = 1.0
    
    # the starting location of the agent is a random point in the scene
    start = @g(uniform_2d(0, 100, 0, 100), "start")
    
    # the destination of the agent is a random point in the scene
    destination = @g(uniform_2d(0, 100, 0, 100), "destination")
    
    if @g(flip(0.5), "use-waypoint")
        waypoint = @g(uniform_2d(0, 100, 0, 100), "waypoint")
        (tree1, rough_path1, final_path1) = plan_path(start, waypoint, scene)
        (tree2, rough_path2, final_path2) = plan_path(waypoint, destination, scene)
        
        # if either path planner sub-problem failed, then no path was found (final_path is null)
        if isnull(final_path1) || isnull(final_path2)
            final_path = Nullable{Path}() # null
        else
            final_path = Nullable{Path}(concatenate(get(final_path1), get(final_path2)))
        end
    else
        (tree, rough_path, final_path) = plan_path(start, destination, scene)
    end
    
    # the path of the agent from its start location to its destination
    # uses a simple 2D holonomic path planner based on RRT (path_planner.jl)
    
    if @e(isnull(final_path), "planning-failed")
        
        # the agent could not find a path to its destination
        # assume it stays at the start location indefinitely
        locations = [start for _ in observation_times]
    else
        
        # the agent found a path to its destination
        # assume it moves from the start to the destinatoin along the path at constnat speed
        # sample its location along this path for each time in observation times
        locations = walk_path(get(final_path), speed, observation_times)
    end
    
    # assume that the observed locations are noisy measurements of the true locations
    # assume the noise is normally distributed with standard deviation 'noise'
    noise = 1.0
    for (i, t) in enumerate(observation_times)
        measured_x = @g(normal(locations[i].x, noise), "x$i")
        measured_y = @g(normal(locations[i].y, noise), "y$i")
    end
    
    # record other program state for rendering
    @e(final_path, "final-path")
    @e(scene, "scene")
end;

function agent_waypoint_model_importance_sampling(trace::Trace, num_samples::Int)
    traces = Vector{Trace}(num_samples)
    scores = Vector{Float64}(num_samples)
    for k=1:num_samples
        t = deepcopy(trace)
        (scores[k], _) = @generate!(agent_waypoint_model(), t)
        traces[k] = t
    end
    weights = exp.(scores - logsumexp(scores))
    weights = weights / sum(weights)
    chosen = rand(Categorical(weights))
    return traces[chosen]
end
