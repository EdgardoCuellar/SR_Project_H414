max_wheel_speed = 10
chase_speed = 10   -- Speed for chasing the prey
min_distance = 20  -- Minimum distance between predators
preyStoppedDistance = 12  -- Distance threshold to consider prey stopped
stop_time = 0  -- Time to stop moving after receiving stop message
stop_time_threshold = 125  -- Time threshold to stop moving after receiving stop message
is_stopped = false  -- Flag to indicate if the predator has stopped moving

function init()
    -- Initialize robot behaviors or attributes
    robot.leds.set_all_colors("blue")  -- Set initial LED color to red
    robot.colored_blob_omnidirectional_camera.enable()  -- Enable camera to detect colored blobs
end

function step()
    -- Execute one step of the simulation
    predatorBehavior()
end

-- Predator behavior: Use swarm intelligence to chase prey while avoiding collisions with other predators
function predatorBehavior()
    -- Search for the closest prey
    local closestPrey = searchClosestPrey()
    local speeds = {max_wheel_speed, max_wheel_speed}

    -- If a prey is found, chase it
    if not is_stopped then
        if closestPrey then
            adjustedAngle = adjustAngleToAvoidCollisions(closestPrey.angle, closestPrey.distance)
            speeds = ComputeSpeedFromAngle(adjustedAngle)
        else
            speeds = avoidObstacles()
        end
    end

    -- Check if the prey has stopped moving
    if closestPrey and closestPrey.distance < preyStoppedDistance then  -- Assuming the prey is considered stopped if it's very close
        -- Broadcast message to stop moving to other predators
        stop_time = stop_time + 1
    elseif stop_time > 0 then
        stop_time = stop_time - 10  -- Decrease stop time by 10 at each step
    end

    if stop_time > stop_time_threshold then
        robot.range_and_bearing.set_data(1,0) 
        is_stopped = true
    end

    for i = 1,#robot.range_and_bearing do
        if robot.range_and_bearing[i].data[1] == 1 then
            is_stopped = true
        end
    end

    if is_stopped then
        speeds = {0, 0}
    end

    robot.wheels.set_velocity(speeds[1], speeds[2])
end

-- Function to search for the closest prey
function searchClosestPrey()
    -- Loop through all detected blobs
    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        -- Check if the blob is a prey (assuming prey emits red light)
        if blob.color.red > 0 then
            return blob
        end
    end
end

function avoidObstacles()
    local vec = { x=0, y=0 }
	local accumul = { x=0, y=0 }
	for i = 1, 24 do 
		-- we calculate the x and y components given length and angle
		vec = {
			x = robot.proximity[i].value * math.cos(robot.proximity[i].angle),
			y = robot.proximity[i].value * math.sin(robot.proximity[i].angle)
		}
		-- we sum the vectors into a variable called accumul
		accumul.x = accumul.x + vec.x
		accumul.y = accumul.y + vec.y
	end
	-- we get length and angle of the final sum vector
	length = math.sqrt(accumul.x * accumul.x + accumul.y * accumul.y)
	angle = math.atan2(accumul.y, accumul.x)
	
	if length > 0.3 then
		if angle > 0 then
            return {math.max(0.5,math.cos(angle)) * max_wheel_speed, 0}
		else
            return {0, math.max(0.5,math.cos(angle)) * max_wheel_speed}
		end
	end
    return {max_wheel_speed, max_wheel_speed}
end

-- Function to adjust angle to avoid collisions with other predators
function adjustAngleToAvoidCollisions(preyAngle, preyDistance)
    local avoidanceVectorX = math.cos(preyAngle) * preyDistance
    local avoidanceVectorY = math.sin(preyAngle) * preyDistance
    
    -- Loop through all detected blobs
    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        -- Check if the blob is a predator (assuming predators emit blue light)
        if blob.color.blue > 0 then
            -- Calculate distance to the predator
            local distance = blob.distance
            -- If the predator is too close, adjust the avoidance angle
            if distance < min_distance then
                avoidanceVectorX = avoidanceVectorX + math.cos(blob.angle) * preyDistance
                avoidanceVectorY = avoidanceVectorY + math.sin(blob.angle) * preyDistance
                break
            end
        end
    end
    local avoidanceAngle = math.atan2(avoidanceVectorY, avoidanceVectorX)
    return avoidanceAngle
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
