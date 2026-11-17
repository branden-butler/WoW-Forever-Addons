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
-- Item names arrive asynchronously; track only requested reagent IDs.
local pendingItems,cachedNames={},{}
function Layout:ItemName(id)
 if cachedNames[id] then return cachedNames[id] end
 local name=call(C_Item and C_Item.GetItemNameByID,id)
 if type(name)=="string" and name~="" then cachedNames[id]=name;pendingItems[id]=nil;return name end
 local firstRequest=pendingItems[id]==nil
 if firstRequest then pendingItems[id]="waiting" end
 -- GetItemInfo is also a cache-loading fallback on clients without RequestLoadItemDataByID.
 name=call((C_Item and C_Item.GetItemInfo) or GetItemInfo,id)
 if type(name)=="string" and name~="" then cachedNames[id]=name;pendingItems[id]=nil;return name end
 if firstRequest then call(C_Item and C_Item.RequestLoadItemDataByID,id) end
end
function Layout:ItemDataReceived(id,success)
 if not pendingItems[id] then return false end
 if success==false then pendingItems[id]="failed";return false end
 if pendingItems[id]=="ready" then return false end
 pendingItems[id]="ready"
 return true
end

function Layout:ReagentText(profession,id)
 local data=self:Get(profession,id)
 if not data or not data.reagents then return "\n\nReagents: Not reported by the client yet." end
 local lines={"\n\nReagents per craft:"}
 for _,slot in ipairs(data.reagents) do
  local choices={}
  for _,choice in ipairs(slot.choices) do
   if choice.itemID then
    local name=self:ItemName(choice.itemID)
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

-- Character learning level and output usage level are independent requirements.
local function nonnegative(v)
 return type(v)=="number" and v>=0 and v<math.huge and v==math.floor(v)
end
local function writeRequirement(profession,id,key,value)
 local d=database();if not d then return end
 d[profession]=d[profession] or {}
 d[profession][id]=d[profession][id] or {}
 d[profession][id][key]=value
end
function Layout:GetLearnLevel(profession,id)
 local get=(C_Spell and C_Spell.GetSpellLevelLearned) or GetSpellLevelLearned
 local level=call(get,id)
 if positive(level) then
  writeRequirement(profession,id,"learnLevel",level)
  writeRequirement(profession,id,"learnLevelSource","spell_level_learned")
  return level
 end
 -- Zero/absent spell-level values are not enough evidence to assert "no requirement".
 local record=self:Get(profession,id)
 return record and record.learnLevel or nil
end
function Layout:GetUseLevel(profession,id,itemID)
 local get=(C_Item and C_Item.GetItemInfo) or GetItemInfo
 if type(get)=="function" then
  local ok,name,link,quality,itemLevel,minimum=pcall(get,itemID)
  if ok and type(name)=="string" and name~="" and nonnegative(minimum) then
   local record=self:Get(profession,id) or {}
   local outputs=record.outputUseLevels or {}
   outputs[itemID]={level=minimum,name=name}
   writeRequirement(profession,id,"outputUseLevels",outputs)
   pendingItems[itemID]=nil
   return minimum,name
  end
 end
 local record=self:Get(profession,id)
 local saved=record and record.outputUseLevels and record.outputUseLevels[itemID]
 if saved then return saved.level,saved.name end
 if pendingItems[itemID]==nil then
  pendingItems[itemID]="waiting"
  call(C_Item and C_Item.RequestLoadItemDataByID,itemID)
 end
end
function Layout:UseLevelText(profession,id,outputIDs)
 if type(outputIDs)~="table" or #outputIDs==0 then
  return "\nLevel required to use: Not reported (no output item identified)"
 end
 local lines={}
 for _,itemID in ipairs(outputIDs) do
  local level,name=self:GetUseLevel(profession,id,itemID)
  local label=level~=nil and (level==0 and "None" or tostring(level)) or "Not reported"
  if #outputIDs==1 then return "\nLevel required to use: "..label end
  lines[#lines+1]=(name or ("Item "..itemID))..": "..label
 end
 return "\nLevel required to use (by output):\n"..table.concat(lines,"\n")
end

-- Populate presentation metadata when Finder opens, independently of learned-state scans.
function Layout:RefreshProfession(profession,recipes)
 local api=C_TradeSkillUI or {}
 if type(api.GetRecipeInfo)~="function" then return end
 local order=self:CaptureOrder()
 for _,recipe in ipairs(recipes or {}) do
  local saved=self:Get(profession,recipe.id)
  if not saved or not saved.categoryName or not saved.reagents then
   if PBFCharacterStore and PBFCharacterStore:BelongsToProfession(profession,recipe.id) then
    local info=call(api.GetRecipeInfo,recipe.id)
    if type(info)=="table" and (not info.recipeID or info.recipeID==recipe.id) then
     self:Capture(recipe.id,info,{[profession]=true},order[recipe.id])
    end
   end
  end
 end
end

-- Only summarize a recipe when every output has a reported, matching requirement.
function Layout:GetUseLevelSummary(profession,id,outputIDs)
 if type(outputIDs)~="table" or #outputIDs==0 then return nil,"?" end
 local common,missing,varies
 for _,itemID in ipairs(outputIDs) do
  local level=self:GetUseLevel(profession,id,itemID)
  if level==nil then missing=true
  elseif common==nil then common=level
  elseif common~=level then varies=true end
 end
 if missing then return nil,"?" end
 if varies then return nil,"Varies" end
 return common,common==0 and "None" or tostring(common)
end
