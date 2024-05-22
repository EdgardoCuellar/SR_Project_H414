-- Global variables for the predators
max_wheel_speed = 10 -- Maximum wheel speed - Maximum speed of the predators
stop_time = 0  -- Time to stop moving after receiving stop message
is_stopped = false  -- Flag to indicate if the predator has stopped moving
prey_old_angle = 0 -- Variable to store the previous angle of the prey, used in prediction

-- Constants for the predators - Parameters for the predator behavior 
-- Value choosen by hard testing, results in ./multiple_results/best_settings.txt
min_distance = 35  -- Minimum distance between predators
preyStoppedDistance = 25  -- Distance threshold to consider prey stopped
stop_time_threshold = 100  -- Time threshold to stop moving after receiving stop message
prediction_intensity = 0.3 -- Intensity of the prediction, the intesinty of the prediction tweak
repeat_signal = 1 -- Number of times the predator should resend the message of where another predator said where the prey is

function init()
    -- Initialize robot behaviors or attributes
    robot.leds.set_all_colors("blue")  -- Set initial LED color to blue, prey being in red
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
    -- If nothing is triggered, the predator will move forward
    local speeds = {max_wheel_speed, max_wheel_speed}
    -- If a prey is found, chase it
    if not is_stopped then
        if closestPrey then
            local preyAngle = adjustAngleToPredictPrey(closestPrey.angle)
            -- Broadcast the angle and distance to the prey to other predators
            -- The angle is normalized to be between 0 and 255
            robot.range_and_bearing.set_data(1, ((preyAngle + math.pi) / math.pi) * 255 )
            robot.range_and_bearing.set_data(2, math.min(closestPrey.distance, 255))
            robot.range_and_bearing.set_data(3, repeat_signal) -- indicate that he knows where the prey is
            local adjustedAngle = adjustAngleToAvoidCollisions(preyAngle, closestPrey.distance)
            speeds = ComputeSpeedFromAngle(adjustedAngle)
        else
            local sumVectorX = 0  -- Initialize sum of vectors in X direction
            local sumVectorY = 0  -- Initialize sum of vectors in Y direction
            local transmit_message = 0  -- Flag to indicate if the predator should resend the message to stop moving
            -- Loop through received messages from other predators
            for i = 1, #robot.range_and_bearing do
                if robot.range_and_bearing[i].data[1] and robot.range_and_bearing[i].data[2] and robot.range_and_bearing[i].data[1] ~= 0 then
                    local preyMessageAngle = ((robot.range_and_bearing[i].data[1] / 255) * math.pi) - math.pi
                    local preyMessageDistance = math.min(robot.range_and_bearing[i].data[2], 255)
                    -- Calculate angle to the prey with respect to the predator, using preyMessageAngle and horizontal_bearing
                    sumVectorX = math.cos(robot.range_and_bearing[i].horizontal_bearing) * robot.range_and_bearing[i].range + (math.cos(preyMessageAngle)+math.cos(robot.range_and_bearing[i].horizontal_bearing)) * preyMessageDistance
                    sumVectorY = math.sin(robot.range_and_bearing[i].horizontal_bearing) * robot.range_and_bearing[i].range + (math.sin(robot.range_and_bearing[i].horizontal_bearing) + math.sin(preyMessageAngle)) * preyMessageDistance 
                    if robot.range_and_bearing[i].data[3] then
                        transmit_message = robot.range_and_bearing[i].data[3] - 1
                    end
                end
            end

            if sumVectorX ~= 0 and sumVectorY ~= 0 then
                local preyAngle = math.atan2(sumVectorY, sumVectorX)
                if transmit_message > 0 then
                    robot.range_and_bearing.set_data(1, ((preyAngle + math.pi) / math.pi) * 255 )
                    robot.range_and_bearing.set_data(2, 255)
                    robot.range_and_bearing.set_data(3, transmit_message)
                else
                    set_data_prey_0()
                end
                local adjustedAngle = adjustAngleToAvoidCollisions(preyAngle, 256)
                speeds = ComputeSpeedFromAngle(adjustedAngle)
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

    -- Check if the predator should stop moving after receiving the stop message of another predator
    -- It prevents the predators from stoping when the prey is not stoped
    if not is_stopped and stop_time > stop_time_threshold then
        for i = 1, #robot.range_and_bearing do
            if robot.range_and_bearing[i].data[5] == 1 then
                is_stopped = true
                robot.leds.set_all_colors("green")
                break
            end
        end
    end

    if is_stopped then
        speeds = {0, 0}
        -- Check if the prey has moved away from the predator
        if closestPrey and closestPrey.distance > preyStoppedDistance + 25 then
            is_stopped = false
            stop_time = 0
            robot.range_and_bearing.set_data(5, 0)
            robot.leds.set_all_colors("blue")
        end
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

