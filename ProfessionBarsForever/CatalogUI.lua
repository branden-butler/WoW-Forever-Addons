-- Read-only client candidate catalog. Independent of character recipe collection.
local function catalog() return PBFClientCatalog70862 end
local frame, results, selected, page, prof, query, searchMode
local catalogOffset=0
local lastFilterKey=nil
local searchModes={"Name + Spell ID","Spell ID","Ability ID","Output Item ID"}
local professions={"All","Alchemy","Blacksmithing","Cooking","Enchanting","Engineering","First Aid","Leatherworking","Tailoring"}
local function label(parent,text,x,y,width,font)
 local f=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlightSmall")
 f:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);f:SetWidth(width);f:SetJustifyH("LEFT");f:SetText(text);return f
end
local function button(parent,text,x,y,w,fn)
 local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
 b:SetSize(w,24);b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",fn);return b
end
local function displayName(s)
 -- Imported fallback names may begin with an output item ID (e.g. "13447: Elixir").
 -- Keep the raw catalog data unchanged; strip the prefix only for presentation.
 return tostring(s or ""):gsub("^%d+:%s*", "")
end
local function safeText(s) return tostring(s or ""):lower() end
local function matches(r, needle)
 if needle=="" then return true end
 local numeric=needle:match("^%s*(%d+)%s*$")
 if searchMode=="Spell ID" then return numeric~=nil and tostring(r[1])==numeric end
 if searchMode=="Ability ID" then return numeric~=nil and tostring(r[2])==numeric end
 if searchMode=="Output Item ID" then
  if not numeric or type(r[6])~="table" then return false end
  for _,id in ipairs(r[6]) do if tostring(id)==numeric then return true end end
  return false
 end
 return safeText(displayName(r[4])):find(needle,1,true)~=nil or (numeric~=nil and tostring(r[1])==numeric)
