local A=AshenBuilds
local function Build(class,race)
  local b=A.NewBuildData("Quest skill");b.class=class or "Warrior";b.race=race or "Human";b.level=60
  b.items={MAINHAND=19019,OFFHAND=19349};b.enchants={};A.EnsureTalents(b);return b
end
local function Near(a,b) return math.abs(a-b)<0.00001 end
for _,class in ipairs({"Warrior","Paladin"}) do
  local b=Build(class);local base=A:GetDerivedStats(b)
  check(class.." legacy build defaults to no quest bonus",base.mainSkill.quest==0 and not b.weaponSkillQuests)
  local sig=A:GetBuildPayloadSignature(b)
  A:GetDerivedStats(b)
  check(class.." reading quest stats is pure",sig==A:GetBuildPayloadSignature(b))
  check(class.." matching family enables",A:SetWeaponSkillQuest("Sword",true,b))
  local quest=A:GetDerivedStats(b)
  check(class.." Human sword quest stacks with racial",quest.mainSkill.total==308 and quest.mainSkill.racial==3 and quest.mainSkill.quest==5)
  check(class.." quest gives exactly5 total",quest.mainSkill.total-base.mainSkill.total==5)
  check(class.." quest does not add flat Hit",quest.hit==base.hit)
  check(class.." quest does not change defensive stats",quest.defense==base.defense and quest.defenseTable.coverage==base.defenseTable.coverage and quest.blockValue==base.blockValue)
  check(class.." sheet weapon skill crit follows existing formula",Near(quest.meleeCrit-base.meleeCrit,0.2))
  check(class.." quest signature is saved content",sig~=A:GetBuildPayloadSignature(b))
  local sum=0;for _,row in ipairs(quest.explain.mainSkill) do sum=sum+row[2] end
  check(class.." weapon skill tooltip reconciles total",sum==quest.mainSkill.total)
  local g={swordSkill=7};local t={swordSkill=5}
  check(class.." quest gear racial talent stack once",A:GetWeaponSkill(b,"MAINHAND",g,t).total==320)
  b.level=59;check(class.." book preview waits untillevel60",A:GetDerivedStats(b).mainSkill.quest==0 and A:HasWeaponSkillQuest(b,"Sword"))
  b.level=60;A:SetWeaponSkillQuest("Sword",false,b)
  check(class.." unchecking returns baseline",A:GetDerivedStats(b).mainSkill.total==base.mainSkill.total)
end
local b=Build("Warrior","Gnome");A:SetWeaponSkillQuest("Sword",true,b)
check("no-racial sword quest gives305",A:GetDerivedStats(b).mainSkill.total==305)
check("paired 1H and2Hsword use one book",A:GetWeaponSkillQuestBonus(b,"Sword")==5 and A:GetWeaponSkillQuestBonus(b,"TwoHandSword")==5)
check("sword book does not affect other families",A:GetWeaponSkillQuestBonus(b,"Axe")==0 and A:GetWeaponSkillQuestBonus(b,"Mace")==0)
local mixed=Build("Warrior");mixed.items.OFFHAND=17068;A:SetWeaponSkillQuest("Sword",true,mixed)
local m=A:GetDerivedStats(mixed)
check("sword book does not leak into offhand axe",m.mainSkill.quest==5 and m.offSkill.type=="Axe" and m.offSkill.quest==0)
A:SetWeaponSkillQuest("Axe",true,mixed)
check("different offhand family can be marked independently",A:GetDerivedStats(mixed).offSkill.quest==5)
for _,entry in ipairs(A.WEAPON_SKILL_QUEST_TYPES) do
  A:SetWeaponSkillQuest(entry.value,true,b)
  check(entry.value.." mastery applies5",A:GetWeaponSkillQuestBonus(b,entry.value)==5)
end
for _,kind in ipairs({"Shield","Wand","FishingPole","Unarmed","Unknown"}) do check(kind.." is not a quest mastery",A:GetWeaponSkillQuestBonus(b,kind)==0) end
local old=A.GetItem
A.GetItem=function(self,id) if id==990099 then return {n="Fishing pole fixture",weaponType="Staff",itemClass=2,subclass=20} end return old(self,id) end
b.items.MAINHAND=990099
check("fishing pole normalized asStaff cannot inherit quest bonus",A:GetWeaponSkill(b,"MAINHAND",{},{})==nil)
A.GetItem=old
local druid=Build("Druid");druid.spec="Feral";druid.form="bear";A:SetWeaponSkillQuest("Staff",true,druid)
check("feral form does not use staff mastery",A:GetWeaponSkillQuestBonus(druid,"Staff")==0)
druid.form="humanoid";check("humanoid staff can use mastery",A:GetWeaponSkillQuestBonus(druid,"Staff")==5)
local sim=Build("Warrior");sim.items.OFFHAND=15806
local W=AshenSim.Warrior;local cfg=W.DefaultSettings();local before=W.BuildCharacter(sim,cfg)
A:SetWeaponSkillQuest("Sword",true,sim);local after=W.BuildCharacter(sim,cfg)
check("sim mainhand inherits exactly5",after.mh.skill-before.mh.skill==5)
check("sim offhand samefamily inherits exactly5",after.oh.skill-before.oh.skill==5)
local current=A.current
A.current=Build("Warrior");A:SaveBuild("Quest persistence")
local rev=AshenBuildsDB.builds["Quest persistence"]._revision
A:SetWeaponSkillQuest("Sword",false)
check("unchanged checkbox state does not dirty saved content",AshenBuildsDB.builds["Quest persistence"]._revision==rev and not A.current.weaponSkillQuests)
A:SetWeaponSkillQuest("Sword",true)
check("checkbox changes stay in the draft before Save",A:HasUnsavedChanges() and A:HasWeaponSkillQuest(A.current,"Sword") and not A:HasWeaponSkillQuest(AshenBuildsDB.builds["Quest persistence"],"Sword") and AshenBuildsDB.builds["Quest persistence"]._revision==rev)
A:SaveBuild("Quest persistence")
check("explicit Save advances the quest build revision",AshenBuildsDB.builds["Quest persistence"]._revision==rev+1)
A:LoadBuild("Quest persistence")
check("saved build reload retains family quest",A:HasWeaponSkillQuest(A.current,"Sword"))
local questOnly=A.NewBuildData("Quest-only plan");questOnly.level=60
check("empty plan has no content",not A:BuildHasContent(questOnly))
questOnly.weaponSkillQuests={Sword=false}
check("unchecked quest alone is not content",not A:BuildHasContent(questOnly))
questOnly.weaponSkillQuests.Sword=true
check("quest-only plan counts as unsaved content",A:BuildHasContent(questOnly))
local oldInventory,oldPrompt=GetInventoryItemLink,A.ShowPrompt
GetInventoryItemLink=function() return nil end
local pending
A.ShowPrompt=function(_,prompt) pending=prompt end
questOnly.class="Paladin";A.current=questOnly
A:ImportEquipped()
check("cross-class import asks before dropping a quest-only draft",pending and A.current.class=="Paladin" and A:HasWeaponSkillQuest(A.current,"Sword"))
if pending then pending.onAccept() end
check("cross-class import does not add a quest draft to the library",not AshenBuildsDB.builds["Quest-only plan (before equipment import)"])
check("cross-class import clears assumed quest completions",A.current.class=="Warrior" and not A.current.weaponSkillQuests)
GetInventoryItemLink=oldInventory;A.ShowPrompt=oldPrompt
A.current=current
