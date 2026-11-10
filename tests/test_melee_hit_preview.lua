local A=AshenBuilds
local function Near(a,b) return math.abs(a-b)<0.000001 end
-- Published Octo developer examples plus the user-reported 4% Hit fixture.
for _,row in ipairs({{300,8},{303,7.4},{305,7},{308,6.4},{315,5},{320,4}}) do
  check("Octo miss at skill "..row[1],Near(A:CalculateMeleeMiss(row[1],315,0,false),row[2]))
end
check("303 skill and four Hit leave3.4miss",Near(A:CalculateMeleeMiss(303,315,4,false),3.4))
check("308 skill and four Hit leave2.4miss",Near(A:CalculateMeleeMiss(308,315,4,false),2.4))
check("dual wield applies penalty before flat Hit",Near(A:CalculateMeleeMiss(308,315,4,true),21.12))
check("miss floors at zero after Hit",A:CalculateMeleeMiss(308,315,20,false)==0)
check("skill above targetDefense still reduces miss",Near(A:CalculateMeleeMiss(320,315,0,false),4))
check("sheet crit and target model retain0.2fromfive skill",Near(A:CalculateMeleeCrit(10,308,60,63)-A:CalculateMeleeCrit(10,303,60,63),0.2))

local function Build(class)
  local b=A.NewBuildData("Hit preview"); b.class=class or "Warrior"; b.race="Human"; b.level=60
  b.items={MAINHAND=19019,OFFHAND=33135};b.enchants={};A.EnsureTalents(b);return b
end
local oldGear=A.GetGearTotals
A.GetGearTotals=function(self,build) local g=oldGear(self,build);g.hit=4;return g end
for _,class in ipairs({"Paladin","Warrior"}) do
  local b=Build(class);local before=A:GetDerivedStats(b)
  A:SetWeaponSkillQuest("Sword",true,b)
  local sig=A:GetBuildPayloadSignature(b);local after=A:GetDerivedStats(b)
  check(class.." checkbox increases displayed effectiveHit by1",Near(after.meleeHit-before.meleeHit,1) and Near(after.meleeHit,5.6))
  check(class.." tooltip miss changes3.4to2.4",Near(before.meleeHitPreview.main.miss,3.4) and Near(after.meleeHitPreview.main.miss,2.4))
  check(class.." raw Hit staysfour to avoid simulator double count",after.hit==4)
  check(class.." preview reads do not edit build",sig==A:GetBuildPayloadSignature(b))
  check(class.." skill+gear tooltip reconciles effective bonus",Near(after.explain.meleeHit[1][2]+after.explain.meleeHit[2][2],after.meleeHit))
  check(class.." shield has no dual-wield penalty",not after.meleeHitPreview.dualWield and Near(after.meleeHitPreview.main.whiteMiss,2.4))
end
local b=Build();b.items.OFFHAND=17068;A:SetWeaponSkillQuest("Sword",true,b)
local mixed=A:GetDerivedStats(b)
check("mixed weapon families have independent miss",Near(mixed.meleeHitPreview.main.miss,2.4) and Near(mixed.meleeHitPreview.off.miss,4))
check("mixed DW white miss uses each hand skill",Near(mixed.meleeHitPreview.main.whiteMiss,21.12) and Near(mixed.meleeHitPreview.off.whiteMiss,22.4))
local W=AshenSim.Warrior;local c=W.BuildCharacter(b,W.DefaultSettings())
check("sim gets flatHit and matching raw weapon skills",c.hit==4 and c.mh.skill==308 and c.oh.skill==300)
for tree=1,3 do for index,talent in ipairs(A:GetTalentData("Warrior")[tree]) do
  if talent.name=="Cruelty" or talent.name=="Dual Wield Specialization" then b.talents.points[A:GetTalentKey(tree,index)]=5 end
end end
local specialized=A:GetDerivedStats(b);local specializedChar=W.BuildCharacter(b,W.DefaultSettings())
check("offhand talent Hit is shared by preview and simulator",specialized.meleeHitPreview.off.offHandHit==10 and specializedChar.offHit==10 and Near(specialized.meleeHitPreview.off.whiteMiss,12.4))
check("offhand Hit cannot leak into the mainhand",specialized.hit==4 and Near(specialized.meleeHitPreview.main.miss,2.4) and Near(specialized.meleeHit,5.6))
A:SetDefenseSetting("targetLevel",60,b)
local equal=A:GetDerivedStats(b)
check("target level controls both incoming and outgoing tables",equal.meleeHitPreview.targetLevel==60 and equal.defenseTable.targetLevel==60 and equal.meleeHitPreview.main.miss==0)
b.items.MAINHAND=nil
check("no mainhand falls back to gearHit without invented skill",A:GetDerivedStats(b).meleeHitPreview==nil and A:GetDerivedStats(b).meleeHit==4)
local feral=Build("Druid");feral.form="bear";feral.spec="Feral"
check("feral avoids a humanoid weaponHit preview",A:GetDerivedStats(feral).meleeHitPreview==nil)
for _,family in ipairs({"Staff","Polearm"}) do
  local id;for candidate,raw in pairs(AshenDB.Items) do if raw[18]==family and raw[3]=="TWOHAND" then id=candidate;break end end
  local two=Build();two.items={MAINHAND=id};A:SetWeaponSkillQuest(family,true,two)
  local info=A:GetWeaponInfo(two,"MAINHAND");local skill=A:GetWeaponSkill(two,"MAINHAND",{},{twoHandSkill=3})
  check(family.." retains family and two-handed talent + quest",id and info.type==family and info.twoHand and skill.talent==3 and skill.quest==5 and skill.total==308)
end
A.GetGearTotals=oldGear
