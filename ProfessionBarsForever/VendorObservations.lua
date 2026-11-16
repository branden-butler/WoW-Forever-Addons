-- Original ProfessionBars observation collector. No external database is bundled.
-- This module never changes recipe learned/missing flags and never uploads data.
local ADDON = ...
local Collector = {}
PBFObservationCollector = Collector
local SCHEMA, LIMIT, PAGE_SIZE = 1, 20000, 200
local active, generation, pending, visitSeen = nil, 0, false, {}
local frame = CreateFrame("Frame")
local function number(v)
 if type(v)=="number" and v==v and v~=math.huge and v~=-math.huge then return v end
end
local function text(v)
 if type(v)=="string" and #v<=256 then return v end
end
local function integer(v)
 v=number(v);if v and v==math.floor(v) then return v end
end
local function positive(v)
 v=integer(v);if v and v>0 then return v end
end
local function json(value)
 local kind=type(value)
 if kind=="string" then
  return '"'..value:gsub('[%z\1-\31\\"]',function(c)
   if c=='"' then return '\\"' elseif c=='\\' then return '\\\\' end
   return string.format("\\u%04x",string.byte(c))
  end)..'"'
 elseif kind=="number" then assert(number(value),"Invalid number");return tostring(value)
 elseif kind=="boolean" then return value and "true" or "false"
 elseif kind=="table" then
  local out={}
  -- Internal arrays are tagged; empty arrays must remain [].
  if value.__array then
   for i=1,#value do out[#out+1]=json(value[i]) end
   return "["..table.concat(out,",").."]"
  end
  local keys={}
  for k in pairs(value) do if k~="__array" then keys[#keys+1]=k end end
  table.sort(keys)
  for _,k in ipairs(keys) do out[#out+1]=json(k)..":"..json(value[k]) end
  return "{"..table.concat(out,",").."}"
 end
 error("Unsupported export value")
end
local function db()
 local d=PBFObservationDB
 if type(d)=="table" and d.schemaVersion==SCHEMA and type(d.records)=="table" then return d end
end
local function now()
 return (GetServerTime and GetServerTime()) or time()
end
local function message(s)
 print("|cffffd100ProfessionBars data:|r "..s)
end
-- Export and storage use this same explicit allowlist, never a SavedVariables dump.
local function clean(v)
 if type(v)~="table" or v.kind~="vendor_item" then return end
 local r={kind="vendor_item",evidence="observed",clientVersion=text(v.clientVersion),
  clientBuild=text(v.clientBuild),interfaceVersion=positive(v.interfaceVersion),
  locale=text(v.locale),npcID=positive(v.npcID),npcName=text(v.npcName),
  itemID=positive(v.itemID),itemName=text(v.itemName),faction=text(v.faction),
  priceCopper=integer(v.priceCopper),purchaseQuantity=positive(v.purchaseQuantity),
  available=integer(v.available),itemClassID=integer(v.itemClassID),
  itemSubclassID=integer(v.itemSubclassID)}
 if not r.npcID or not r.itemID or not r.clientBuild then return end
 if r.priceCopper and r.priceCopper<0 then r.priceCopper=nil end
 if r.available and r.available < -1 then r.available=nil end
 if type(v.purchasable)=="boolean" then r.purchasable=v.purchasable end
 if type(v.hasExtendedCost)=="boolean" then r.hasExtendedCost=v.hasExtendedCost end
 if r.itemClassID then r.isRecipeItem=(r.itemClassID==9) end
 if type(v.location)=="table" then
  local p=v.location;local mapID,x,y=positive(p.mapID),number(p.x),number(p.y)
  if mapID and x and y and x>=0 and x<=1 and y>=0 and y<=1 then
   r.location={mapID=mapID,x=x,y=y,positionType="observer"}
  end
 end
 -- Extended costs are intentionally not interpreted in v1.
 -- hasExtendedCost=true means copper alone is NOT the full cost.
 return r
end
local function captureContext()
 local guid=UnitGUID and UnitGUID("npc")
 local id=guid and (guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
  or guid:match("^Vehicle%-%d+%-%d+%-%d+%-%d+%-(%d+)%-"))
 if not positive(tonumber(id)) then return end
 local version,build,_,interface=GetBuildInfo()
 local r={npcID=tonumber(id),npcName=UnitName("npc"),clientVersion=version,
  clientBuild=tostring(build),interfaceVersion=interface,locale=GetLocale(),
  faction=UnitFactionGroup("player")}
 if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
  local mapID=C_Map.GetBestMapForUnit("player")
  local p=mapID and C_Map.GetPlayerMapPosition(mapID,"player")
  if p then
   local x,y=p:GetXY()
   -- Rounded player position near interaction, not an exact NPC spawn point.
   r.location={mapID=mapID,x=math.floor(x*10000+0.5)/10000,
    y=math.floor(y*10000+0.5)/10000}
  end
 end
 return r
end
local function merchantInfo(i)
 if C_MerchantFrame and C_MerchantFrame.GetItemInfo then
  local ok,info=pcall(C_MerchantFrame.GetItemInfo,i)
  if ok and type(info)=="table" then return info end
 end
 if GetMerchantItemInfo then
  local name,_,price,quantity,available,purchasable,_,extended=GetMerchantItemInfo(i)
  if name then return {name=name,price=price,stackCount=quantity,
   numAvailable=available,isPurchasable=purchasable,hasExtendedCost=extended} end
 end
end
local function record(raw)
 local d=db();local r=clean(raw);if not d or not r then return end
 local key=json(r);local existing=d.records[key]
 if existing then
  existing.lastSeen=now()
  if not visitSeen[key] then existing.observations=(positive(existing.observations) or 1)+1 end
 elseif (d.recordCount or 0)<LIMIT then
  d.records[key]={data=r,firstSeen=now(),lastSeen=now(),observations=1}
  d.recordCount=(d.recordCount or 0)+1
 else
  d.atCapacity=true
 end
 visitSeen[key]=true
end
local function scan()
 local d=db()
 if not active or not d or d.enabled==false then return end
 -- Never fall back to target: it may be a different NPC.
 local current=captureContext()
 if not current or current.npcID~=active.npcID then return end
 local count=GetMerchantNumItems and GetMerchantNumItems() or 0
 for i=1,count do
  local info=merchantInfo(i)
  local id=GetMerchantItemID and GetMerchantItemID(i)
  if not id and GetMerchantItemLink then
   local link=GetMerchantItemLink(i);id=link and tonumber(link:match("item:(%d+)"))
  end
  if info and id then
   local raw={}
   for k,v in pairs(active) do raw[k]=v end
   raw.kind="vendor_item";raw.itemID=id;raw.itemName=info.name
   raw.priceCopper=info.price;raw.purchaseQuantity=info.stackCount
   raw.available=info.numAvailable;raw.purchasable=info.isPurchasable
   raw.hasExtendedCost=info.hasExtendedCost
   local instant=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
   if instant then
    local _,_,_,_,_,classID,subclassID=instant(id)
    raw.itemClassID=classID;raw.itemSubclassID=subclassID
   end
   record(raw)
  end
 end
end
local function schedule()
 if pending or not active then return end
 pending=true;local token=generation
 C_Timer.After(0.25,function()
  if token~=generation then return end
  pending=false;scan()
 end)
end
local function stop()
 generation=generation+1;active=nil;pending=false;visitSeen={}
end
local function start()
 stop()
 local d=db();if not d or d.enabled==false then return end
 active=captureContext();if not active then return end
 schedule()
 local token=generation
 -- Bounded retries cover delayed item links and item classification.
 for delay=1,3 do
  C_Timer.After(delay,function() if token==generation then schedule() end end)
 end
end

-- Name matching is a review aid, never evidence of the spell an item teaches.
-- Resolve at read/export time so observations collected before this feature also work.
local function recipeCandidate(observation)
 if type(observation)~="table" or observation.itemClassID~=9 then return nil,"not_recipe" end
 if observation.locale~="enUS" and observation.locale~="enGB" then return nil,"unsupported_locale" end
 local itemName=observation.itemName
 if type(itemName)~="string" then return nil,"unmatched" end
 local wanted
 for _,prefix in ipairs({"Recipe:","Pattern:","Plans:","Schematic:","Formula:"}) do
  if itemName:sub(1,#prefix)==prefix then wanted=itemName:sub(#prefix+1);break end
 end
 if not wanted then return nil,"unmatched" end
 local function normalize(name)
  return (name:gsub("^%d+:%s*",""):gsub("^%s+",""):gsub("%s+$",""):gsub("%s+"," "):lower())
 end
 wanted=normalize(wanted)
 local catalog=PBFClientCatalog70862
 if type(catalog)~="table" or type(catalog.professions)~="table" then return nil,"catalog_unavailable" end
 local found,profession
 for prof,rows in pairs(catalog.professions) do
  for _,row in ipairs(rows) do
   if row[5]~=3 and type(row[4])=="string" and normalize(row[4])==wanted then
    if found and (found~=row[1] or profession~=prof) then return nil,"ambiguous" end
    found,profession=row[1],prof
   end
  end
 end
 if found then return found,"unique_name_candidate",profession end
 return nil,"unmatched"
end
function Collector:GetRecipeCandidate(observation)
 return recipeCandidate(observation)
end
function Collector:GetVendorCandidateSummary(spellID)
 local d=db();if not d then return end
 local _,build=GetBuildInfo()
 local matches,seen={},{}
 for _,saved in pairs(d.records) do
  local r=type(saved)=="table" and clean(saved.data)
  if r and r.clientBuild==tostring(build) then
   local candidate,status=recipeCandidate(r)
   if candidate==spellID and status=="unique_name_candidate" then
    local identity=tostring(r.npcID)..":"..r.itemID
    if not seen[identity] then
     seen[identity]=true
     matches[#matches+1]={npcID=r.npcID,itemID=r.itemID,name=r.npcName or ("NPC "..r.npcID)}
    end
   end
  end
 end
 if #matches==0 then return end
 table.sort(matches,function(a,b)
  if a.npcID~=b.npcID then return a.npcID<b.npcID end
  return a.itemID<b.itemID
 end)
 local lines={"\n\n|cffffaa55Observed vendor candidates (name match only):|r"}
 for i=1,math.min(2,#matches) do
  local r=matches[i]
  lines[#lines+1]=r.name.." (NPC "..r.npcID..", recipe item "..r.itemID..")"
 end
 if #matches>2 then lines[#lines+1]="+"..(#matches-2).." more; see /pbfdata export" end
 return table.concat(lines,"\n")
end

function Collector:GetExport(page)
 local d=db();if not d then return nil,"Observation database unavailable or from a newer schema." end
 local keys={}
 for key in pairs(d.records) do keys[#keys+1]=key end
 table.sort(keys)
 local pages=math.max(1,math.ceil(#keys/PAGE_SIZE))
 page=tonumber(page) or 1
 if page~=math.floor(page) or page<1 or page>pages then return nil,"Page must be between 1 and "..pages.."." end
 local rows={__array=true}
 for i=(page-1)*PAGE_SIZE+1,math.min(page*PAGE_SIZE,#keys) do
  local saved=d.records[keys[i]]
  if type(saved)=="table" then
   local r=clean(saved.data)
   if r then
    if r.itemClassID==9 then
     local id,status,profession=recipeCandidate(r)
     r.mappingStatus=status
     if id then r.candidateSpellID=id;r.candidateProfession=profession end
    end
    r.firstSeen=positive(saved.firstSeen);r.lastSeen=positive(saved.lastSeen)
    r.observations=positive(saved.observations) or 1
    rows[#rows+1]=r
   end
  end
 end
 return json({format="professionbars-observations",schemaVersion=SCHEMA,
  page=page,totalPages=pages,storedRecords=#keys,observations=rows}),pages
end
local exportFrame
local function showExport(page)
 local payload,pages=Collector:GetExport(page)
 if not payload then message(pages);return end
 if not exportFrame then
  local f=CreateFrame("Frame","PBFObservationExportFrame",UIParent,"BasicFrameTemplateWithInset")
  f:SetSize(650,460);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG")
  f.TitleText:SetText("ProfessionBars - Game data export")
  local note=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  note:SetPoint("TOPLEFT",15,-32);note:SetWidth(615);note:SetJustifyH("LEFT")
  note:SetText("Review before sharing. Ctrl+A, Ctrl+C to copy. No upload occurs. Use /pbfdata export N for another page.")
  local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT",15,-65);scroll:SetPoint("BOTTOMRIGHT",-35,20)
  local edit=CreateFrame("EditBox",nil,scroll)
  edit:SetMultiLine(true);edit:SetAutoFocus(false);edit:SetFontObject(ChatFontNormal)
  edit:SetWidth(590);edit:SetMaxLetters(0)
  edit:SetScript("OnEscapePressed",function(self) self:ClearFocus();f:Hide() end)
  scroll:SetScrollChild(edit);f.edit=edit;f.scroll=scroll
  exportFrame=f
 end
 exportFrame:Show();exportFrame.edit:SetText(payload)
 exportFrame.scroll:SetVerticalScroll(0);exportFrame.edit:SetFocus();exportFrame.edit:HighlightText()
 message("Export page "..(tonumber(page) or 1).." of "..pages..". Review and copy; nothing has been sent.")
end
SLASH_PBFOBSERVATIONS1="/pbfdata"
SlashCmdList.PBFOBSERVATIONS=function(input)
 local command,arg=(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
 command=command:lower()
 local d=db()
 if command=="export" then showExport(arg~="" and arg or 1)
 elseif command=="off" and d then d.enabled=false;stop();message("Automatic local collection disabled. Existing observations retained.")
 elseif command=="on" and d then d.enabled=true;message("Automatic local collection enabled. Open a vendor shop to collect.")
 else
  message(d and ((d.enabled==false and "Disabled" or "Enabled").."; "..(d.recordCount or 0).." / "..LIMIT.." observations stored"..(d.atCapacity and " (at capacity)" or "")..".") or "Database schema unsupported; data retained.")
  message("/pbfdata export [page], /pbfdata on, /pbfdata off. Local vendor observations only; no uploads.")
 end
end
frame:SetScript("OnEvent",function(self,event,name)
 if event=="ADDON_LOADED" then
  if name~=ADDON and name~="ProfessionBarsForever" then return end
  if PBFObservationDB==nil then PBFObservationDB={schemaVersion=SCHEMA,enabled=true,records={},recordCount=0} end
  local d=db()
  if d then
   local count=0;for _ in pairs(d.records) do count=count+1 end
   d.recordCount=count;d.atCapacity=count>=LIMIT
  end
 elseif event=="MERCHANT_SHOW" then start()
 elseif event=="MERCHANT_CLOSED" or event=="PLAYER_LEAVING_WORLD" then stop()
 elseif event=="MERCHANT_UPDATE" or event=="GET_ITEM_INFO_RECEIVED" then schedule()
 end
end)
for _,event in ipairs({"ADDON_LOADED","MERCHANT_SHOW","MERCHANT_CLOSED",
 "MERCHANT_UPDATE","GET_ITEM_INFO_RECEIVED","PLAYER_LEAVING_WORLD"}) do frame:RegisterEvent(event) end
