-- ProfessionBars Forever 1.1.38 trainer directory and expanded recipe metadata test - Forever 1.60.1 profession API compatibility.
local ADDON = "ProfessionBarsForever"
local skills, bars, lastValues = {}, {}, {}
local activeCraftProfession=nil
local liveRecipes={} -- live recipe list; acquisition sources are not bundled
local recipeSources=PBFRecipeSources or {} -- verified metadata keyed by spell ID or normalized recipe name
local function recipeMetadata(id,name)
 return recipeSources[id] or (name and recipeSources[string.lower(name)]) or {}
end
local panel, browser, browserText, titleText, settings, minimapButton, barPicker
local professions = {
 ["Alchemy"]=true,["Blacksmithing"]=true,["Enchanting"]=true,["Engineering"]=true,
 ["Herbalism"]=true,["Leatherworking"]=true,["Mining"]=true,["Skinning"]=true,
 ["Tailoring"]=true,["Cooking"]=true,["Fishing"]=true,["First Aid"]=true,
 ["Jewelcrafting"]=true,["Inscription"]=true
}
-- Gathering professions have a resource view rather than a conventional recipe catalog.
-- Mining can additionally have smelting recipes; gathering utility/camp crafts
-- are displayed only if confirmed by an actual profession scan.
local gatheringProfessions={Herbalism=true,Mining=true,Skinning=true,Fishing=true}
local gatheringNotes={
 Herbalism="Gather herbs in the world. Resource skill thresholds and zones are pending verified Forever data.",
 Mining="Mine ore and stone nodes. Smelting and other learned crafts appear below if discovered by a profession scan. Node thresholds and zones are pending verification.",
 Skinning="Skin eligible creatures. Creature skill thresholds and zones are pending verified Forever data.",
 Fishing="Catch fish in open water and fishing pools. Catch locations and skill thresholds are pending verified Forever data."
}
local weaponNames = { ["Swords"]=true,["Two-Handed Swords"]=true,["Axes"]=true,["Two-Handed Axes"]=true,
 ["Maces"]=true,["Two-Handed Maces"]=true,["Daggers"]=true,["Staves"]=true,["Polearms"]=true,
 ["Bows"]=true,["Crossbows"]=true,["Guns"]=true,["Thrown"]=true,["Wands"]=true,
 ["Unarmed"]=true,["Defense"]=true,["Fist Weapons"]=true }
local colors = {Alchemy={0.57,0.72,0.93},Mining={0.78,0.62,0.36},Engineering={0.83,0.53,0.27},
 Herbalism={0.35,0.74,0.40},Cooking={0.89,0.56,0.28},Fishing={0.35,0.62,0.88},
 ["First Aid"]={0.50,0.79,0.69},Enchanting={0.73,0.48,0.88}}
-- Classic-era upgrade references; NOT confirmed as WoW Forever rules or NPC availability.
-- Data is kept separate from the recipe catalog. Never invent coordinates.
local rankGuides={}
local function ranks(expertMethod,expertDetail,artisanMethod,artisanDetail,artisanSkill)
 return {
  {cap=75,rank="Journeyman",required=50,nextCap=150,method="Profession trainer",detail="Visit a profession trainer."},
  {cap=150,rank="Expert",required=125,nextCap=225,method=expertMethod or "Profession trainer",detail=expertDetail or "Visit an eligible profession trainer."},
  {cap=225,rank="Artisan",required=artisanSkill or 200,nextCap=300,method=artisanMethod or "Advanced trainer",detail=artisanDetail or "Find an eligible Artisan profession trainer."},
 }
end
for _,name in ipairs({"Alchemy","Blacksmithing","Enchanting","Engineering","Herbalism","Leatherworking","Mining","Skinning","Tailoring"}) do
 rankGuides[name]=ranks()
end
rankGuides.Alchemy[3].detail="Classic: Kylanna Windwhisper (Alliance, Feralas) / Rogvar (Horde, Swamp of Sorrows)."
rankGuides.Blacksmithing[3].detail="Classic: Brikk Keencraft (Booty Bay, Stranglethorn Vale)."
rankGuides.Enchanting[3].detail="Classic: Annora (Uldaman)."
rankGuides.Engineering[3].detail="Classic: Buzzek Bracketswing (Gadgetzan, Tanaris)."
rankGuides.Leatherworking[3].detail="Classic: Drakk Stonehand (Alliance, Hinterlands) / Hahrana Ironhide (Horde, Feralas)."
rankGuides.Tailoring[3].detail="Classic: Timothy Worthington (Alliance, Dustwallow Marsh) / Daryl Stack (Horde, Hillsbrad Foothills)."
rankGuides.Cooking=ranks("Expert Cookbook","Classic: Shandrina (Alliance, Ashenvale) / Wulan (Horde, Desolace).","Clamlette Surprise quest","Classic: Dirge Quikcleave (Gadgetzan, Tanaris); level 35 required.",225)
rankGuides["First Aid"]=ranks("Expert First Aid - Under Wraps book","Classic: Deneb Walker (Alliance, Arathi Highlands) / Balai Lok'Wein (Horde, Dustwallow Marsh).","Triage quest","Classic: Triage quest; level 35 required.",225)
rankGuides.Fishing=ranks("Expert Fishing - The Bass and You book","Classic: Old Man Heming (Booty Bay, Stranglethorn Vale).","Nat Pagle fishing quest","Classic: Nat Pagle (Dustwallow Marsh); check level requirements.",225)
-- Forever may include extra professions. Do not assert Classic rank rules for them.
-- Same-zone positions can be compared directly. Other zones are NOT assigned fake distances.
local function playerMapPosition()
 if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
  local ok,map=pcall(C_Map.GetBestMapForUnit,"player")
  if ok and map then
   local good,pos=pcall(C_Map.GetPlayerMapPosition,map,"player")
   if good and pos and pos.x and pos.y then return map,pos.x*100,pos.y*100 end
  end
 end
 if GetCurrentMapAreaID and GetPlayerMapPosition then
  local ok,map=pcall(GetCurrentMapAreaID)
  local good,x,y=pcall(GetPlayerMapPosition,"player")
  if ok and good and map and x and y and x>0 and y>0 then return map,x*100,y*100 end
 end
