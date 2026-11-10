local A=AshenBuilds
local function Near(a,b) return math.abs(a-b)<0.000001 end
local function Build(class)
  local b=A.NewBuildData("Active defense");b.class=class;b.race="Human";b.level=60;b.spec=A.SPECS[class][1]
  b.items={MAINHAND=19019,OFFHAND=19349};b.enchants={};A.EnsureTalents(b);return b
end
local function Talent(b,name)
  for tree=1,3 do for index,talent in ipairs(A:GetTalentData(b.class)[tree]) do
    if talent.name==name then b.talents.points[A:GetTalentKey(tree,index)]=table.getn(talent.ranks) end
  end end
end
local function BlockLine()
  for _,line in ipairs(A.statsColumns[5].lines) do if line[3].key=="blockPreview" then return line end end
end
local b=Build("Paladin");Talent(b,"Holy Shield");Talent(b,"Redoubt")
A.current=b;A:RefreshUI();A.defenseBrowser:Show()
local passive=A.lastStats.block;local value=A.lastStats.blockValue
check("main block starts at passive value",Near(A.lastStats.blockPreview,passive) and BlockLine()[1]:GetText()=="Block")
A.defenseBrowser.holyShield:SetChecked(1);A.defenseBrowser.holyShield:Click()
check("HolyShield immediately updates the main gear card",Near(A.lastStats.blockPreview,passive+45) and tonumber((string.gsub(BlockLine()[2]:GetText(),"%%","")))==tonumber(string.format("%.2f",passive+45)))
check("main block labels active preview",BlockLine()[1]:GetText()=="Block (active)" and A.defenseClassNote:GetText()=="Paladin: active block preview")
A.defenseBrowser.redoubt:SetChecked(1);A.defenseBrowser.redoubt:Click()
check("Redoubt stacks on the main gear card",Near(A.lastStats.blockPreview,passive+60))
check("active preview does not overwrite passive combat inputs",A.lastStats.block==passive and A.lastStats.blockValue==value)
check("main sheet and attacker block differ once by0.6",Near(A.lastStats.blockPreview-A.lastStats.defenseTable.block,0.6))
check("main block tooltip sources reconcile",Near(A.lastStats.explain.blockPreview[1][2]+A.lastStats.explain.blockPreview[2][2],A.lastStats.blockPreview))
check("sheet102.4 and adjusted100 have the same gap",Near(A.lastStats.defenseTable.sheetCap,102.4) and Near(A.lastStats.defenseTable.sheetGap,A.lastStats.defenseTable.capGap))
A.defenseBrowser.holyShield:SetChecked(nil);A.defenseBrowser.holyShield:Click()
check("uncheckingHolyShield preserves onlyRedoubt",Near(A.lastStats.blockPreview,passive+15))
A.defenseBrowser.redoubt:SetChecked(nil);A.defenseBrowser.redoubt:Click()
check("unchecking both returns the main card to passive",Near(A.lastStats.blockPreview,passive) and BlockLine()[1]:GetText()=="Block")
A:SetWeaponSkillQuest("Sword",true)
check("weapon mastery does not grant defensive avoidance",Near(A.lastStats.blockPreview,passive) and A.lastStats.block==passive)
local w=Build("Warrior");A.current=w;A:RefreshUI();local warriorPassive=A.lastStats.block
A.defenseBrowser.shieldBlock:SetChecked(1);A.defenseBrowser.shieldBlock:Click()
check("ShieldBlock also updates the main gear card",Near(A.lastStats.blockPreview,warriorPassive+75) and A.lastStats.block==warriorPassive)
w.items.OFFHAND=nil;A:RefreshUI()
check("stored active state cannot add block without shield",A.lastStats.blockPreview==0 and A.lastStats.defenseTable.activeBlock==0)
local oldLine=GameTooltip.AddLine;local unverified=false
GameTooltip.AddLine=function(self,text) if string.find(text,"not yet verified on Octo",1,true) then unverified=true end end
A:ShowStatTooltip({key="meleeCrit",label="Melee Crit",value="10%"})
check("crit tooltip explicitly marks Octo verification gap",unverified)
GameTooltip.AddLine=oldLine
