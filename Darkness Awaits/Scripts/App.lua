--This function will be called once when the program starts
function App:Start()
	
	--Initialize Steamworks (optional)
	Steamworks:Initialize()

	--Set the application title
	self.title="Darkness Awaits"
	
	--Create a window
	local windowstyle = Window.Titlebar+Window.Center+8
	if System:GetProperty("fullscreen")=="1" then windowstyle=windowstyle+Window.FullScreen end
	self.window=Window:Create(self.title,0,0,System:GetProperty("screenwidth","1024"),System:GetProperty("screenheight","768"),windowstyle)
	self.window:HideMouse()
	
	--Create the graphics context
	self.context=Context:Create(self.window,0)
	if self.context==nil then return false end

	self.menuactive=true
	
	self.pentagram = Texture:Load("Materials/HUD/pentagram1.tex")
	self.titleimage = Texture:Load("Materials/HUD/darknessawaits.tex")

	self.menumusic=Sound:Load("Sound/Music/dark_minions_full.wav")
	if self.menumusic~=nil then
		self.musicsource = Source:Create()
		self.musicsource:SetSound(self.menumusic)
		self.menumusic:Release()
		self.menumusic=nil
		self.musicsource:SetVolume(1)
		self.musicsource:SetLoopMode(true)
		self.musicsource:Play()
	end

	--Create settings table and add defaults
	self.settings={}
	self.settings.vsync=false
	
	--Get default font for rendering stats
	self.statsfont = Font:Load("Fonts/arial.ttf",10)
	
	--Load our special font
	self.uifont = Font:Load("Fonts/MORPHEUS.TTF",24)
	self.context:SetFont(self.uifont)
	
	--Create a world
	self.world=World:Create()
	self.world:SetLightQuality((System:GetProperty("lightquality","1")))

	--Pause timing initially
	Time:Pause()
	
	return true
end

--This is our main program loop and will be called continuously until the program ends
function App:Loop()
	
	--If window has been closed, end the program
	if self.window:Closed() or self.window:KeyDown(Key.Escape) then
		return false
	end	
	
	--Handle map change
	if changemapname~=nil then
		
		--Clear all entities
		self.world:Clear()
		
		--Load the next map
		Time:Pause()
		if Map:Load(changemapname)==false then return false end
		Time:Resume()

		--Restart music
		if self.musicsource:GetState()~= Source.Playing then
			self.musicsource:Play()
		end

		self.mapfilename = changemapname --Save current map before we make changemapname nil -reep
		changemapname = nil
	end	

	--Update the app timing
	Time:Update()
	
	if self.menuactive==true then
	
		--Clear the screen
		self.context:SetColor(0,0,0)
		self.context:Clear()
		self.context:SetColor(1,1,1)
		
		--Draw title image onscreen
		local sw = self.context:GetWidth()
		local sh = self.context:GetHeight()
		local x = (sw - self.pentagram:GetWidth())/2
		local y = (sh - self.pentagram:GetHeight())/2
		self.context:SetBlendMode(Blend.Solid)
		self.context:DrawImage(self.pentagram,x,y)
		
		--Draw pentagram background
		local x = (sw - self.titleimage:GetWidth())/2
		local y = (sh - self.titleimage:GetHeight())/2		
		self.context:SetBlendMode(Blend.Alpha)
		self.context:DrawImage(self.titleimage,x,y)

		--Draw text onscreen
		local font = self.context:GetFont()
		local text = "Press Enter to Start"
		
		local tx = (self.context:GetWidth() - font:GetTextWidth(text))/2
		local ty = self.context:GetHeight() - font:GetHeight() - 50
		local alpha = Math:Sin(Time:Millisecs()/10.0)*0.25+0.75
		
		self.context:SetColor(0.75,0,0,alpha)
		self.context:SetBlendMode(Blend.Alpha)
		self.context:DrawText(text,tx,ty)
		self.context:SetColor(1,1,1,1)
		self.context:SetBlendMode(Blend.Solid)
		
		--Switch to live game mode
		if self.window:KeyHit(Key.Enter) then
			self.menuactive=false
			
			self.context:SetColor(0,0,0)
			self.context:Clear()
			self.context:SetColor(1,1,1)
			x = (sw - self.pentagram:GetWidth())/2
			y = (sh - self.pentagram:GetHeight())/2
			self.context:DrawImage(self.pentagram,x,y)
			self.context:SetColor(0.75,0,0,1.0)
			self.context:SetBlendMode(Blend.Alpha)
			tx = (self.context:GetWidth() - font:GetTextWidth("Loading..."))/2
			ty = self.context:GetHeight() - font:GetHeight() - 50
			self.context:DrawText("Loading...",tx,ty)
			self.context:SetColor(1,1,1,1)
			self.context:SetBlendMode(Blend.Solid)
			self.context:Sync()
			
			--Load the starting map
			self.mapfilename=System:GetProperty("map","Maps/start.map") --Not local so we can access it elsewhere -reep
			if Map:Load(self.mapfilename)==false then return false end
			
			--Change the game music
			if self.musicsource~=nil then
				self.musicsource:Release()
				self.musicsource=nil
			end
			self.gamemusic=Sound:Load("Sound/Music/warlords_full_loop.wav")
			if self.gamemusic~=nil then
				self.musicsource = Source:Create()
				self.musicsource:SetSound(self.gamemusic)
				self.gamemusic:Release()
				self.gamemusic=nil
				self.musicsource:SetVolume(0.5)
				self.musicsource:SetLoopMode(true)
				self.musicsource:Play()
			end
			self.context:SetColor(0,0,0)
			self.context:Clear()
			self.context:SetColor(1,1,1)
			--Resume timing as we switch to game mode
			Time:Resume()
		end
	else
		--Update the world
		self.world:Update()
		
		--Render the world
		self.world:Render()

		self.context:SetBlendMode(Blend.Alpha)	
		self.context:SetFont(self.statsfont)

		if DEBUG then
			self.context:SetColor(1,0,0,1)
			self.context:DrawText("Debug Mode",2,2)
			self.context:SetColor(1,1,1,1)
			self.context:DrawStats(2,22)
			
		else
			--Toggle statistics on and off
			if (self.window:KeyHit(Key.F11)) then showstats = not showstats end
			if showstats then
				self.context:SetColor(1,1,1,1)
				self.context:DrawText("FPS: "..Math:Round(Time:UPS()),2,2)
			end
		end
		self.context:SetFont(self.uifont)
		self.context:SetBlendMode(Blend.Solid)
	end
	
	--Refresh the screen
	self.context:Sync(true)--self.settings.vsync)

	--Returning true tells the main program to keep looping
	return true
end