end
local function orderedTrainers(name,cap)
 local faction=UnitFactionGroup and UnitFactionGroup("player") or nil
 local map,x,y=playerMapPosition()
 local matches={}
 for _,e in ipairs(PBFTrainerData or {}) do
  if e.profession==name and e.cap==cap and (e.faction=="Both" or e.faction==faction) then
   local same=map and e.mapID and tonumber(e.mapID)==tonumber(map) and x and y and e.x and e.y
   local d=same and ((x-e.x)^2+(y-e.y)^2) or nil
   matches[#matches+1]={entry=e,distance=d}
  end
 end
 table.sort(matches,function(a,b)
  if (a.distance~=nil)~=(b.distance~=nil) then return a.distance~=nil end
  if a.distance and b.distance and a.distance~=b.distance then return a.distance<b.distance end
  local af=a.entry.confidence=="Forever documented";local bf=b.entry.confidence=="Forever documented"
  if af~=bf then return af end
  return (a.entry.npc or "")<(b.entry.npc or "")
 end)
 return matches
end
local function nextTrainerCap(name,skill)
 local guides=rankGuides[name];if not guides or not skill then return nil end
 local cap=tonumber(skill.max) or 0
 for _,rank in ipairs(guides) do if cap<=rank.cap then return rank.nextCap end end
end
local function addRankTooltip(name,skill)
 if not skill or skill.kind=="weapon" then return end
 local guides=rankGuides[name]
 if not guides then GameTooltip:AddLine("Upgrade guide: not verified for Forever",0.95,0.77,0.40);return end
 local currentCap=tonumber(skill.max) or 0;local current=tonumber(skill.value) or 0
 local nextRank
 for _,rank in ipairs(guides) do if currentCap<=rank.cap then nextRank=rank;break end end
 if not nextRank then GameTooltip:AddLine("No further rank listed",0.65,0.85,0.65);return end
 GameTooltip:AddLine("Next: "..nextRank.rank.." ("..nextRank.nextCap.." cap)",1,0.82,0.28)
 local remaining=math.max(0,nextRank.required-current)
 if remaining>0 then GameTooltip:AddLine("Skill: "..nextRank.required.." needed ("..remaining.." to go)",1,0.65,0.35)
 else GameTooltip:AddLine("Skill: "..nextRank.required.." threshold met",0.4,1,0.5) end
 GameTooltip:AddLine("Get it: "..nextRank.method,0.9,0.9,0.8)
 local matches=orderedTrainers(name,nextRank.nextCap)
 if #matches==0 then GameTooltip:AddLine(nextRank.detail,0.83,0.83,0.83,true);return end
 GameTooltip:AddLine("Trainer locations (same-zone first):",1,0.78,0.38)
 local classic=false
 for i=1,math.min(3,#matches) do
  local t=matches[i];local e=t.entry
  if e.confidence~="Forever documented" then classic=true end
  local label=(e.x and e.y) and string.format("%s - %s (%.1f, %.1f)",e.npc,e.zone,e.x,e.y) or (e.npc.." - "..e.zone)
  if t.distance then label=label.." [same zone]" end
  GameTooltip:AddLine(label,0.86,0.86,0.79,true)
 end
 if #matches>3 then GameTooltip:AddLine("+"..(#matches-3).." more: Alt+right-click for full list",0.7,0.7,0.7) end
 if classic then GameTooltip:AddLine("Classic reference - needs Forever confirmation",1,0.55,0.35) end
end
local function chat(s)
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd27fPBF:|r "..s) end
end
-- Classic map IDs: these are references and may differ on custom clients.
local trainerMapIDs={ ["Orgrimmar"]=1454,["Thunder Bluff"]=1456,["Undercity"]=1458,
 ["Stormwind City"]=1453,["Ironforge"]=1455,["Darnassus"]=1457,
 ["Dustwallow Marsh"]=1445,["Durotar"]=1411,["Arathi Highlands"]=1417,["Swamp of Sorrows"]=1435 }
-- TomTom is an optional integration; no dependency or bundled code.
local function hasTomTom()
 return type(TomTom)=="table" and type(TomTom.AddWaypoint)=="function"
end
local function trainerDescription(e)
 return (e.npc or "Unknown trainer").." - "..(e.zone or "Unknown zone")..((e.x and e.y) and string.format(" (%.1f, %.1f)",e.x,e.y) or " (coordinates unavailable)")
end
local function waypointForEntry(e,name)
 if not e then return end
 local description=trainerDescription(e)
 if not hasTomTom() then chat(description.." | TomTom is optional and not enabled.");return end
 local mapID=tonumber(e.mapID or trainerMapIDs[e.zone])
 if not mapID or not tonumber(e.x) or not tonumber(e.y) then
  chat(description.." | Cannot set waypoint: destination map or coordinates unavailable.");return
 end
 local ok,result=pcall(function()
  return TomTom:AddWaypoint(mapID,tonumber(e.x)/100,tonumber(e.y)/100,{title=(e.npc or "Trainer").." ("..name..")",persistent=false})
 end)
 if not ok then chat(description.." | TomTom could not set this waypoint (map "..mapID..").");return end
 if result==false or result==nil then
  chat(description.." | TomTom did not confirm waypoint creation (map "..mapID..").");return
 end
 chat("Waypoint requested: "..description)
end
local function waypointForProfession(name,skill)
 if not hasTomTom() then return end
 local cap=nextTrainerCap(name,skill)
 local ranked=cap and orderedTrainers(name,cap) or {}
 if #ranked>0 then waypointForEntry(ranked[1].entry,name) else chat("No trainer destination available for "..name) end
end

-- Independent window placement, focus, and saved positions (character-specific).
local windowFocusLevel=120
local floatingWindows={}
local function focusFloatingWindow(frame)
 -- WoW frame strata outranks frame level. Move the previously focused window
 -- back to DIALOG, then promote the requested one above all DIALOG children.
 for _,other in pairs(floatingWindows) do
  if other ~= frame then other:SetFrameStrata("DIALOG") end
 end
 frame:SetFrameStrata("FULLSCREEN_DIALOG")
 windowFocusLevel=windowFocusLevel+2
 frame:SetFrameLevel(windowFocusLevel)
end
local function setupFloatingWindow(frame,key,defaultX,defaultY)
 floatingWindows[key]=frame
 frame:SetClampedToScreen(true)
 frame:SetClampRectInsets(0,0,0,0)
 frame:ClearAllPoints()
 local pos=PBFDB and PBFDB.windowPositions and PBFDB.windowPositions[key]
 if type(pos)=="table" and type(pos.x)=="number" and type(pos.y)=="number" then
  frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",pos.x,pos.y)
 else
  frame:SetPoint("CENTER",UIParent,"CENTER",defaultX,defaultY)
 end
 frame:SetScript("OnMouseDown",function(self)
  focusFloatingWindow(self)
 end)
 frame:SetScript("OnDragStart",function(self)
  focusFloatingWindow(self)
  self:StartMoving()
 end)
 frame:SetScript("OnDragStop",function(self)
  self:StopMovingOrSizing()
  local x,y=self:GetCenter()
  if x and y and PBFDB then
   PBFDB.windowPositions=PBFDB.windowPositions or {}
   PBFDB.windowPositions[key]={x=x,y=y}
  end
 end)
 frame:HookScript("OnShow",function(self)
  focusFloatingWindow(self)
 end)
end

-- The directory remains fully functional with no TomTom installed.
local trainerDirectory, trainerDirectoryRows, trainerDirectoryTitle, trainerDirectoryInfo
local trainerDirectoryProfession=nil
local trainerDirectoryOffset=0
local function refreshTrainerDirectory()
 if not trainerDirectory or not trainerDirectoryProfession then return end
 local name=trainerDirectoryProfession
 local cap=nextTrainerCap(name,skills[name])
 local entries=cap and orderedTrainers(name,cap) or {}
 trainerDirectoryTitle:SetText("Trainer Directory - "..name)
 trainerDirectoryInfo:SetText(#entries.." matching locations | same-zone first | coordinates shown | TomTom optional")
 local maxOffset=math.max(0,#entries-10)
 trainerDirectoryOffset=math.min(math.max(0,trainerDirectoryOffset),maxOffset)
 for i,row in ipairs(trainerDirectoryRows) do
  local match=entries[i+trainerDirectoryOffset]
  if match then
   local e=match.entry
   row.entry=e
   local suffix=match.distance and string.format(" | same zone: %.1f map units",math.sqrt(match.distance)) or ""
   local origin=e.confidence=="Forever documented" and "Forever" or "Classic ref"
   local coords=(type(e.x)=="number" and type(e.y)=="number") and string.format(" (%.1f, %.1f)",e.x,e.y) or " (coordinates unavailable)"
   row.text:SetText(string.format("%s | %s%s | %s",e.npc or "Unknown trainer",e.zone or "Unknown zone",coords,origin))
   row:Show()
  else row.entry=nil;row:Hide() end
 end
 trainerDirectory.prev:SetEnabled(trainerDirectoryOffset>0)
 trainerDirectory.next:SetEnabled(trainerDirectoryOffset<maxOffset)
end
local function showTrainerDirectory(name)
 if not trainerDirectory then
  local f=CreateFrame("Frame","PBFTrainerDirectory",UIParent,"BackdropTemplate")
  f:SetSize(590,415);f:SetFrameStrata("DIALOG")
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=10,right=10,top=10,bottom=10}})
  f:EnableMouse(true);f:SetMovable(true);f:RegisterForDrag("LeftButton")
  setupFloatingWindow(f,"trainerDirectory",225,90)
  local heading=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");heading:SetPoint("TOP",0,-22)
  trainerDirectoryTitle=heading
  local info=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");info:SetPoint("TOP",0,-52)
  trainerDirectoryInfo=info
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",-8,-8)
  trainerDirectoryRows={}
  for i=1,10 do
   local row=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
   row:SetSize(550,27);row:SetPoint("TOP",0,-74-(i-1)*28)
   row:SetText("")
   row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   row.text:SetPoint("LEFT",row,"LEFT",10,0);row.text:SetPoint("RIGHT",row,"RIGHT",-10,0)
   row.text:SetJustifyH("LEFT")
   row:SetScript("OnClick",function(self)
    if not self.entry then return end
    if hasTomTom() then waypointForEntry(self.entry,trainerDirectoryProfession)
    else chat(trainerDescription(self.entry)) end
   end)
   row:SetScript("OnEnter",function(self)
    if not self.entry then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
    GameTooltip:AddLine(self.entry.npc)
    GameTooltip:AddLine(self.entry.zone..((self.entry.x and self.entry.y) and string.format(" (%.1f, %.1f)",self.entry.x,self.entry.y) or ""),1,1,1)
    GameTooltip:AddLine(self.entry.confidence or "Source unknown",0.8,0.8,0.8)
    GameTooltip:AddLine(hasTomTom() and "Click: request optional TomTom waypoint" or "Click: print trainer location in chat",0.7,1,0.7)
    GameTooltip:Show()
   end)
   row:SetScript("OnLeave",function()GameTooltip:Hide()end)
   trainerDirectoryRows[i]=row
  end
  local prev=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");prev:SetSize(95,24);prev:SetPoint("BOTTOM",-65,19);prev:SetText("Previous")
  local next=CreateFrame("Button",nil,f,"UIPanelButtonTemplate");next:SetSize(95,24);next:SetPoint("BOTTOM",65,19);next:SetText("Next")
  prev:SetScript("OnClick",function()trainerDirectoryOffset=trainerDirectoryOffset-10;refreshTrainerDirectory()end)
  next:SetScript("OnClick",function()trainerDirectoryOffset=trainerDirectoryOffset+10;refreshTrainerDirectory()end)
  f.prev=prev;f.next=next
  f:SetScript("OnShow",refreshTrainerDirectory)
  trainerDirectory=f
 end
 trainerDirectoryProfession=name;trainerDirectoryOffset=0
 refreshTrainerDirectory();trainerDirectory:Show();focusFloatingWindow(trainerDirectory)
end

local function defaults()
 if type(PBFDB)~="table" then PBFDB={} end
 if not PBFDB.mode then PBFDB.mode="compact" end
 if not PBFDB.width then PBFDB.width=240 end
 PBFDB.scale=1 -- Overall scaling removed; normalize old saved settings.
 if not PBFDB.barScale then PBFDB.barScale=1 end
 -- Migrate the old shared opacity setting without losing user preferences.
 if PBFDB.panelOpacity==nil then PBFDB.panelOpacity=PBFDB.opacity or 1 end
 if PBFDB.barOpacity==nil then PBFDB.barOpacity=PBFDB.opacity or 1 end
 PBFDB.panelOpacity=math.max(0,math.min(1,PBFDB.panelOpacity))
 PBFDB.barOpacity=math.max(0.2,math.min(1,PBFDB.barOpacity))
 if PBFDB.titleOnHover==nil then PBFDB.titleOnHover=false end
 if PBFDB.showTitle==nil then PBFDB.showTitle=true end
 if PBFDB.locked==nil then PBFDB.locked=false end
 if PBFDB.weapons==nil then PBFDB.weapons=false end
 if PBFDB.showGroupLabels==nil then PBFDB.showGroupLabels=true end
 if not PBFDB.groupLabelScale then PBFDB.groupLabelScale=1 end
 PBFDB.groupLabelScale=math.max(0.7,math.min(2,PBFDB.groupLabelScale))
 if PBFDB.glow==nil then PBFDB.glow=true end
 if not PBFDB.positions then PBFDB.positions={} end
 if type(PBFDB.windowPositions)~="table" then PBFDB.windowPositions={} end
 if type(PBFDB.hiddenBars)~="table" then PBFDB.hiddenBars={} end
 if not PBFDB.known then PBFDB.known={} end
 if not PBFDB.scanned then PBFDB.scanned={} end
 if type(PBFDB.recipeSnapshots)~="table" then PBFDB.recipeSnapshots={} end
 if type(PBFAccountDB)~="table" then PBFAccountDB={} end
 if type(PBFAccountDB.recipeCatalogs)~="table" then PBFAccountDB.recipeCatalogs={} end
 -- Preserve snapshots from older per-character installations.
 for name,snapshot in pairs(PBFDB.recipeSnapshots) do
  if type(snapshot)=="table" and type(snapshot.recipes)=="table" and #snapshot.recipes>0 and not PBFAccountDB.recipeCatalogs[name] then
   local shared={}
   for _,r in ipairs(snapshot.recipes) do shared[#shared+1]={id=r.id,name=r.name,requiredSkill=r.requiredSkill} end
   PBFAccountDB.recipeCatalogs[name]={profession=name,recipes=shared,count=#shared}
  end
 end
 if PBFDB.showMinimap==nil then PBFDB.showMinimap=true end
 if PBFDB.minimapAngle==nil then PBFDB.minimapAngle=225 end
 if PBFDB.minimapHidden==nil then PBFDB.minimapHidden=false end
end
local function setPosition(frame,key,x,y)
 frame:ClearAllPoints()
 local p=PBFDB.positions[key]
 if p then frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",p[1],p[2])
 else frame:SetPoint("CENTER",UIParent,"CENTER",x or 0,y or 0) end
end
local function makeMovable(frame,key)
 frame:SetMovable(true); frame:EnableMouse(true); frame:RegisterForDrag("LeftButton")
 frame:SetScript("OnDragStart",function(self) if not PBFDB.locked then self.isDragging=true;self:StartMoving() end
 end)
 frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing()
  local x,y=self:GetCenter()
  if self.isDragging then self.isDragging=false;self.suppressClick=true end
  if x and y then PBFDB.positions[key]={x,y} end
 end)
end
-- Title visibility also controls the compact panel layout.  The panel remains
-- a single draggable group even when its background is fully transparent.
local titleVisible = nil
local layoutCompactBars
local function updateTitleVisibility(hovered)
 if not titleText then return end
 local show = PBFDB.showTitle and (not PBFDB.titleOnHover or hovered)
 if titleVisible == show then return end
 titleVisible = show
 if show then titleText:Show() else titleText:Hide() end
 if layoutCompactBars then layoutCompactBars() end
end
local function refreshHover()
 if not panel or not PBFDB or PBFDB.mode~="compact" then return end
 local hovered=panel:IsMouseOver()
 if not hovered then
  for _,bar in pairs(bars) do
   if bar:IsShown() and bar:IsMouseOver() then hovered=true;break end
  end
 end
 updateTitleVisibility(hovered)
end
local function createPanel()
 panel=CreateFrame("Frame","PBFMainPanel",UIParent,"BackdropTemplate")
 panel:SetWidth(260); panel:SetHeight(50)
 panel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
 panel:SetBackdropColor(0.07,0.09,0.13,0.90)
 panel:SetFrameStrata("MEDIUM")
 setPosition(panel,"panel",0,80); makeMovable(panel,"panel")
 titleText=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 titleText:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-8)
 titleText:SetText("ProfessionBars Forever")
 panel:SetScript("OnEnter",refreshHover)
 panel:SetScript("OnLeave",refreshHover)
 panel:SetScript("OnUpdate",function(self,elapsed)
  self.hoverElapsed=(self.hoverElapsed or 0)+elapsed
  if self.hoverElapsed>=0.08 then self.hoverElapsed=0;refreshHover() end
 end)
 panel:SetScript("OnMouseUp",function(self, arg1) if arg1=="RightButton" and browser then if browser:IsShown() then browser:Hide() else browser:Show() end end
 end)
end
-- Weapon and Defense bars open the character Skills tab, not the professions book.
local function openCharacterSkills()
 -- Load the Blizzard character UI before selecting its Skills pane.
 if type(CharacterFrame_LoadUI)=="function" then pcall(CharacterFrame_LoadUI) end
 if type(UIParentLoadAddOn)=="function" then pcall(UIParentLoadAddOn,"Blizzard_CharacterUI") end
 -- ToggleCharacter can silently succeed without opening a frame on this client;
 -- never treat pcall success alone as proof that the panel is visible.
 if not (CharacterFrame and CharacterFrame:IsShown()) then
  if type(ToggleCharacter)=="function" then pcall(ToggleCharacter,"SkillFrame") end
 end
 if CharacterFrame and not CharacterFrame:IsShown() then
  if type(ShowUIPanel)=="function" then pcall(ShowUIPanel,CharacterFrame) end
  if not CharacterFrame:IsShown() then CharacterFrame:Show() end
 end
 if type(CharacterFrame_ShowSubFrame)=="function" then
  pcall(CharacterFrame_ShowSubFrame,"SkillFrame")
 end
 if CharacterFrame and CharacterFrame:IsShown() and SkillFrame then
  if type(PanelTemplates_SetTab)=="function" and CharacterFrameTab3 then
   -- In the classic character UI, tab 3 is Skills.
   pcall(PanelTemplates_SetTab,CharacterFrame,3)
  end
  SkillFrame:Show()
 end
 if not (CharacterFrame and CharacterFrame:IsShown()) then
  chat("Unable to open Character panel; try the Character keybind (C).")
 end
end
-- Open the native crafting window when possible, otherwise the native professions book.
local function openNativeProfession(name)
 if name ~= "Herbalism" and name ~= "Skinning" and name ~= "Mining" and name ~= "Fishing" and not weaponNames[name] then activeCraftProfession=name end
 local craftable = name ~= "Herbalism" and name ~= "Skinning" and name ~= "Mining" and name ~= "Fishing"
 if craftable and C_TradeSkillUI and type(C_TradeSkillUI.OpenTradeSkill)=="function" then
  local enumByName={ ["First Aid"]=0,Blacksmithing=1,Leatherworking=2,Alchemy=3,Herbalism=4,Cooking=5,Mining=6,Tailoring=7,Engineering=8,Enchanting=9,Fishing=10,Skinning=11,Jewelcrafting=12,Inscription=13 }
  local enum=enumByName[name]
  if enum and type(C_TradeSkillUI.GetProfessionSkillLineID)=="function" then
   local ok,id=pcall(C_TradeSkillUI.GetProfessionSkillLineID,enum)
   if ok and type(id)=="number" and id>0 then
    local success=pcall(C_TradeSkillUI.OpenTradeSkill,id)
    if success then return end
   end
  end
 end
 if type(ToggleProfessionsBook)=="function" then ToggleProfessionsBook();return end
 if type(ToggleProfessions)=="function" then ToggleProfessions();return end
 if type(ProfessionsFrame_LoadUI)=="function" then pcall(ProfessionsFrame_LoadUI) end
 if ProfessionsFrame and type(ProfessionsFrame.Show)=="function" then ProfessionsFrame:Show();return end
 chat("Could not open the native profession window for "..name..". Try the game's Professions shortcut.")
end
local function createBar(key)
 local f=CreateFrame("Frame",nil,UIParent,"BackdropTemplate")
 f:SetSize(240,24)
 f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1,insets={left=1,right=1,top=1,bottom=1}})
 f:SetBackdropColor(0.055,0.065,0.075,0.95)
 f:SetBackdropBorderColor(0.55,0.47,0.32,0.95)
 f.fill=f:CreateTexture(nil,"ARTWORK")
 f.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
 f.fill:SetTexCoord(0,1,0,1)
 f.fill:SetPoint("TOPLEFT",f,"TOPLEFT",2,-2)
 f.fill:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",2,2)
 f.name=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 f.name:SetPoint("LEFT",f,"LEFT",7,0); f.name:SetJustifyH("LEFT")
 f.amount=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 f.amount:SetPoint("RIGHT",f,"RIGHT",-7,0)
 -- Skill gain feedback stays INSIDE the corresponding bar, adjacent to its value.
 f.flash=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 f.flash:SetPoint("RIGHT",f.amount,"LEFT",-9,0)
 f.flash:SetTextColor(0.45,1,0.48)
 f.flash:Hide()
 -- Gold edge flash and a moving highlight across the filled portion.
 f.gainBorder=f:CreateTexture(nil,"OVERLAY")
 f.gainBorder:SetTexture("Interface\\Buttons\\WHITE8X8")
 f.gainBorder:SetAllPoints(f)
 f.gainBorder:SetBlendMode("ADD")
 f.gainBorder:SetVertexColor(1,0.75,0.20)
 f.gainBorder:SetAlpha(0)
 f.gainShine=f:CreateTexture(nil,"OVERLAY")
 f.gainShine:SetTexture("Interface\\Buttons\\WHITE8X8")
 f.gainShine:SetBlendMode("ADD")
 f.gainShine:SetVertexColor(1,0.95,0.6)
 f.gainShine:SetWidth(20)
 f.gainShine:SetPoint("TOP",f,"TOP",0,-2)
 f.gainShine:SetPoint("BOTTOM",f,"BOTTOM",0,2)
 f.gainShine:SetAlpha(0)
 f.gainTime=0
 f.gainDuration=1.5
 f.gainFillStart=nil
 f.gainFillTarget=nil
 f:SetScript("OnUpdate",function(self,elapsed)
  if not self.gainTime or self.gainTime<=0 then return end
  self.gainTime=math.max(0,self.gainTime-elapsed)
  local progress=1-self.gainTime/self.gainDuration
  local pulse=math.sin(progress*math.pi*5)
  local fade=1-progress
  self.gainBorder:SetAlpha((0.10+0.19*math.abs(pulse))*fade)
  self:SetBackdropBorderColor(1,0.78,0.24,0.65+0.35*fade)
  self.flash:SetAlpha(math.min(1,fade*2))
  local fillWidth=self.gainFillTarget or self.fill:GetWidth()
  if self.gainFillStart and self.gainFillTarget then
   local eased=1-(1-math.min(1,progress*2))^3
   fillWidth=self.gainFillStart+(self.gainFillTarget-self.gainFillStart)*eased
   self.fill:SetWidth(math.max(1,fillWidth))
  end
  if progress<0.85 then
   local x=2+math.max(0,fillWidth-22)*(progress/0.85)
   self.gainShine:ClearAllPoints()
   self.gainShine:SetPoint("TOPLEFT",self,"TOPLEFT",x,-2)
   self.gainShine:SetPoint("BOTTOMLEFT",self,"BOTTOMLEFT",x,2)
   self.gainShine:SetAlpha(0.42*fade)
  else self.gainShine:SetAlpha(0) end
  if self.gainTime<=0 then
   self.flash:Hide()
   self.gainShine:SetAlpha(0)
   self.gainBorder:SetAlpha(0)
   self.gainFillStart=nil
   self.gainFillTarget=nil
   self:SetBackdropBorderColor(0.55,0.47,0.32,0.95)
  end
 end)
 makeMovable(f,"bar:"..key)
 f:SetScript("OnEnter",function(self)
  if PBFDB.mode=="compact" then refreshHover() end
  GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
  GameTooltip:AddLine(key)
  addRankTooltip(key,skills[key])
  GameTooltip:AddLine(weaponNames[key] and "Left-click: Character Skills tab" or "Left-click: Open profession",0.85,0.9,0.7)
  GameTooltip:AddLine("Right-click: recipe browser",0.85,0.8,0.6)
  GameTooltip:AddLine("Alt+right-click: trainer directory",0.8,0.8,0.6)
  if hasTomTom() then GameTooltip:AddLine("Alt+left-click: optional TomTom waypoint",0.8,0.8,0.6) end
  GameTooltip:Show()
 end)
 f:SetScript("OnLeave",function() GameTooltip:Hide(); if PBFDB.mode=="compact" then refreshHover() end end)
 f:SetScript("OnMouseUp",function(self,button)
  if button=="LeftButton" then if self.suppressClick then self.suppressClick=false elseif IsAltKeyDown and IsAltKeyDown() then (function() if hasTomTom() then waypointForProfession(key,skills[key]) else showTrainerDirectory(key) end end)() else if weaponNames[key] then openCharacterSkills() else openNativeProfession(key) end end end
  if button=="RightButton" then
   if IsAltKeyDown and IsAltKeyDown() then showTrainerDirectory(key)
   elseif browser then if browser:IsShown() then browser:Hide() else browser:Show() end end
  end
 end)
 bars[key]=f
 return f
