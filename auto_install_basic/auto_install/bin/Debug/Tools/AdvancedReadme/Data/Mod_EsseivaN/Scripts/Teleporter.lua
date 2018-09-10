-- Teleporter.lua
-- version 3
-- Author : EsseivaN
-- Description : Fly with a custom tool

-- How to use - Default modes :
-- Crouching : Hover
-- Aiming : Verical up
-- Crouching and Aiming : Horizontal
-- Idle : Normal
-- Q (Toggle) : Decrease power
-- R (Reload) : Increase power

dofile "AnimationUtil.lua"

Teleporter = class()

-- ######################## FREE TO EDIT REGION BELOW #################################
-- ########################  \/\/\/\/\/\/\/\/\/\/\/\/ #################################
-- You can edit setting in this region at your will
-- If you want no save reloading between changed in this region,
-- add the "-dev" launch arguments to the game

-- You can edit modes :
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

-- You can add multiples modes (ex. 0x104 for Vertical up and x10)

-- Mode while IDLE
local modeIdle = 0x000
-- Mode while Crouching
local modeCrouching = 0x800
-- Mode while Aiming
local modeAiming = 0x004
-- Mode whiel Crouching and Aiming
local modeCrouchingAiming = 0x001
-- Angle to switch from vertical up to vertical down (from 1.0 to -1.0)
local limitUpDown = -0.45
-- Enable high speed mode /!\ Warning
-- This is really high speed, so use it at your own risk, you might maybe get stuck somewhere (true / false)
local HIGH_SPEED = false

-- Every number of tick to apply the pulse (40 ticks per seconds)
-- For best result in hover mode, set it to 1
local updateCounterMax = 1

-- Don't print debug log in the console
local silentMode = true

-- ######################## END OF THE FREE TO EDIT REGION #################################

local renderables = {
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Base/char_spudgun_base_basic.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Barrel/Barrel_basic/char_spudgun_barrel_basic.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Sight/Sight_basic/char_spudgun_sight_basic.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Stock/Stock_broom/char_spudgun_stock_broom.rend",
	"$GAME_DATA/Character/Char_Tools/Char_spudgun/Tank/Tank_basic/char_spudgun_tank_basic.rend"
}

local renderablesTp = {"$GAME_DATA/Character/Char_Male/Animations/char_male_tp_spudgun.rend", "$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_tp_animlist.rend"}
local renderablesFp = {"$GAME_DATA/Character/Char_Tools/Char_spudgun/char_spudgun_fp_animlist.rend"}

sm.tool.preloadRenderables( renderables )
sm.tool.preloadRenderables( renderablesTp )
sm.tool.preloadRenderables( renderablesFp )

function Teleporter.client_onCreate( self )
	
	print("Teleporter mod loaded")

	self.isLocal = self.tool:isLocal()
	self.shootEffect = sm.effect.createEffect( "PotatoRifle - Shoot" )
	self.shootEffectFP = sm.effect.createEffect( "PotatoRifle - ShootFP" )
	
	-- Teleporter - Settings
	-- Current mode distance
    self.mode = 0
	-- Maximum distance mode
    self.maxmode = 19
	-- Update per second counter - 40 frames / 5 times per second = 8
	self.updateCounter = updateCounterMax
	
	-- Current distance from mode
    self:UpdateDistance()
	
	self.isAiming = false
	self.isCrouching = false
	
	-- Disable aim animation
	self.aiming = false
	
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

-- Teleporter - MovePlayer
function Teleporter.movePlayer(self, data)
	local character = data["character"]
	local impulse = data["impulse"]

	if character ~= nil then
		--if not silentMode then
		--	print ("Teleporting player from :")
		--	print (character.worldPosition)
		--end
		
		-- Remove all velocity
		velocity = -character.velocity
		-- Player's mass is 75
		velocity = (velocity * (character.mass))
		--if not silentMode then
		--	print (velocity)
		--end
		
		sm.physics.applyImpulse(character, velocity)
		
		-- Apply impulse
		--if not silentMode then
		--	print (impulse)
		--end
	
		sm.physics.applyImpulse(character, impulse)
	end
end

