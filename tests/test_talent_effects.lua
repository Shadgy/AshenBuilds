-- Explicit effects must agree with ranks and scope, never numbers guessed from prose.
local A=AshenBuilds

local function Build(class,id,rank,spec)
  local b=A.NewBuildData("Talent regression"); b.class=class; b.level=60; b.spec=spec or "Custom"
  b.talents={points={}}; local data=A:GetTalentData(class); local t,i,v,found
  for t=1,3 do for i=1,table.getn(data[t]) do
    v=data[t][i]
    if v.ranks[1]==id then b.talents.points[A:GetTalentKey(t,i)]=rank; found=true end
  end end
  check("fixture talent exists "..class.."/"..id,found)
  return b
end

local r,m,b
for r=1,5 do
  m=A:GetTalentModifiers(Build("Warrior",12299,r))
  check("Toughness armor at rank "..r,m.armorPct==r*2)
  check("Toughness shield absorption at rank "..r,m.blockValuePct==r*3)
  m=A:GetTalentModifiers(Build("Warrior",12298,r))
  check("warrior shield specialization block rank "..r,m.block==r)
end
for r=1,3 do
  m=A:GetTalentModifiers(Build("Paladin",20148,r))
  check("paladin shield specialization BV rank "..r,m.blockValuePct==r*10 and not m.block)
  m=A:GetTalentModifiers(Build("Warrior",12297,r))
  check("warrior Anticipation Defense rank "..r,m.defense==({7,14,20})[r])
  m=A:GetTalentModifiers(Build("Paladin",20096,r))
  check("paladin Anticipation Defense rank "..r,m.defense==({7,14,20})[r])
  m=A:GetTalentModifiers(Build("Druid",45715,r))
  check("Natural Weapons selects hit series rank "..r,m.hit==r and m.spellHit==r)
  m=A:GetTalentModifiers(Build("Warrior",12163,r))
  check("two-hand specialization selects skill series rank "..r,m.twoHandSkill==r)
end

m=A:GetTalentModifiers(Build("Paladin",20925,1))
check("Holy Shield does not passively add block",not m.block)
check("Holy Shield exposes timed charged effect",m.activeEffects.holyShield.block==45 and m.activeEffects.holyShield.duration==10 and m.activeEffects.holyShield.charges==4)
for r=1,5 do
  m=A:GetTalentModifiers(Build("Paladin",45818,r))
  check("Redoubt uses block series only when activated rank "..r,not m.block and m.activeEffects.redoubt.block==r*3)
end
m=A:GetTalentModifiers(Build("Warrior",12975,1))
check("Last Stand is not passive health",not m.healthPct and m.activeEffects.lastStand.healthPct==30)
m=A:GetTalentModifiers(Build("Warrior",51598,2))
check("Improved Shield Slam does not parse cooldown as block",not m.block and m.activeEffects.improvedShieldSlam.block==70)
m=A:GetTalentModifiers(Build("Druid",45708,1,"Feral"))
check("Berserk energy text is not passive health",not m.healthPct and m.activeEffects.berserk.bearHealthPct==20)
m=A:GetTalentModifiers(Build("Hunter",19263,1))
check("Deterrence avoidance is conditional",not m.parry and not m.dodge and m.activeEffects.deterrence.parry==25)