end
local function sortedKeys(t)
 local a={}; for k in pairs(t) do table.insert(a,k) end
 table.sort(a); return a
end
-- Stable category ordering regardless of whether headings are displayed.
local secondaryProfessions={Cooking=true,["First Aid"]=true,Fishing=true,Archaeology=true}
local groupTitles={"Primary Professions","Secondary Professions","Skills"}
local groupHeaders={}
local function groupFor(name,v)
 if v.kind=="weapon" then return 3 end
 if secondaryProfessions[name] then return 2 end
 return 1
end
local function orderedVisibleSkills()
 local grouped={{},{},{}}
 for name,v in pairs(skills) do
  if (v.kind=="profession" or PBFDB.weapons) and not PBFDB.hiddenBars[name] then
   local group=groupFor(name,v)
   table.insert(grouped[group],name)
  end
 end
 local result={}
 for group=1,3 do
  table.sort(grouped[group])
  for _,name in ipairs(grouped[group]) do table.insert(result,{name=name,group=group}) end
 end
 return result
end
local function ensureGroupHeaders()
 if groupHeaders[1] then return end
 for i=1,3 do
  local t=panel:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  t:SetText(groupTitles[i]);t:SetTextColor(1,0.82,0)
  t:SetJustifyH("LEFT")
  groupHeaders[i]=t
 end
end
layoutCompactBars=function()
 if not panel or PBFDB.mode~="compact" then return end
 ensureGroupHeaders()
 local entries=orderedVisibleSkills()
 -- All measurements are panel-local. Overall scale is applied once by the
 -- parent frame; only the category font size uses groupLabelScale.
 local barHeight=math.floor(24*PBFDB.barScale+0.5)
 local rowHeight=barHeight+7
 local y=(titleVisible and 30 or 10)
 local lastGroup=nil
 for _,header in ipairs(groupHeaders) do header:Hide() end
 for _,entry in ipairs(entries) do
  if entry.group~=lastGroup then
   if PBFDB.showGroupLabels then
    local header=groupHeaders[entry.group]
    local fontPath,_,fontFlags=header:GetFont()
    local size=math.max(8,math.floor(12*PBFDB.groupLabelScale+0.5))
    if fontPath then header:SetFont(fontPath,size,fontFlags) end
    -- Scale only the space needed for the heading, not a second large gap.
    -- The previous 10px group gap plus 9px heading padding made small
    -- labels appear detached from their bars.
    if lastGroup then y=y+math.max(2,math.floor(size*0.15+0.5)) end
    local headingHeight=math.ceil(size*1.12)
    header:SetHeight(headingHeight)
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT",panel,"TOPLEFT",10,-y)
    header:Show()
    y=y+headingHeight+math.max(2,math.floor(size*0.18+0.5))
   end
   lastGroup=entry.group
  end
  local f=bars[entry.name]
  if f then
   f:ClearAllPoints();f:SetPoint("TOPLEFT",panel,"TOPLEFT",8,-y)
  end
  y=y+rowHeight
 end
 panel:SetHeight(math.max(titleVisible and 44 or 18,y+8))
