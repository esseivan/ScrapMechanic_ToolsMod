-- Jetpack.lua
-- version 7
-- Author : EsseivaN
-- Description : Fly with a custom tool

-- How to use - Default modes :
-- Crouching : Hover
-- Aiming : Verical up
-- Crouching and Aiming : Horizontal
-- Idle : Normal
-- Q (Toggle) : Toggle hover mode
-- R (Reload) : Increase power

Jetpack = class()

-- ######################## FREE TO EDIT REGION BELOW #################################
-- ########################  \/\/\/\/\/\/\/\/\/\/\/\/ #################################
-- You can edit setting in this region at your will
-- If you want no save reloading between changed in this region,
-- add the "-dev" launch arguments to the game

-- You can edit modes :
-- 0x0000 : Normal
-- 0x0001 : Horizontal
-- 0x0002 : Vertical 
-- 0x0004 : Verical up
-- 0x0008 : Vertical down
-- 0x0010 : Vertical inverted
-- 0x0020 : x0.1
-- 0x0040 : x0.2
-- 0x0080 : x0.5
-- 0x0100 : x10
-- 0x0200 : x5
-- 0x0400 : x2
-- 0x0800 : Hover

-- You can add multiples modes (ex. 0x104 for Vertical up and x10)

-- Mode while IDLE
local modeIdle = 0x000
-- Mode while Crouching
local modeCrouching = 0x081
-- Mode while Aiming
local modeAiming = 0x082
-- Mode whiel Crouching and Aiming
local modeCrouchingAiming = 0x800
-- Angle to switch from vertical up to vertical down (from 1.0 to -1.0)
local limitUpDown = -0.45
-- Enable high speed mode /!\ Warning
-- This is really high speed, so use it at your own risk, you might maybe get stuck somewhere (true / false)
local HIGH_SPEED = false

-- Every number of tick to apply the pulse (40 ticks per seconds)
-- For best result in hover mode, set it to 2
local updateCounterMax = 2

-- Don't print debug log in the console
local silentMode = true

-- ######################## END OF THE FREE TO EDIT REGION #################################

function Jetpack.client_onCreate( self )
	
	print("Jetpack mod loaded")

	self.isLocal = self.tool:isLocal()
	
	-- Jetpack - Settings
	-- Maximum distance mode
    self.maxmode = 12
	-- Current mode distance
    self.mode = self.maxmode
    -- Hover mode
    self.hoverEnabled = false
    self.wasHover = false
    self.modeHover = false
	-- Update per second counter - 40 frames / 5 times per second = 8
	self.updateCounter = updateCounterMax

	-- Current distance from mode
    self:UpdateDistance()
	
	self.isAiming = false
	self.isCrouching = false
	
	-- Get current player
	local currentPlayer = nil
	if(self.isLocal) then 
		print ("Local player")
		currentPlayer = sm.localPlayer.getPlayer()
	else
		local allPlayers = sm.player.getAllPlayers()
		if not silentMode then
			print (allPlayers)
		end
		currentPlayer = allPlayers[2];
	end
	
	if currentPlayer ~= nil then 
        print("Player found")
		print (currentPlayer)
		self.character = currentPlayer.character
    else
        print("No player found. Mod not working")
		self.character = nil
    end
end

-- Jetpack - MovePlayer
function Jetpack.movePlayer(self, data)
	local character = data["character"]
	local impulse = data["impulse"]

	if character ~= nil then
        if self.modeHover then
            self:stabilize(data)
        else
    		-- Remove all residual velocity
    		velocity = -character.velocity
    		velocity = (velocity * character.mass / 2)
    		sm.physics.applyImpulse(character, velocity)
        end
		
		-- Apply impulse
		sm.physics.applyImpulse(character, impulse)
	end
end

-- Jetpack - Reload (R key)
function Jetpack.client_onReload( self )
    -- Increase mode
    if self.mode >= self.maxmode then 
        self.mode = 0
    else
        self.mode = self.mode + 1
    end

    self:UpdateDistance()
