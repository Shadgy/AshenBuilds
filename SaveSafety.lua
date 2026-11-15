-- Keep the per-character draft separate from the shared saved library.
local A=AshenBuilds
local payloadKeys={"class","race","level","spec","form","items","enchants","talents","notes","defense","unmappedEnchants","weaponSkillQuests"}

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
function A:RememberDraft()
  if self.current and AshenBuildsDB then remember(self.current) end
end

local function baseline(build,saved)
  build._savedRevision=saved and revision(saved) or nil
  build._savedSignature=saved and A:GetBuildPayloadSignature(saved) or nil
end

local function matchesSavedVersion(build,saved)
  return saved and build._savedRevision==revision(saved)
    and build._savedSignature==A:GetBuildPayloadSignature(saved)
end

function A:HasUnsavedChanges(build)
  build=build or self.current
  if not build then return false end
  if build.savedName then
    return self.CleanBuildName(build.name)~=build.savedName
      or self:GetBuildPayloadSignature(build)~=build._savedSignature
  end
  if self:BuildHasContent(build) or build.manual or build.name~="New Build" or build.form then return true end
  if type(build.defense)=="table" and next(build.defense) then return true end
  local specs=self.SPECS[build.class]
  return specs and build.spec~=specs[1] or false
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
  local b=self.current
  local target=b.savedName and AshenBuildsDB.builds[b.savedName]
  if b.savedName then
    -- Older plans without a recorded baseline can link to an identical saved copy.
    local legacyMatch=target and not b._savedRevision and not b._savedSignature
      and self:GetBuildPayloadSignature(b)==self:GetBuildPayloadSignature(target)
    if not matchesSavedVersion(b,target) and not legacyMatch then
      detach(b,"The original saved build changed or was removed.")
      return
    end
  end
  baseline(b,target)
  remember(b)
end

-- Saving under a different name renames a linked build. Save As creates a copy.
function A:SaveBuild(name,saveAs)
  local b=self.current
  local savedName=b.savedName
  local linked=savedName and AshenBuildsDB.builds[savedName]
  if savedName and not saveAs and not matchesSavedVersion(b,linked) then
    detach(b,"The original saved build changed or was removed.")
    self:RefreshUI()
    return false
  end
  name=self.CleanBuildName(name or b.name)
  if name=="" then name="Unnamed Build" end
  if AshenBuildsDB.builds[name] and (saveAs or name~=savedName) then
    self.Print("A saved build named |cffffffff"..name.."|r already exists. Choose a different name.")
    return false
  end
  local rev=linked and not saveAs and revision(linked)+1 or 1
  if linked and not saveAs and savedName~=name then
    if not self:RenameBuild(savedName,name) then return false end
  end
  self:MigrateBuild(b)
  b.name=name
  b.savedName=name
  b.updated=time()
  local saved=libraryCopy(b,name,rev)
  AshenBuildsDB.builds[name]=saved
  baseline(b,saved)
  remember(b)
  self.Print("Saved |cffffffff"..name.."|r.")
  self:RefreshBuildList()
  self:RefreshUI()
  return true
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
local function readEquipped(self,requireComplete)
  local items,enchants,unmapped={},{},{}
  local found,missing,unknownEnchant=0,0,0
  local i,slot,link,id,native,_,__,item,enchant
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]
    local inventorySlot=self.INVENTORY_SLOTS[slot]
    link=GetInventoryItemLink("player",inventorySlot)
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
      elseif requireComplete then
        return nil,"an equipped item's link could not be read"
      else missing=missing+1 end
    elseif requireComplete and GetInventoryItemTexture and GetInventoryItemTexture("player",inventorySlot) then
      return nil,"equipped item links are still loading"
    end
  end
  return items,enchants,unmapped,found,missing,unknownEnchant
end