end
redraw=function()
 if not panel then return end
 local entries=orderedVisibleSkills()
 local barHeight=math.floor(24*PBFDB.barScale+0.5)
 panel:SetScale(1)
 panel:SetAlpha(1)
 panel:SetBackdropColor(0.07,0.09,0.13,0.90*PBFDB.panelOpacity)
 panel:SetBackdropBorderColor(0.65,0.60,0.51,PBFDB.panelOpacity)
 panel:SetWidth(PBFDB.width+16)
 local shown={}
 for i,entry in ipairs(entries) do
  local name=entry.name
  local v=skills[name]
  shown[name]=true
  local f=bars[name] or createBar(name)
  f:SetScale(1)
  f:SetAlpha(PBFDB.barOpacity)
  f:SetSize(PBFDB.width,barHeight)
  f.name:SetText(name)
  f.amount:SetText(v.value.."/"..v.max)
  local c=colors[name] or (v.kind=="weapon" and {0.65,0.65,0.7}) or {0.48,0.74,0.54}
  f.fill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  f.fill:SetVertexColor(c[1],c[2],c[3])
  local targetWidth=math.max(1,(PBFDB.width-4)*math.min(1,v.value/math.max(1,v.max)))
  if f.gainTime and f.gainTime>0 and f.gainFillStart then f.gainFillTarget=targetWidth else f.fill:SetWidth(targetWidth) end
  f:SetParent(UIParent);f:EnableMouse(true)
  if PBFDB.mode=="compact" then
   f:SetFrameStrata(panel:GetFrameStrata())
   f:SetFrameLevel(panel:GetFrameLevel()+3)
  else
   setPosition(f,"bar:"..name,-120,100-(i-1)*42)
  end
  f:Show()
 end
 for name,f in pairs(bars) do if not shown[name] then f:Hide() end end
 if PBFDB.mode=="compact" then
  panel:Show()
  layoutCompactBars()
 else
  panel:Hide()
  for _,header in ipairs(groupHeaders) do header:Hide() end
 end
 if #entries==0 then titleText:SetText("ProfessionBars Forever - no professions detected (/profbar debug)")
 else titleText:SetText("ProfessionBars Forever  |  "..(PBFDB.locked and "LOCKED" or "Drag to move")) end
 refreshHover()
end
-- Forever 1.60.1 uses modern profession APIs. Prefer the player's actual
-- learned professions via GetProfessions; never show unlearned skill lines.
local scanSource="none"
local function collectProfessions()
 local found={}
 local function add(name,rank,cap)
  if type(name)=="string" and professions[name] and type(rank)=="number" and type(cap)=="number" and cap>0 and rank>=0 then
   found[name]={value=rank,max=cap,kind="profession"}
  end
 end
 if type(GetProfessions)=="function" and type(GetProfessionInfo)=="function" then
  local ok,a,b,c,d,e=pcall(GetProfessions)
  if ok then
   local indices={a,b,c,d,e}
   for slot=1,5 do
    local index=indices[slot]
    if type(index)=="number" then
     local valid,name,icon,rank,cap=pcall(GetProfessionInfo,index)
     if valid then add(name,rank,cap) end
    end
   end
  end
 end
 if next(found) then return found,"GetProfessions/GetProfessionInfo" end
 -- Backup: scan modern skill lines explicitly associated with learned professions.
 if C_TradeSkillUI and type(C_TradeSkillUI.GetAllProfessionTradeSkillLines)=="function"
  and type(C_TradeSkillUI.GetProfessionInfoBySkillLineID)=="function" then
  local ok,ids=pcall(C_TradeSkillUI.GetAllProfessionTradeSkillLines)
  if ok and type(ids)=="table" then
   for _,id in ipairs(ids) do
    local valid,info=pcall(C_TradeSkillUI.GetProfessionInfoBySkillLineID,id)
    if valid and type(info)=="table" then
     add(info.professionName or info.parentProfessionName,info.skillLevel,info.maxSkillLevel)
    end
   end
  end
 end
 if next(found) then return found,"C_TradeSkillUI.GetAllProfessionTradeSkillLines" end
 -- Last fallback for classic-compatible skill lists.
 if type(GetNumSkillLines)=="function" and type(GetSkillLineInfo)=="function" then
  local ok,n=pcall(GetNumSkillLines)
  if ok and type(n)=="number" then
   for i=1,n do
    local valid,name,isHeader,_,rank,_,_,cap=pcall(GetSkillLineInfo,i)
    if valid and not isHeader then add(name,rank,cap) end
   end
  end
 end
 return found,next(found) and "GetSkillLineInfo" or "none"
end
local function scanSkills(initial)
 local new,source=collectProfessions()
 scanSource=source
 if PBFDB.weapons then
  local function readSkillLine(countFn,infoFn)
   if type(countFn)~="function" or type(infoFn)~="function" then return end
   local ok,n=pcall(countFn)
   if not ok or type(n)~="number" then return end
   for i=1,n do
    local valid,a,b,c,d,e,f,g,h=pcall(infoFn,i)
    if valid then
     local name,header,rank,cap
     if type(a)=="table" then
      name=a.skillName or a.name
      header=a.isHeader
      rank=a.skillLevel or a.rank
      cap=a.maxSkillLevel or a.maxRank
     else
      name=a;header=b;rank=d;cap=h
     end
     if type(name)=="string" and weaponNames[name] and not header and type(rank)=="number" and type(cap)=="number" and cap>0 then
      new[name]={value=rank,max=cap,kind="weapon"}
     end
    end
   end
  end
  if C_SkillInfo then readSkillLine(C_SkillInfo.GetNumSkillLines,C_SkillInfo.GetSkillLineInfo) end
  readSkillLine(GetNumSkillLines,GetSkillLineInfo)
 end
 for name,v in pairs(new) do
  local old=lastValues[name]
  if not initial and old and v.value>old then
   if PBFDB.glow then
    local f=bars[name] or createBar(name)
    f.flash:SetText("+"..(v.value-old))
    f.flash:SetAlpha(1)
    f.flash:Show()
    f.gainDuration=1.5
    f.gainTime=f.gainDuration
    f.gainFillStart=math.max(1,(PBFDB.width-4)*math.min(1,old/math.max(1,v.max)))
    f.gainFillTarget=math.max(1,(PBFDB.width-4)*math.min(1,v.value/math.max(1,v.max)))
    f.fill:SetWidth(f.gainFillStart)
   end
  end
  lastValues[name]=v.value
 end
 skills=new
 redraw()
end
-- Capture learned recipes from the modern profession UI (and older clients).
-- Recipe IDs are retained as keys where possible, so duplicate names do not collide.
local recipeScanSource="none"
local function currentCraftName()
 -- GetTradeSkillLine is nil on Forever 1.60.1; the name of the last
 -- profession opened through a PBF bar is the most reliable hint.
 local t=C_TradeSkillUI
 if t and type(t.GetTradeSkillLine)=="function" then
  local ok,id=pcall(t.GetTradeSkillLine)
  if ok and type(id)=="number" and type(t.GetProfessionInfoBySkillLineID)=="function" then
   local good,info=pcall(t.GetProfessionInfoBySkillLineID,id)
   if good and type(info)=="table" then
    local n=info.professionName or info.parentProfessionName
    if professions[n] then return n end
   end
  end
 end
 if type(GetTradeSkillLine)=="function" then
  local ok,n=pcall(GetTradeSkillLine)
  if ok and type(n)=="string" and professions[n] then return n end
 end
 if activeCraftProfession then return activeCraftProfession end
 -- Some Forever builds expose a profession ID but not its name.
 -- Avoid attributing a scan to a guessed profession.
 return nil
end
-- The recipe API varies by client build. Only display a skill requirement
-- when the client actually supplies one; never infer it from recipe ID.
local function recipeRequiredSkill(info,id,modern)
 local function getNumber(data)
  if type(data)~="table" then return nil end
  for _,key in ipairs({"requiredSkillLevel","requiredSkill","requiredSkillRank","minSkillLevel","skillLevelRequired"}) do
   local value=data[key]
   if type(value)=="number" and value>0 then return math.floor(value) end
  end
  return nil
 end
 local value=getNumber(info)
 if value then return value end
 if modern and type(modern.GetRecipeSchematic)=="function" then
  local ok,schematic=pcall(modern.GetRecipeSchematic,id,false)
  if ok then return getNumber(schematic) end
 end
 return nil