end
local function render()
 if not frame then return end
 local db=catalog();if not db then return end
 local needle=safeText(query)
 local filterKey=prof.."\031"..searchMode.."\031"..needle
 if filterKey~=lastFilterKey or not results then
 lastFilterKey=filterKey
 results={}
 for name,rows in pairs(db.professions) do
  if prof=="All" or prof==name then
   for _,r in ipairs(rows) do
    if matches(r,needle) then
     results[#results+1]={profession=name,record=r}
    end
   end
  end
 end
 table.sort(results,function(a,b)
  if a.profession~=b.profession then return a.profession<b.profession end
  if displayName(a.record[4])~=displayName(b.record[4]) then return displayName(a.record[4])<displayName(b.record[4]) end
  return a.record[1]<b.record[1]
 end)
 end -- Refilter and sort only when profession, search mode, or query changes.
 local maxOffset=math.max(0,#results-15)
 catalogOffset=math.max(0,math.min(catalogOffset,maxOffset))
 frame.summary:SetText(prof.."  |  "..#results.." candidate records  |  Scroll to browse")
 UIDropDownMenu_SetText(frame.profDropdown,"Profession: "..prof)
 frame.scrollbar:SetMinMaxValues(0,maxOffset)
 if math.abs(frame.scrollbar:GetValue()-catalogOffset)>0.01 then frame.scrollbar:SetValue(catalogOffset) end
 frame.scrollbar:SetShown(maxOffset>0)
 frame.upArrow:SetEnabled(maxOffset>0)
 frame.downArrow:SetEnabled(maxOffset>0)
 for i=1,15 do
  local entry=results[catalogOffset+i];local b=frame.rows[i]
  if entry then
   local r=entry.record
   b:SetText((r[5]==3 and "? " or "")..displayName(r[4]).." ("..r[1]..")")
   b:Show()
  else b:Hide() end
 end
 local entry=selected
 if entry then
  local r=entry.record;local db=catalog()
  local itemIDs=type(r[6])=="table" and table.concat(r[6],", ") or ""
  local evidence=db.nameEvidenceLabels[r[5]] or "unknown"
  local kind=db.kindLabels[r[3]] or "unknown"
  frame.details:SetText("|cffffd100"..displayName(r[4]).."|r\n\nProfession: "..entry.profession.."\nType: "..kind.."\nSpell ID: "..r[1].."\nAbility ID: "..tostring(r[2]).."\nOutput item IDs: "..(itemIDs~="" and itemIDs or "none").."\nName evidence: "..evidence.."\n\nRaw skill-up low/high: "..tostring(r[7]).." / "..tostring(r[8]).."\nRaw acquisition code: "..tostring(r[9]).."\nAssociation: "..(r[10] and "matched" or "needs review").."\n\n|cffffaa55Learning requirement and acquisition source NOT verified.|r")
 else frame.details:SetText("Select a candidate to inspect its IDs and raw metadata.\n\nThis catalog is read-only. It does not mark recipes learned or change your collection.") end
end
local function ensureFrame()
 if frame then return end
 frame=CreateFrame("Frame","PBFCandidateCatalogWindow",UIParent,"BackdropTemplate")
 frame:SetSize(900,580);frame:SetPoint("CENTER",UIParent,"CENTER",30,20)
 frame:SetFrameStrata("DIALOG");frame:SetMovable(true);frame:EnableMouse(true)
 frame:RegisterForDrag("LeftButton");frame:SetScript("OnDragStart",frame.StartMoving);frame:SetScript("OnDragStop",frame.StopMovingOrSizing)
 frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",edgeSize=28,insets={left=12,right=12,top=12,bottom=12}})
 frame:SetBackdropColor(0.065,0.052,0.044,1)
 label(frame,"Forever Client Recipe Candidates — 70862",25,-23,680,"GameFontNormalLarge")
 button(frame,"X",845,-16,29,function() frame:Hide() end)
 label(frame,"Unverified candidate data: no trainer, vendor, quest, drop, or learning-level claims.",25,-56,835)
 prof="All";page=1;query="";selected=nil;searchMode="Name + Spell ID"
 frame.profDropdown=CreateFrame("Frame","PBFClientProfessionDropdown",frame,"UIDropDownMenuTemplate")
 frame.profDropdown:SetPoint("TOPLEFT",frame,"TOPLEFT",5,-78)
 UIDropDownMenu_SetWidth(frame.profDropdown,195)
 UIDropDownMenu_Initialize(frame.profDropdown,function(self,level)
  for _,name in ipairs(professions) do
   local option=UIDropDownMenu_CreateInfo()
   option.text=name;option.checked=(prof==name)
   option.func=function() prof=name;catalogOffset=0;selected=nil;CloseDropDownMenus();render() end
   UIDropDownMenu_AddButton(option,level)
  end
 end)
 frame.modeButton=button(frame,"Search: Name + Spell ID",265,-83,183,function()
  local idx=1
  for i,v in ipairs(searchModes) do if v==searchMode then idx=i;break end end
  searchMode=searchModes[idx%#searchModes+1]
  frame.modeButton:SetText("Search: "..searchMode)
  catalogOffset=0;selected=nil;render()
 end)
 local search=CreateFrame("EditBox",nil,frame,"InputBoxTemplate")
 search:SetSize(250,23);search:SetPoint("TOPLEFT",frame,"TOPLEFT",455,-83)
 search:SetAutoFocus(false);search:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
 search:SetScript("OnTextChanged",function(self) query=self:GetText() or "";catalogOffset=0;selected=nil;render() end)
 frame.summary=label(frame,"",25,-122,850,"GameFontNormal")
 local listBg=CreateFrame("Frame",nil,frame,"BackdropTemplate")
 listBg:SetPoint("TOPLEFT",frame,"TOPLEFT",22,-150);listBg:SetSize(495,360)
 listBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});listBg:SetBackdropColor(0.12,0.10,0.08,0.95)
 frame.rows={}
 for i=1,15 do
  local b=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
  b:SetSize(455,22);b:SetPoint("TOPLEFT",frame,"TOPLEFT",32,-160-(i-1)*23)
  b:GetFontString():SetJustifyH("LEFT")
  local slot=i
  b:SetScript("OnClick",function()
   selected=results[catalogOffset+slot];render()
  end)
  frame.rows[i]=b
 end
 frame.scrollbar=CreateFrame("Slider","PBFClientCatalogScrollbar",frame,nil)
 frame.scrollbar:SetPoint("TOPLEFT",frame,"TOPLEFT",490,-195)
 frame.scrollbar:SetSize(16,276);frame.scrollbar:SetValueStep(1)
 -- Standalone slider: the Blizzard scroll template calls SetVerticalScroll
 -- on a scroll frame and is incompatible with our virtualized row list.
 frame.scrollbar:SetOrientation("VERTICAL")
 frame.scrollbar:EnableMouse(true)
 frame.scrollbar:SetFrameLevel(frame:GetFrameLevel()+8)
 frame.scrollbar:SetThumbTexture("Interface\\Buttons\\UI-ScrollBar-Knob")
 local thumb=frame.scrollbar:GetThumbTexture()
 if thumb then thumb:SetSize(24,24);thumb:SetDrawLayer("OVERLAY") end
 local track=frame.scrollbar:CreateTexture(nil,"BACKGROUND")
  track:SetAllPoints();track:SetTexture("Interface\\Buttons\\WHITE8X8")
  track:SetVertexColor(0.20,0.17,0.14,0.85)
  frame.scrollbar:SetHitRectInsets(-5,-5,0,0)
  frame.scrollbar:SetMinMaxValues(0,0)
 frame.scrollbar:SetValue(0)
 frame.scrollbar:SetScript("OnValueChanged",function(self,value)
  local offset=math.floor(value+0.5)
  if catalogOffset~=offset then catalogOffset=offset;render() end
 end)
 -- Arrow buttons operate the same standalone slider as mouse dragging.
 local function arrow(name,y,delta)
  local b=CreateFrame("Button",name,frame,"UIPanelScrollUpButtonTemplate")
  b:ClearAllPoints();b:SetPoint("TOPLEFT",frame,"TOPLEFT",487,y)
  if delta>0 then
   b:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
   b:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down")
   b:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled")
  end
  b:SetScript("OnClick",function() frame.scrollbar:SetValue(frame.scrollbar:GetValue()+delta) end)
  return b
 end
 frame.upArrow=arrow("PBFClientCatalogScrollUp",-169,-1)
 frame.downArrow=arrow("PBFClientCatalogScrollDown",-475,1)

 listBg:EnableMouseWheel(true)
 listBg:SetScript("OnMouseWheel",function(self,delta) catalogOffset=math.max(0,math.min(math.max(0,#results-15),catalogOffset-delta*3));render() end)
 local detailBg=CreateFrame("Frame",nil,frame,"BackdropTemplate")
 detailBg:SetPoint("TOPLEFT",frame,"TOPLEFT",530,-150);detailBg:SetSize(345,360)
 detailBg:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"});detailBg:SetBackdropColor(0.11,0.09,0.07,0.96)
 frame.details=label(detailBg,"",12,-15,320,"GameFontHighlightSmall")
 label(frame,"Mouse wheel or scrollbar to browse recipes. Client-derived candidates are unverified.",30,-526,825)
 frame:Hide()
end
function PBFToggleCandidateCatalog()
 ensureFrame()
 if frame:IsShown() then frame:Hide() else render();frame:Show();frame:Raise() end
end
function PBFCreateCatalogButton(recipeBrowser)
 if not recipeBrowser or recipeBrowser.PBFCatalogButton then return end
 -- Attach to existing recipe browser without changing its collection and status behavior.
 recipeBrowser.PBFCatalogButton=button(recipeBrowser,"Client Catalog (Preview)",0,0,190,PBFToggleCandidateCatalog)
 recipeBrowser.PBFCatalogButton:ClearAllPoints()
 recipeBrowser.PBFCatalogButton:SetPoint("TOPRIGHT",recipeBrowser,"TOPRIGHT",-42,-63)
end
SLASH_PBFCATALOG1="/pbfcatalog"
SlashCmdList.PBFCATALOG=PBFToggleCandidateCatalog
