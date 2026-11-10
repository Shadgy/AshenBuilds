-- Permanent set bonuses must enter the same totals as item/enchants exactly once.
local AB=AshenBuilds
local stats=AB.StaticSetStats or {}
check("static set catalog includes Deathbone defense",stats[7516] and stats[7516].defense==3)
check("static set catalog includes flat Deathbone armor and parry",stats[9764] and stats[9764].bonusArmor==50 and not stats[9764].armor and stats[13665] and stats[13665].parry==1)
check("static set catalog includes all five ordinary resistances",stats[18686] and stats[18686].fireRes==15 and stats[18686].frostRes==15 and stats[18686].natureRes==15 and stats[18686].shadowRes==15 and stats[18686].arcaneRes==15)
check("static set catalog includes Might shield block value",stats[23562] and stats[23562].blockValue==30)
check("spell hit set aura does not become spell crit",stats[23727] and stats[23727].spellHit==1 and not stats[23727].spellCrit)
check("paired AP and RAP set aura does not double ranged AP",stats[14049] and stats[14049].ap==40 and not stats[14049].rap)
check("proc and stance effects remain explicitly unhandled",not stats[21838] and not stats[52401] and AB.StaticSetStatsUnhandled and AB.StaticSetStatsUnhandled[21838] and AB.StaticSetStatsUnhandled[52401])
check("unconditional mixed set spell keeps BV and its unknown threat note",stats[51836] and stats[51836].blockValue==67 and AB.StaticSetStatsUnhandled[51836])

local function Build(items)
  local b=AB.NewBuildData("set regression"); b.class="Warrior"; b.race="Human"; b.level=60
  b.items=items; b.enchants={}; AB.EnsureTalents(b)
  return b
end
local function ItemOnly(build,key)
  local total,id=0,nil
  for _,id in pairs(build.items) do total=total+(AB:GetItemStatTotals(id)[key] or 0) end
  return total
end
local one=Build({CHEST=14624})
local two=Build({CHEST=14624,HANDS=14622})
local three=Build({CHEST=14624,HANDS=14622,WAIST=14620})
local five=Build({CHEST=14624,HANDS=14622,WAIST=14620,LEGS=14623,FEET=14621})
check("one Deathbone piece does not activate two-piece defense",(AB:GetGearTotals(one).defense or 0)==ItemOnly(one,"defense"))
check("two Deathbone pieces add exactly three defense",(AB:GetGearTotals(two).defense or 0)==ItemOnly(two,"defense")+3)
check("three Deathbone pieces add exactly fifty flat bonus armor",(AB:GetGearTotals(three).bonusArmor or 0)==ItemOnly(three,"bonusArmor")+50)
local all=AB:GetGearTotals(five)
check("five Deathbone pieces do not repeat lower thresholds",(all.defense or 0)==ItemOnly(five,"defense")+3 and (all.bonusArmor or 0)==ItemOnly(five,"bonusArmor")+50)
check("four-piece resistance and five-piece parry are active together",(all.fireRes or 0)==ItemOnly(five,"fireRes")+15 and (all.parry or 0)==ItemOnly(five,"parry")+1)
local might=Build({WAIST=16864,WRIST=16861,CHEST=16865,OFFHAND=19349})
check("three Might pieces add thirty BV to native and Equip values",(AB:GetGearTotals(might).blockValue or 0)==ItemOnly(might,"blockValue")+30)
