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
