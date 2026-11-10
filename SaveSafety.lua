-- Protect the shared library from stale per-character drafts and metadata-only refreshes.
local A=AshenBuilds
local watched={}
local suspended=false
local payloadKeys={"class","race","level","spec","form","items","enchants","talents","notes","defense","unmappedEnchants"}

local function charKey()
  return (UnitName("player") or "?").."-"..(GetRealmName and GetRealmName() or "")
end
local function serialize(value,seen)
  local kind=type(value)
  if kind=="nil" then return "z" end
  if kind=="string" then return "s"..string.len(value)..":"..value end
  if kind=="number" then return "n"..tostring(value)..";" end
  if kind=="boolean" then return value and "b1" or "b0" end
  if kind~="table" then return "unsupported" end
  if seen[value] then return "cycle" end
  seen[value]=true
  local keys,out,key={},{}
  for key in pairs(value) do table.insert(keys,key) end
  table.sort(keys,function(x,y) return type(x)..tostring(x)<type(y)..tostring(y) end)
  for _,key in ipairs(keys) do table.insert(out,serialize(key,seen)..serialize(value[key],seen)) end
  seen[value]=nil
  return "t{"..table.concat(out).."}"
end
function A:GetBuildPayloadSignature(build)
  local out,key={},nil
  for _,key in ipairs(payloadKeys) do table.insert(out,key.."="..serialize(build and build[key],{})) end
  return table.concat(out,"|")
end
local function revision(build)
  return math.max(1,math.floor(tonumber(build and build._revision) or 1))
end
local function remember(build)
  AshenBuildsDB.current=build
  AshenBuildsDB.currentByChar=AshenBuildsDB.currentByChar or {}
  AshenBuildsDB.currentByChar[charKey()]=build
end
local function baseline(build,saved)
  local sig=A:GetBuildPayloadSignature(build)
  watched[build]={payload=sig,revision=saved and revision(saved),savedSignature=saved and A:GetBuildPayloadSignature(saved)}
  build._savedRevision=saved and revision(saved) or nil
  build._savedSignature=saved and A:GetBuildPayloadSignature(saved) or nil
end
local function detach(build,message)
  local old=build.savedName or build.name or "Build"
  build.savedName=nil; build._savedRevision=nil; build._savedSignature=nil
  build.name=old.." (recovered draft)"; build.manual=true
  baseline(build,nil); remember(build)
  A.Print(message.." Your plan was kept as |cffffffff"..build.name.."|r; use Save As to keep a separate copy.")
end
local function libraryCopy(build,name,rev)
  local copy=A:DeepCopy(build)
  copy.name=name; copy.savedName=nil; copy._savedRevision=nil; copy._savedSignature=nil; copy._revision=rev
  return copy
end

local initialize=A.InitializeDB
function A:InitializeDB()
  initialize(self)
  local _,saved
  for _,saved in pairs(AshenBuildsDB.builds) do saved._revision=revision(saved) end
  local b=self.current; local target=b.savedName and AshenBuildsDB.builds[b.savedName]
  if target and self:GetBuildPayloadSignature(b)~=self:GetBuildPayloadSignature(target) then
    detach(b,"A newer or different saved build exists; the character's older snapshot was not written over it.")
  else
    if b.savedName and not target then b.savedName=nil end
    baseline(b,target); remember(b)
  end
end

function A:AutoSave()
  if suspended or not self.current or not AshenBuildsDB then return false end
  local b=self.current; local state=watched[b]
  remember(b)
  if not state then
    local target=b.savedName and AshenBuildsDB.builds[b.savedName]
    if target and self:GetBuildPayloadSignature(b)~=self:GetBuildPayloadSignature(target) then
      detach(b,"The restored draft differs from the saved build; no saved data was replaced.")
    else baseline(b,target) end
    return false
  end
  local sig=self:GetBuildPayloadSignature(b)
  if sig==state.payload then return false end
  local name=b.savedName
  if not name then baseline(b,nil); return false end
  local target=AshenBuildsDB.builds[name]
  if not target or revision(target)~=state.revision or self:GetBuildPayloadSignature(target)~=state.savedSignature then
    detach(b,"This saved build changed elsewhere; your draft was preserved instead of overwriting the newer version.")
    return false
  end
  local rev=revision(target)+1
  AshenBuildsDB.builds[name]=libraryCopy(b,name,rev)
  baseline(b,AshenBuildsDB.builds[name]); remember(b)
  return true
