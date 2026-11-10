local A=AshenBuilds
local function Build(class)
  local b=A.NewBuildData("Hit UI");b.class=class or "Warrior";b.race="Human";b.level=60;b.spec=A.SPECS[b.class][1]
  b.items={MAINHAND=19019,OFFHAND=33135};b.enchants={};A.EnsureTalents(b);return b
end
local function Stat(col,key)
  for _,line in ipairs(A.statsColumns[col].lines) do if line[3].key==key then return line end end
end
local function Number(text) return tonumber((string.gsub(text,"%%",""))) end
local b=Build();A.current=b;A:RefreshUI()
local before=Number(Stat(3,"meleeHit")[2]:GetText())
A.weaponSkillQuestCheck:SetChecked(1);A.weaponSkillQuestCheck:Click()
local after=Number(Stat(3,"meleeHit")[2]:GetText())
check("visible MeleeHit gains one point from the checkbox",math.abs(after-before-1)<0.000001)
check("ranged bonus is labelled separately",Stat(3,"rangedHit")[1]:GetText()=="Ranged Hit bonus")
A.meleeTargetDrop.opts.onSelect(60)
check("main target selector synchronizes attack and defense target",A:GetDefenseSettings().targetLevel==60 and A.lastStats.meleeHitPreview.targetLevel==60 and A.lastStats.defenseTable.targetLevel==60 and A.meleeTargetDrop.text:GetText()=="vs 60")
local oldOwner,oldDouble=GameTooltip.SetOwner,A.AddTooltipDouble
local owners,rows=0,{}
GameTooltip.SetOwner=function() owners=owners+1 end
A.AddTooltipDouble=function(self,label,value) rows[label]=value end
b.race="Gnome";A:SetWeaponSkillQuest("Sword",false);A:SetDefenseSetting("targetLevel",63);A:RefreshUI()
A:ShowStatTooltip(Stat(3,"meleeHit")[3])
check("zero Hit still opens target miss tooltip",owners==1 and rows["MH special / single-wield miss"]=="8.00%")
GameTooltip.SetOwner=oldOwner;A.AddTooltipDouble=oldDouble
local w=Build("Warlock");w.items.HEAD=47016;A.current=w;A:RefreshUI()
check("unsupported defenses show N/A rather than unexplained zero",Stat(5,"parry")[2]:GetText()=="N/A" and Stat(5,"blockPreview")[2]:GetText()=="N/A" and Stat(5,"blockValue")[2]:GetText()=="N/A")
check("class ability limitation is visible on the main panel",A.defenseClassNote:GetText()=="Warlock: no parry or shield block")
check("incompatible equipment exposes calculation notes on main panel",A.calculationNotesButton:IsShown())
A:ShowCalculationWarnings(A.calculationNotesButton)
check("calculation notes identify the selected class",GameTooltip:GetText()=="Calculated for Warlock")
for _,class in ipairs({"Paladin","Warrior"}) do
  A.current=Build(class);A:RefreshUI()
  check(class.." main panel shows positive parry block BV",Number(Stat(5,"parry")[2]:GetText())>0 and Number(Stat(5,"blockPreview")[2]:GetText())>0 and Number(Stat(5,"blockValue")[2]:GetText())>0)
  check(class.." panel labels its calculation class",A.defenseClassNote:GetText()=="Calculated for "..class)
end
