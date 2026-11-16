-- Original client-derived recipe presentation data. No inferred profession membership.
PBFRecipeLayout={}
local Layout=PBFRecipeLayout
local function call(fn,...)
 if type(fn)~="function" then return end
 local ok,value=pcall(fn,...)
 if ok then return value end
end
local function positive(v) return type(v)=="number" and v>0 and v<math.huge and v==math.floor(v) end
local function context()
 local _,build=GetBuildInfo()
 return tostring(build)..":"..GetLocale()
end
local function database()
 if not PBFAccountDB then return end
 PBFAccountDB.recipePresentation=PBFAccountDB.recipePresentation or {}
 local key=context()
 PBFAccountDB.recipePresentation[key]=PBFAccountDB.recipePresentation[key] or {}
 return PBFAccountDB.recipePresentation[key]
end
function Layout:Get(profession,id)
 local d=database()
 return d and d[profession] and d[profession][id]
end
function Layout:Capture(id,info,owners,recipeOrder)
 if type(info)~="table" or type(owners)~="table" then return end
 local api=C_TradeSkillUI or {}
 local update={}
 if positive(info.categoryID) then
  update.categoryID=info.categoryID
  local category=call(api.GetCategoryInfo,info.categoryID)
  if type(category)=="table" and type(category.name)=="string" and category.name~="" then
   update.categoryName=category.name
   if type(category.uiOrder)=="number" then update.categoryOrder=category.uiOrder end
   -- Keep the leaf group; retain parent info for future nested category views.
   update.parentCategoryID=category.parentCategoryID
  end
 end
 if recipeOrder then update.recipeOrder=recipeOrder end
 if update.categoryName and not update.categoryOrder and self.categoryRanks then update.categoryOrder=self.categoryRanks[info.categoryID] end
 local schematic=call(api.GetRecipeSchematic,id,false)
 if type(schematic)=="table" and (not schematic.recipeID or schematic.recipeID==id)
  and type(schematic.reagentSlotSchematics)=="table" and #schematic.reagentSlotSchematics>0 then
  local slots={}
  for _,slot in ipairs(schematic.reagentSlotSchematics) do
   if positive(slot.quantityRequired) and type(slot.reagents)=="table" then
    local choices={}
    for _,reagent in ipairs(slot.reagents) do
     if positive(reagent.itemID) then choices[#choices+1]={itemID=reagent.itemID}
     elseif positive(reagent.currencyID) then choices[#choices+1]={currencyID=reagent.currencyID} end
    end
    if #choices>0 then
     slots[#slots+1]={quantity=slot.quantityRequired,optional=slot.required==false,choices=choices}
    end
   end
  end
  -- Empty/partial responses never erase a previously populated schematic.
  if #slots==#schematic.reagentSlotSchematics then update.reagents=slots end
 end
 if not next(update) then return end
 local d=database();if not d then return end
 for profession in pairs(owners) do
  d[profession]=d[profession] or {}
  local record=d[profession][id] or {}
  for k,v in pairs(update) do record[k]=v end
  d[profession][id]=record
 end
end
function Layout:CaptureOrder()
 local api=C_TradeSkillUI or {}
 local order={}
 self.categoryRanks={}
 local categories=call(api.GetCategories)
 if type(categories)=="table" then
  for i,id in ipairs(categories) do if positive(id) then self.categoryRanks[id]=i end end
 end
 local ids=call(api.GetFilteredRecipeIDs)
 if type(ids)=="table" then
  for i,id in ipairs(ids) do if positive(id) then order[id]=i end end
 end
 return order
end
function Layout:BuildRows(profession,recipes,grouped,collapsed)
 if not grouped then return recipes end
 local groups={}
 for _,recipe in ipairs(recipes) do
  local meta=self:Get(profession,recipe.id) or {}
  local key=meta.categoryName and ("category:"..tostring(meta.categoryID)) or "uncategorized"
  local group=groups[key]
  if not group then
   group={header=true,key=key,name=meta.categoryName or "Uncategorized",order=meta.categoryOrder,recipes={}}
   groups[key]=group
  end
  group.recipes[#group.recipes+1]=recipe
 end
 local sorted={}
 for _,group in pairs(groups) do sorted[#sorted+1]=group end
 table.sort(sorted,function(a,b)
  if a.key=="uncategorized" then return false elseif b.key=="uncategorized" then return true end
  if (a.order~=nil)~=(b.order~=nil) then return a.order~=nil end
  if a.order and b.order and a.order~=b.order then return a.order<b.order end
  if a.name~=b.name then return a.name<b.name end
  return a.key<b.key
 end)
 local rows={}
 for _,group in ipairs(sorted) do
  table.sort(group.recipes,function(a,b)
   local ma,mb=self:Get(profession,a.id) or {},self:Get(profession,b.id) or {}
   if (ma.recipeOrder~=nil)~=(mb.recipeOrder~=nil) then return ma.recipeOrder~=nil end
   if ma.recipeOrder and mb.recipeOrder and ma.recipeOrder~=mb.recipeOrder then return ma.recipeOrder<mb.recipeOrder end
   if a.name~=b.name then return a.name<b.name end
   return a.id<b.id
  end)
  group.count=#group.recipes;rows[#rows+1]=group
  if not (collapsed and collapsed[group.key]) then
   for _,recipe in ipairs(group.recipes) do rows[#rows+1]=recipe end
  end
 end
 return rows
end
function Layout:ReagentText(profession,id)
 local data=self:Get(profession,id)
 if not data or not data.reagents then return "\n\nReagents: Not reported by the client yet." end
 local lines={"\n\nReagents per craft:"}
 for _,slot in ipairs(data.reagents) do
  local choices={}
  for _,choice in ipairs(slot.choices) do
   if choice.itemID then
    local get=(C_Item and C_Item.GetItemNameByID) or GetItemInfo
    local name=call(get,choice.itemID)
    choices[#choices+1]=name or ("Item "..choice.itemID)
   else choices[#choices+1]="Currency "..choice.currencyID end
  end
  lines[#lines+1]=slot.quantity.." x "..table.concat(choices," OR ")..(slot.optional and " (optional)" or "")
 end
 return table.concat(lines,"\n")
end

function Layout:Refresh(profession,id)
 if not PBFCharacterStore or not PBFCharacterStore:BelongsToProfession(profession,id) then return end
 local api=C_TradeSkillUI or {}
 local info=call(api.GetRecipeInfo,id)
 if type(info)=="table" and (not info.recipeID or info.recipeID==id) then
  self:Capture(id,info,{[profession]=true})
 end
end