end

local save=A.SaveBuild
function A:SaveBuild(name,saveAs)
  local b=self.current; local linked=b.savedName and AshenBuildsDB.builds[b.savedName]
  if linked and not saveAs then
    if b._savedRevision~=revision(linked) or b._savedSignature~=self:GetBuildPayloadSignature(linked) then
      detach(b,"The saved version changed elsewhere; Save did not overwrite it.")
      return false
    end
  end
  local cleaned=self.CleanBuildName(name or b.name); if cleaned=="" then cleaned="Unnamed Build" end
  if saveAs and AshenBuildsDB.builds[cleaned] then
    self.Print("Save As requires a new name; the existing saved build was not replaced.")
    return false
  end
  local previous=AshenBuildsDB.builds[cleaned] or (not saveAs and linked)
  local rev=previous and revision(previous)+1 or 1
  local was=suspended; suspended=true
  local ok,result=pcall(save,self,name,saveAs)
  suspended=was
  if not ok then error(result) end
  if result then
    local target=AshenBuildsDB.builds[b.savedName]
    target._revision=rev; target._savedRevision=nil; target._savedSignature=nil
    baseline(b,target); remember(b)
  end
  return result
end

function A:LoadBuild(name)
  local target=AshenBuildsDB.builds[name]; if not target then return false end
  local b=self:DeepCopy(target)
  b.name=name; b.savedName=name; self:MigrateBuild(b)
  self.current=b; baseline(b,target); remember(b)
  self:RefreshUI(); self.Print("Loaded |cffffffff"..name.."|r.")
  return true
end

-- The permanent enchant number in an item link is not the planner's enchant ID.
local function importedEnchant(slot,native,item)
  local candidates=A.NativeEnchantIds and A.NativeEnchantIds[native]
  if type(candidates)=="number" then candidates={candidates} end
  local i,id
  for i=1,table.getn(candidates or {}) do
    id=candidates[i]
    if item and A:IsEnchantAllowed(slot,id,item) then return id end
  end
end
local function preserveBeforeImport(build)
  local base=(build.name or "Build").." (before equipment import)"
  local name,n=base,1
  while AshenBuildsDB.builds[name] do n=n+1; name=base.." "..n end
  AshenBuildsDB.builds[name]=libraryCopy(build,name,1)
  A.Print("The previous class/level plan was preserved as |cffffffff"..name.."|r before importing your character's equipment.")
  if A.RefreshBuildList then A:RefreshBuildList() end
end
function A:ImportEquipped()
  local items,enchants,unmapped={},{},{}
  local found,missing,unknownEnchant=0,0,0
  local i,slot,link,id,native,_,__,item,enchant
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]; link=GetInventoryItemLink("player",self.INVENTORY_SLOTS[slot])
    if link then
      _,__,id,native=string.find(link,"item:(%d+):(%d*)")
      if not id then _,__,id=string.find(link,"item:(%d+)") end
      id=tonumber(id); native=tonumber(native) or 0
      if id and id>0 then
        items[slot]=id; item=self:GetItem(id)
        if item then found=found+1 else missing=missing+1 end
        if native>0 then
          enchant=importedEnchant(slot,native,item)
          if enchant then enchants[slot]=enchant else unmapped[slot]=native; unknownEnchant=unknownEnchant+1 end
        end
      else missing=missing+1 end
    end
  end
  local player=self.NewBuildData("Imported")
  local b=self.current
  local candidate=self:DeepCopy(b)
  candidate.class=player.class; candidate.level=player.level
  local valid=not self.ValidateTalents or self:ValidateTalents(candidate)
  if b.class~=player.class or not valid then
    if self:BuildHasContent(b) or (b.notes and b.notes~="") then preserveBeforeImport(b) end
    b.savedName=nil; b._savedRevision=nil; b._savedSignature=nil
    b.talents={points={}}; b.spec=player.spec; b.form=nil
    b.name=player.class.." equipment import"
    baseline(b,nil)
  end
  b.items=items; b.enchants=enchants; b.unmappedEnchants=unmapped
  b.class=player.class; b.race=player.race; b.level=player.level; b.manual=true; b.updated=time()
  remember(b); self:RefreshUI()
  self.Print("Imported "..found.." known equipped items. "..missing.." items are missing from the database; their IDs were retained. "..unknownEnchant.." unrecognized enchant effects were kept as warnings and were not counted.")
  return found,missing,unknownEnchant
end
