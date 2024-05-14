max_wheel_speed = 10
chase_speed = 10   -- Speed for chasing the prey

function init()
    -- Initialize robot behaviors or attributes
    robot.leds.set_all_colors("blue")  -- Set initial LED color to red
    robot.colored_blob_omnidirectional_camera.enable()  -- Enable camera to detect colored blobs
end

function step()
    -- Execute one step of the simulation
    predatorBehavior()
end

-- Predator behavior: Use swarm intelligence to chase prey
function predatorBehavior()
    -- Search for the closest prey
    local closestPrey = searchClosestPrey()

    -- If a prey is found, chase it
    if closestPrey then
        speeds = ComputeSpeedFromAngle(closestPrey.angle)
        robot.wheels.set_velocity(speeds[1], speeds[2])
    else
        avoidObstacles()
    end
end

-- Function to search for the closest prey
function searchClosestPrey()
    local closestPrey = nil
    local minDistance = math.huge

    -- Loop through all detected blobs
    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        -- Check if the blob is a prey (assuming prey emits red light)
        if blob.color.red > 0 then
            -- Calculate distance to the prey
            local distance = blob.distance
            -- Update closest prey if this one is closer
            if distance < minDistance then
                minDistance = distance
                closestPrey = blob
            end
        end
    end

    return closestPrey
end

function avoidObstacles()
    -- Set default velocities
    local leftVelocity = max_wheel_speed
    local rightVelocity = max_wheel_speed
    
    -- Iterate through all proximity sensors
    for i, sensor in ipairs(robot.proximity) do
        -- Check if an obstacle is detected
        if sensor.value > 0.7 then
            -- If an obstacle is detected, adjust velocities to avoid it
            if sensor.angle < 0 then
                -- Obstacle detected on the left side, adjust right velocity
                rightVelocity = max_wheel_speed - 2  -- Reduce right wheel speed to turn away from the obstacle
            else
                -- Obstacle detected on the right side, adjust left velocity
                leftVelocity = max_wheel_speed - 2  -- Reduce left wheel speed to turn away from the obstacle
            end
        end
    end
    
    -- Set adjusted velocities to avoid obstacles
    robot.wheels.set_velocity(leftVelocity, rightVelocity)
end

--This function computes the necessary wheel speed to go in the direction of the desired angle.
function ComputeSpeedFromAngle(angle)
    dotProduct = 0.0;
    KProp = 20;
    wheelsDistance = 0.14;

    -- if the target angle is behind the robot, we just rotate, no forward motion
    if angle > math.pi/2 or angle < -math.pi/2 then
        dotProduct = 0.0;
    else
    -- else, we compute the projection of the forward motion vector with the desired angle
        forwardVector = {math.cos(0), math.sin(0)}
        targetVector = {math.cos(angle), math.sin(angle)}
        dotProduct = forwardVector[1]*targetVector[1]+forwardVector[2]*targetVector[2]
    end

	 -- the angular velocity component is the desired angle scaled linearly
    angularVelocity = KProp * angle;
    -- the final wheel speeds are compute combining the forward and angular velocities, with different signs for the left and right wheel.
    speeds = {dotProduct * max_wheel_speed - angularVelocity * wheelsDistance, dotProduct * max_wheel_speed + angularVelocity * wheelsDistance}

    return speeds
end

-- Reset function
function reset()
    -- Reset any necessary variables or states
end

-- Destroy function
function destroy()
    -- Clean up resources if needed
end
