max_wheel_speed = 10
min_distance = 15  -- Minimum distance between predators

preyStoppedDistance = 12  -- Distance threshold to consider prey stopped
stop_time = 0  -- Time to stop moving after receiving stop message
stop_time_threshold = 105  -- Time threshold to stop moving after receiving stop message
is_stopped = false  -- Flag to indicate if the predator has stopped moving

prey_old_angle = 0
prediction_intensity = 2

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
    local closestPrey = searchPrey()
    local speeds = {max_wheel_speed, max_wheel_speed}
    -- If a prey is found, chase it
    if not is_stopped then
        if closestPrey then
            local preyAngle = adjustAngleToPredictPrey(closestPrey.angle)
            robot.range_and_bearing.set_data(1, ((preyAngle + math.pi) / math.pi) * 255 )
            robot.range_and_bearing.set_data(2, closestPrey.distance)
            adjustedAngle = adjustAngleToAvoidCollisions(preyAngle, closestPrey.distance)
            speeds = ComputeSpeedFromAngle(adjustedAngle)
        else
            local preyAngle  -- Variable to store prey angle and distance from other predators
            local sumVectorX = 0  -- Initialize sum of vectors in X direction
            local sumVectorY = 0  -- Initialize sum of vectors in Y direction

            -- Loop through received messages from other predators
            for i = 1, #robot.range_and_bearing do
                if robot.range_and_bearing[i].data[1] and robot.range_and_bearing[i].data[2] and robot.range_and_bearing[i].data[1] ~= 0 then
                    local preyMessageAngle = ((robot.range_and_bearing[i].data[1] / 255) * math.pi) - math.pi
                    local preyMessageDistance = math.min(robot.range_and_bearing[i].data[2], 255)
                    -- Calculate angle to the prey with respect to the predator, using preyMessageAngle and horizontal_bearing
                    sumVectorX = math.cos(robot.range_and_bearing[i].horizontal_bearing) * robot.range_and_bearing[i].range + (math.cos(preyMessageAngle)+math.cos(robot.range_and_bearing[i].horizontal_bearing)) * preyMessageDistance
                    sumVectorY = math.sin(robot.range_and_bearing[i].horizontal_bearing) * robot.range_and_bearing[i].range + (math.sin(robot.range_and_bearing[i].horizontal_bearing) + math.sin(preyMessageAngle)) * preyMessageDistance
                    robot.range_and_bearing.set_data(3, ((math.atan2(sumVectorY, sumVectorX) + math.pi) / math.pi) * 255 )
                elseif robot.range_and_bearing[i].data[3] and robot.range_and_bearing[i].data[3] ~= 0 then
                    local preyMessageAngle = ((robot.range_and_bearing[i].data[3] / 255) * math.pi) - math.pi
                    local preyMessageDistance = 300 -- Maximum distance threshold
                    -- Calculate angle to the prey with respect to the predator, using preyMessageAngle and horizontal_bearing
                    sumVectorX = math.cos(robot.range_and_bearing[i].horizontal_bearing) * robot.range_and_bearing[i].range + (math.cos(preyMessageAngle)+math.cos(robot.range_and_bearing[i].horizontal_bearing)) * preyMessageDistance
                    sumVectorY = math.sin(robot.range_and_bearing[i].horizontal_bearing) * robot.range_and_bearing[i].range + (math.sin(robot.range_and_bearing[i].horizontal_bearing) + math.sin(preyMessageAngle)) * preyMessageDistance
                end
            end
            robot.range_and_bearing.clear_data()

            if sumVectorX ~= 0 and sumVectorY ~= 0 then
                preyAngle = math.atan2(sumVectorY, sumVectorX)
                speeds = ComputeSpeedFromAngle(preyAngle)
            else
                speeds = avoidObstacles()
            end
        end
    end

    -- Check if the prey has stopped moving
    if not is_stopped and closestPrey and closestPrey.distance < preyStoppedDistance then  -- Assuming the prey is considered stopped if it's very close
        stop_time = stop_time + 1
        if stop_time > stop_time_threshold then
            -- Broadcast message to stop moving to other predators
            robot.range_and_bearing.set_data(5, 1)
        end
    end

    if not is_stopped and stop_time > stop_time_threshold then
        for i = 1, #robot.range_and_bearing do
            if robot.range_and_bearing[i].data[5] == 1 then
                is_stopped = true
            end
        end
    end

    if is_stopped then
        speeds = {0, 0}
    end

    robot.wheels.set_velocity(speeds[1], speeds[2])
end

-- Function to search for the closest prey
function searchPrey()
    -- Loop through all detected blobs
    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        -- Check if the blob is a prey (assuming prey emits red light)
        if blob.color.red > 0 then
            return blob
        end
    end
end

function adjustAngleToPredictPrey(preyAngle)
    local finalPreyAngleX = math.cos(preyAngle)
    local finalPreyAngleY = math.sin(preyAngle)

    if prey_old_angle ~= 0 then
        finalPreyAngleX = finalPreyAngleX + math.cos(prey_old_angle) ^ prediction_intensity
        finalPreyAngleY = finalPreyAngleY + math.sin(prey_old_angle) ^ prediction_intensity
    end

    finalPreyAngle = math.atan2(finalPreyAngleY, finalPreyAngleX)
    prey_old_angle = finalPreyAngle
    return finalPreyAngle
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
                avoidanceVectorX = avoidanceVectorX - math.cos(blob.angle) * preyDistance
                avoidanceVectorY = avoidanceVectorY - math.sin(blob.angle) * preyDistance
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
