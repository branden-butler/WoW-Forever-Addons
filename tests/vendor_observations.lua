-- Run from repository root: lua5.1 tests/vendor_observations.lua
local frames,timers={},{}
local npcID,stock,price,itemID=12345,2,100,6326
local modern,cacheReady=true,true
local function noop() end
function CreateFrame()
 local f={RegisterEvent=noop}
 function f:SetScript(key,fn) self[key]=fn end
 frames[#frames+1]=f;return f
end
SlashCmdList={}
function UnitGUID(unit)
 assert(unit=="npc")
 return "Creature-0-1-2-3-"..npcID.."-0000000001"
end
function UnitName(unit) assert(unit=="npc");return "Test Vendor" end
function UnitFactionGroup() return "Horde" end
function GetBuildInfo() return "1.60.1","70862","date",16001 end
function GetLocale() return "enUS" end
local clock=100
function GetServerTime() clock=clock+1;return clock end
C_Map={
 GetBestMapForUnit=function() return 1456 end,
 GetPlayerMapPosition=function() return {GetXY=function() return 0.123456,0.789012 end} end
}
C_Timer={After=function(delay,fn) timers[#timers+1]=fn end}
function GetMerchantNumItems() return itemID and 1 or 0 end
function GetMerchantItemID() return cacheReady and itemID or nil end
function GetMerchantItemLink() return cacheReady and itemID and ("item:"..itemID) or nil end
function GetMerchantItemInfo()
 return "Recipe",0,price,1,stock,true,true,false
end
C_MerchantFrame={GetItemInfo=function()
 if not modern then return nil end
 return {name="Recipe",price=price,stackCount=1,numAvailable=stock,
 isPurchasable=true,hasExtendedCost=false}
end}
C_Item={GetItemInfoInstant=function(id) return id,"Recipe","Cooking","",0,9,5 end}
local function flush()
 local steps=0
 while #timers>0 do
  local batch=timers;timers={}
  for _,fn in ipairs(batch) do fn() end
  steps=steps+1;assert(steps<20,"timer loop")
 end
end
dofile("ProfessionBarsForever/VendorObservations.lua")
local f=frames[1]
local function event(e,...) f.OnEvent(f,e,...) end
event("ADDON_LOADED","ProfessionBarsForever")
assert(PBFObservationDB.schemaVersion==1 and PBFObservationDB.enabled)
-- No interaction, no collection.
event("MERCHANT_UPDATE");flush()
assert(PBFObservationDB.recordCount==0)
event("MERCHANT_SHOW");flush()
assert(PBFObservationDB.recordCount==1)
local key,saved=next(PBFObservationDB.records)
assert(saved.data.npcID==12345 and saved.data.itemID==6326)
assert(saved.data.location.positionType=="observer")
assert(saved.data.location.x==0.1235)
assert(saved.data.isRecipeItem==true)
assert(saved.observations==1,"retries must not inflate visits")
event("MERCHANT_UPDATE");flush()
assert(saved.observations==1)
event("MERCHANT_CLOSED")
event("MERCHANT_SHOW");flush()
assert(saved.observations==2,"new visit counted")
-- Out-of-stock and price changes are preserved as separate observations.
stock=0;price=80;event("MERCHANT_UPDATE");flush()
assert(PBFObservationDB.recordCount==2)
-- Empty or filtered inventories never remove earlier positive evidence.
itemID=nil;event("MERCHANT_UPDATE");flush()
assert(PBFObservationDB.recordCount==2)
-- Closing a window cancels queued collection.
itemID=999;event("MERCHANT_SHOW");event("MERCHANT_CLOSED");flush()
assert(PBFObservationDB.recordCount==2)
-- NPC changes cannot contaminate the original vendor.
event("MERCHANT_SHOW");npcID=777;flush()
assert(PBFObservationDB.recordCount==2)
-- Modern unavailable -> legacy fallback, delayed item links.
modern=false;cacheReady=false;event("MERCHANT_SHOW");flush()
assert(PBFObservationDB.recordCount==2)
cacheReady=true;event("GET_ITEM_INFO_RECEIVED");flush()
assert(PBFObservationDB.recordCount==3)
event("MERCHANT_CLOSED")
-- Only allowlisted fields can leave the database, even if unrelated saved fields exist.
PBFObservationDB.playerName="DO_NOT_EXPORT"
saved.data.characterName="DO_NOT_EXPORT"
saved.data.location.realm="DO_NOT_EXPORT"
saved.accountID="DO_NOT_EXPORT"
saved.data.npcName='Vendor "quote"\\slash\nline'
local payload,pages=PBFObservationCollector:GetExport(1)
assert(payload and pages==1 and not payload:find("DO_NOT_EXPORT",1,true))
assert(payload:find('\\"quote\\"',1,true))
assert(payload:find("\\u000a",1,true))
assert(not PBFObservationCollector:GetExport(0))
local output=assert(io.open("/tmp/pbf-observations-test.json","w"))
output:write(payload);output:close()
-- Disable does not delete observations and prevents future collection.
SlashCmdList.PBFOBSERVATIONS("off")
itemID=1000;event("MERCHANT_SHOW");flush()
assert(PBFObservationDB.recordCount==3)
SlashCmdList.PBFOBSERVATIONS("on")
event("MERCHANT_SHOW");flush()
assert(PBFObservationDB.recordCount==4)
-- Bounded storage, while existing records remain refreshable.
PBFObservationDB.recordCount=20000
itemID=1001;event("MERCHANT_UPDATE");flush()
assert(PBFObservationDB.recordCount==20000 and PBFObservationDB.atCapacity)
-- Pagination and empty arrays stay valid JSON.
PBFObservationDB.records={}
PBFObservationDB.recordCount=0
payload,pages=PBFObservationCollector:GetExport(1)
assert(payload:find('"observations":[]',1,true) and pages==1)
for i=1,201 do
 PBFObservationDB.records[tostring(i)]={data={kind="vendor_item",npcID=1,itemID=i,clientBuild="70862"}}
end
payload,pages=PBFObservationCollector:GetExport(2)
assert(pages==2 and payload:find('"page":2',1,true))
assert(not PBFObservationCollector:GetExport(3))
-- Unknown future schemas are retained and never overwritten or exported.
PBFObservationDB={schemaVersion=99,records={keep=true}}
event("ADDON_LOADED","ProfessionBarsForever")
event("MERCHANT_SHOW");flush()
assert(PBFObservationDB.schemaVersion==99 and PBFObservationDB.records.keep)
assert(not PBFObservationCollector:GetExport())
print("Vendor observation tests passed")


-- Matching works on already-collected recipe items, with no purchase/learning event.
PBFClientCatalog70862={professions={Cooking={
 {7753,1,1,"Longjaw Mud Snapper",1,{4592}},
 {7827,2,1,"Rainbow Fin Albacore",1,{5095}}
}}}
local recipe={kind="vendor_item",clientBuild="70862",locale="enUS",
 itemClassID=9,itemID=6328,itemName="Recipe: Longjaw Mud Snapper",npcID=5748,npcName="Killian Sanatha"}
local id,status,profession=PBFObservationCollector:GetRecipeCandidate(recipe)
assert(id==7753 and status=="unique_name_candidate" and profession=="Cooking")
PBFObservationDB={schemaVersion=1,records={test={data=recipe}},recordCount=1}
local export=PBFObservationCollector:GetExport(1)
assert(export:find('"candidateSpellID":7753',1,true))
assert(export:find('"mappingStatus":"unique_name_candidate"',1,true))
assert(PBFObservationCollector:GetVendorCandidateSummary(7753):find("Killian Sanatha",1,true))
-- Same ID repeated is not ambiguity; distinct IDs with same name are.
table.insert(PBFClientCatalog70862.professions.Cooking,{7753,3,1,"Longjaw Mud Snapper",1,{4592}})
assert(PBFObservationCollector:GetRecipeCandidate(recipe)==7753)
table.insert(PBFClientCatalog70862.professions.Cooking,{999,4,1,"Longjaw Mud Snapper",1,{4592}})
id,status=PBFObservationCollector:GetRecipeCandidate(recipe)
assert(id==nil and status=="ambiguous")
assert(not PBFObservationCollector:GetVendorCandidateSummary(7753))
PBFClientCatalog70862.professions.Cooking[4]=nil
recipe.locale="esMX"
id,status=PBFObservationCollector:GetRecipeCandidate(recipe)
assert(id==nil and status=="unsupported_locale")
recipe.locale="enUS";recipe.itemClassID=7
assert(not PBFObservationCollector:GetRecipeCandidate(recipe))
recipe.itemClassID=9;recipe.itemName="Recipe: Not In Catalog"
id,status=PBFObservationCollector:GetRecipeCandidate(recipe)
assert(id==nil and status=="unmatched")
-- Do not show a vendor observation from a different build.
recipe.itemName="Recipe: Longjaw Mud Snapper";recipe.clientBuild="other"
assert(not PBFObservationCollector:GetVendorCandidateSummary(7753))
print("Recipe candidate matching tests passed")
