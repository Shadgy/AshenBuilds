local A=AshenBuilds
UnitClass=function() return "Paladin","PALADIN" end
UnitRace=function() return "Dwarf","Dwarf" end
UnitLevel=function() return 60 end

local talentData=A:GetTalentData("Paladin")
local talentMismatch,spentMismatch,localized=false,false,false
function GetLocale() return localized and "frFR" or "enUS" end
-- The client can enumerate a tree in a different order from the planner catalog.
function GetNumTalentTabs() return 3 end
function GetNumTalents(tree) return table.getn(talentData[4-tree]) end
function GetTalentTabInfo(tree)
  local catalogTree=4-tree
  local name=localized and ("Localized tree "..tree) or A.TREE_NAMES.PALADIN[catalogTree]
  local spent=catalogTree==1 and (spentMismatch and 6 or 5) or 0
  return name,nil,spent,A.TREE_ART.PALADIN[catalogTree]
end
local function ReadLiveTalent(tree,index)
  local catalogTree=4-tree
  local catalogIndex=table.getn(talentData[catalogTree])+1-index
  local talent=talentData[catalogTree][catalogIndex]
  local learned=catalogTree==1 and catalogIndex==1
  if learned and talentMismatch then
    return "Unknown Learned Talent","Interface\\Icons\\INV_Misc_QuestionMark",talent.row,talent.column,5,5
  end
  local name=localized and ("Localized talent "..index) or talent.name
  return name,talent.icon,talent.row,talent.column,learned and 5 or 0,table.getn(talent.ranks)
end
GetTalentInfo=ReadLiveTalent
local function ReadInventoryLink(_,slot)
  if slot==16 then return "|Hitem:19019:0:0:0|h[Thunderfury]|h" end
  if slot==17 then return "|Hitem:19349:929:0:0|h[Elementium Reinforced Bulwark]|h" end
end
GetInventoryItemLink=ReadInventoryLink

local name="Saved warrior plan"
local old=A.NewBuildData(name)
old.class="Warrior"
old.race="Human"
old.level=50
old.spec="Custom"
old.notes="Keep these planning notes"
old.items.HEAD=12640
A.EnsureTalents(old)[A:GetTalentKey(1,1)]=3
A.current=old
A:RefreshUI()
A:SaveBuild(name)
local revision=old._savedRevision
local original=AshenBuildsDB.builds[name]
local originalPayload=A:GetBuildPayloadSignature(original)

check("Import Character is available from the planner toolbar",A.importCharacterButton and A.importCharacterButton:GetText()=="Import Character")
Click(A.importCharacterButton)
local prompt=A.promptDialog
check("character import always asks before changing the current plan",prompt:IsShown() and A.current==old and A:GetBuildPayloadSignature(old)==originalPayload)
check("character import offers overwrite, new build and cancel",string.find(string.lower(prompt.accept:GetText()),"overwrite",1,true) and prompt.alternate:IsShown() and string.find(string.lower(prompt.alternate:GetText()),"new build",1,true) and prompt.cancel:IsShown())
Click(prompt.cancel)
check("cancel preserves the draft and the saved revision",not prompt:IsShown() and A.current==old and not A:HasUnsavedChanges() and AshenBuildsDB.builds[name]==original)

local function libraryUnmodified()
  return AshenBuildsDB.builds[name]==original and original._revision==revision and A:GetBuildPayloadSignature(original)==originalPayload
end

GetTalentInfo=nil
A:ImportCharacter()
check("unavailable talent API leaves the draft and saved build untouched",not prompt:IsShown() and A.current==old and libraryUnmodified())
GetTalentInfo=ReadLiveTalent
talentMismatch=true
A:ImportCharacter()
check("unmappable learned talent blocks even a partial equipment import",not prompt:IsShown() and A.current==old and A:GetBuildPayloadSignature(old)==originalPayload and libraryUnmodified())
talentMismatch=false
spentMismatch=true
A:ImportCharacter()
check("tree totals detect a partially read talent snapshot",not prompt:IsShown() and A.current==old and libraryUnmodified())
spentMismatch=false

A:ImportCharacter()
GetTalentInfo=nil
Click(prompt.accept)
check("talents must still be readable when the user accepts the import",A.current==old and A:GetBuildPayloadSignature(old)==originalPayload and libraryUnmodified())
GetTalentInfo=ReadLiveTalent

A:ImportCharacter()
GetInventoryItemLink=function(_,slot) if slot==16 then return "|h[Unreadable item]|h" end end
Click(prompt.accept)
check("a malformed item link prevents partial character import",A.current==old and A:GetBuildPayloadSignature(old)==originalPayload and libraryUnmodified())
GetInventoryItemLink=ReadInventoryLink

