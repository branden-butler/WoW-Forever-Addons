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
   names[#names+1]=row.profile.name.." - "..row.profile.realm
  end
 end
 return names
end