-- Function to adjust angle to predict prey movement
-- The prediction is based on the previous angle of the prey and the current angle
-- The difference between the two angles is used to adjust the current angle
function adjustAngleToPredictPrey(preyAngle)
    if prey_old_angle ~= 0 then
        local newPreyAngleX = math.cos(preyAngle)
        local newPreyAngleY = math.sin(preyAngle)

        local differenceX = newPreyAngleX - math.cos(prey_old_angle)
        local differenceY = newPreyAngleY - math.sin(prey_old_angle)

        local finalPreyAngleX = newPreyAngleX + differenceX * prediction_intensity
        local finalPreyAngleY = newPreyAngleY + differenceY * prediction_intensity

        prey_old_angle = math.atan2(finalPreyAngleY, finalPreyAngleX)
        return prey_old_angle
    end
    prey_old_angle = preyAngle
    return preyAngle
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
	
	if length > 0.2 then
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
    local distance = math.huge
    local blob_angle = nil
    local blob_color = nil
    -- Loop through all detected blobs
    for i, blob in ipairs(robot.colored_blob_omnidirectional_camera) do
        -- Check if the blob is a predator (assuming predators emit blue light)
        if blob.color.blue > 0 or blob.color.green > 0 then
            -- Calculate distance to the predator
            if blob.distance < distance then
                distance = blob.distance
                blob_angle = blob.angle
                if blob.color.blue > 0 then
                    blob_color = "blue"
                else
                    blob_color = "green"
                end
            end
        end
    end
    -- If predators start creating a cluster and moving together, the predator should stop
    -- because if not they are going to push the whole group, and so move the prey
    -- but the prey should be stopped, to stop the whole group
    if distance < min_distance then -- If the predator is too close, adjust the avoidance angle
        if blob_color == "blue" then
            avoidanceVectorX = avoidanceVectorX - (math.cos(blob_angle) * preyDistance)
            avoidanceVectorY = avoidanceVectorY - (math.sin(blob_angle) * preyDistance)
        else -- If the predator is green, try to avoid it
            avoidanceVectorX = avoidanceVectorX - (math.cos(blob_angle) * preyDistance + 50)
            avoidanceVectorY = avoidanceVectorY - (math.sin(blob_angle) * preyDistance + 50)
        end
    end

    return math.atan2(avoidanceVectorY, avoidanceVectorX)
end

--This function computes the necessary wheel speed to go in the direction of the desired angle.
function ComputeSpeedFromAngle(angle)
    dotProduct = 0.0;
    KProp = 100;
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

-- Function to set data to 0 - Reset data to avoid sending wrong information
-- Did not use the clear_data() function because it clears all data and we need to keep some data at any time like the stop message
function set_data_prey_0()
    robot.range_and_bearing.set_data(1, 0)
    robot.range_and_bearing.set_data(2, 0)
    robot.range_and_bearing.set_data(3, 0)
end

-- Reset function
function reset()
    -- Reset any necessary variables or states
end

-- Destroy function
function destroy()
    -- Clean up resources if needed
end
