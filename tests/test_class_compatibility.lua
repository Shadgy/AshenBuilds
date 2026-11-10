local A=AshenBuilds
local function Build(class)
  local b=A.NewBuildData("Class compatibility")
  b.class=class; b.race="Human"; b.level=60; b.spec=A.SPECS[class][1]
  b.items={MAINHAND=19019,OFFHAND=33135,HEAD=47016}; b.enchants={OFFHAND=113689}
  A.EnsureTalents(b)
  return b
end
local function HasWarning(stats,slot,fragment)
  for _,warning in ipairs(stats.warnings) do
    if string.find(warning,slot..":",1,true) and string.find(warning,fragment,1,true) then return true end
  end
  return false
end
local warlock=Build("Warlock")
local before=A:GetBuildPayloadSignature(warlock)
local wd=A:GetDerivedStats(warlock)
check("Warlock plan warns about Paladin-only helmet",HasWarning(wd,"HEAD","requires a different class than Warlock"))
check("Warlock plan warns about shield proficiency",HasWarning(wd,"OFFHAND","armor or shield proficiency"))
check("checking incompatible equipment does not change class or items",warlock.class=="Warlock" and warlock.items.HEAD==47016 and warlock.items.OFFHAND==33135 and A:GetBuildPayloadSignature(warlock)==before)
check("incompatible gear remains a hypothetical stat preview",wd.gear.defense==10 and wd.gear.shieldBaseBlockValue==48 and wd.armor>2645)
check("Warlock with Defense and shield gains no parry or block ability",wd.defense==310 and wd.parry==0 and wd.block==0 and wd.blockValue==0 and not wd.canParry and not wd.canBlock)
check("defensive attack table also excludes unsupported abilities",wd.defenseTable.parry==0 and wd.defenseTable.block==0)
local paladin=Build("Paladin"); local pd=A:GetDerivedStats(paladin)
check("Paladin can use matching helmet and shield without warning",not HasWarning(pd,"HEAD","class") and not HasWarning(pd,"OFFHAND","proficiency"))
check("screenshot shield native48 BV is included for Paladin",pd.gear.shieldBaseBlockValue==48 and pd.blockValue==52)
check("Paladin has class-gated parry and block",pd.canParry and pd.canBlock and math.abs(pd.parry-5.4)<0.00001 and math.abs(pd.block-9.4)<0.00001)
local warrior=Build("Warrior"); local rd=A:GetDerivedStats(warrior)
check("Warrior warns about Paladin-only helmet",HasWarning(rd,"HEAD","requires a different class than Warrior"))
check("Warrior can use the shield without proficiency warning",not HasWarning(rd,"OFFHAND","proficiency"))
check("screenshot shield native48 BV is included for Warrior",rd.gear.shieldBaseBlockValue==48 and rd.blockValue==53 and rd.canParry and rd.canBlock)
warlock.items.HEAD=nil; warlock.items.CHEST=14624; warlock.items.MAINHAND=17068
local other=A:GetDerivedStats(warlock)
check("ordinary plate also warns when it has no class restriction",HasWarning(other,"CHEST","armor or shield proficiency"))
check("unusable weapon family warns without changing the plan",HasWarning(other,"MAINHAND","weapon proficiency") and warlock.items.MAINHAND==17068)
warrior.items.HEAD=nil; warrior.items.CHEST=14624; warrior.level=20
check("armor proficiency respects the planned level",HasWarning(A:GetDerivedStats(warrior),"CHEST","at level 20"))