end
-- Store recipe catalogs account-wide and learned flags per character. Never replace
-- an existing catalog with an empty or incomplete API response.
local function persistRecipes(profession,list)
 if not professions[profession] or type(list)~="table" or #list==0 then return false end
 local existing=PBFAccountDB.recipeCatalogs[profession]
 local merged={}
 if existing and type(existing.recipes)=="table" then
  for _,r in ipairs(existing.recipes) do if type(r.id)=="number" then merged[r.id]={id=r.id,name=r.name,requiredSkill=r.requiredSkill} end end
 end
 local known={}
 for _,r in ipairs(list) do
  if type(r.id)=="number" and type(r.name)=="string" then
   local old=merged[r.id] or {}
   merged[r.id]={id=r.id,name=r.name,requiredSkill=r.requiredSkill or old.requiredSkill}
   if r.learned then known[r.id]=true end
  end
 end
 local catalog={}
 for _,r in pairs(merged) do catalog[#catalog+1]=r end
 table.sort(catalog,function(a,b) return (a.name or "")<(b.name or "") end)
 PBFAccountDB.recipeCatalogs[profession]={profession=profession,recipes=catalog,count=#catalog}
 -- Learned status is updated only on a complete scan (not a partial load).
 if not existing or #list>=#(existing.recipes or {}) then
  PBFDB.recipeKnownByID=PBFDB.recipeKnownByID or {}
  PBFDB.recipeKnownByID[profession]=known
 end
 return true
end
-- Seed only verified data. Other professions remain visible without inventing recipe lists.
local function seedVerifiedCatalogs()
 if not PBFAccountDB or not PBFAccountDB.recipeCatalogs then return end
 local old=PBFAccountDB.recipeCatalogs.Cooking
 if (not old or not old.recipes or #old.recipes<132) and type(PBFSeedCooking)=="table" then
  local list={}
  for _,r in ipairs(PBFSeedCooking) do list[#list+1]={id=r[1],name=r[2]} end
  PBFAccountDB.recipeCatalogs.Cooking={profession="Cooking",recipes=list,count=#list,seeded=true}
 end
end
local function loadSavedRecipeSnapshot(profession)
 if not profession then return false end
 local shared=PBFAccountDB and PBFAccountDB.recipeCatalogs and PBFAccountDB.recipeCatalogs[profession]
 local old=PBFDB and PBFDB.recipeSnapshots and PBFDB.recipeSnapshots[profession]
 local snapshot=shared or old
 if type(snapshot)~="table" or type(snapshot.recipes)~="table" then return false end
 local list={}
 local known=PBFDB.recipeKnownByID and PBFDB.recipeKnownByID[profession]
 for _,r in ipairs(snapshot.recipes) do
  if type(r.id)=="number" and type(r.name)=="string" then
   local meta=recipeMetadata(r.id,r.name)
   local learned=nil
   if known then learned=(known[r.id]==true)
   elseif old and old.recipes then
    for _,prior in ipairs(old.recipes) do if prior.id==r.id then learned=(prior.learned==true);break end end
   end
   list[#list+1]={id=r.id,name=r.name,learned=learned,requiredSkill=r.requiredSkill or meta.requiredSkill,source=meta.source,sourceDetails=meta.details,sourceLocation=meta.location}
  end
 end
 if #list==0 then return false end
 table.sort(list,function(a,b) return a.name<b.name end)
 liveRecipes={profession=profession,list=list,fromSnapshot=true}
 return true
end
local function captureRecipeSnapshot()
 if liveRecipes.profession and liveRecipes.list and persistRecipes(liveRecipes.profession,liveRecipes.list) then
  chat("Saved "..#liveRecipes.list.." recipes for "..liveRecipes.profession.." (automatic on profession open).")
 else chat("No identifiable profession data available to save yet.") end
end
local function loadFirstSavedProfession()
 if not PBFAccountDB or not PBFAccountDB.recipeCatalogs then return false end
 local names={}
 for name,data in pairs(PBFAccountDB.recipeCatalogs) do if data.recipes and #data.recipes>0 then names[#names+1]=name end end
 table.sort(names)
 if #names==0 then return false end
 return loadSavedRecipeSnapshot(names[1])
end
local function scanRecipes()
 if not PBFDB then return end
 local modern=C_TradeSkillUI
 local profession=currentCraftName()
 local found=0
 local missing=0
 local source="none"
 if modern and type(modern.GetAllRecipeIDs)=="function" and type(modern.GetRecipeInfo)=="function" then
  local ok,ids=pcall(modern.GetAllRecipeIDs)
  if ok and type(ids)=="table" and #ids>0 then
   -- Preserve the live list even when the client does not identify the
   -- profession. Do not mislabel recipes from an unknown source as Cooking.
   local list={}
   local known={}
   for _,id in ipairs(ids) do
    local good,info=pcall(modern.GetRecipeInfo,id)
    if good and type(info)=="table" and type(info.name)=="string" then
     local learned=(info.learned==true)
     local meta=recipeMetadata(id,info.name)
     table.insert(list,{id=id,name=info.name,learned=learned,requiredSkill=recipeRequiredSkill(info,id,modern) or meta.requiredSkill,source=meta.source,sourceDetails=meta.details,sourceLocation=meta.location})
     if learned then known[info.name]=true;found=found+1 else missing=missing+1 end
    end
   end
   table.sort(list,function(a,b) return a.name<b.name end)
   liveRecipes={profession=profession or "Current profession",list=list}
   if profession and #list>0 then persistRecipes(profession,list) end
   if profession then
    -- Replace the last snapshot rather than retaining recipes that were
    -- unlearned or belonged to a different scanned profession.
    PBFDB.known[profession]=known
    PBFDB.scanned[profession]=true
   end
   source="C_TradeSkillUI"
  end
 end
 if source=="none" and type(GetNumTradeSkills)=="function" and type(GetTradeSkillInfo)=="function" and type(GetTradeSkillLine)=="function" then
  local ok,n=pcall(GetTradeSkillLine)
  if ok and type(n)=="string" and professions[n] then
   local countOK,count=pcall(GetNumTradeSkills)
   if countOK and type(count)=="number" then
    local known={}
    for i=1,count do
     local good,itemName,itemType=pcall(GetTradeSkillInfo,i)
     if good and itemName and itemType~="header" and itemType~="subheader" then
      known[itemName]=true;found=found+1
     end
    end
    PBFDB.known[n]=known;PBFDB.scanned[n]=true
    source="legacy trade skills"
   end
  end
 end
 recipeScanSource=source.." ("..found.." learned, "..missing.." unlearned; "..(profession or "unidentified")..")"
 if browser and browser:IsShown() then browser.refresh() end
end
local function makeButton(parent,label,x,y,w,callback)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetWidth(w); b:SetHeight(23); b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
 b:SetText(label); b:SetScript("OnClick",callback)
 return b
end
local function createBrowser()
 browser=CreateFrame("Frame","PBFRecipeBrowser",UIParent,"BackdropTemplate")
 browser:SetSize(860,570)
 browser:SetFrameStrata("DIALOG")
 browser:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=28,insets={left=12,right=12,top=12,bottom=12}})
 browser:SetBackdropColor(0.055,0.045,0.035,1)
 -- Dialog background artwork is translucent even with backdrop alpha set to 1.
 -- Add a genuinely opaque fill behind the content while preserving the WoW border.
 local solidBackground=browser:CreateTexture(nil,"BACKGROUND",nil,1)
 solidBackground:SetTexture("Interface\\Buttons\\WHITE8X8")
 solidBackground:SetPoint("TOPLEFT",browser,"TOPLEFT",14,-14)
 solidBackground:SetPoint("BOTTOMRIGHT",browser,"BOTTOMRIGHT",-14,14)
 solidBackground:SetVertexColor(0.065,0.052,0.044,1)
 browser.solidBackground=solidBackground
 browser:EnableMouse(true);browser:SetMovable(true);browser:RegisterForDrag("LeftButton")
 setupFloatingWindow(browser,"recipeBrowser",-170,-35)
 local function label(text,x,y,w,font)
  local f=browser:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
  f:SetPoint("TOPLEFT",browser,"TOPLEFT",x,y);f:SetWidth(w);f:SetJustifyH("LEFT");f:SetText(text);return f
 end
 local heading=browser:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 heading:SetPoint("TOP",browser,"TOP",0,-20);heading:SetText("Profession Recipe Collection")
 makeButton(browser,"X",811,-13,25,function() browser:Hide() end)
 local hint=label("Recipes are collected automatically when a profession book opens. Collection is shared; learned status is per character.",28,-53,790)
 hint:SetTextColor(0.78,0.75,0.69)
 browser.status=label("",28,-84,790,"GameFontNormal")
 -- Standard WoW dropdown: known professions first, then unlearned professions.
 local professionDropdown=CreateFrame("Frame","PBFProfessionDropdown",browser,"UIDropDownMenuTemplate")
 professionDropdown:SetPoint("TOPLEFT",browser,"TOPLEFT",8,-103)
 UIDropDownMenu_SetWidth(professionDropdown,195)
 local function selectProfession(name)
  if not loadSavedRecipeSnapshot(name) then
   liveRecipes={profession=name,list={},fromSnapshot=false,catalogUnavailable=true}
  end
  PBFDB.selectedCollection=name
  browser.page=1;browser.scrollOffset=0;browser.selectedID=nil;browser.refresh()
 end
 UIDropDownMenu_Initialize(professionDropdown,function(self,level)
  local known,unknown={},{}
  for name in pairs(professions) do
   if skills[name] then known[#known+1]=name else unknown[#unknown+1]=name end
  end
  table.sort(known);table.sort(unknown)
  local function addHeading(text)
   local info=UIDropDownMenu_CreateInfo();info.text=text;info.isTitle=true;info.notCheckable=true
   UIDropDownMenu_AddButton(info,level)
  end
  local function addOption(name)
   local info=UIDropDownMenu_CreateInfo()
   local cat=PBFAccountDB and PBFAccountDB.recipeCatalogs and PBFAccountDB.recipeCatalogs[name]
   local n=cat and cat.recipes and #cat.recipes or 0
   info.text=name..(gatheringProfessions[name] and (n>0 and (" (gathering + "..n.." crafts)") or " (gathering)") or (n>0 and (" ("..n.." recipes)") or " (catalog pending)"))
   info.checked=(liveRecipes.profession==name)
   info.func=function() selectProfession(name);CloseDropDownMenus() end
   UIDropDownMenu_AddButton(info,level)
  end
  addHeading("Known Professions")
  for _,name in ipairs(known) do addOption(name) end
  addHeading("Unlearned Professions")
  for _,name in ipairs(unknown) do addOption(name) end
 end)
 label("Search",253,-117,53,"GameFontNormalSmall")
 local search=CreateFrame("EditBox",nil,browser,"InputBoxTemplate")
 search:SetSize(240,22);search:SetPoint("TOPLEFT",browser,"TOPLEFT",307,-111)
 search:SetAutoFocus(false);search:SetMaxLetters(80)
 search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
 browser.searchBox=search;browser.filter="all";browser.sourceFilter="all";browser.page=1
 local filter=makeButton(browser,"Status: All",563,-110,132,function()
  local options={"all","known","missing","learnable"};local i=1
  for n,v in ipairs(options) do if v==browser.filter then i=n;break end end
  browser.filter=options[i%#options+1];browser.page=1;browser.scrollOffset=0;browser.refresh()
 end)
 local sourceButton=makeButton(browser,"Source: All",702,-110,132,function()
  local options={"all","trainer","vendor","world drop","quest","other","unknown"};local i=1
  for n,v in ipairs(options) do if v==browser.sourceFilter then i=n;break end end
  browser.sourceFilter=options[i%#options+1];browser.page=1;browser.scrollOffset=0;browser.refresh()
 end)
 local count=label("",29,-145,780,"GameFontNormalSmall")
 -- Click headers to sort; Shift-click adds or changes a secondary key.
 -- Third click removes that key and returns to the default sort.
 local sortColumns={
  {key="name",title="Recipe",x=28,w=273},
  {key="status",title="Status",x=306,w=95},
  {key="skill",title="Skill",x=401,w=65},
 }
 local sortButtons={}
 local function getSortSpec()
  if type(PBFDB.recipeSort)~="table" then PBFDB.recipeSort={} end
  return PBFDB.recipeSort
 end
 local function sortClick(key)
  local spec=getSortSpec()
  local shift=type(IsShiftKeyDown)=="function" and IsShiftKeyDown()
  local idx
  for i,entry in ipairs(spec) do if entry.key==key then idx=i;break end end
  local nextDirection=idx and (spec[idx].dir=="asc" and "desc" or nil) or "asc"
  if not shift then
   -- A plain click changes the primary sort, preserving no secondary keys.
   PBFDB.recipeSort=nextDirection and {{key=key,dir=nextDirection}} or {}
  else
   if idx then table.remove(spec,idx) end
   if nextDirection then spec[#spec+1]={key=key,dir=nextDirection} end
  end
  browser.page=1;browser.scrollOffset=0;browser.refresh()
 end
 for _,col in ipairs(sortColumns) do
  local b=CreateFrame("Button",nil,browser)
  b:SetPoint("TOPLEFT",browser,"TOPLEFT",col.x,-170)
  b:SetSize(col.w,23)
  local t=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  t:SetPoint("LEFT",b,"LEFT",3,0);t:SetJustifyH("LEFT");t:SetWidth(col.w-5)
  b.label=t;b.title=col.title;b.sortKey=col.key
  b:SetScript("OnClick",function() sortClick(col.key) end)
  b:SetScript("OnEnter",function(self) self.label:SetTextColor(1,1,1) end)
  b:SetScript("OnLeave",function(self) self.label:SetTextColor(1,0.82,0) end)
  sortButtons[#sortButtons+1]=b
 end
 local detailsBg=CreateFrame("Frame",nil,browser,"BackdropTemplate")
 detailsBg:SetPoint("TOPLEFT",browser,"TOPLEFT",480,-171);detailsBg:SetSize(350,323)
 detailsBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=4,right=4,top=4,bottom=4}})
 detailsBg:SetBackdropColor(0.10,0.085,0.065,0.97)
 detailsBg:SetBackdropBorderColor(0.38,0.29,0.17,0.9)
 -- Source-related fields are shown in the details panel rather than table
 -- columns. Provide compact sort controls for those fields as well.
 local extraSortColumns={
  {key="source",title="Source",x=493,w=91},
  {key="details",title="NPC / Mob",x=588,w=111},
  {key="location",title="Location",x=703,w=112},
 }
 for _,col in ipairs(extraSortColumns) do
  local b=CreateFrame("Button",nil,browser)
  b:SetPoint("TOPLEFT",browser,"TOPLEFT",col.x,-150)
  b:SetSize(col.w,19)
  local t=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  t:SetPoint("LEFT",b,"LEFT",2,0);t:SetWidth(col.w-3);t:SetJustifyH("LEFT")
  b.label=t;b.title=col.title;b.sortKey=col.key
  b:SetScript("OnClick",function() sortClick(col.key) end)
  b:SetScript("OnEnter",function(self) self.label:SetTextColor(1,1,1) end)
  b:SetScript("OnLeave",function(self) self.label:SetTextColor(1,0.82,0) end)
  sortButtons[#sortButtons+1]=b
 end
 local details=detailsBg:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 details:SetPoint("TOPLEFT",detailsBg,"TOPLEFT",16,-18);details:SetWidth(315);details:SetJustifyH("LEFT");details:SetJustifyV("TOP")
 details:SetText("Select a recipe to see its details.")
 local rowButtons={}
 for i=1,14 do
  local btn=CreateFrame("Button",nil,browser)
  btn:SetSize(414,21);btn:SetPoint("TOPLEFT",browser,"TOPLEFT",28,-196-(i-1)*21)
  local highlight=btn:CreateTexture(nil,"BACKGROUND")
  highlight:SetAllPoints();highlight:SetTexture("Interface\\Buttons\\WHITE8X8");highlight:SetVertexColor(0.55,0.40,0.17,0.25);highlight:Hide()
  btn:SetScript("OnEnter",function() highlight:Show() end)
  btn:SetScript("OnLeave",function() highlight:Hide() end)
  local cells={}
  for j,c in ipairs({{0,275},{282,90},{378,50}}) do
   local f=btn:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
   f:SetPoint("LEFT",btn,"LEFT",c[1],0);f:SetWidth(c[2]);f:SetJustifyH("LEFT");cells[j]=f
  end
  btn.cells=cells;rowButtons[i]=btn
 end
 local footer=label("",29,-519,780,"GameFontHighlightSmall")
 browser.scrollOffset=0
 local scroll=CreateFrame("Slider","PBFCollectionScrollbar",browser,nil)
 scroll:SetPoint("TOPLEFT",browser,"TOPLEFT",452,-230)
 scroll:SetSize(16,227);scroll:SetValueStep(1)
 -- Standalone slider: the Blizzard scroll template calls SetVerticalScroll
 -- on a scroll frame and is incompatible with our virtualized row list.
 scroll:SetOrientation("VERTICAL")
 scroll:EnableMouse(true)
 scroll:SetFrameLevel(browser:GetFrameLevel()+8)
 scroll:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
 local thumb=scroll:GetThumbTexture()
 if thumb then thumb:SetSize(24,24);thumb:SetDrawLayer("OVERLAY") end
 local track=scroll:CreateTexture(nil,"BACKGROUND")
  track:SetAllPoints();track:SetTexture("Interface\\Buttons\\WHITE8X8")
  track:SetVertexColor(0.20,0.17,0.14,0.85)
  scroll:SetHitRectInsets(-5,-5,0,0)
  scroll:SetMinMaxValues(0,0)
 scroll:SetValue(0)
 scroll:SetScript("OnValueChanged",function(self,value)
  local offset=math.floor(value+0.5)
  if browser.scrollOffset~=offset then browser.scrollOffset=offset;browser.refresh() end
 end)
 -- Keep arrow controls AND a draggable slider thumb. No secure scroll template.
 local function arrow(name,anchor,y,delta)
  local b=CreateFrame("Button",name,browser,"UIPanelScrollUpButtonTemplate")
  b:ClearAllPoints();b:SetPoint("TOPLEFT",browser,"TOPLEFT",449,y)
  if delta>0 then
   b:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
   b:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
   b:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
  end
  b:SetFrameLevel(scroll:GetFrameLevel()+1)
  b:SetScript("OnClick",function() scroll:SetValue(scroll:GetValue()+delta) end)
  return b
 end
 local upArrow=arrow("PBFCollectionScrollUp",browser,-204,-1)
 local downArrow=arrow("PBFCollectionScrollDown",browser,-463,1)

 browser:EnableMouseWheel(true)
 browser:SetScript("OnMouseWheel",function(self,delta)
  browser.scrollOffset=math.max(0,math.min(math.max(0,(browser.matchCount or 0)-#rowButtons),browser.scrollOffset-delta*3))
  browser.refresh()
 end)
 browser.refresh=function()
  local recipes=liveRecipes.list or {}
  local name=liveRecipes.profession or "No profession saved"
  local gathering=gatheringProfessions[name]
  local knownCount=0
  for _,r in ipairs(recipes) do if r.learned then knownCount=knownCount+1 end end
  -- A profession is unlearned only when the current character's profession
  -- API returned a usable skill list and the selected profession is absent.
  local professionUnlearned = professions[name] and skills[name]==nil and scanSource~="none"
  local function recipeStatus(r)
   if professionUnlearned then return "|cff999999Unlearned Profession|r" end
   if r.learned==true then return "|cff66ff99Known|r" end
   if r.learned==false then return "|cffffaa55Missing|r" end
   return "|cffaaaaaaNot Verified|r"
  end
  local statusVerified=false
  for _,r in ipairs(recipes) do if r.learned~=nil then statusVerified=true;break end end
  browser.status:SetText(name.."  |  "..(professionUnlearned and ("Unlearned Profession  |  "..#recipes.." recipes") or (statusVerified and (knownCount.." / "..#recipes.." Known") or (#recipes.." recipes; status not verified")))..(liveRecipes.fromSnapshot and "  (saved)" or ""))
  if gathering then browser.status:SetText(name.."  |  Gathering  |  "..(skills[name] and "Known Profession" or "Unlearned Profession").."  |  "..#recipes.." verified crafts") end
  UIDropDownMenu_SetText(professionDropdown,name)
  filter:SetText("Status: "..({all="All",known="Known",missing="Missing",learnable="Skill Met"})[browser.filter])
  sourceButton:SetText("Source: "..(browser.sourceFilter=="all" and "All" or browser.sourceFilter))
  if liveRecipes.catalogUnavailable and not gathering then count:SetText("Catalog not yet verified for this profession; open its book to collect recipes.") end
  local matches={};local q=string.lower(search:GetText() or "")
  for _,r in ipairs(recipes) do
   local source=string.lower(tostring(r.source or "Unknown"))
   local eligible=r.learned==false and type(r.requiredSkill)=="number" and skills[name] and skills[name].value>=r.requiredSkill
   local statusOK=browser.filter=="all" or (browser.filter=="known" and not professionUnlearned and r.learned==true) or (browser.filter=="missing" and not professionUnlearned and r.learned==false) or (browser.filter=="learnable" and not professionUnlearned and eligible)
   if statusOK and (browser.sourceFilter=="all" or browser.sourceFilter==source) and (q=="" or string.find(string.lower(r.name),q,1,true) or string.find(tostring(r.id),q,1,true)) then matches[#matches+1]=r end
  end
  local spec=getSortSpec()
  local function statusRank(r)
   if professionUnlearned then return 2 end
   if r.learned==true then return 0 end
   if r.learned==false then return 1 end
   return 3
  end
  local function valueFor(r,key)
   if type(r)~="table" then return nil end
   if key=="status" then return statusRank(r) end
   if key=="skill" then
    return type(r.requiredSkill)=="number" and r.requiredSkill or nil
   end
   local value
   if key=="name" then value=r.name
   elseif key=="source" then value=r.source
   elseif key=="details" then value=r.sourceDetails
   elseif key=="location" then value=r.sourceLocation end
   if type(value)~="string" or value=="" or value=="Unknown" or value=="Not verified" then return nil end
   return string.lower(value)
  end
  local function compareKey(a,b,key,dir)
   local va,vb=valueFor(a,key),valueFor(b,key)
   -- Unknown values always last, even for descending sorts.
   if va==nil and vb~=nil then return false,true end
   if vb==nil and va~=nil then return true,true end
   if va==nil and vb==nil then return false,false end
   if va~=vb then
    if dir=="desc" then return va>vb,true end
    return va<vb,true
   end
   return false,false
  end
  table.sort(matches,function(a,b)
   local order=spec
   if #order==0 then
    order={{key="status",dir="asc"},{key="skill",dir="asc"},{key="name",dir="asc"}}
   end
   for _,entry in ipairs(order) do
    local result,decided=compareKey(a,b,entry.key,entry.dir)
    if decided then return result end
   end
   -- Stable deterministic tie-breakers; default behavior when user keys tie.
   local na,nb=string.lower(a.name or ""),string.lower(b.name or "")
   if na~=nb then return na<nb end
   return (a.id or 0)<(b.id or 0)
  end)
  for _,b in ipairs(sortButtons) do
   local suffix=""
   for i,entry in ipairs(spec) do
    if entry.key==b.sortKey then
     suffix=" "..(entry.dir=="asc" and "^" or "v")..( #spec>1 and tostring(i) or "")
     break
    end
   end
   b.label:SetText(b.title..suffix)
  end
  count:SetText(gathering and (#matches.." verified gathering crafts / utility abilities") or (#matches.." matching recipes"))
  browser.matchCount=#matches
  local maxOffset=math.max(0,#matches-#rowButtons)
  browser.scrollOffset=math.max(0,math.min(browser.scrollOffset,maxOffset))
  scroll:SetMinMaxValues(0,maxOffset)
  scroll:SetValue(browser.scrollOffset)
  upArrow:SetEnabled(maxOffset>0)
  downArrow:SetEnabled(maxOffset>0)
  scroll:SetShown(maxOffset>0)
  for i,btn in ipairs(rowButtons) do
   local r=matches[browser.scrollOffset+i]
   if r then
    btn:Show();btn.cells[1]:SetText(r.name)
    btn.cells[2]:SetText(recipeStatus(r))
    btn.cells[3]:SetText(r.requiredSkill and tostring(r.requiredSkill) or "?")
    btn:SetScript("OnClick",function() browser.selectedID=r.id;browser.refresh() end)
   else btn:Hide() end
  end
  local selected
  for _,r in ipairs(recipes) do if r.id==browser.selectedID then selected=r;break end end
  if not selected then selected=matches[1] end
  if selected then
   local source=selected.source or "Unknown"
   details:SetText("|cffffd46a"..selected.name.."|r\n\n"..recipeStatus(selected).."\n\nRequired skill: "..(selected.requiredSkill or "Not available").."\n\nSource: "..source.."\n\nTrainer / Vendor / Mob:\n"..(selected.sourceDetails or "Not verified").."\n\nLocation:\n"..(selected.sourceLocation or "Not verified").."\n\nSpell ID: "..selected.id)
  elseif gathering then
   local skill=skills[name]
   local progress=skill and ((skill.value or 0).." / "..(skill.max or skill.maxValue or "?")) or "Not learned / not detected"
   details:SetText("|cffffd46a"..name.." - Gathering|r\n\nCurrent skill: "..progress.."\n\n"..gatheringNotes[name].."\n\nNo verified crafting or camp-object abilities have been collected for this profession.\n\nGatherable resources, minimum skill and zone information will appear here when a verified Forever resource dataset is available. No unverified locations are displayed.")
  else details:SetText("No recipes match your filters.") end
  footer:SetText(gathering and ("Gathering overview  |  "..( #recipes>0 and "Verified utility crafts shown" or "Resource database pending verification")) or ("Scroll to browse  |  Click headers to sort; Shift-click adds sort  |  Skill ? = unknown"))
 end
 search:SetScript("OnTextChanged",function() browser.page=1;browser.scrollOffset=0;browser.refresh() end)
 browser:Hide()
end
-- Settings UI and minimap launcher, using legacy-client UI primitives.
local function toggleSettings()
 if not settings then return end
 if settings:IsShown() then settings:Hide() else settings:Show() end
end
local function addCheck(parent,label,y,get,set)
 local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
 b:SetPoint("TOPLEFT",parent,"TOPLEFT",22,y); b:SetWidth(24); b:SetHeight(24)
 local t=parent:CreateFontString(nil,"OVERLAY","GameFontHighlight")
 t:SetPoint("LEFT",b,"RIGHT",5,0); t:SetText(label)
 b:SetScript("OnClick",function(self, arg1) set(self:GetChecked()==1 or self:GetChecked()==true); scanSkills(true) end)
 parent.checks=parent.checks or {}; table.insert(parent.checks,{button=b,get=get})
 return b
end
local function createBarPicker()
 barPicker=CreateFrame("Frame","PBFBarPicker",UIParent,"BackdropTemplate")
 barPicker:SetSize(350,460)
 barPicker:SetPoint("CENTER",UIParent,"CENTER",430,0)
 barPicker:SetFrameStrata("DIALOG")
 barPicker:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
 barPicker:EnableMouse(true);barPicker:SetMovable(true);barPicker:RegisterForDrag("LeftButton")
 barPicker:SetScript("OnDragStart",function(self) self:StartMoving() end)
 barPicker:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
 local title=barPicker:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 title:SetPoint("TOP",barPicker,"TOP",0,-18);title:SetText("Visible Skill Bars")
 makeButton(barPicker,"X",308,-12,25,function() barPicker:Hide() end)
 local hint=barPicker:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 hint:SetPoint("TOP",barPicker,"TOP",0,-45);hint:SetText("Check the bars you want to display.")
 barPicker.rows={}
 for i=1,12 do
  local cb=CreateFrame("CheckButton",nil,barPicker,"UICheckButtonTemplate")
  cb:SetSize(24,24);cb:SetPoint("TOPLEFT",barPicker,"TOPLEFT",23,-65-(i-1)*28)
  local label=barPicker:CreateFontString(nil,"OVERLAY","GameFontHighlight")
  label:SetPoint("LEFT",cb,"RIGHT",7,0)
  cb:SetScript("OnClick",function(self)
   if self.skillName then PBFDB.hiddenBars[self.skillName]=not self:GetChecked();redraw() end
  end)
  barPicker.rows[i]={check=cb,label=label}
 end
 barPicker.page=1
 local pageLabel=barPicker:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 pageLabel:SetPoint("BOTTOM",barPicker,"BOTTOM",0,45)
 barPicker.refresh=function(self)
  local names=sortedKeys(skills)
  local totalPages=math.max(1,math.ceil(#names/12))
  self.page=math.max(1,math.min(self.page,totalPages))
  for i,row in ipairs(self.rows) do
   local name=names[(self.page-1)*12+i]
   if name then
    row.check.skillName=name;row.check:SetChecked(not PBFDB.hiddenBars[name]);row.check:Show()
    row.label:SetText(name);row.label:Show()
   else row.check.skillName=nil;row.check:Hide();row.label:Hide() end
  end
  pageLabel:SetText("Page "..self.page.." of "..totalPages)
 end
 makeButton(barPicker,"<",40,-392,55,function() barPicker.page=barPicker.page-1;barPicker:refresh() end)
 makeButton(barPicker,">",245,-392,55,function() barPicker.page=barPicker.page+1;barPicker:refresh() end)
 barPicker:SetScript("OnShow",function(self) self:refresh() end)
 barPicker:Hide()
end
-- Editable numeric values: Enter or clicking away commits, Escape restores.
local function addNumericInput(parent, y, key, minimum, maximum, percent, integer)
 local edit=CreateFrame("EditBox",nil,parent,"InputBoxTemplate")
 edit:SetSize(54,22)
 edit:SetPoint("TOPLEFT",parent,"TOPLEFT",347,y)
 edit:SetAutoFocus(false)
 edit:SetMaxLetters(7)
 edit:SetJustifyH("CENTER")
 local function display()
  local v=PBFDB[key]
  if percent then return tostring(math.floor(v*100+0.5)) end
  if integer then return tostring(math.floor(v+0.5)) end
  return string.format("%.2f",v):gsub("0+$",""):gsub("%.$","")
 end
 local function commit(self)
  local n=tonumber(self:GetText())
  if n then
   if percent then n=n/100 end
   n=math.max(minimum,math.min(maximum,n))
   if integer then n=math.floor(n+0.5) end
   PBFDB[key]=n
   redraw()
  else
   chat("Invalid number; value restored.")
  end
  self:ClearFocus()
  parent:refresh()
 end
 edit:SetScript("OnEnterPressed",commit)
 edit:SetScript("OnEscapePressed",function(self) self:SetText(display());self:ClearFocus() end)
 edit:SetScript("OnEditFocusLost",function(self)
  if self:GetText()~=display() then commit(self) end
 end)
 edit.refresh=function(self)
  if not self:HasFocus() then self:SetText(display()) end
 end
 parent.numericInputs=parent.numericInputs or {}
 table.insert(parent.numericInputs,edit)
 edit:refresh()
 return edit
end
local function createSettings()
 settings=CreateFrame("Frame","PBFSettingsFrame",UIParent,"BackdropTemplate")
 settings:SetWidth(420);settings:SetHeight(660)
 settings:SetPoint("CENTER",UIParent,"CENTER",0,0)
 settings:SetFrameStrata("DIALOG")
 settings:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=32,insets={left=11,right=12,top=12,bottom=11}})
 settings:EnableMouse(true);settings:SetMovable(true);settings:RegisterForDrag("LeftButton")
 settings:SetScript("OnDragStart",function(self, arg1) self:StartMoving() end)
 settings:SetScript("OnDragStop",function(self, arg1) self:StopMovingOrSizing() end)
 local heading=settings:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
 heading:SetPoint("TOP",settings,"TOP",0,-19);heading:SetText("ProfessionBars Forever")
 local intro=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 intro:SetPoint("TOP",settings,"TOP",0,-48);intro:SetText("Drag bars when unlocked. Click the minimap button to reopen.")
 makeButton(settings,"X",380,-13,24,function(self, arg1) settings:Hide() end)
 makeButton(settings,"Compact Panel",22,-77,180,function(self, arg1) PBFDB.mode="compact";redraw();settings:refresh() end)
 makeButton(settings,"Individual Bars",218,-77,180,function(self, arg1) PBFDB.mode="individual";redraw();settings:refresh() end)
 local mode=settings:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
 mode:SetPoint("TOP",settings,"TOP",0,-109)
 settings.modeLabel=mode
 addCheck(settings,"Show optional weapon skills",-131,function(self, arg1) return PBFDB.weapons end,function(v) PBFDB.weapons=v end)
 addCheck(settings,"Flash and +1 on skill gains",-161,function(self, arg1) return PBFDB.glow end,function(v) PBFDB.glow=v; if not v then for _,bar in pairs(bars) do bar.gainTime=0;bar.flash:Hide();bar.gainShine:SetAlpha(0);bar.gainBorder:SetAlpha(0);bar.gainFillStart=nil;bar.gainFillTarget=nil;bar:SetBackdropBorderColor(0.55,0.47,0.32,0.95) end;redraw() end end)
 addCheck(settings,"Lock bar positions",-191,function(self, arg1) return PBFDB.locked end,function(v) PBFDB.locked=v end)
 local width=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 width:SetPoint("TOPLEFT",settings,"TOPLEFT",25,-229);settings.widthLabel=width
 makeButton(settings,"-",245,-221,42,function(self, arg1) PBFDB.width=math.max(180,PBFDB.width-20);redraw();settings:refresh() end)
 makeButton(settings,"+",295,-221,42,function(self, arg1) PBFDB.width=math.min(400,PBFDB.width+20);redraw();settings:refresh() end)
 local barScale=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 barScale:SetPoint("TOPLEFT",settings,"TOPLEFT",25,-263);settings.barScaleLabel=barScale
 makeButton(settings,"-",245,-255,42,function() PBFDB.barScale=math.max(0.5,math.floor((PBFDB.barScale-0.1)*10+0.5)/10);redraw();settings:refresh() end)
 makeButton(settings,"+",295,-255,42,function() PBFDB.barScale=math.min(2.5,math.floor((PBFDB.barScale+0.1)*10+0.5)/10);redraw();settings:refresh() end)
 local barOpacity=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 barOpacity:SetPoint("TOPLEFT",settings,"TOPLEFT",25,-297);settings.barOpacityLabel=barOpacity
 makeButton(settings,"-",245,-289,42,function() PBFDB.barOpacity=math.max(0.2,math.floor(PBFDB.barOpacity*20+0.5)/20-0.05);redraw();settings:refresh() end)
 makeButton(settings,"+",295,-289,42,function() PBFDB.barOpacity=math.min(1,math.floor(PBFDB.barOpacity*20+0.5)/20+0.05);redraw();settings:refresh() end)
 local panelOpacity=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 panelOpacity:SetPoint("TOPLEFT",settings,"TOPLEFT",25,-331);settings.panelOpacityLabel=panelOpacity
 makeButton(settings,"-",245,-323,42,function() PBFDB.panelOpacity=math.max(0,math.floor(PBFDB.panelOpacity*20+0.5)/20-0.05);redraw();settings:refresh() end)
 makeButton(settings,"+",295,-323,42,function() PBFDB.panelOpacity=math.min(1,math.floor(PBFDB.panelOpacity*20+0.5)/20+0.05);redraw();settings:refresh() end)
 addNumericInput(settings,-221,"width",180,400,false,true)
 addNumericInput(settings,-255,"barScale",0.5,2.5,false,false)
 addNumericInput(settings,-289,"barOpacity",0.2,1,true,true)
 addNumericInput(settings,-323,"panelOpacity",0,1,true,true)
 addCheck(settings,"Show panel title",-364,function() return PBFDB.showTitle end,function(v) PBFDB.showTitle=v;titleVisible=nil;refreshHover();redraw() end)
 addCheck(settings,"Title only on hover",-393,function() return PBFDB.titleOnHover end,function(v) PBFDB.titleOnHover=v;titleVisible=nil;refreshHover();redraw() end)
 addCheck(settings,"Show category labels (compact panel)",-422,function() return PBFDB.showGroupLabels end,function(v) PBFDB.showGroupLabels=v;redraw() end)
 local groupLabelSize=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 groupLabelSize:SetPoint("TOPLEFT",settings,"TOPLEFT",25,-456);settings.groupLabelSizeLabel=groupLabelSize
 makeButton(settings,"-",245,-448,42,function() PBFDB.groupLabelScale=math.max(0.7,math.floor((PBFDB.groupLabelScale-0.1)*10+0.5)/10);redraw();settings:refresh() end)
 makeButton(settings,"+",295,-448,42,function() PBFDB.groupLabelScale=math.min(2,math.floor((PBFDB.groupLabelScale+0.1)*10+0.5)/10);redraw();settings:refresh() end)
 makeButton(settings,"Recipe Browser",22,-543,180,function(self, arg1) settings:Hide();browser.refresh();browser:Show();focusFloatingWindow(browser) end)
 makeButton(settings,"Reset Positions",218,-543,180,function(self, arg1) PBFDB.positions={};setPosition(panel,"panel",0,80);redraw();chat("Bar positions reset") end)
 makeButton(settings,"Choose Visible Bars",22,-493,376,function() barPicker:Show();barPicker:refresh() end)
 local note=settings:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
 note:SetPoint("TOP",settings,"TOP",0,-591);note:SetWidth(375)
 note:SetText("Missing recipes, zone sources and trainer locations require verified server data.")
 settings.refresh=function(self, arg1) settings.modeLabel:SetText("Display: "..PBFDB.mode)
  settings.widthLabel:SetText("Bar width: "..PBFDB.width)
  settings.barScaleLabel:SetText("Bar height scale: "..PBFDB.barScale)
  settings.barOpacityLabel:SetText("Bar opacity: "..math.floor(PBFDB.barOpacity*100+0.5).."%")
  settings.groupLabelSizeLabel:SetText("Category label size: "..math.floor(PBFDB.groupLabelScale*100+0.5).."%")
  settings.panelOpacityLabel:SetText("Panel opacity: "..math.floor(PBFDB.panelOpacity*100+0.5).."%")
  for _,c in ipairs(settings.checks) do c.button:SetChecked(c.get()) end
  for _,edit in ipairs(settings.numericInputs or {}) do edit:refresh() end
 end
 settings:SetScript("OnShow",function(self) self:refresh() end)
 settings:Hide()
end
local function placeMinimapButton()
 if not minimapButton then return end
 local angle=(PBFDB.minimapAngle or 225)*math.pi/180
 minimapButton:ClearAllPoints()
 minimapButton:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*108,math.sin(angle)*108)
 if PBFDB.minimapHidden then minimapButton:Hide() else minimapButton:Show() end
end
local function createMinimapButton()
 if not Minimap then return end
 minimapButton=CreateFrame("Button","PBFMinimapButton",Minimap)
 minimapButton:SetWidth(31);minimapButton:SetHeight(31);minimapButton:SetFrameStrata("MEDIUM")
 minimapButton:SetFrameLevel(Minimap:GetFrameLevel()+8)
 local icon=minimapButton:CreateTexture(nil,"ARTWORK")
 icon:SetWidth(19);icon:SetHeight(19);icon:SetPoint("CENTER",minimapButton,"CENTER",0,0)
 -- The built-in profession icon is a hammer/pick-style tradeskill symbol.
 icon:SetTexture("Interface\\AddOns\\ProfessionBarsForever\\ProfessionIcon.tga")
 local border=minimapButton:CreateTexture(nil,"OVERLAY")
 border:SetWidth(53);border:SetHeight(53);border:SetPoint("CENTER",minimapButton,"CENTER",10,-10)
 border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
 minimapButton:RegisterForClicks("LeftButtonUp","RightButtonUp")
 minimapButton:RegisterForDrag("LeftButton")
 minimapButton:SetScript("OnClick",function(self, arg1) if arg1=="RightButton" then browser.refresh();if browser:IsShown() then browser:Hide() else browser:Show() end
  else toggleSettings() end
 end)
 minimapButton:SetScript("OnDragStart",function(self, arg1) self.dragging=true end)
 minimapButton:SetScript("OnDragStop",function(self, arg1) self.dragging=false end)
 minimapButton:SetScript("OnUpdate",function(self, arg1) if not self.dragging then return end
  local x,y=GetCursorPosition();local scale=UIParent:GetEffectiveScale();x=x/scale;y=y/scale
  local mx,my=Minimap:GetCenter()
  local a=math.atan2 and math.atan2(y-my,x-mx) or math.atan(y-my,x-mx)
  PBFDB.minimapAngle=a*180/math.pi;placeMinimapButton()
 end)
 minimapButton:SetScript("OnEnter",function(self, arg1) GameTooltip:SetOwner(self,"ANCHOR_LEFT")
  GameTooltip:AddLine("ProfessionBars Forever")
  GameTooltip:AddLine("Left-click: Settings",1,1,1)
  GameTooltip:AddLine("Right-click: Recipes",1,1,1)
  GameTooltip:AddLine("Drag: Move around minimap",1,1,1)
  GameTooltip:Show()
 end)
 minimapButton:SetScript("OnLeave",function(self, arg1) GameTooltip:Hide() end)
 placeMinimapButton()
end
local function command(msg)
 msg=string.lower(msg or "")
 if msg=="" or msg=="help" or msg=="settings" then toggleSettings()
 elseif string.match(msg,"^wowhead%s+%d+$") or msg=="wowhead" then
  local id=tonumber(string.match(msg,"^wowhead%s+(%d+)$"))
  if id and id>0 and math.floor(id)==id then chat("Forever recipe lookup: https://www.wowhead.com/forever/spell="..id.." (verify this ID is a spell/recipe ID)")
  else chat("Usage: /profbar wowhead <recipe ID> (copy URL from chat)") end
 elseif msg=="capture" then captureRecipeSnapshot()
 elseif msg=="captures" then
  local snapshots=PBFAccountDB and PBFAccountDB.recipeCatalogs or {}
  local total=0
  for name,data in pairs(snapshots) do chat(name..": "..tostring(data.count or #(data.recipes or {})).." saved recipes");total=total+1 end
  if total==0 then chat("No saved recipes yet. Open a crafting profession to collect them automatically.") end
 elseif msg=="recipes" then if browser:IsShown() then browser:Hide() else browser.refresh();browser:Show();focusFloatingWindow(browser) end
 elseif msg=="minimap" then PBFDB.minimapHidden=not PBFDB.minimapHidden;placeMinimapButton();chat("Minimap icon "..(PBFDB.minimapHidden and "hidden" or "shown"))
 elseif msg=="mode compact" or msg=="mode individual" then PBFDB.mode=string.sub(msg,6);redraw();chat("Mode: "..PBFDB.mode)
 elseif msg=="weapons on" or msg=="weapons off" then PBFDB.weapons=(msg=="weapons on");scanSkills(true)
 elseif msg=="glow on" or msg=="glow off" then PBFDB.glow=(msg=="glow on")
 elseif msg=="lock" then PBFDB.locked=true;chat("Bars locked")
 elseif msg=="unlock" then PBFDB.locked=false;chat("Bars unlocked")
 elseif string.match(msg,"^barscale%s+[%d%.]+$") then
  local v=tonumber(string.match(msg,"[%d%.]+"))
  if v then PBFDB.barScale=math.max(0.5,math.min(2.5,v));redraw();chat("Bar height scale: "..PBFDB.barScale) end
 elseif string.match(msg,"^opacity%s+[%d%.]+$") or string.match(msg,"^opacity%s+bars%s+[%d%.]+$") or string.match(msg,"^opacity%s+panel%s+[%d%.]+$") then
  local target,raw=string.match(msg,"^opacity%s+(%a+)%s+([%d%.]+)$")
  if not raw then raw=string.match(msg,"^opacity%s+([%d%.]+)$") end
  local v=tonumber(raw)
  if v then
   v=math.max(target=="bars" and 0.2 or 0,math.min(1,math.floor(v*20+0.5)/20))
   if target=="bars" then PBFDB.barOpacity=v
   elseif target=="panel" then PBFDB.panelOpacity=v
   else PBFDB.barOpacity=v;PBFDB.panelOpacity=v end
   redraw();chat("Opacity updated to "..math.floor(v*100+0.5).."%")
  end
 elseif msg=="title hover" or msg=="title always" or msg=="title off" then
  PBFDB.showTitle=(msg~="title off")
  if PBFDB.showTitle then PBFDB.titleOnHover=(msg=="title hover") end
  titleVisible=nil;refreshHover();redraw();chat("Title: "..(not PBFDB.showTitle and "hidden" or (PBFDB.titleOnHover and "hover only" or "always visible")))
 elseif msg=="refresh" then scanSkills(true);scanRecipes();chat("Profession scan refreshed ("..scanSource..")")
 elseif string.match(msg,"^craft%s+[%a%s]+$") then
  local n=string.match(msg,"^craft%s+(.+)$")
  if professions[n] then activeCraftProfession=n;scanRecipes();chat("Recipe scan labeled: "..n) else chat("Unknown profession: "..tostring(n)) end
 elseif msg=="debug" then
  chat("Version 1.1.27; scan source: "..scanSource.."; bars: "..tostring(#sortedKeys(skills)).."; locked: "..tostring(PBFDB.locked).."; mode: "..PBFDB.mode)
  chat("Recipe scan: "..recipeScanSource.."; modern recipe API="..tostring(C_TradeSkillUI and type(C_TradeSkillUI.GetAllRecipeIDs)))
  chat("GetProfessions="..tostring(type(GetProfessions)).." GetProfessionInfo="..tostring(type(GetProfessionInfo)).." C_TradeSkillUI="..tostring(type(C_TradeSkillUI)))
  chat("Weapon API: C_SkillInfo="..tostring(type(C_SkillInfo)).." GetNumSkillLines="..tostring(type(GetNumSkillLines)))
  for name,v in pairs(skills) do chat(name.." "..v.value.."/"..v.max) end
 elseif msg=="reset" then PBFDB.positions={};setPosition(panel,"panel",0,80);redraw();chat("Positions reset")
 else chat("Use /profbar to open settings, /profbar recipes, or /profbar minimap") end
end
-- Register slash commands immediately so they work even if an initialization event was missed.
SLASH_PBF1="/profbar"
SLASH_PBF2="/pbf"
SlashCmdList["PBF"]=command
local initialized=false
local function initialize()
 if initialized then return end
 initialized=true
 defaults();seedVerifiedCatalogs();loadFirstSavedProfession();createPanel();createBrowser();if PBFCreateCatalogButton then PBFCreateCatalogButton(browser) end;createBarPicker();createSettings();createMinimapButton();scanSkills(true)
 chat("Loaded. Left-click minimap icon for settings; /profbar opens settings.")
end
-- Forever uses a modern client; legacy profession events may not exist.
-- Register only supported events so an unknown event cannot abort addon loading.
local events=CreateFrame("Frame")
local function safeRegister(name)
 local ok=pcall(function(self, arg1) events:RegisterEvent(name) end)
 return ok
end
safeRegister("VARIABLES_LOADED")
safeRegister("PLAYER_LOGIN")
safeRegister("SKILL_LINES_CHANGED")
safeRegister("SKILL_LINES_UPDATED")
safeRegister("SPELLS_CHANGED")
safeRegister("PLAYER_ENTERING_WORLD")
safeRegister("TRADE_SKILL_SHOW")
safeRegister("TRADE_SKILL_UPDATE")
safeRegister("CRAFT_SHOW")
safeRegister("CRAFT_UPDATE")
safeRegister("TRADE_SKILL_DATA_SOURCE_CHANGED")
safeRegister("TRADE_SKILL_LIST_UPDATE")
events:SetScript("OnEvent",function(self,ev)
 local e=ev
 if e=="VARIABLES_LOADED" or e=="PLAYER_LOGIN" then initialize()
 elseif e=="SKILL_LINES_CHANGED" or e=="SKILL_LINES_UPDATED" or e=="SPELLS_CHANGED" or e=="PLAYER_ENTERING_WORLD" then
  if initialized then scanSkills(false);if browser and browser:IsShown() then browser.refresh() end end
 elseif e=="TRADE_SKILL_SHOW" or e=="TRADE_SKILL_UPDATE" or e=="TRADE_SKILL_LIST_UPDATE" or e=="TRADE_SKILL_DATA_SOURCE_CHANGED" or e=="CRAFT_SHOW" or e=="CRAFT_UPDATE" then
  if initialized then scanSkills(false);scanRecipes() end
 end
end)

-- Low-frequency refresh covers skill changes when a client event is unavailable.
local refreshTimer=CreateFrame("Frame")
local elapsedRefresh=0
refreshTimer:SetScript("OnUpdate",function(self,elapsed)
 if not initialized then return end
 elapsedRefresh=elapsedRefresh+elapsed
 if elapsedRefresh>=3 then elapsedRefresh=0;scanSkills(false); if (ProfessionsFrame and ProfessionsFrame:IsShown()) or (TradeSkillFrame and TradeSkillFrame:IsShown()) or (CraftFrame and CraftFrame:IsShown()) then scanRecipes() end end
end)
