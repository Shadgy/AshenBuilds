-- SavedVariables are shared between characters; opening a draft must never lose newer work.
local A=AshenBuilds
local oldDB,oldCurrent,oldRefresh,oldName,oldInventory,oldSaved,oldLevel,oldPrompt=AshenBuildsDB,A.current,A.RefreshUI,UnitName,GetInventoryItemLink,A.OnBuildSaved,UnitLevel,A.ShowPrompt
A.RefreshUI=function(self) self:RememberDraft() end
UnitName=function() return "CharacterA" end
local function Build(name,notes)
  local b=A.NewBuildData(name); b.class="Warrior"; b.race="Human"; b.level=60; b.notes=notes or ""
  A.EnsureTalents(b); return b
end
local function Init(saved,draft)
  AshenBuildsDB={builds=saved or {},settings={},currentByChar={["CharacterA-Realm"]=draft or Build("New")}}
  A:InitializeDB()
end

local latest=Build("Shared","LATEST FROM ANOTHER CHARACTER")
local stale=A:DeepCopy(latest); stale.notes="STALE CHARACTER COPY"; stale.savedName="Shared"
Init({Shared=latest},stale)
A:RefreshUI()
check("alt login never overwrites newer shared build",AshenBuildsDB.builds.Shared.notes=="LATEST FROM ANOTHER CHARACTER")
check("stale snapshot is preserved as a detached draft",A.current.notes=="STALE CHARACTER COPY" and not A.current.savedName and string.find(A.current.name,"recovered draft",1,true))
check("recovered draft remains the character's persistent current",AshenBuildsDB.currentByChar["CharacterA-Realm"]==A.current)

local same=A:DeepCopy(latest); same.savedName="Shared"
Init({Shared=latest},same)
local rev=AshenBuildsDB.builds.Shared._revision
A:RefreshUI(); A:RefreshUI()
check("ordinary refresh keeps a clean saved draft and revision",not A:HasUnsavedChanges() and AshenBuildsDB.builds.Shared._revision==rev)
A.current.updated=time()+100; A.current.created=time()-100
A:RefreshUI()
check("timestamp-only changes are not content edits",not A:HasUnsavedChanges() and AshenBuildsDB.builds.Shared._revision==rev)
local savedCallback,callbackCount
callbackCount=0
A.OnBuildSaved=function(_,name) savedCallback=name; callbackCount=callbackCount+1 end
A.current.notes="REAL EDIT"
A:RefreshUI()
check("a real edit remains in the working draft until Save Changes",A:HasUnsavedChanges() and AshenBuildsDB.currentByChar["CharacterA-Realm"].notes=="REAL EDIT" and AshenBuildsDB.builds.Shared.notes==latest.notes)
check("draft refresh does not advance the revision or publish changes",AshenBuildsDB.builds.Shared._revision==rev and callbackCount==0)
check("explicit Save Changes commits the draft",A:SaveBuild("Shared")==true and AshenBuildsDB.builds.Shared.notes=="REAL EDIT")
check("explicit Save Changes updates the baseline and callback once",not A:HasUnsavedChanges() and AshenBuildsDB.builds.Shared._revision==rev+1 and A.current._savedRevision==rev+1 and savedCallback=="Shared" and callbackCount==1)
A:RememberDraft()
check("remembering the saved draft does not write again",AshenBuildsDB.builds.Shared._revision==rev+1 and callbackCount==1)

AshenBuildsDB.builds.Shared.notes="NEWER LIBRARY REVISION"
AshenBuildsDB.builds.Shared._revision=rev+2
A.current.notes="MY CONFLICTING EDIT"
A:RememberDraft()
check("remembering a stale draft preserves its original saved baseline",A.current._savedRevision==rev+1 and A.current.notes=="MY CONFLICTING EDIT" and AshenBuildsDB.builds.Shared.notes=="NEWER LIBRARY REVISION")
check("explicit Save refuses a conflicting revision",A:SaveBuild("Shared")==false)
check("conflict preserves both versions",AshenBuildsDB.builds.Shared.notes=="NEWER LIBRARY REVISION" and A.current.notes=="MY CONFLICTING EDIT" and not A.current.savedName)
check("Save As cannot replace an existing name",A:SaveBuild("Shared",true)==false and AshenBuildsDB.builds.Shared.notes=="NEWER LIBRARY REVISION")
check("recovered draft can be saved under a new name",A:SaveBuild("My separate copy",true)==true and AshenBuildsDB.builds["My separate copy"].notes=="MY CONFLICTING EDIT")
check("explicit Save As preserves the community callback",savedCallback=="My separate copy" and callbackCount==2)
A:LoadBuild("Shared")
check("explicit load uses latest shared version",A.current.notes=="NEWER LIBRARY REVISION")
check("loaded current persists immediately per character",AshenBuildsDB.currentByChar["CharacterA-Realm"]==A.current)
rev=AshenBuildsDB.builds.Shared._revision
A:RefreshUI()
check("load and refresh do not overwrite or bump saved content",AshenBuildsDB.builds.Shared._revision==rev)
AshenBuildsDB.builds.Shared.notes="LATER CHANGE"; AshenBuildsDB.builds.Shared._revision=rev+1
A.current.notes="EXPLICIT SAVE CONFLICT"
check("explicit Save also refuses a changed library revision",A:SaveBuild("Shared")==false and AshenBuildsDB.builds.Shared.notes=="LATER CHANGE")
check("explicit-save conflict keeps the edited draft",not A.current.savedName and A.current.notes=="EXPLICIT SAVE CONFLICT")
local beforeRead=A:GetBuildPayloadSignature(A.current)
A:GetDerivedStats(A.current)
check("reading derived stats never mutates the saved payload",A:GetBuildPayloadSignature(A.current)==beforeRead)