function Teleporter.server_ApplyImpulse( self, data )
	local character = data[0]
	local vec = data[1]

	
end

-- Teleporter - Reload (R key)
function Teleporter.client_onReload( self )
    -- Increase mode
    if self.mode >= self.maxmode then 
        self.mode = 0
    else
        self.mode = self.mode + 1
    end

    self:UpdateDistance()
end

-- Teleporter - Toggle (Q key)
function Teleporter.client_onToggle( self )
    -- Decrease mode
    if self.mode <= 0 then 
        self.mode = self.maxmode
    else
        self.mode = self.mode - 1
    end
	
    self:UpdateDistance()
end

-- Teleporter - update power
function Teleporter.UpdateDistance ( self )
	if HIGH_SPEED then
		self.distance = math.pow(10,(self.mode + 1))
	else
		self.distance = (self.mode + 1) * 500
	end
    print("Power: " .. tostring(self.distance))
end

function Teleporter.client_onRefresh( self )
	self:loadAnimations()
end

function Teleporter.loadAnimations( self )

	self.tpAnimations = createTpAnimations(
		self.tool,
		{
			shoot = { "spudgun_shoot", { crouch = "spudgun_crouch_shoot" } },
			aim = { "spudgun_aim", { crouch = "spudgun_crouch_aim" } },
			aimShoot = { "spudgun_aim_shoot", { crouch = "spudgun_crouch_aim_shoot" } },
			idle = { "spudgun_idle" },
			pickup = { "spudgun_pickup", { nextAnimation = "idle" } },
			putdown = { "spudgun_putdown" }
		}
	)
	local movementAnimations = {
		idle = "spudgun_idle",
		idleRelaxed = "spudgun_relax",

		sprint = "spudgun_sprint",
		runFwd = "spudgun_run_fwd",
		runBwd = "spudgun_run_bwd",

		jump = "spudgun_jump",
		jumpUp = "spudgun_jump_up",
		jumpDown = "spudgun_jump_down",

		land = "spudgun_jump_land",
		landFwd = "spudgun_jump_land_fwd",
		landBwd = "spudgun_jump_land_bwd",

		crouchIdle = "spudgun_crouch_idle",
		crouchFwd = "spudgun_crouch_fwd",
		crouchBwd = "spudgun_crouch_bwd"
	}

	for name, animation in pairs( movementAnimations ) do
		self.tool:setMovementAnimation( name, animation )
	end

	setTpAnimation( self.tpAnimations, "idle", 5.0 )

	if self.isLocal then
		self.fpAnimations = createFpAnimations(
			self.tool,
			{
				equip = { "spudgun_pickup", { nextAnimation = "idle" } },
				unequip = { "spudgun_putdown" },

				idle = { "spudgun_idle", { looping = true } },
				shoot = { "spudgun_shoot", { nextAnimation = "idle" } },
				
				aimInto = { "spudgun_aim_into", { nextAnimation = "aimIdle" } },
				aimExit = { "spudgun_aim_exit", { nextAnimation = "idle", blendNext = 0 } },
				aimIdle = { "spudgun_aim_idle", { looping = true} },
				aimShoot = { "spudgun_aim_shoot", { nextAnimation = "aimIdle"} },

				sprintInto = { "spudgun_sprint_into", { nextAnimation = "sprintIdle",  blendNext = 0.2 } },
				sprintExit = { "spudgun_sprint_exit", { nextAnimation = "idle",  blendNext = 0 } },
				sprintIdle = { "spudgun_sprint_idle", { looping = true } },
			}
		)
	end

	self.normalFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 2.6,
		spreadMinAngle = .25,
		spreadMaxAngle = 8,
		fireVelocity = 130.0,
		
		minDispersionStanding = 0.1,
		minDispersionCrouching = 0.04,
		
		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.aimFireMode = {
		fireCooldown = 0.20,
		spreadCooldown = 0.18,
		spreadIncrement = 1.3,
		spreadMinAngle = 0,
		spreadMaxAngle = 8,
		fireVelocity =  130.0,
		
		minDispersionStanding = 0.01,
		minDispersionCrouching = 0.01,
		
		maxMovementDispersion = 0.4,
		jumpDispersionMultiplier = 2
	}

	self.fireCooldownTimer = 0.0
	self.spreadCooldownTimer = 0.0
	
	self.movementDispersion = 0.0

	self.sprintCooldownTimer = 0.0	
	self.sprintCooldown = 0.3

	self.aimBlendSpeed = 60.0
	self.blendTime = 0.2

	self.jointWeight = 0.0
	self.spineWeight = 0.0
	self.aimWeight = 0.0