end

-- Jetpack - Toggle (Q key)
function Jetpack.client_onToggle( self )
    -- Toggle hover mode
    if self.hoverEnabled or self.wasHover then
    	print("Hover disabled")
    	self.hoverEnabled = false
        self.wasHover = false
	else
    	print("Hover enabled")
        self.hoverZPos = self.character.worldPosition
        self.hoverEnabled = true
        self.wasHover = false
	end

    ---- Decrease mode
    --if self.mode <= 0 then 
    --    self.mode = self.maxmode
    --else
    --    self.mode = self.mode - 1
    --end
	--
    --self:UpdateDistance()
end

-- Jetpack - update power
function Jetpack.UpdateDistance ( self )
	if HIGH_SPEED then
		self.distance = math.pow(10,(self.mode + 1))
	else
		if self.mode < 3 then
			self.distance = (self.mode + 1) * 250
		else
			self.distance = (self.mode - 2) * 1000
		end	
	end
    print("Power: " .. tostring(self.distance).. " ("..self.mode.."/"..self.maxmode..")")
end

-- Request stabilization
function Jetpack.server_stabilize( self , data )
	self:stabilize(data)
end

-- Jetpack - stabilize
function Jetpack.stabilize(self, data)
	local character = data["character"]
    local count = data["count"]
	if character ~= nil then
		-- Clear velocity when needed
        velocity = -character.velocity
        local valX = sm.vec3.getX(velocity)
        local valY = sm.vec3.getY(velocity)
        local valZ = sm.vec3.getZ(velocity)
        local required = false
        velocity = velocity * 0
        if (math.abs(valX) >= 0.1) then
            sm.vec3.setX(velocity, valX * 40)
            required = true
        end
        if (math.abs(valY) >= 0.1) then
            sm.vec3.setY(velocity, valY * 40)
            required = true
        end
        if (math.abs(valZ) >= 2) then
            sm.vec3.setZ(velocity, valZ * character.mass)
            required = true
        end
            
        if required then
            if not silentMode then
                print("### Clearing velocity ###")
            end
            sm.physics.applyImpulse(character, velocity)
        end

        -- Hover at specified Z pos
        local currentPos = sm.vec3.getZ(character.worldPosition)
        local destPos = sm.vec3.getZ(data["zPos"])
        local zVelocity = (sm.vec3.getZ(character.velocity))
        local delta = currentPos - destPos
        local pulse

        -- If delta is too large
        if (delta > 0.6) then
            if not silentMode then
                print("Delta too large up   : "..tostring(delta))
            end
            pulse = sm.vec3.new(0,0,character.mass * -10);
        else
        if (delta < -0.6) then
            if not silentMode then
                print("Delta too large down : "..tostring(delta).." | "..tostring(zVelocity))
            end
            pulse = sm.vec3.new(0,0,character.mass * 10);
        else
            -- If going up too fast up
            if (zVelocity >= 0.2) then
                if not silentMode then
                    print("Too fast up          : "..tostring(delta).." | "..tostring(zVelocity))
                end
                if (delta < -0.1) then
                    pulse = sm.vec3.new(0,0,character.mass * 1.00);
                else
                    pulse = sm.vec3.new(0,0,character.mass * 0.99)
                end
            else
            -- If going down too fast down, reducing speed
            if (zVelocity <= -0.2) then
                if not silentMode then
                    print("Too fast down      : "..tostring(delta).." | "..tostring(zVelocity))
                end
                if (delta > 0.1) then
                    pulse = sm.vec3.new(0,0,character.mass * 1.00);
                else
                    pulse = sm.vec3.new(0,0,character.mass * 1.01)
                end
            else
                -- Speed OK
                -- If too high
                if (delta > 0.1) then
                    if not silentMode then
                        print("Too High            : "..tostring(delta).." | "..tostring(zVelocity))
                    end
                    pulse = sm.vec3.new(0,0,character.mass * 0.99);
                else
                -- If too low
                if (delta < -0.1) then
                    if not silentMode then
                        print("Too Low           : "..tostring(delta).." | "..tostring(zVelocity))
                    end
                    pulse = sm.vec3.new(0,0,character.mass * 1.01);
                else
                    if (delta > 0.01) then
                        if not silentMode then
                            print("Little Too High     : "..tostring(delta).." | "..tostring(zVelocity))
                        end
                        pulse = sm.vec3.new(0,0,character.mass * 0.999);
                    else
                    -- If too low
                    if (delta < -0.01) then
                        if not silentMode then
                            print("Little Too Low      : "..tostring(delta).." | "..tostring(zVelocity))
                        end
                        pulse = sm.vec3.new(0,0,character.mass * 1.001);
                    else

                    -- If good height, applying ideal acceleration
                        if not silentMode then
                            print("Ideal height        : "..tostring(delta).." | "..tostring(zVelocity))
                        end
                        pulse = sm.vec3.new(0,0,character.mass * 1.00);
                    end
                    end
                end
                end
            end
            end
        end
        end

        sm.physics.applyImpulse(character, pulse)
	end