m=A:GetTalentModifiers(Build("Druid",17002,2,"Feral"))
check("Feral Swiftness never treats movement speed as dodge",not m.dodge and m.feralDodge==4)
m=A:GetTalentModifiers(Build("Druid",16929,3))
check("Thick Hide counts armor once",m.armorPct==10)
m=A:GetTalentModifiers(Build("Druid",16942,3))
check("Sharpened Claws counts crit once",m.feralCrit==6)
m=A:GetTalentModifiers(Build("Druid",16972,3))
check("Predatory Strikes counts attack power once",m.feralAPPct==10)
m=A:GetTalentModifiers(Build("Priest",18551,3))
check("Mental Strength counts Intellect once",m.intPct==10)
m=A:GetTalentModifiers(Build("Priest",14901,5))
check("Spiritual Guidance counts Spirit conversion once",m.spiritToSpellPct==25)
m=A:GetTalentModifiers(Build("Priest",20711,1))
check("Spirit of Redemption counts passive Spirit once",m.spiPct==10)
m=A:GetTalentModifiers(Build("Priest",18544,5))
check("Force of Will is damage multiplier, not flat spell power",m.spellDamagePct==5 and not m.spellPowerPct)
check("offensive spell crit does not inflate healing crit",m.offensiveSpellCrit==5 and not m.spellCrit and table.getn(m.scopedEffects)==1)
m=A:GetTalentModifiers(Build("Priest",14889,5))
check("Divinity remains school-scoped",not m.spellCrit and m.scopedEffects[1].stats.spellCrit==5)
m=A:GetTalentModifiers(Build("Mage",11115,3))
check("Critical Mass remains Fire-scoped",not m.spellCrit and m.scopedEffects[1].stats.spellCrit==6)
m=A:GetTalentModifiers(Build("Hunter",19609,3))
check("pet Thick Hide does not change player armor",not m.armorPct)
m=A:GetTalentModifiers(Build("Shaman",45545,3))
check("Ancestral Guardian separates armor and dodge series",m.armorPct==15 and m.dodge==6)
m=A:GetTalentModifiers(Build("Shaman",16253,5))
check("shaman shield specialization handles both passive effects",m.block==5 and m.blockValuePct==30)
m=A:GetTalentModifiers(Build("Warlock",18697,5))
check("Demonic Embrace reduces rather than increases Spirit",m.staPct==15 and m.spiPct==-5)
m=A:GetTalentModifiers(Build("Rogue",13712,5))
check("Rogue Lightning Reflexes grants dodge",m.dodge==5)
m=A:GetTalentModifiers(Build("Hunter",19426,5))
check("Lethal Shots remains ranged-only",m.rangedCrit==5 and not m.meleeCrit)

-- Stable IDs, rather than names and incidental numbers, select known effects.
local data=A:GetTalentData("Warrior"); local talent=data[3][6]
local t,i
for t=1,3 do for i=1,table.getn(data[t]) do if data[t][i].ranks[1]==12299 then talent=data[t][i] end end end
local oldName,oldDesc=talent.name,talent.desc
talent.name="Renamed talent"; talent.desc="Increases total health by 999% and block by 777%."
m=A:GetTalentModifiers(Build("Warrior",12299,5))
check("ID effects do not depend on label or description numbers",m.armorPct==10 and m.blockValuePct==15 and not m.healthPct)
talent.name=oldName; talent.desc=oldDesc

-- Talent editing preserves Druid form even when it changes the preset label.
local original=A.current
b=Build("Druid",17002,1,"Feral"); A.current=b
local ti,ix
local dd=A:GetTalentData("Druid")
for t=1,3 do for i=1,table.getn(dd[t]) do if dd[t][i].ranks[1]==17002 then ti=t; ix=i end end end
A:SetTalentRank(ti,ix,2)
check("talent edits preserve feral form",b.spec=="Custom" and A:GetBuildForm(b)=="bear")
b.form="cat"; A:ResetTalents()
check("reset preserves explicitly selected form",A:GetBuildForm(b)=="cat")
b.form="humanoid"
check("explicit humanoid form overrides old preset",A:GetBuildForm(b)=="humanoid")

-- Ordinary clicks may not invalidate higher-tier points or make self-exports unusable.
b=A.NewBuildData("Tier regression"); b.class="Warrior"; b.level=60; b.talents={points={}}; A.current=b
for i=1,5 do A:AddTalentPoint(1,2) end
A:AddTalentPoint(1,5)
check("tier fixture is valid",A:ValidateTalents(b))
local before=A:ExportBuild(b)
check("removing a required earlier-row point is rejected",A:RemoveTalentPoint(1,2)==false and A:GetTalentRank(b,1,2)==5)
local decoded=A:DecodeBuild(A:ExportBuild(b))
check("rejected removal leaves a valid round-trip",decoded~=nil and before==A:ExportBuild(b))
check("valid higher-tier removal succeeds",A:RemoveTalentPoint(1,5)==true)
check("earlier row can be removed after dependencies",A:RemoveTalentPoint(1,2)==true and A:GetTalentRank(b,1,2)==4)
b.talents.points[A:GetTalentKey(1,2)]=1.5
check("fractional talent ranks fail validation",not A:ValidateTalents(b))
A.current=original
