-- Run from repository root: lua5.1 tests/character_store.lua
GetServerTime=function() return 1234 end
dofile("ProfessionBarsForever/CharacterStore.lua")
local store=PBFCharacterStore
local account={}
local legacy={recipeKnownByID={Alchemy={[1]=true,[2]=false}},
 recipeSnapshots={Alchemy={recipes={{id=3},{id=4,learned=true}}}}}
local a=store:Initialize(account,legacy,{guid="Player-A",name="Alpha",realm="Realm One"})
assert(a.knownByID.Alchemy[1]==true and a.knownByID.Alchemy[2]==false)
assert(a.knownByID.Alchemy[3]==nil and a.knownByID.Alchemy[4]==true)
store:RecordSkills({Alchemy={value=150,max=225,kind="profession"},Herbalism={value=140,max=225,kind="profession"}},"test")
store:RecordSkills({},"none")
assert(a.skills.Alchemy.value==150 and a.skills.Herbalism)
store:MergeRecipes("Alchemy",{{id=1,learned=false},{id=2,learned=true},{id=5},{id=6,learned=false}})
assert(a.knownByID.Alchemy[1] and a.knownByID.Alchemy[2])
assert(a.knownByID.Alchemy[5]==nil and a.knownByID.Alchemy[6]==false)
store:MergeRecipes("Alchemy",{})
assert(a.knownByID.Alchemy[1])
local bLegacy={}
local b=store:Initialize(account,bLegacy,{guid="Player-B",name="Beta",realm="Realm Two"})
store:RecordSkills({Tailoring={value=100,max=150,kind="profession"},Enchanting={value=80,max=150,kind="profession"}},"test")
store:MergeRecipes("Tailoring",{{id=10,learned=true}})
assert(b.knownByID.Alchemy==nil and b.skills.Alchemy==nil)
assert(a.knownByID.Tailoring==nil)
assert(store:KnownOn("Alchemy",1)[1]=="Alpha - Realm One")
assert(store:KnownOn("Tailoring",10)[1]=="Beta - Realm Two")
assert(#store:List()==2)
-- Simulate loading a saved account table with a new per-character session.
local function copy(v)
 if type(v)~="table" then return v end
 local out={};for k,x in pairs(v) do out[k]=copy(x) end;return out
end
account=copy(account)
dofile("ProfessionBarsForever/CharacterStore.lua")
store=PBFCharacterStore
legacy={}
a=store:Initialize(account,legacy,{guid="Player-A",name="Alpha",realm="Realm One"})
assert(a.knownByID.Alchemy[1] and a.skills.Alchemy.value==150)
assert(legacy.recipeKnownByID==a.knownByID)
assert(store:Get("Player-B").knownByID.Tailoring[10])
-- Exercise the real persistence/list-building/scan functions from the main addon.
local f=assert(io.open("ProfessionBarsForever/ProfessionBarsForever.lua"))
local source=f:read("*a");f:close()
local function extract(startText,endText)
 local start=assert(source:find(startText,1,true))
 local stop=assert(source:find(endText,start+1,true))
 return source:sub(start,stop-1)
end
local viewedKey
local open=false
local calls=0
local info={name="Test Recipe",learned=true}
local linked=false
local env=setmetatable({
 PBFDB=legacy,PBFAccountDB=account,PBFCharacterStore=store,
 PBFClientCatalog70862={professions={Alchemy={{1,1,1,"Test Recipe",1,{100}}}}},
 professions={Alchemy=true,Tailoring=true},
 recipeMetadata=function() return {} end,
 viewedProfile=function() return store:Get(viewedKey) end,
 viewingCurrentCharacter=function() return not viewedKey or viewedKey==store.currentKey end,
 clientCatalogRows=function(profession) return profession=="Alchemy" and {{1,1,1,"Test Recipe",1,{100}}} or nil end,
 catalogDisplayName=function(n) return n end,
 currentCraftName=function() return "Alchemy" end,
 recipeRequiredSkill=function() return nil end,
 ProfessionsFrame={IsShown=function() return open end},
 C_TradeSkillUI={
  GetAllRecipeIDs=function() calls=calls+1;return {1,6} end,
  GetRecipeInfo=function(id) if id==1 then return info else return {name="Missing",learned=false} end end,
  IsTradeSkillLinked=function() return linked end
 }
},{__index=_G})
legacy.known={};legacy.scanned={}
account.recipeCatalogs={}
local persist=extract("local function persistRecipes(","-- Seed only verified")
local load=extract("local function loadSavedRecipeSnapshot(","local function captureRecipeSnapshot(")
local scan=extract("local function scanRecipes()","local function makeButton(")
local chunk=assert(loadstring(persist..load..scan.."\nreturn {scan=scanRecipes,load=loadSavedRecipeSnapshot,get=function() return liveRecipes end}"))
setfenv(chunk,env)
local api=chunk()
-- Opening/closing the Recipe Finder only rebuilds lists, never resets learned flags.
for i=1,3 do
 assert(api.load("Alchemy"))
 assert(api.get().list[1].learned==true)
end
api.scan();assert(calls==0,"closed profession UI must not scan cached data")
open=true;api.scan();assert(calls==1 and a.knownByID.Alchemy[1])
info={name="Test Recipe"};api.scan()
assert(a.knownByID.Alchemy[1],"nil learned flag erased saved state")
info={name="Test Recipe",learned=false};api.scan()
assert(a.knownByID.Alchemy[1],"transient false erased positive evidence")
local before=calls;linked=true;api.scan();assert(calls==before)
linked=false
viewedKey="Player-B"
api.load("Tailoring")
local oldProfession=api.get().profession
info={name="Test Recipe",learned=true};api.scan()
assert(api.get().profession==oldProfession,"current scan switched selected alt")
assert(store:Get("Player-B").knownByID.Alchemy==nil,"current scan contaminated alt")
api.load("Alchemy")
local rows=api.get().list
for _,r in ipairs(rows) do assert(r.learned==nil,"current character flags leaked into alt view") end
viewedKey=nil;api.load("Alchemy")
local flags={}
for _,r in ipairs(api.get().list) do flags[r.id]=r.learned end
assert(flags[1]==true and flags[6]==false)
print("Character persistence and real scan integration tests passed")
