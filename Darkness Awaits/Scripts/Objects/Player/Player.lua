import "Scripts/AnimationManager.lua"
import "Scripts/Functions/ReleaseTableObjects.lua"

local testmultiplier = 1--use this value to test animation in slow-motion
local walkmultiplier = 0.8
local runmultiplier = 0.8
local goscreenalpha = 0--for gameover screen -reep

Script.health = 100 --int "Health"
Script.maxHealth = 100
Script.MoveSpeed = 2.4 * testmultiplier * walkmultiplier
Script.RunSpeed = 6.5 * testmultiplier * runmultiplier
Script.maxAcceleration = 1.0--float "Max Acceleration"

--Player states
Script.state={}
Script.state.idle=0
Script.state.walk=1
Script.state.run=2
Script.state.attack=3
Script.state.hurt=4
Script.state.dead=5

--Animation sequences
Script.sequence={}
Script.sequence.walk="walk"
Script.sequence.run="run"
Script.sequence.idle="idle"
Script.sequence.attack0="attack0"
Script.sequence.attack1="attack1"
Script.sequence.hit ="hit"
Script.sequence.death ="death"

--Animation speed
Script.animationspeed={}
Script.animationspeed.walk = 0.05 * testmultiplier * walkmultiplier
Script.animationspeed.run = 0.04 * testmultiplier * runmultiplier

--Private
Script.inhibitAttack = false
Script.stunned = false
Script.swordattackdelay = 400

function Script:Start()
	-- Set the type to player.
	self.entity:SetKeyValue("type","player")

	--Create a camera. In the original project, the level designer had to add a camera in the map.
	--Now instead, the camera is created with the player, but still functions like the old way. -reep
	self.camera = Camera:Create()
	self.camera:SetFOV(70)
	self.camera:SetRange(0.1,1000)
	self.camera:SetMultisampleMode((System:GetProperty("multisample","1")))
	local playerpos = self.entity:GetPosition()
	self.camera:SetPosition(playerpos.x, playerpos.y + 4.7438, playerpos.z -3.68664 )
	self.camera:SetRotation(Vec3(45,0,0))
	self.camera:SetScript("Scripts/Objects/Cameras/3rdPersonFollow.lua",false)
	self.camera.script.target = self.entity
	self.camera.script:Start()
	
	self.image={}
	self.image.healthbar = Texture:Load("Materials/HUD/healthbar.tex")
	self.image.healthmeter = Texture:Load("Materials/HUD/healthmeter.tex")
	
	--Create a listener
	self.listener = Listener:Create()
	local v = self.entity:GetPosition(true)
	v.y = v.y + 1.8
	self.listener:SetPosition(v,true)
	
	self.currentyrotation=self.entity:GetRotation().y

	self.currentState=-1
	self.turnSpeed=5
	self.swingmode=0
	
	self.sound={}

	self.sound.gameover=Sound:Load("Sound/Music/gameover.wav")
	if self.sound.gameover~=nil then
		self.source = Source:Create()
		self.source:SetSound(self.sound.gameover)
		self.sound.gameover:Release()
		self.sound.gameover=nil
		self.source:SetVolume(0.8)
		self.source:SetLoopMode(false)
	end

	self.sound.swordhit={}
	self.sound.swordhit[0]=Sound:Load("Sound/Weapons/sword_strike_body_stab_01.wav")
	self.sound.swordhit[1]=Sound:Load("Sound/Weapons/sword_strike_body_stab_04.wav")
	self.sound.swordhit[2]=Sound:Load("Sound/Weapons/sword_strike_body_slash_05.wav")
	self.sound.swordhit[3]=Sound:Load("Sound/Weapons/sword_strike_body_slash_04.wav")

	self.sound.swordswing={}
	self.sound.swordswing[0]=Sound:Load("Sound/Weapons/sword_whoosh07.wav")
	self.sound.swordswing[1]=Sound:Load("Sound/Weapons/sword_whoosh12.wav")

	self.sound.pain={}
	self.sound.pain.lasttimeplayed=0
	self.sound.pain[0]=Sound:Load("Sound/Player/warriors_pain_single_01.wav")
	self.sound.pain[1]=Sound:Load("Sound/Player/warriors_pain_single_02.wav")
	self.sound.pain[2]=Sound:Load("Sound/Player/warriors_pain_single_11.wav")

	self.sound.footsteps={}
	self.sound.footsteps.step={}
	self.sound.footsteps.step[1] = Sound:Load("Sound/Footsteps/step1.wav")
	self.sound.footsteps.step[2] = Sound:Load("Sound/Footsteps/step2.wav")
	self.sound.footsteps.step[3] = Sound:Load("Sound/Footsteps/step3.wav")
	self.sound.footsteps.step[4] = Sound:Load("Sound/Footsteps/step4.wav")

	self.smoothedhealth = self.health
	self.alive=true

	self.animationmanager = AnimationManager:Create(self.entity)