end

-- Player is holding click, applying pulse
function Jetpack.server_primaryHold( self , data )
	local t_character = data["character"]
	local t_power = data["power"]
	data["impulse"] = t_character.direction * t_power
	
	local t_crouching = data["crouching"]
	local t_aiming = data["aiming"]
	
	local modes = data["modes"]
	
	if t_crouching and t_aiming then
		-- Crouching & Aiming
		data["mode"] = modes["crouchingAndAiming"]
		data["impulse"] = self:editImpulseFromMode(data)
	else
		if t_crouching then
			-- Crouching
			data["mode"] = modes["crouching"]
			data["impulse"] = self:editImpulseFromMode(data)
		else
			if t_aiming then
				-- Aiming
				data["mode"] = modes["aiming"]
				data["impulse"] = self:editImpulseFromMode(data)
			else
				-- Idle
				data["mode"] = modes["idle"]
				data["impulse"] = self:editImpulseFromMode(data)
			end
		end
	end
			
	self:movePlayer(data)
end

-- 0x000 : Normal
-- 0x001 : Horizontal
-- 0x002 : Vertical 
-- 0x004 : Verical up
-- 0x008 : Vertical down
-- 0x010 : Vertical inverted
-- 0x020 : x0.1
-- 0x040 : x0.2
-- 0x080 : x0.5
-- 0x100 : x10
-- 0x200 : x5
-- 0x400 : x2
-- 0x800 : Hover
function Jetpack.editImpulseFromMode( self, data )
	-- Edit the impulse corresponding to the selected mode
	local mode = data["mode"]
	local impulse = data["impulse"]
	local character = data["character"]
	local distance = data["power"]
	
    self.modeHover = false

	if not silentMode then
		print ("Mode : "..mode)
	end
	
	if(mode == 0x000) then
		if not silentMode then
		print ("No modifier")
		end
	else

	if (bitand(mode,0x001) == 0x001) then
		if not silentMode then
			print ("Horizontal")
		end
        self.modeHover = true
        self.hoverZPos = self.character.worldPosition
		sm.vec3.setZ(impulse, character.mass * 1)
	end
	
	if (bitand(mode,0x002) == 0x002) then
		if not silentMode then
			print ("Vertical")
		end
		sm.vec3.setY(impulse, 0)
		sm.vec3.setX(impulse, 0)
		if not silentMode then
			print (sm.vec3.getZ(character.direction))
		end
		if sm.vec3.getZ(character.direction) >= limitUpDown then
			sm.vec3.setZ(impulse, distance)
		else
			sm.vec3.setZ(impulse, -distance)
		end
	end
	
	if bitand(mode,0x004) == 0x004 then
		if not silentMode then
			print ("Vertical up")
		end
		sm.vec3.setY(impulse, 0)
		sm.vec3.setX(impulse, 0)
		sm.vec3.setZ(impulse, distance)
	end
	
	if bitand(mode,0x008) == 0x008 then
		if not silentMode then
			print ("Vertical down")
		end
		sm.vec3.setY(impulse, 0)
		sm.vec3.setX(impulse, 0)
		sm.vec3.setZ(impulse, -distance)
	end
	
	if bitand(mode,0x010) == 0x010 then
		if not silentMode then
			print ("Vertical inverted")
		end
		sm.vec3.setY(impulse, 0)
		sm.vec3.setX(impulse, 0)
		if sm.vec3.getZ(character.direction) >= limitUpDown then
			sm.vec3.setZ(impulse, -distance)
		else
			sm.vec3.setZ(impulse, distance)
		end
	end
	
	if bitand(mode,0x020) == 0x020 then
		if not silentMode then
			print ("x0.1")
		end
		impulse = impulse * 0.1
	end
	
	if bitand(mode,0x040) == 0x040 then
		if not silentMode then
			print ("x0.2")
		end
		impulse = impulse * 0.2
	end
	
	
	if bitand(mode,0x080) == 0x080 then
		if not silentMode then
			print ("x0.5")
		end
		impulse = impulse * 0.5
	end
	
	if bitand(mode,0x100) == 0x100 then
		if not silentMode then
			print ("x10")
		end
		impulse = impulse * 10
	end
	
	if bitand(mode,0x200) == 0x200 then
		if not silentMode then
			print ("x5")
		end
		impulse = impulse * 5
	end
	
	if bitand(mode,0x400) == 0x400 then
		if not silentMode then
			print ("x2")
		end
		impulse = impulse * 2
	end
	
	if bitand(mode,0x800) == 0x800 then
		if not silentMode then
			print ("Hover")
		end
        -- Clear impulse and enable hover mode
		impulse = impulse * 0
        self.modeHover = true
        self.hoverZPos = self.character.worldPosition
    end

	end
	
	return impulse
