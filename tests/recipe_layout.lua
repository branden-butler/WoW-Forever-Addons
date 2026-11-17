GetBuildInfo=function() return "1.60.1","70938","date",16001 end
GetLocale=function() return "enUS" end
PBFAccountDB={}
dofile("ProfessionBarsForever/RecipeLayout.lua")
local layout=PBFRecipeLayout
local schematics={
 [100]={recipeID=100,reagentSlotSchematics={
  {quantityRequired=2,required=true,reagents={{itemID=10940}}},
  {quantityRequired=1,required=false,reagents={{itemID=1000},{itemID=1001}}}
 }},
 [101]={recipeID=101,reagentSlotSchematics={{quantityRequired=1,required=true,reagents={{currencyID=77}}}}}
}
C_TradeSkillUI={
 GetCategories=function() return {20,10} end,
 GetFilteredRecipeIDs=function() return {102,101,100} end,
 GetCategoryInfo=function(id) return {name=id==20 and "Rods" or "Chest Enchants",uiOrder=id==20 and 1 or 2} end,
 GetRecipeSchematic=function(id) return schematics[id] end
}
local order=layout:CaptureOrder()
layout:Capture(100,{categoryID=10},{Enchanting=true},order[100])
layout:Capture(101,{categoryID=10},{Enchanting=true},order[101])
layout:Capture(102,{categoryID=20},{Enchanting=true},order[102])
assert(not layout:Get("Cooking",100),"presentation leaked into another profession")
local recipes={{id=100,name="A"},{id=101,name="B"},{id=102,name="C"},{id=103,name="Unknown"}}
local rows=layout:BuildRows("Enchanting",recipes,true,{})
assert(rows[1].header and rows[1].name=="Rods")
assert(rows[2].id==102)
assert(rows[3].header and rows[3].name=="Chest Enchants")
assert(rows[4].id==101 and rows[5].id==100,"native recipe order not retained")
assert(rows[6].header and rows[6].name=="Uncategorized")
assert(rows[7].id==103)
local collapsed=layout:BuildRows("Enchanting",recipes,true,{["category:10"]=true})
assert(#collapsed==5 and collapsed[3].header)
assert(layout:BuildRows("Enchanting",recipes,false,{})==recipes,"flat view must retain user sort")
GetItemInfo=function(id) if id==10940 then return "Strange Dust" end end
local text=layout:ReagentText("Enchanting",100)
assert(text:find("2 x Strange Dust",1,true))
assert(text:find("Item 1000 OR Item 1001 (optional)",1,true))
assert(layout:ReagentText("Enchanting",101):find("Currency 77",1,true))
assert(layout:ReagentText("Enchanting",103):find("Not reported",1,true))
-- Partial responses must not erase a previously complete schematic or category.
C_TradeSkillUI.GetRecipeSchematic=function() return {reagentSlotSchematics={}} end
C_TradeSkillUI.GetCategoryInfo=function() return nil end
layout:Capture(100,{categoryID=10},{Enchanting=true})
assert(layout:Get("Enchanting",100).categoryName=="Chest Enchants")
assert(#layout:Get("Enchanting",100).reagents==2)
C_TradeSkillUI.GetRecipeSchematic=function()
 return {recipeID=100,reagentSlotSchematics={{quantityRequired=2,required=true,reagents={}}}}
end
layout:Capture(100,{},{Enchanting=true})
assert(#layout:Get("Enchanting",100).reagents==2)
-- A schematic for a different spell must never be copied.
C_TradeSkillUI.GetRecipeSchematic=function() return schematics[101] end
layout:Capture(100,{},{Enchanting=true})
assert(#layout:Get("Enchanting",100).reagents==2)
-- Saved data survives reopening; incompatible build/locale gets its own namespace.
local saved=PBFAccountDB
dofile("ProfessionBarsForever/RecipeLayout.lua")
layout=PBFRecipeLayout
assert(layout:Get("Enchanting",100).reagents[1].quantity==2)
GetLocale=function() return "esMX" end
assert(not layout:Get("Enchanting",100))
GetLocale=function() return "enUS" end
GetBuildInfo=function() return "1.60.1","new","date",16001 end
assert(not layout:Get("Enchanting",100))
-- Missing APIs still render catalog recipes under Uncategorized.
C_TradeSkillUI={}
layout:Capture(200,{},{Enchanting=true})
rows=layout:BuildRows("Enchanting",{{id=200,name="No metadata"}},true,{})
assert(rows[1].name=="Uncategorized" and rows[2].id==200)
print("Recipe grouping, client order, reagent persistence and fallback tests passed")

-- First click can render an ID; cache completion must refresh the same selection automatically.
GetBuildInfo=function() return "1.60.1","70938","date",16001 end
dofile("ProfessionBarsForever/RecipeLayout.lua")
layout=PBFRecipeLayout
local requests,loaded=0,false
GetItemInfo=nil
C_Item={
 GetItemNameByID=function(id) if loaded and id==10940 then return "Strange Dust" end end,
 RequestLoadItemDataByID=function() requests=requests+1 end
}
local first=layout:ReagentText("Enchanting",100)
assert(first:find("Item 10940",1,true))
local requestCount=requests
layout:ReagentText("Enchanting",100)
assert(requests==requestCount,"repeated rendering re-requested unresolved items")
assert(not layout:ItemDataReceived(123456789,true),"unrelated item caused refresh")
assert(not layout:ItemDataReceived(10940,false),"failed load caused refresh")
-- Wire the real main-addon event handler with only the UI surface mocked.
local sourceFile=assert(io.open("ProfessionBarsForever/ProfessionBarsForever.lua"))
local source=sourceFile:read("*a");sourceFile:close()
local start=assert(source:find("local itemDetailsRefreshPending=false",1,true))
local stop=assert(source:find("-- Low-frequency refresh",start,true))
local callback,timers
timers={}
local renders=0
local selected=100
local shown=true
local env=setmetatable({
 initialized=true,PBFRecipeLayout=layout,
 C_Timer={After=function(_,fn) timers[#timers+1]=fn end},
 events={SetScript=function(_,_,fn) callback=fn end},
 browser={IsShown=function() return shown end,refresh=function()
  renders=renders+1
  assert(selected==100,"cache callback changed recipe selection")
  local text=layout:ReagentText("Enchanting",100)
  assert(text:find("Strange Dust",1,true))
 end}
},{__index=_G})
local chunk=assert(loadstring(source:sub(start,stop-1)));setfenv(chunk,env);chunk()
loaded=true
callback(nil,"GET_ITEM_INFO_RECEIVED",10940,true)
callback(nil,"ITEM_DATA_LOAD_RESULT",1000,true)
assert(#timers==1,"item completion events were not coalesced")
timers[1]()
assert(renders==1)
assert(layout:ReagentText("Enchanting",100):find("Strange Dust",1,true))
callback(nil,"GET_ITEM_INFO_RECEIVED",123456789,true)
assert(renders==1 and #timers==1)
-- A closed window must not be reopened by an item callback.
shown=false
callback(nil,"GET_ITEM_INFO_RECEIVED",1001,true)
assert(#timers==1)
-- Legacy cache lookup still works when modern APIs are absent.
C_Item=nil
GetItemInfo=function(id) return "Legacy Name "..id end
assert(layout:ItemName(2000)=="Legacy Name 2000")
print("Async item-name resolution, automatic details refresh and legacy fallback tests passed")

-- Learning character level must remain separate from output use level and item level.
GetBuildInfo=function() return "1.60.1","level-tests","date",16001 end
GetLocale=function() return "enUS" end
local queriedLevel=20
C_Spell={GetSpellLevelLearned=function(id) return queriedLevel end}
C_Item={GetItemInfo=function(itemID)
 if itemID==501 then return "Output", "item:501",2,99,35 end
 if itemID==502 then return "No level output", "item:502",1,50,0 end
end}
local learning=layout:GetLearnLevel("Cooking",123)
assert(learning==20)
local use=layout:GetUseLevel("Cooking",123,501)
assert(use==35 and use~=99 and use~=learning)
assert(layout:UseLevelText("Cooking",123,{501}):find("Level required to use: 35",1,true))
assert(layout:UseLevelText("Cooking",123,{502}):find("Level required to use: None",1,true))
queriedLevel=0
assert(layout:GetLearnLevel("Cooking",124)==nil,"zero spell level was invented as no learning requirement")
assert(layout:GetLearnLevel("Cooking",123)==20,"empty learning data erased prior evidence")
queriedLevel=nil
C_Spell=nil
GetSpellLevelLearned=function() return 15 end
assert(layout:GetLearnLevel("Cooking",125)==15)
GetSpellLevelLearned=nil
assert(layout:GetLearnLevel("Cooking",126)==nil)
assert(layout:UseLevelText("Cooking",123,{}):find("no output item identified",1,true))
local multi=layout:UseLevelText("Cooking",123,{501,502})
assert(multi:find("Output: 35",1,true) and multi:find("No level output: None",1,true))
-- Saved use requirements remain available when item data isn't currently cached.
C_Item=nil;GetItemInfo=nil
local savedUse=layout:GetUseLevel("Cooking",123,501)
assert(savedUse==35)
-- An uncached output uses the same async completion path as reagent item names.
local loads=0
C_Item={RequestLoadItemDataByID=function(id) assert(id==503);loads=loads+1 end}
assert(layout:GetUseLevel("Cooking",123,503)==nil)
assert(layout:GetUseLevel("Cooking",123,503)==nil and loads==1)
assert(layout:ItemDataReceived(503,true))
C_Item.GetItemInfo=function() return "Loaded output","item:503",1,88,40 end
assert(layout:GetUseLevel("Cooking",123,503)==40)
-- Item level/quality alone never populate a usage requirement.
C_Item.GetItemInfo=function() return "Partial output","item:504",4,80 end
assert(layout:GetUseLevel("Cooking",123,504)==nil)
print("Learning vs output-use character-level tests passed")