function A:ImportEquipped()
  local items,enchants,unmapped,found,missing,unknownEnchant=readEquipped(self)
  local player=self.NewBuildData("Imported")
  local b=self.current
  local candidate=self:DeepCopy(b)
  candidate.class=player.class; candidate.level=player.level
  local valid=not self.ValidateTalents or self:ValidateTalents(candidate)
  local resetsTalents=b.class~=player.class or not valid
  local function apply()
    if resetsTalents then
      if b.class~=player.class then b.weaponSkillQuests=nil end
      b.savedName=nil
      b.talents={points={}}
      b.spec=player.spec
      b.form=nil
      b.name=player.class.." equipment import"
      baseline(b,nil)
    end
    b.items=items
    b.enchants=enchants
    b.unmappedEnchants=unmapped
    b.class=player.class
    b.race=player.race
    b.level=player.level
    b.manual=true
    b.updated=time()
    self:RefreshUI()
    self.Print("Imported "..found.." known equipped items. "..missing.." items are missing from the database; their IDs were retained. "..unknownEnchant.." unrecognized enchant effects were kept as warnings and were not counted.")
  end
  if resetsTalents then
    if not self:ConfirmDiscard("your character's equipment",apply) then return end
  else
    apply()
  end
  return found,missing,unknownEnchant
end

local function readCharacterBuild(self)
  local name=UnitName("player")
  local _,token=UnitClass("player")
  local level=UnitLevel("player")
  if not name or not token or type(level)~="number" or level<1 then
    return nil,"your character is not ready"
  end
  local player=self.NewBuildData(name.." build")
  if self.CLASS_TOKENS[player.class]~=token then return nil,"unsupported character class" end
  local points,why=self:ReadCharacterTalents(player)
  if not points then return nil,why end
  player.spec="Custom"
  player.talents={points=points}
  local valid
  valid,why=self:ValidateTalents(player)
  if not valid then return nil,why end
  return player
end

function A:ImportCharacter()
  local draft=self.current
  local signature=self:GetBuildPayloadSignature(draft)
  local name,savedName=draft.name,draft.savedName
  local player,why=readCharacterBuild(self)
  if not player then
    self.Print("Could not import character because "..why..". The current build was kept.")
    return
  end

  local function canApply()
    if self.current==draft and draft.name==name and draft.savedName==savedName
      and self:GetBuildPayloadSignature(draft)==signature then return true end
    self.Print("The current plan has changed. Open Import Character again.")
    return false
  end

  local function apply(useCurrent)
    if not canApply() then return end
    local imported,reason=readCharacterBuild(self)
    if not imported then
      self.Print("Could not import character because "..reason..". The current build was kept.")
      return
    end
    local items,enchants,unmapped,found,missing,unknownEnchant=readEquipped(self,true)
    if not items then
      self.Print("Could not import character because "..enchants..". The current build was kept.")
      return
    end
    local b=imported
    if useCurrent then
      b=draft
      if b.class~=imported.class then
        b.form=nil; b.defense=nil; b.weaponSkillQuests=nil; b.base=nil
      elseif b.class=="Druid" then
        b.form=self:GetBuildForm(b)
      end
      b.class=imported.class; b.race=imported.race; b.level=imported.level
      b.spec=imported.spec; b.talents=imported.talents
    else
      local baseName,suffix=b.name,2
      while AshenBuildsDB.builds[b.name] do
        b.name=baseName.." ("..suffix..")"
        suffix=suffix+1
      end
    end
    b.items=items; b.enchants=enchants; b.unmappedEnchants=unmapped
    b.manual=true; b.updated=time()
    self.current=b
    self:RefreshUI()
    if not self.frame:IsShown() then self.frame:Show() end
    self:ShowTab("planner")
    self.Print("Imported "..found.." known equipped items and "..self:GetTalentPointsSpent(b).." talent points. Click Save Changes to keep this build.")
    if missing>0 or unknownEnchant>0 then
      self.Print(missing.." equipped items are missing from the database. "..unknownEnchant.." unrecognized enchant effects were kept as warnings.")
    end
  end

  self:ShowPrompt({
    title="IMPORT CHARACTER",
    text="Overwrite replaces the draft's gear, talents, class, race and level.\nNew Build starts a separate draft. Save Changes updates the library.",
    accept="Overwrite", onAccept=function() apply(true) end,
    alternate="New Build", onAlternate=function()
      if canApply() then self:ConfirmDiscard("a new character build",function() apply(false) end) end
    end,
  })
end
