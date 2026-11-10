local A=AshenBuilds
local function Find(options,value)
  for _,entry in ipairs(options) do if entry.value==value then return entry end end
end
local count=0
for _,race in ipairs(A.RACES) do for _,class in ipairs(A.CLASSES) do if A:IsRaceClassAllowed(race,class) then count=count+1 end end end
check("Octo profile matrix contains59supported pairs",count==59)
for _,pair in ipairs({{"Dwarf","Warlock"},{"Tauren","Priest"},{"Gnome","Hunter"},{"Undead","Hunter"},{"Human","Hunter"},{"Orc","Mage"},{"Dwarf","Mage"},{"Troll","Warlock"},{"High Elf","Paladin"},{"Goblin","Warlock"}}) do
  check(pair[1].." "..pair[2].." is an available Octo pair",A:IsRaceClassAllowed(pair[1],pair[2]))
end
for _,pair in ipairs({{"Tauren","Rogue"},{"High Elf","Warlock"},{"Goblin","Priest"},{"Night Elf","Mage"},{"Orc","Paladin"},{"Dwarf","Shaman"}}) do
  check(pair[1].." "..pair[2].." is unavailable",not A:IsRaceClassAllowed(pair[1],pair[2]))
end
for _,race in ipairs(A.RACES) do check(race.." supports Warrior and Hunter",A:IsRaceClassAllowed(race,"Warrior") and A:IsRaceClassAllowed(race,"Hunter")) end
check("profile compatibility accepts canonical client aliases",A:IsRaceClassAllowed("BloodElf","PALADIN") and A:IsRaceClassAllowed("NightElf","DRUID") and A:IsRaceClassAllowed("Scourge","WARLOCK"))
check("unknown race or class is rejected",not A:IsRaceClassAllowed("Unknown","Rogue") and not A:IsRaceClassAllowed("Tauren","Unknown"))
local original=A.current
local b=A.NewBuildData("Profile options");b.class="Warrior";b.race="Tauren";b.spec="Custom";b.talents=nil
A.current=b
local sig=A:GetBuildPayloadSignature(b);local options=A:GetProfileOptions("class")
check("class menu contains all nine choices including disabled",table.getn(options)==9 and Find(options,"Rogue").disabled and not Find(options,"Priest").disabled)
check("disabled pair has a readable reason",string.find(Find(options,"Rogue").reason,"Tauren",1,true)~=nil)
check("opening profile menus is pure for a legacy build",A:GetBuildPayloadSignature(b)==sig and b.talents==nil)
check("direct invalid class selection is rejected",A:SetClass("Rogue")==false and A.current.class=="Warrior" and A:GetBuildPayloadSignature(b)==sig)
check("valid Octo class change succeeds",A:SetClass("Priest") and b.class=="Priest" and b.race=="Tauren" and b.spec=="Discipline")
check("incompatible race option is visible and disabled",Find(A:GetProfileOptions("race"),"Goblin").disabled)
sig=A:GetBuildPayloadSignature(b)
check("direct invalid race selection cannot modify a plan",A:SetRace("Goblin")==false and b.race=="Tauren" and A:GetBuildPayloadSignature(b)==sig)
check("valid race and spec can be selected directly",A:SetRace("Human") and A:SetSpec("Shadow") and b.race=="Human" and b.spec=="Shadow")
sig=A:GetBuildPayloadSignature(b)
check("another class spec is rejected",A:SetSpec("Fury")==false and A:GetBuildPayloadSignature(b)==sig)
b.spec="Custom";b.updated=12345;b.manual=nil;sig=A:GetBuildPayloadSignature(b)
check("choosing current class does not reset Custom or dirty a plan",A:SetClass("PRIEST") and b.spec=="Custom" and b.updated==12345 and b.manual==nil and A:GetBuildPayloadSignature(b)==sig)
check("choosing current race or spec is also a no-op",A:SetRace("Human") and A:SetSpec("Custom") and b.updated==12345 and b.manual==nil)
b.talents={points={["1:1"]=1}};sig=A:GetBuildPayloadSignature(b)
check("class menu explains the existing talent reset requirement",Find(A:GetProfileOptions("class"),"Warlock").disabled and string.find(Find(A:GetProfileOptions("class"),"Warlock").reason,"Reset talents",1,true)~=nil)
check("class setter preserves talents until explicit reset",A:SetClass("Warlock")==false and b.class=="Priest" and b.talents.points["1:1"]==1 and A:GetBuildPayloadSignature(b)==sig)
b.class="Warrior";b.race="Human";b.spec="Saved tank label";b.talents={points={}}
local specs=A:GetProfileOptions("spec")
check("a saved custom label remains available alongside class presets",table.getn(specs)==5 and Find(specs,"Saved tank label") and not Find(specs,"Saved tank label").disabled)
b.class="Rogue";b.race="Tauren";b.spec="Custom";b.items={};b.enchants={}
A:MigrateBuild(b)
local d=A:GetDerivedStats(b);local warning=false
for _,line in ipairs(d.warnings) do if string.find(line,"Tauren / Rogue",1,true) then warning=true end end
check("old incompatible plans are preserved and explained",b.class=="Rogue" and b.race=="Tauren" and warning)
check("an old incompatible plan can be repaired via a valid race",A:SetRace("Human") and b.class=="Rogue" and b.race=="Human")
A.current=original