local first=Build("One","payload"); first.items={HEAD=12640,CHEST=11726}; first.defense={targetLevel=63,holyShield=false}
local second=A:DeepCopy(first); second.name="Another name"; second._revision=99; second.updated=time()+300
second.items={CHEST=11726,HEAD=12640}
check("signature is independent of key order and bookkeeping",A:GetBuildPayloadSignature(first)==A:GetBuildPayloadSignature(second))
second.defense.targetLevel=60
check("defense settings are actual saved content",A:GetBuildPayloadSignature(first)~=A:GetBuildPayloadSignature(second))

-- Import replaces the previous plan; unknown native effects remain explicit warnings.
Init({},Build("Equipment import"))
A.current.items={HEAD=12640,CHEST=11726}; A.current.enchants={HEAD=25,CHEST=25}
GetInventoryItemLink=function(_,slot) if slot==1 then return "|Hitem:999999999:2583:0:0|h[Unknown item]|h" end end
local known,missing,unrecognized=A:ImportEquipped()
check("unknown equipped item replaces the previous planned item",A.current.items.HEAD==999999999 and missing==1)
check("empty inventory slots and old enchants are cleared",not A.current.items.CHEST and not next(A.current.enchants))
check("unknown item enchant is retained as an uncounted warning",A.current.unmappedEnchants.HEAD==2583 and unrecognized==1)
GetInventoryItemLink=function(_,slot) if slot==1 then return "|Hitem:12640:2583:0:0|h[Lionheart Helm]|h" end end
known,missing,unrecognized=A:ImportEquipped()
check("native permanent enchant maps to the planner's stable ID",A.current.enchants.HEAD==25 and known==1 and missing==0 and unrecognized==0)
GetInventoryItemLink=function(_,slot)
  if slot==17 then return "|Hitem:19349:929:0:0|h[Elementium Reinforced Bulwark]|h" end
  if slot==8 then return "|Hitem:14616:929:0:0|h[Bloodmail Boots]|h" end
end
A:ImportEquipped()
check("shared native enchant effect resolves by item slot",A.current.enchants.OFFHAND==13 and A.current.enchants.FEET==68)
GetInventoryItemLink=function(_,slot) if slot==1 then return "|Hitem:12640:999999:0:0|h[Lionheart Helm]|h" end end
A:ImportEquipped()
check("unrecognized native enchant never leaves an old planned bonus",not A.current.enchants.HEAD and A.current.unmappedEnchants.HEAD==999999)
GetInventoryItemLink=function() return nil end
A:ImportEquipped()
check("empty equipment import leaves no phantom gear or enchants",not next(A.current.items) and not next(A.current.enchants) and not next(A.current.unmappedEnchants))

local otherClass=Build("Mage plan","Keep this other-class plan")
otherClass.class="Mage"; otherClass.spec="Fire"; otherClass.items={HEAD=12640}; otherClass.talents.points["1:1"]=1
Init({},otherClass)
A:SaveBuild("Mage plan")
A.current.notes="Unsaved Mage edit"
local pending
A.ShowPrompt=function(_,prompt) pending=prompt end
A:ImportEquipped()
check("cross-class import waits before replacing a dirty linked draft",pending and A.current.class=="Mage" and A.current.notes=="Unsaved Mage edit")
if pending then pending.onAccept() end
local preserved=AshenBuildsDB.builds["Mage plan"]
check("cross-class import leaves the saved Mage plan intact",preserved.class=="Mage" and preserved.notes=="Keep this other-class plan" and preserved.talents.points["1:1"]==1)
check("cross-class import creates no automatic saved copy",not AshenBuildsDB.builds["Mage plan (before equipment import)"])
check("cross-class import cannot keep another class's talent allocation",A.current.class=="Warrior" and not next(A.current.talents.points) and not A.current.savedName and A.current.spec=="Arms")
local roundTrip=A:DecodeBuild(A:ExportBuild(A.current))
check("cross-class import produces a valid export/import round trip",roundTrip and roundTrip.class=="Warrior" and not next(roundTrip.talents.points))
local highLevel=Build("Level 60 plan","Preserve the high-level allocation")
highLevel.talents.points["1:2"]=5
Init({},highLevel)
UnitLevel=function() return 5 end
pending=nil
A:ImportEquipped()
check("lower-level import asks before dropping a valid unsaved allocation",pending and A.current.level==60 and A.current.talents.points["1:2"]==5)
if pending then pending.onAccept() end
check("lower-level import clears an allocation beyond the character's budget",A.current.level==5 and not next(A.current.talents.points))
check("accepted lower-level import stays outside the saved library",not next(AshenBuildsDB.builds))

AshenBuildsDB=oldDB; A.current=oldCurrent; A.RefreshUI=oldRefresh; UnitName=oldName; GetInventoryItemLink=oldInventory; A.OnBuildSaved=oldSaved; UnitLevel=oldLevel; A.ShowPrompt=oldPrompt
