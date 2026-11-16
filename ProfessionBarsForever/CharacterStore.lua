-- Local account-wide character snapshots. Never included in vendor exports.
PBFCharacterStore = {}
local Store=PBFCharacterStore
local function copy(value)
 if type(value)~="table" then return value end
 local out={};for k,v in pairs(value) do out[k]=copy(v) end;return out
end
local function timestamp()
 return (GetServerTime and GetServerTime()) or (time and time()) or 0
end
local function merge(flags,recipes)
 for _,r in ipairs(recipes or {}) do
  if type(r.id)=="number" and type(r.learned)=="boolean" then
   -- Partial/loading responses must not erase positive learned evidence.
   if r.learned or flags[r.id]~=true then flags[r.id]=r.learned end
  end
 end
end
function Store:Initialize(account,legacy,identity)
 account.characters=type(account.characters)=="table" and account.characters or {}
 self.account=account
 local key=identity.guid or ((identity.realm or "?")..":"..(identity.name or "?"))
 self.currentKey=key
 local profile=account.characters[key]
 if type(profile)~="table" then profile={};account.characters[key]=profile end
 profile.name=identity.name or profile.name or "Unknown"
 profile.realm=identity.realm or profile.realm or "Unknown"
 profile.faction=identity.faction or profile.faction
 profile.knownByID=type(profile.knownByID)=="table" and profile.knownByID or {}
 profile.skills=type(profile.skills)=="table" and profile.skills or {}
 profile.lastScan=type(profile.lastScan)=="table" and profile.lastScan or {}
 profile.lastSeen=timestamp()
 if not profile.migrated then
  for profession,flags in pairs(legacy.recipeKnownByID or {}) do
   profile.knownByID[profession]=profile.knownByID[profession] or {}
   local rows={}
   for id,known in pairs(flags) do rows[#rows+1]={id=id,learned=known} end
   merge(profile.knownByID[profession],rows)
  end
  for profession,snapshot in pairs(legacy.recipeSnapshots or {}) do
   if type(snapshot)=="table" then
    profile.knownByID[profession]=profile.knownByID[profession] or {}
    merge(profile.knownByID[profession],snapshot.recipes)
   end
  end
  profile.migrated=true
 end
 -- Backward compatibility: the existing per-character key references its own profile only.
 legacy.recipeKnownByID=profile.knownByID
 return profile
end
function Store:Get(key)
 return self.account and self.account.characters[key or self.currentKey]
end
function Store:List()
 local rows={}
 for key,profile in pairs(self.account and self.account.characters or {}) do
  if type(profile)=="table" then rows[#rows+1]={key=key,profile=profile} end
 end
 table.sort(rows,function(a,b)
  local an=(a.profile.name or "").."-"..(a.profile.realm or "")
  local bn=(b.profile.name or "").."-"..(b.profile.realm or "")
  if an==bn then return a.key<b.key end
  return an<bn
 end)
 return rows
end
function Store:RecordSkills(skills,source)
 local p=self:Get()
 if not p or source=="none" or not next(skills or {}) then return end
 local found={}
 for name,skill in pairs(skills) do
  if skill.kind=="profession" then found[name]=copy(skill) end
 end
 if next(found) then p.skills=found;p.skillsRecorded=true;p.lastSeen=timestamp() end
end
function Store:MergeRecipes(profession,recipes)
 local p=self:Get()
 if not p or type(profession)~="string" or #recipes==0 then return end
 p.knownByID[profession]=p.knownByID[profession] or {}
 merge(p.knownByID[profession],recipes)
 p.lastScan[profession]=timestamp()
end
function Store:KnownOn(profession,id)
 local names={}
 for _,row in ipairs(self:List()) do
  local flags=row.profile.knownByID and row.profile.knownByID[profession]
  if flags and flags[id]==true then
   names[#names+1]=row.profile.name
  end
 end
 return names
end

-- Discover positive learned evidence without opening any profession window.
-- A false spell query is NOT proof a client candidate is obtainable/missing.
function Store:ScanKnownSpells(catalog)
 local p=self:Get();if not p then return 0,"no_character" end
 local queries={}
 if C_SpellBook and type(C_SpellBook.IsSpellKnown)=="function" then
  queries[#queries+1]=function(id) return C_SpellBook.IsSpellKnown(id) end
 end
 if type(IsPlayerSpell)=="function" then queries[#queries+1]=IsPlayerSpell end
 if type(IsSpellKnown)=="function" then
  queries[#queries+1]=function(id) return IsSpellKnown(id,false) end
 end
 if #queries==0 then return 0,"unavailable" end
 local byProfession={}
 for profession,rows in pairs(catalog and catalog.professions or {}) do
  byProfession[profession]={}
  for _,row in ipairs(rows) do
   if type(row[1])=="number" then byProfession[profession][row[1]]=true end
  end
 end
 for profession,data in pairs(self.account.recipeCatalogs or {}) do
  byProfession[profession]=byProfession[profession] or {}
  for _,row in ipairs(data.recipes or {}) do
   if type(row.id)=="number" and self:BelongsToProfession(profession,row.id,catalog) then byProfession[profession][row.id]=true end
  end
 end
 local changed=0
 for profession,ids in pairs(byProfession) do
  for id in pairs(ids) do
   local known=false
   for _,query in ipairs(queries) do
    local ok,result=pcall(query,id)
    if ok and result==true then known=true;break end
   end
   if known then
    p.knownByID[profession]=p.knownByID[profession] or {}
    if p.knownByID[profession][id]~=true then
     p.knownByID[profession][id]=true;changed=changed+1
     p.lastScan[profession]=timestamp()
    end
   end
  end
 end
 p.lastBackgroundCheck=timestamp()
 return changed,"spell_queries"
end

-- The bundled spell-to-profession associations define list boundaries.
-- Shared API catalogs are not trusted to define a profession.
function Store:RecipeOwners(id,catalog)
 catalog=catalog or PBFClientCatalog70862
 if not catalog or type(catalog.professions)~="table" then return nil end
 if self.boundaryCatalog~=catalog then
  self.boundaryCatalog=catalog;self.recipeOwners={}
  for profession,rows in pairs(catalog.professions) do
   for _,row in ipairs(rows) do
    self.recipeOwners[row[1]]=self.recipeOwners[row[1]] or {}
    self.recipeOwners[row[1]][profession]=true
   end
  end
 end
 return self.recipeOwners[id]
end
function Store:BelongsToProfession(profession,id,catalog)
 local owners=self:RecipeOwners(id,catalog)
 return owners and owners[profession]==true or false
end
function Store:PartitionRecipes(list,catalog)
 local groups,unknown={},{}
 for _,r in ipairs(list or {}) do
  local owners=self:RecipeOwners(r.id,catalog)
  if owners then
   for profession in pairs(owners) do
    groups[profession]=groups[profession] or {}
    groups[profession][#groups[profession]+1]=r
   end
  else unknown[#unknown+1]=r end
 end
 return groups,unknown
end
function Store:RepairRecipeBoundaries(catalog)
 if not self.account or not catalog or type(catalog.professions)~="table" then return end
 local account=self.account
 local rows={}
 for _,data in pairs(account.recipeCatalogs or {}) do
  for _,r in ipairs(data.recipes or {}) do rows[#rows+1]=r end
 end
 for _,r in pairs(account.unassignedRecipeRows or {}) do rows[#rows+1]=r end
 local groups,unknown=self:PartitionRecipes(rows,catalog)
 account.unassignedRecipeRows={}
 for _,r in ipairs(unknown) do account.unassignedRecipeRows[r.id]=copy(r) end
 account.recipeCatalogs={}
 for profession,list in pairs(groups) do
  local unique={}
  for _,r in ipairs(list) do unique[r.id]=r end
  local sorted={}
  for _,r in pairs(unique) do sorted[#sorted+1]=r end
  table.sort(sorted,function(a,b) return a.id<b.id end)
  account.recipeCatalogs[profession]={profession=profession,recipes=sorted,count=#sorted}
 end
 for _,p in pairs(account.characters or {}) do
  local all={}
  local function collect(flags)
   for id,known in pairs(flags or {}) do
    if type(known)=="boolean" and (known or all[id]~=true) then all[id]=known end
   end
  end
  for _,flags in pairs(p.knownByID or {}) do collect(flags) end
  collect(p.unassignedKnownByID)
  p.knownByID={};p.unassignedKnownByID={}
  for id,known in pairs(all) do
   local owners=self:RecipeOwners(id,catalog)
   if owners then
    for profession in pairs(owners) do
     p.knownByID[profession]=p.knownByID[profession] or {}
     p.knownByID[profession][id]=known
    end
   else p.unassignedKnownByID[id]=known end
  end
 end
 account.recipeBoundaryVersion=1
end