end

-- Function required for editImpulseFromMode
function bitand(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = math.floor(a/2) -- shift right
      b = math.floor(b/2)
    end
    return result
end

-- called every TICK
function Jetpack.client_onFixedUpdate(self, dt)
	-- If ready
    self.updateCounter = self.updateCounter + 1
	if (self.updateCounter >= updateCounterMax) then
		self.updateCounter = 0
		-- If holding click
		if self.primaryState == 2  or self.primaryState == 1 then
            -- Disabling hover while in jetpack mode
            if self.hoverEnabled then
                self.hoverEnabled = false
                self.wasHover = true
            end

			self.isCrouching = self.tool:isCrouching()
			-- Request the server to apply impulse
			self.network:sendToServer("server_primaryHold", {character=self.character, zPos = self.hoverZPos, power=self.distance, crouching = self.isCrouching, aiming = self.isAiming, modes = {idle = modeIdle, crouching = modeCrouching, aiming = modeAiming, crouchingAndAiming = modeCrouchingAiming}})
		else
            if self.wasHover then
                self.wasHover = false
                self.hoverZPos = self.character.worldPosition
                self.hoverEnabled = true
                self.wasHover = false
            end
			-- If not holding click
			-- If hover enabled
			if self.hoverEnabled then
				-- Request the server to hover
				self.network:sendToServer("server_stabilize", {character=self.character, zPos = self.hoverZPos})
			else
			end
		end
    end
end

function Jetpack.calibrate( self) 

end

-- Left click
function Jetpack.client_onPrimaryUse( self, state )
	self.primaryState = state
end

-- Right click
function Jetpack.client_onSecondaryUse( self, state )
	if state == sm.tool.interactState.start and not self.isAiming then
		-- Start aiming
		self.isAiming = true
	end
	
	--if self.aiming and (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
	if (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
		-- Stop aiming
		self.isAiming = false
	end
end