end

function clamp( value, min, max )
	if value < min then return min elseif value > max then return max else return value end 
end

function lerp( a, b, p )
	return (1.0 - p) * a + p * b 
end

function isAnyOf(is, off)
	for _, v in pairs(off) do
		if is == v then
			return true
		end
	end
	return false
end

function Teleporter.server_primaryHold( self , data )
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
function Teleporter.editImpulseFromMode( self, data )
	local mode = data["mode"]
	local impulse = data["impulse"]
	local character = data["character"]
	local distance = data["power"]
	
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
		impulse = impulse * 0
		sm.vec3.setZ(impulse, character.mass * 1)
	end
	
	end
	
	return impulse
end

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
function Teleporter.client_onFixedUpdate(self, dt)
	if (self.updateCounter >= updateCounterMax) then
		self.updateCounter = 0
		if self.primaryState == 2  or self.primaryState == 1 then
			self.isCrouching = self.tool:isCrouching()
			self.network:sendToServer("server_primaryHold", {character=self.character, power=self.distance, crouching = self.isCrouching, aiming = self.isAiming, modes = {idle = modeIdle, crouching = modeCrouching, aiming = modeAiming, crouchingAndAiming = modeCrouchingAiming}})
		else
			self.updateCounter = updateCounterMax
		end
	else
		self.updateCounter = self.updateCounter + 1
	end
end