A:ImportCharacter()
GetInventoryItemLink=function() return nil end
GetInventoryItemTexture=function(_,slot) if slot==16 then return "equipped" end end
Click(prompt.accept)
check("gear already present with an unloaded item link is not treated as an empty slot",A.current==old and A:GetBuildPayloadSignature(old)==originalPayload and libraryUnmodified())
GetInventoryItemLink=ReadInventoryLink
GetInventoryItemTexture=nil

local other=A.NewBuildData("Another draft")
A:ImportCharacter()
A.current=other
A:RefreshUI()
Click(prompt.accept)
check("a stale overwrite confirmation cannot change a different current draft",A.current==other and not next(other.items) and libraryUnmodified())
A.current=old
A:RefreshUI()

A:ImportCharacter()
old.notes="New edit while import was open"
Click(prompt.accept)
check("a stale confirmation preserves edits made while the prompt was open",old.notes=="New edit while import was open" and old.class=="Warrior" and libraryUnmodified())
old.notes=original.notes

Click(A.savedBuildsButton)
Click(A.importCharacterButton)
Click(prompt.accept)
local replaced=A.current
check("overwrite imports the player's class, race, level and custom spec",replaced.class=="Paladin" and replaced.race=="Dwarf" and replaced.level==60 and replaced.spec=="Custom")
check("overwrite imports live gear, resolves enchants and clears old slots",replaced.items.MAINHAND==19019 and replaced.items.OFFHAND==19349 and replaced.enchants.OFFHAND==13 and not replaced.items.HEAD)
check("talents map to planner keys despite a different client enumeration order",A:GetTalentRank(replaced,1,1)==5 and A:GetTalentPointsSpent(replaced)==5)
check("overwrite keeps the build name, notes and saved baseline",replaced.name==name and replaced.notes=="Keep these planning notes" and replaced.savedName==name and replaced._savedRevision==revision)
check("overwrite returns to Planner and changes only the draft",A.plannerPage:IsShown() and A:HasUnsavedChanges() and libraryUnmodified())

A:ImportCharacter()
Click(prompt.alternate)
check("new build asks before leaving an unsaved current draft",prompt:IsShown() and A.current==replaced and not prompt.alternate:IsShown())
Click(prompt.cancel)
check("canceling draft discard keeps the imported work",A.current==replaced and A:HasUnsavedChanges() and libraryUnmodified())
check("Save Changes explicitly updates the linked build revision",A:SaveBuild(name) and AshenBuildsDB.builds[name]._revision==revision+1 and AshenBuildsDB.builds[name].items.OFFHAND==19349)

local saved=AshenBuildsDB.builds[name]
local savedPayload=A:GetBuildPayloadSignature(saved)
local firstName,secondName="Tester build","Tester build (2)"
local firstBuild,secondBuild=A.NewBuildData(firstName),A.NewBuildData(secondName)
AshenBuildsDB.builds[firstName]=firstBuild
AshenBuildsDB.builds[secondName]=secondBuild
localized=true
A:ImportCharacter()
Click(prompt.alternate)
local fresh=A.current
check("new build creates a fresh unsaved draft with live gear and talents",fresh~=replaced and not fresh.savedName and not fresh._savedRevision and fresh.notes=="" and fresh.items.OFFHAND==19349 and A:GetTalentRank(fresh,1,1)==5)
check("localized talent names resolve using tree art and talent icon",fresh.class=="Paladin" and A:GetTalentPointsSpent(fresh)==5)
check("new build leaves the previous library entry and its revision intact",AshenBuildsDB.builds[name]==saved and saved._revision==revision+1 and A:GetBuildPayloadSignature(saved)==savedPayload)
check("a fresh import uses an available name without changing the existing entries",fresh.name=="Tester build (3)" and AshenBuildsDB.builds[firstName]==firstBuild and AshenBuildsDB.builds[secondName]==secondBuild)
local decoded=A:DecodeBuild(A:ExportBuild(fresh))
check("imported equipment, enchants and talents survive the share-code round trip",decoded and decoded.items.OFFHAND==19349 and decoded.enchants.OFFHAND==13 and A:GetTalentRank(decoded,1,1)==5)

GetNumTalentTabs=function() return 0 end
UnitLevel=function() return 9 end
A:ImportCharacter()
Click(prompt.accept)
check("a character below level 10 can import before the talent trees are available",A.current.level==9 and A:GetTalentPointsSpent(A.current)==0 and A.current.items.MAINHAND==19019)
