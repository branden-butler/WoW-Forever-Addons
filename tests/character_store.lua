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
assert(store:KnownOn("Alchemy",1)[1]=="Alpha")
assert(store:KnownOn("Tailoring",10)[1]=="Beta")
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
 PBFClientCatalog70862={professions={Alchemy={{1,1,1,"Test Recipe",1,{100}},{6,2,1,"Missing",1,{101}}},Tailoring={{10,3,1,"Tailoring Test",1,{102}}}}},
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
_G.PBFClientCatalog70862=env.PBFClientCatalog70862
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

-- Background positive detection works with all profession frames closed.
viewedKey=nil;open=false
local catalog={professions={Alchemy={{1},{7},{8}},Tailoring={{11}}}}
local function checkKnownSpells()
 local old=store:Get().knownByID.Alchemy[1]
 local changed,status=store:ScanKnownSpells(catalog)
 assert(status=="spell_queries")
 assert(store:Get().knownByID.Alchemy[7]==true)
 assert(store:Get().knownByID.Alchemy[8]==nil,"false/unsupported became Missing")
 assert(store:Get().knownByID.Alchemy[1]==old,"background check erased prior flags")
 assert(store:Get("Player-B").knownByID.Alchemy==nil,"alt contamination")
 return changed
end
IsPlayerSpell=function(id) return id==7 end
assert(checkKnownSpells()==1)
assert(checkKnownSpells()==0)
IsPlayerSpell=nil
-- Modern adapter; no overrides API is used.
store:Get().knownByID.Alchemy[7]=nil
C_SpellBook={IsSpellKnown=function(id) return id==7 end}
assert(checkKnownSpells()==1)
C_SpellBook=nil
store:Get().knownByID.Alchemy[7]=nil
IsSpellKnown=function(id,pet) assert(pet==false);return id==7 end
assert(checkKnownSpells()==1)
-- Failing queries cannot destroy evidence or abort scanning.
IsSpellKnown=function() error("not available on this build") end
local count=store:ScanKnownSpells(catalog);assert(count==0)
IsSpellKnown=nil
local _,status=store:ScanKnownSpells(catalog);assert(status=="unavailable")
-- Unclassified shared recipes must not acquire profession membership from a mislabeled cache.
account.recipeCatalogs.NewProfession={recipes={{id=456,name="New"}}}
IsPlayerSpell=function(id) return id==456 end
store:ScanKnownSpells(catalog)
assert(store:Get().knownByID.NewProfession==nil)
IsPlayerSpell=nil
print("Background known-spell tests passed")

-- Reproduce the reported mixed Cooking list using real catalog spell IDs.
dofile("ProfessionBarsForever/CatalogData.lua")
local real=PBFClientCatalog70862
assert(real and real.professions.Cooking)
account.recipeCatalogs={
 Cooking={recipes={
  {id=7751,name="Brilliant Smallfish"},
  {id=7934,name="Anti-Venom"},
  {id=3276,name="Heavy Linen Bandage"},
  {id=2331,name="Minor Mana Potion"},
  {id=999999999,name="Unclassified craft"}}}
}
a.knownByID.Cooking={[7751]=true,[7934]=true,[3276]=false,[2331]=true,[999999999]=true}
store:Get("Player-B").knownByID.Cooking={[7934]=false}
store:RepairRecipeBoundaries(real)
legacy.recipeKnownByID=a.knownByID
assert(a.knownByID.Cooking[7751]==true)
assert(a.knownByID.Cooking[7934]==nil)
assert(a.knownByID["First Aid"][7934]==true)
assert(a.knownByID["First Aid"][3276]==false)
assert(a.knownByID.Alchemy[2331]==true)
assert(a.unassignedKnownByID[999999999]==true)
assert(account.unassignedRecipeRows[999999999])
assert(store:Get("Player-B").knownByID["First Aid"][7934]==false,"repair crossed character boundaries")
assert(#account.recipeCatalogs.Cooking.recipes==1)
-- Repeated repair is idempotent and keeps unresolved evidence.
store:RepairRecipeBoundaries(real)
legacy.recipeKnownByID=a.knownByID
assert(#account.recipeCatalogs.Cooking.recipes==1 and a.unassignedKnownByID[999999999])
env.PBFClientCatalog70862=real
env.professions.Cooking=true;env.professions["First Aid"]=true
env.clientCatalogRows=function(p) return real.professions[p] end
env.C_TradeSkillUI.GetAllRecipeIDs=function() return {7751,7934,3276,2331,999999999} end
env.C_TradeSkillUI.GetRecipeInfo=function(id) return {name="Recipe "..id,learned=true} end
open=true;linked=false;viewedKey=nil
assert(api.load("Cooking"))
api.scan()
assert(api.get().profession=="Cooking","mixed scan switched selected profession")
assert(a.knownByID.Cooking[7934]==nil,"mixed scan recontaminated Cooking")
assert(a.knownByID["First Aid"][7934] and a.knownByID.Alchemy[2331])
for _,r in ipairs(api.get().list) do assert(store:BelongsToProfession("Cooking",r.id,real)) end
-- Recontaminate the shared cache deliberately: display and background still enforce boundaries.
account.recipeCatalogs.Cooking.recipes[#account.recipeCatalogs.Cooking.recipes+1]={id=7934,name="Anti-Venom"}
api.load("Cooking")
for _,r in ipairs(api.get().list) do assert(r.id~=7934) end
IsPlayerSpell=function(id) return id==7934 end
store:ScanKnownSpells(real)
assert(a.knownByID.Cooking[7934]==nil)
assert(a.knownByID["First Aid"][7934])
IsPlayerSpell=nil
print("Real-catalog boundary repair, mixed scans and background regression tests passed")