-- Called every FRAME
function Teleporter.client_onUpdate( self, dt )
	-- First person animation	
	local isSprinting =  self.tool:isSprinting() 
	local isCrouching =  self.tool:isCrouching() 
	
	if self.isLocal then
		if self.equipped then
			if isSprinting and self.fpAnimations.currentAnimation ~= "sprintInto" and self.fpAnimations.currentAnimation ~= "sprintIdle" then
				swapFpAnimation( self.fpAnimations, "sprintExit", "sprintInto", 0.0 )
			elseif not self.tool:isSprinting() and ( self.fpAnimations.currentAnimation == "sprintIdle" or self.fpAnimations.currentAnimation == "sprintInto" ) then
				swapFpAnimation( self.fpAnimations, "sprintInto", "sprintExit", 0.0 )
			end

			if self.aiming and not isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimExit", "aimInto", 0.0 )
			end
			if not self.aiming and isAnyOf( self.fpAnimations.currentAnimation, { "aimInto", "aimIdle", "aimShoot" } ) then
				swapFpAnimation( self.fpAnimations, "aimInto", "aimExit", 0.0 )
			end
		end
		updateFpAnimations( self.fpAnimations, self.equipped, dt )
	end

	if not self.equipped then
		if self.wantEquipped then
			self.wantEquipped = false
			self.equipped = true
		end
		return
	end
	
	local effectPos, rot
	
	if self.isLocal then
	
		local zOffset = 0.6
		if self.tool:isCrouching() then
			zOffset = 0.29
		end

		local dir = sm.localPlayer.getDirection()
		local firePos = self.tool:getFpJointPos( "pejnt_barrel" )
		
		if not self.aiming then
			effectPos = firePos + dir * 0.2
		else
			effectPos = firePos + dir * 0.45
		end

		rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir )
		
		
		self.shootEffectFP:setPosition( effectPos )
		self.shootEffectFP:setVelocity( self.tool:getMovementVelocity() )
		self.shootEffectFP:setRotation( rot )
	end
	local pos = self.tool:getTpJointPos( "pejnt_barrel" )
	local dir = self.tool:getTpJointDir( "pejnt_barrel" )
	
	effectPos = pos + dir * 0.2

	rot = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), dir )
	
	
	self.shootEffect:setPosition( effectPos )
	self.shootEffect:setVelocity( self.tool:getMovementVelocity() )
	self.shootEffect:setRotation( rot )

	-- Timers
	self.fireCooldownTimer = math.max( self.fireCooldownTimer - dt, 0.0 )
	self.spreadCooldownTimer = math.max( self.spreadCooldownTimer - dt, 0.0 )
	self.sprintCooldownTimer = math.max( self.sprintCooldownTimer - dt, 0.0 )
	

	if self.isLocal then
		local dispersion = 0.0
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		local recoilDispersion = 1.0 - ( math.max( fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )
		
		if isCrouching then
			dispersion = fireMode.minDispersionCrouching
		else
			dispersion = fireMode.minDispersionStanding
		end
		
		if self.tool:getRelativeMoveDirection():length() > 0 then
			dispersion = dispersion + fireMode.maxMovementDispersion * self.tool:getMovementSpeedFraction()
		end
		
		if not self.tool:isOnGround() then
			dispersion = dispersion * fireMode.jumpDispersionMultiplier
		end
		
		self.movementDispersion = dispersion
		
		self.spreadCooldownTimer = clamp( self.spreadCooldownTimer, 0.0, fireMode.spreadCooldown )
		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
		
		self.tool:setDispersionFraction( clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 ) )
		
		if self.aiming then
			if self.tool:isInFirstPersonView() then
				self.tool:setCrossHairAlpha( 0.0 )
			else
				self.tool:setCrossHairAlpha( 1.0 )
			end
			self.tool:setInteractionTextSuppressed( true )
		else
			self.tool:setCrossHairAlpha( 1.0 )
			self.tool:setInteractionTextSuppressed( false )
		end
	end

	-- Sprint block
	local blockSprint = self.aiming or self.sprintCooldownTimer > 0.0
	self.tool:setBlockSprint( blockSprint )

	local playerDir = self.tool:getDirection()
	local angle = math.asin( playerDir:dot( sm.vec3.new( 0, 0, 1 ) ) ) / ( math.pi / 2 )
	local linareAngle = playerDir:dot( sm.vec3.new( 0, 0, 1 ) )

	local linareAngleDown = clamp( -linareAngle, 0.0, 1.0 )

	down = clamp( -angle, 0.0, 1.0 )
	fwd = ( 1.0 - math.abs( angle ) )
	up = clamp( angle, 0.0, 1.0 )

	local crouchWeight = self.tool:isCrouching() and 1.0 or 0.0
	local normalWeight = 1.0 - crouchWeight 

	local totalWeight = 0.0
	for name, animation in pairs( self.tpAnimations.animations ) do
		animation.time = animation.time + dt

		if name == self.tpAnimations.currentAnimation then
			animation.weight = math.min( animation.weight + ( self.tpAnimations.blendSpeed * dt ), 1.0 )
			
			if animation.time >= animation.info.duration - self.blendTime then
				if ( name == "shoot" or name == "aimShoot" ) then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 10.0 )
				elseif name == "pickup" then
					setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 0.001 )
				elseif animation.nextAnimation ~= "" then
					setTpAnimation( self.tpAnimations, animation.nextAnimation, 0.001 )
				end 
			end
		else
			animation.weight = math.max( animation.weight - ( self.tpAnimations.blendSpeed * dt ), 0.0 )
		end

		totalWeight = totalWeight + animation.weight
	end

	totalWeight = totalWeight == 0 and 1.0 or totalWeight
	for name, animation in pairs( self.tpAnimations.animations ) do
		local weight = animation.weight / totalWeight
		if name == "idle" then
			self.tool:updateMovementAnimation( animation.time, weight )
		elseif animation.crouch then
			self.tool:updateAnimation( animation.info.name, animation.time, weight * normalWeight )
			self.tool:updateAnimation( animation.crouch.name, animation.time, weight * crouchWeight )
		else
			self.tool:updateAnimation( animation.info.name, animation.time, weight )
		end
	end

	-- Third Person joint lock
	local relativeMoveDirection = self.tool:getRelativeMoveDirection()
	if ( ( ( isAnyOf( self.tpAnimations.currentAnimation, { "aimInto", "aim", "shoot" } ) and ( relativeMoveDirection:length() > 0 or isCrouching) ) or ( self.aiming and ( relativeMoveDirection:length() > 0 or isCrouching) ) ) and not isSprinting ) then
		self.jointWeight = math.min( self.jointWeight + ( 10.0 * dt ), 1.0 )
	else
		self.jointWeight = math.max( self.jointWeight - ( 6.0 * dt ), 0.0 )
	end

	if ( not isSprinting ) then
		self.spineWeight = math.min( self.spineWeight + ( 10.0 * dt ), 1.0 )
	else
		self.spineWeight = math.max( self.spineWeight - ( 10.0 * dt ), 0.0 )
	end

	local finalAngle = ( 0.5 + angle * 0.5 )
	self.tool:updateAnimation( "spudgun_spine_bend", finalAngle, self.spineWeight )

	local totalOffsetZ = lerp( -22.0, -26.0, crouchWeight )
	local totalOffsetY = lerp( 6.0, 12.0, crouchWeight )
	local crouchTotalOffsetX = clamp( ( angle * 60.0 ) -15.0, -60.0, 40.0 )
	local normalTotalOffsetX = clamp( ( angle * 50.0 ), -45.0, 50.0 )
	local totalOffsetX = lerp( normalTotalOffsetX, crouchTotalOffsetX , crouchWeight )

	local finalJointWeight = ( self.jointWeight )
	  

	self.tool:updateJoint( "jnt_hips", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.35 * finalJointWeight * ( normalWeight ) )

	local crouchSpineWeight = ( 0.35 / 3 ) * crouchWeight

	self.tool:updateJoint( "jnt_spine1", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight )  * finalJointWeight )
	self.tool:updateJoint( "jnt_spine2", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.10 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_spine3", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), ( 0.45 + crouchSpineWeight ) * finalJointWeight )
	self.tool:updateJoint( "jnt_head", sm.vec3.new( totalOffsetX, totalOffsetY, totalOffsetZ ), 0.3 * finalJointWeight )


	-- Third Person Camera update
	local bobbing = 1
	if self.aiming then
		self.aimWeight = math.min( self.aimWeight + ( ( 1.0 - self.aimWeight ) * dt * self.aimBlendSpeed ), 1.0 )
		bobbing = 0.12
	else
		self.aimWeight = math.max( self.aimWeight + ( -self.aimWeight * dt * self.aimBlendSpeed ), 0.0 )
		bobbing = 1
	end

	self.tool:updateCamera( 2.8, 30.0, sm.vec3.new( 0.65, 0.0, 0.05 ), self.aimWeight )
	self.tool:updateFpCamera( 30.0, sm.vec3.new( 0.0, 0.0, 0.0 ), self.aimWeight, bobbing )
end

function Teleporter.client_onEquip( self )
	self.wantEquipped = true
	self.aiming = false
	self.aimWeight = 0.0
	self.jointWeight = 0.0
	
	for k,v in pairs( renderables ) do renderablesTp[#renderablesTp+1] = v end
	for k,v in pairs( renderables ) do renderablesFp[#renderablesFp+1] = v end
	
	self.tool:setTpRenderables( renderablesTp )

	self:loadAnimations()

	setTpAnimation( self.tpAnimations, "pickup", 0.0001 )

	if self.isLocal then
		-- Sets spudgun renderable, change this to change the mesh
		self.tool:setFpRenderables( renderablesFp )
		swapFpAnimation( self.fpAnimations, "unequip", "equip", 0.2 )
	end
end

function Teleporter.client_onUnequip( self )
	self.equipped = false
	setTpAnimation( self.tpAnimations, "putdown" )
	if self.isLocal and self.fpAnimations.currentAnimation ~= "unequip" then
		swapFpAnimation( self.fpAnimations, "equip", "unequip", 0.2 )
	end
end

function Teleporter.server_network_onAim( self, aiming )
	self.network:sendToClients( "client_network_onAim", aiming )
end

function Teleporter.client_network_onAim( self, aiming )
	if not self.tool:isLocal() then
		self:onAim( aiming )
	end
end

function Teleporter.onAim( self, aiming )
	self.aiming = aiming
	if self.tpAnimations.currentAnimation == "idle" or self.tpAnimations.currentAnimation == "aim" or self.tpAnimations.currentAnimation == "relax" and self.aiming then
		setTpAnimation( self.tpAnimations, self.aiming and "aim" or "idle", 5.0 )
	end
end

function Teleporter.server_network_onShoot( self, dir ) 
	self.network:sendToClients( "client_network_onShoot", dir )
end

function Teleporter.client_network_onShoot( self, dir ) 
	if not self.tool:isLocal() then
		self:onShoot( dir )
	end
end

function Teleporter.onShoot( self, dir ) 
	self.tpAnimations.animations.idle.time = 0
	self.tpAnimations.animations.shoot.time = 0
	self.tpAnimations.animations.aimShoot.time = 0

	setTpAnimation( self.tpAnimations, self.aiming and "aimShoot" or "shoot", 10.0 )
	
	if self.tool:isInFirstPersonView() then
			self.shootEffectFP:start()
		else
			self.shootEffect:start()
	end

end

function Teleporter.calculateFirePosition( self )
	local crouching = self.tool:isCrouching()
	local firstPerson = self.tool:isInFirstPersonView()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )		
	local right = sm.localPlayer.getRight()
	
	local fireOffset = sm.vec3.new( 0.0, 0.0, 0.0 )

	if crouching then
		fireOffset.z = 0.15
	else
		fireOffset.z = 0.45
	end

	if firstPerson then
		if not self.aiming then
			fireOffset = fireOffset + right * 0.05
		end
	else
		fireOffset = fireOffset + right * 0.25		
		fireOffset = fireOffset:rotate( math.rad( pitch ), right )
	end
	local firePosition = sm.localPlayer.getPosition() + fireOffset
	return firePosition
end

function Teleporter.calculateTpMuzzlePos( self )
	local crouching = self.tool:isCrouching()
	local dir = sm.localPlayer.getDirection()
	local pitch = math.asin( dir.z )		
	local right = sm.localPlayer.getRight()
	local up = right:cross(dir)
	
	local fakeOffset = sm.vec3.new( 0.0, 0.0, 0.0 )
	
	--General offset
	fakeOffset = fakeOffset + right * 0.25
	fakeOffset = fakeOffset + dir * 0.5
	fakeOffset = fakeOffset + up * 0.25
	
	--Action offset
	local pitchFraction = pitch / ( math.pi * 0.5 )
	if crouching then
		fakeOffset = fakeOffset + dir * 0.2
		fakeOffset = fakeOffset + up * 0.1
		fakeOffset = fakeOffset - right * 0.05
		
		if pitchFraction > 0.0 then
			fakeOffset = fakeOffset - up * 0.2 * pitchFraction
		else
			fakeOffset = fakeOffset + up * 0.1 * math.abs( pitchFraction )
		end		
	else
		fakeOffset = fakeOffset + up * 0.1 *  math.abs( pitchFraction )		
	end
	
	local fakePosition = fakeOffset + sm.localPlayer.getPosition()
	return fakePosition
end

function Teleporter.calculateFpMuzzlePos( self )
	local fovScale = ( sm.camera.getFov() - 45 ) / 45
	
	local up = sm.localPlayer.getUp()
	local dir = sm.localPlayer.getDirection()
	local right = sm.localPlayer.getRight()
	
	local muzzlePos45 = sm.vec3.new( 0.0, 0.0, 0.0 )
	local muzzlePos90 = sm.vec3.new( 0.0, 0.0, 0.0 )
		
	if self.aiming then
		muzzlePos45 = muzzlePos45 - up * 0.2
		muzzlePos45 = muzzlePos45 + dir * 0.5
		
		muzzlePos90 = muzzlePos90 - up * 0.5
		muzzlePos90 = muzzlePos90 - dir * 0.6
	else
		muzzlePos45 = muzzlePos45 - up * 0.15
		muzzlePos45 = muzzlePos45 + right * 0.2
		muzzlePos45 = muzzlePos45 + dir * 1.25
		
		muzzlePos90 = muzzlePos90 - up * 0.15
		muzzlePos90 = muzzlePos90 + right * 0.2
		muzzlePos90 = muzzlePos90 + dir * 0.25
	end

	return self.tool:getFpJointPos( "pejnt_barrel" ) + sm.vec3.lerp( muzzlePos45, muzzlePos90, fovScale )
end

function Teleporter.client_onPrimaryUse( self, state )
	self.primaryState = state

	if self.fireCooldownTimer <= 0.0 and state == sm.tool.interactState.start then
	
		local firstPerson = self.tool:isInFirstPersonView()
		
		local dir = sm.localPlayer.getDirection()
		
		local firePos = self:calculateFirePosition()
		local fakePosition = self:calculateTpMuzzlePos()
		local fakePositionSelf = fakePosition
		if firstPerson then
			fakePositionSelf = self:calculateFpMuzzlePos()
		end

		-- Aim assist
		if not firstPerson then
			local raycastPos = sm.camera.getPosition() + sm.camera.getDirection() * sm.camera.getDirection():dot(sm.localPlayer.getPosition() - sm.camera.getPosition())
			local hit, result = sm.localPlayer.getRaycast( 250, raycastPos, sm.camera.getDirection() )
			if hit then 
				local norDir = sm.vec3.normalize( result.pointWorld - firePos )
				local dirDot = norDir:dot( dir )
				
				if dirDot > 0.96592583 then -- max 15 degrees off
					dir = norDir
				else
					local radsOff = math.asin( dirDot )
					dir = sm.vec3.lerp( dir, norDir, math.tan( radsOff ) / 3.7320508 ) -- if more than 15, make it 15
				end
			end
		end

		dir = dir:rotate( math.rad( 0.955 ), sm.camera.getRight() ) -- 50 m sight calibration
		
		-- Spread
		local fireMode = self.aiming and self.aimFireMode or self.normalFireMode
		local recoilDispersion = 1.0 - ( math.max(fireMode.minDispersionCrouching, fireMode.minDispersionStanding ) + fireMode.maxMovementDispersion )
		
		local spreadFactor = fireMode.spreadCooldown > 0.0 and clamp( self.spreadCooldownTimer / fireMode.spreadCooldown, 0.0, 1.0 ) or 0.0
		spreadFactor = clamp( self.movementDispersion + spreadFactor * recoilDispersion, 0.0, 1.0 )
		local spreadDeg =  fireMode.spreadMinAngle + ( fireMode.spreadMaxAngle - fireMode.spreadMinAngle ) * spreadFactor
		
		dir = sm.noise.gunSpread( dir, spreadDeg )

		sm.projectile.playerFire( "potato", firePos, dir * fireMode.fireVelocity, fakePosition, fakePositionSelf )

		-- Timers
		self.fireCooldownTimer = fireMode.fireCooldown
		self.spreadCooldownTimer = math.min( self.spreadCooldownTimer + fireMode.spreadIncrement, fireMode.spreadCooldown )
		self.sprintCooldownTimer = self.sprintCooldown

		-- Send TP shoot over network and dircly to self
		self:onShoot( dir )
		self.network:sendToServer( "server_network_onShoot", dir )

		-- Play FP shoot animation
		setFpAnimation( self.fpAnimations, self.aiming and "aimShoot" or "shoot", 0.05 )
	end
end

function Teleporter.client_onSecondaryUse( self, state )
	if state == sm.tool.interactState.start and not self.aiming then
		-- Start aiming
		self.isAiming = true
		
		--self.aiming = true
		--self.tpAnimations.animations.idle.time = 0
		
		--self:onAim( self.aiming )
		--self.tool:setMovementSlowDown( self.aiming )
		--self.network:sendToServer( "server_network_onAim", self.aiming )
	end
	
	--if self.aiming and (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
	if (state == sm.tool.interactState.stop or state == sm.tool.interactState.null) then
		-- Stop aiming
		self.isAiming = false
	
		--self.aiming = false
		--self.tpAnimations.animations.idle.time = 0
		
		--self:onAim( self.aiming )
		--self.tool:setMovementSlowDown( self.aiming )
		--self.network:sendToServer( "server_network_onAim", self.aiming )
	end
end
