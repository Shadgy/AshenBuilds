local A=AshenBuilds
local checkbox,dropdown=A.weaponSkillQuestCheck,A.weaponSkillQuestDrop
check("quest checkbox has the requested label",checkbox and checkbox.label:GetText()=="Weapon skill quest +5")
check("quest controls fit the header strip above tabs",checkbox:GetHeight()<=22 and dropdown:GetHeight()<=22 and dropdown:GetWidth()>=130)
local cp,dp=checkbox._points[table.getn(checkbox._points)],dropdown._points[table.getn(dropdown._points)]
check("quest controls leave the save row and tabs clear",-cp[5]>=72 and -cp[5]+checkbox:GetHeight()<=98 and -dp[5]>=72 and -dp[5]+dropdown:GetHeight()<=98 and dp[4]+dropdown:GetWidth()<=A.frame:GetWidth()-24)

local function Build(name,items)
  local b=A.NewBuildData(name); b.class="Warrior"; b.race="Human"; b.level=60
  b.items=items or {}; b.enchants={}; A.EnsureTalents(b)
  return b
end
local b=Build("Quest UI",{MAINHAND=19019})
A.current=b; A:RefreshUI()
check("new build defaults the selector to the equipped main-hand family",A.weaponSkillQuestFamily=="Sword" and dropdown.text:GetText()=="Swords")
check("new build starts without a selected mastery book",not checkbox:GetChecked())
checkbox:SetChecked(1); checkbox:Click()
check("checkbox enables only the selected family",A:HasWeaponSkillQuest(b,"Sword") and not A:HasWeaponSkillQuest(b,"Axe") and checkbox:GetChecked())
local selectedSignature=A:GetBuildPayloadSignature(b)
dropdown.opts.onSelect("Axe")
check("choosing another family reflects its own completion",A.weaponSkillQuestFamily=="Axe" and not checkbox:GetChecked())
check("browsing another family does not edit the saved plan",A:GetBuildPayloadSignature(b)==selectedSignature)
checkbox:SetChecked(1); checkbox:Click()
check("a second family can be enabled independently",A:HasWeaponSkillQuest(b,"Sword") and A:HasWeaponSkillQuest(b,"Axe"))
dropdown.opts.onSelect("Sword"); checkbox:SetChecked(nil); checkbox:Click()
check("unchecking one family preserves other mastery books",not A:HasWeaponSkillQuest(b,"Sword") and A:HasWeaponSkillQuest(b,"Axe"))
A:RefreshUI()
check("ordinary refresh preserves the selected family without granting a book",A.weaponSkillQuestFamily=="Sword" and not checkbox:GetChecked())

local bow
for id,raw in pairs(AshenDB.Items) do if raw[18]=="Bow" then bow=id; break end end
local other=Build("Ranged quest UI",{RANGED=bow})
A.current=other; A:RefreshUI()
check("switching builds chooses a matching ranged family when main hand is empty",A.weaponSkillQuestFamily=="Bow" and not checkbox:GetChecked())
A.current=b; A:RefreshUI()
check("switching back restores completion for the selected build",A.weaponSkillQuestFamily=="Sword" and not checkbox:GetChecked() and A:HasWeaponSkillQuest(b,"Axe"))

local early=Build("Mastery before level 60",{MAINHAND=19019}); early.level=59
A.current=early; A:RefreshUI(); checkbox:SetChecked(1); checkbox:Click()
check("below level 60 even a dispatched click cannot grant mastery",not A:HasWeaponSkillQuest(early,"Sword") and not checkbox:GetChecked())
local full=Build("Saved quest controls",{MAINHAND=19019}); A.current=full; A:RefreshUI()
checkbox:SetChecked(1); checkbox:Click(); A:SaveBuild("Saved quest controls",true)
A.current=Build("Other plan"); A:RefreshUI(); A:LoadBuild("Saved quest controls")
check("saved build load restores the displayed quest checkbox",A.weaponSkillQuestFamily=="Sword" and checkbox:GetChecked() and A:HasWeaponSkillQuest(A.current,"Sword"))