end

function Script:UpdatePhysics()
	local movement=Vec3()
	local window=Window:GetCurrent()
	local changed
	local move=0
	local prevState = self.currentState
	
	if self.currentState==self.state.dead or self.health <= 0 then return end

	--Position the listener.  We're doing this manually instead of parenting it because we want it to keep the same orientation as the camera
	local v = self.entity:GetPosition(true)
	v.y = v.y + 1.8
	self.listener:SetPosition(v,true)
	
	if self.currentState~=self.state.attack then
		self.currentState=self.state.idle
	end

	--Update the footstep sounds when walking
	self:UpdateFootsteps()

	--Detect if attack started
	if self.currentState~=self.state.attack then
		local doattack = false
		if window:KeyDown(Key.Space) then 
			self.currentState=self.state.attack
			self.attackstarttime = Time:GetCurrent()
		end
	elseif not self.inhibitAttack then --only attack if the sword is in mid-swing
		if Time:GetCurrent() - self.attackstarttime > self.swordattackdelay then
			self:Attack()
		end
	end
	
	--Movement
	--Code for detecting key hits for movement and attacks
	if (window:KeyDown(Key.D)) then movement.x=movement.x+1 changed=true end
	if (window:KeyDown(Key.A)) then movement.x=movement.x-1 changed=true end
	if (window:KeyDown(Key.W)) then movement.z=movement.z+1 changed=true end
	if (window:KeyDown(Key.S)) then movement.z=movement.z-1 changed=true end
	if changed then
		if self.currentState~=self.state.attack then
			if window:KeyDown(Key.Shift) then--this will never happen with touch controls
				movement = movement:Normalize() * self.RunSpeed
				move=self.RunSpeed
				self.currentState=self.state.run
			else
				move=self.MoveSpeed
				movement = movement:Normalize() * self.MoveSpeed
				self.currentState=self.state.walk			
			end
		end
	end
	
	--Rotate model to face correct direction
	if (changed) then
		movement = movement:Normalize()
		local targetRotation = Math:ATan2(movement.x,movement.z)-180
		self.currentyrotation = Math:IncAngle(targetRotation,self.currentyrotation,self.turnSpeed)--first two parameters were swapped
	end
	
	self.entity:SetInput(self.currentyrotation,move,0,0,false,self.maxAcceleration)	

	--Update animation
	if prevState~=self.currentState then
		if self.animationmanager then
			if self.currentState==self.state.idle then
				self.animationmanager:SetAnimationSequence(self.sequence.idle,0.05,200)
			elseif self.currentState==self.state.walk then
				self.animationmanager:SetAnimationSequence(self.sequence.walk,self.animationspeed.walk,200)			
			elseif self.currentState==self.state.run then
				self.animationmanager:SetAnimationSequence(self.sequence.run,self.animationspeed.run,200)
			elseif self.currentState==self.state.attack then
				self.swingmode = 1-self.swingmode
				self.sound.swordswing[math.random(0,#self.sound.swordswing)]:Play()
				if self.swingmode==1 then
					self.animationmanager:SetAnimationSequence(self.sequence.attack0,0.03,200,1,self,self.EndAttack)
				else
					self.animationmanager:SetAnimationSequence(self.sequence.attack1,0.03,200,1,self,self.EndAttack)
				end
			end
		end
	end
end

--This function plays footstep sounds in regular intervals as the player walks
function Script:UpdateFootsteps() 
	local footstepwalkdelay = 450
	local footsteprundelay = 300
	if self.lastfootsteptime==nil then self.lastfootsteptime=0 end
	local speed = self.entity:GetVelocity():xz():Length()
	if self.entity:GetAirborne()==false then
		if (speed>self.MoveSpeed*0.5) then
			local t = Time:GetCurrent()
			local repeatdelay = footstepwalkdelay
			if speed>self.MoveSpeed * (1+(self.RunSpeed-1)*0.5) then repeatdelay = footsteprundelay end
			if t-self.lastfootsteptime>repeatdelay then
				self.lastfootsteptime = t
				local index = math.random(1,4)
				self.sound.footsteps.step[index]:Play()
			end
		end
	end
end

function Script:EndAttack()
	self.currentState=-1
	self.inhibitAttack = false
end

function Script:EndStun()
	self.stunned = false
end

function Script:Release()
	ReleaseTableObjects(self.sound)
	ReleaseTableObjects(self.image)
	self.listener:Release()
end

function Script:AttackEnemy(enemy) --narrow check
	local entitypos = enemy.entity:GetPosition(true)
	local pos = Transform:Point(entitypos.x,entitypos.y,entitypos.z,enemy.entity,self.entity)
	
	pos = pos * self.entity:GetScale()
	pos.z = pos.z * -1
	if pos.z>0 and pos.z<2.5 then
		if pos.z>math.abs(pos.x) then
			if pos.z>math.abs(pos.y) then	
				enemy:TakeDamage(10)
				self.sound.swordhit[math.random(0,#self.sound.swordhit)]:Play()
			end
		end
	end
end

function PlayerForEachEntityInAABBDoCallback(entity,extra)	
	if extra~=entity then
		if entity.script then
			if type(entity.script.Use)=="function" then
				local entitypos = entity:GetPosition(true)
				local pos = Transform:Point(entitypos.x,entitypos.y,entitypos.z,nil,extra)			
				pos = pos * extra:GetScale()
				pos.z = pos.z * -1
				if pos.z>0 and pos.z<2.5 then
					if pos.z>math.abs(pos.x) then
						if pos.z>math.abs(pos.y) then	
							entity.script:Use()
						end
					end
				end
			end
		end
		if entity.script~=nil then
			if type(entity.script.AttackEnemy)=="function" then
				if entity.script.currentState~=entity.script.state.dead then
					extra.script:AttackEnemy(entity.script)
				end
			end
		end
	end
end

function Script:Attack() --broad check for nearby enemies 
	local attackrange=3
	
	self.inhibitAttack = true
	
	local position = self.entity:GetPosition(true)
	
	local aabb = AABB()
	aabb.min.x=position.x-attackrange
	aabb.min.y=position.y-attackrange
	aabb.min.z=position.z-attackrange
	aabb.max.x=position.x+attackrange
	aabb.max.y=position.y+attackrange
	aabb.max.z=position.z+attackrange
	aabb:Update()
	
	self.entity.world:ForEachEntityInAABBDo(aabb,"PlayerForEachEntityInAABBDoCallback",self.entity)
end

function Script:TakeDamage(damage)

	--Don't do anything to dead players
	if self.health>0 then
		self.health = self.health - damage
		self.component:CallOutputs("OnHit")

		if self.health>0 then
			
			--We don't want to play the pain sound or animation if player is attacking
			if self.currentState ~= self.state.attack then
				
				--Play the pain animation if player is idle
				if self.currentState==self.state.idle then
					if self.stunned==false then
						self.stunned=true
						self.animationmanager:SetAnimationSequence(self.sequence.hit,0.04,100,1,self,self.EndStun)
					end
				end
				
				--Play the pain sound, but not too frequently
				if Time:GetCurrent() > self.sound.pain.lasttimeplayed then
					self.sound.pain.lasttimeplayed = Time:GetCurrent()+ 1000 + Math:Random(-200,200)
					self.sound.pain[math.random(0,#self.sound.pain)]:Play()
				end
				
			end
		else
			self.animationmanager:SetAnimationSequence(self.sequence.death,0.03,200,1,self,self.EndDeath)
		end
	end
end

function Script:EndDeath()
	self.currentState = self.state.dead
	self.alive = false
	self.entity:SetCollisionType(0)
	self.entity:SetMass(0)
	self.entity:SetPhysicsMode(Entity.RigidBodyPhysics)
	self.component:CallOutputs("OnDead")

	--Stop game music, and play GameOver sound
	App.musicsource:Stop()
	self.source:Play()
end

function Script:Draw()
	self.animationmanager:Update()
end

function Script:PostRender(context)
	local iw = self.image.healthbar:GetWidth()
	local ih = self.image.healthbar:GetHeight()
	local indent = 12
	local x = context:GetWidth()-indent-iw
	local y = indent
	
	--Smooth the displayed health value
	self.smoothedhealth = Math:Curve(self.health,self.smoothedhealth,10 / Time:GetSpeed())

	context:SetBlendMode(Blend.Alpha)
	context:SetColor(0,1,0)

	-- HACK!! Don't draw the healthmeter image if we are dead! -reep
	if self.health>0 then
		context:DrawImage(self.image.healthmeter,x+30,y+8,196*self.smoothedhealth/100,16)
	end

	context:SetColor(1,1,1)
	context:DrawImage(self.image.healthbar,x,y)

	--GameOver screen
	if self.currentState == self.state.dead then
		if goscreenalpha < 1.0 then
			goscreenalpha = goscreenalpha + 0.01 / Time:GetSpeed()
		end
		if goscreenalpha > 1.0 then goscreenalpha = 1.0 end
		context:SetColor(0,0,0,goscreenalpha)
		context:DrawRect(0,0,context:GetWidth(),context:GetHeight())
		context:SetColor(1,1,1,goscreenalpha)
		local text = "GAME OVER"
		local font = context:GetFont()
		local tx = (context:GetWidth() - font:GetTextWidth(text))/2
		local ty = context:GetHeight() / 2 - font:GetHeight() /2
		context:DrawText(text,tx,ty)

		if self.source:GetState()~= Source.Playing then
			local text = "Press Enter to Try Again"
			local tx = (context:GetWidth() - font:GetTextWidth(text))/2
			local ty = context:GetHeight() - font:GetHeight() - 50
			local alpha = Math:Sin(Time:Millisecs()/10.0)*0.25+0.75
			context:SetColor(0.75,0,0,alpha)
			context:DrawText(text,tx,ty)
			
			local window = Window:GetCurrent()
			if window:KeyHit(Key.Enter) then
				changemapname = App.mapfilename --Restart the current map -reep
			end
		end
	end
	context:SetColor(1,1,1,1)
	context:SetBlendMode(Blend.Solid)
end

--Return whether the player is alive
function Script:IsAlive()
	return self.alive
end

function Script:Respawn()--in
end

--Increase health
function Script:ReceiveHealth(healthPoints)--in
	--Increase health
	self.health = self.health + healthPoints;

	--Health can not be more then maximum health
	if self.health > self.maxHealth then
		self.health = self.maxHealth
	end
	
	--Call Health received output
	self.component:CallOutputs("HealthReceived")
end