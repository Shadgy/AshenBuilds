-- Shared item totals and frontal physical melee defense model (Lua 5.0).
local AB = AshenBuilds

local function Add(target, source)
  local key, value
  for key, value in pairs(source or {}) do
    if type(value)=="number" then target[key]=(target[key] or 0)+value end
  end
end

function AB:GetItemStatTotals(id)
  local item=self:GetItem(id); if not item then return {} end
  local totals={}; Add(totals,item.stats)
  if totals.armor==nil then totals.armor=item.armor or 0 end
  local key,value
  for key,value in pairs(self:GetItemEffectStats(id) or {}) do
    -- An exporter may already include an Equip stat. It must not count twice.
    if not item.stats or item.stats[key]==nil then totals[key]=value end
  end
  if item.shield then
    totals.shieldBaseBlockValue=item.shieldBaseBlockValue or 0
    totals.blockValue=(totals.blockValue or 0)+totals.shieldBaseBlockValue
  end
  return totals
end

function AB:GetSetStatTotals(build)
  local totals, applied={},{}
  local setId,count,i,bonus,stats,key,value
  for setId,count in pairs(self:GetSetCounts(build)) do
    local set=self:GetItemSet(setId)
    for i=1,table.getn(set and set.bonuses or {}) do
      bonus=set.bonuses[i]
      if count>=(bonus[1] or 99) then
        stats=self.StaticSetStats and self.StaticSetStats[bonus[2]]
        if stats then
          Add(totals,stats)
          table.insert(applied,{set=set.name,spell=bonus[2],stats=stats})
        end
      end
    end
  end
  return totals,applied
end

function AB:GetDefenseSettings(build)
  build=build or self.current
  local s=build and type(build.defense)=="table" and build.defense or {}
  local function Enabled(value) return value==true or value==1 end
  return {targetLevel=math.max(1,math.min(63,math.floor(tonumber(s.targetLevel) or 63))),
    holyShield=Enabled(s.holyShield),redoubt=Enabled(s.redoubt),shieldBlock=Enabled(s.shieldBlock)}
end

function AB:SetDefenseSetting(key,value,build)
  build=build or self.current; if not build then return false end
  if key~="targetLevel" and key~="holyShield" and key~="redoubt" and key~="shieldBlock" then return false end
  local s=self:GetDefenseSettings(build)
  if key=="targetLevel" then s[key]=math.max(1,math.min(63,math.floor(tonumber(value) or 63)))
  else s[key]=value==true or value==1 end
  build.defense=s; build.updated=time()
  return true
end

local function Percent(value) return math.max(0,math.min(100,value or 0)) end

-- Octo developer formula: miss = 5 - 0.2 * (weapon skill - target Defense).
-- Keep flat Hit separate: the simulator must not count skill a second time.
function AB:CalculateMeleeMiss(weaponSkill,targetDefense,hit,dualWield)
  local miss=5+((targetDefense or 0)-(weaponSkill or 0))*0.2
  if dualWield then miss=miss*0.8+20 end
  return Percent(miss-(hit or 0))
end

-- The inherited 1.12 sheet model also grants 0.04% crit per bonus skill.
function AB:CalculateMeleeCrit(baseCrit,weaponSkill,level,targetLevel)
  return math.max(0,(baseCrit or 0)+(level-targetLevel)+(weaponSkill-level*5)*0.04)
end

function AB:GetMeleeHitPreview(stats,build)
  if not stats.mainSkill then return nil end
  local form=self.GetBuildForm and self:GetBuildForm(build)
  if build.class=="Druid" and (form=="cat" or form=="bear" or form=="direbear") then return nil end
  local level=stats.base.level
  local targetLevel=self:GetDefenseSettings(build).targetLevel
  local targetDefense=targetLevel*5
  local dualWield=stats.offSkill and true or false
  local function Hand(skill,offHandHit)
    if not skill then return nil end
    local bonus=(skill.total-level*5)*0.2
    local hit=stats.hit+(offHandHit or 0)
    return {skill=skill.total,skillHit=bonus,effectiveHit=hit+bonus,offHandHit=offHandHit or 0,
      hitCap=self:CalculateMeleeMiss(skill.total,targetDefense,0,false),
      miss=self:CalculateMeleeMiss(skill.total,targetDefense,hit,false),
      whiteMiss=self:CalculateMeleeMiss(skill.total,targetDefense,hit,dualWield)}
  end
  return {targetLevel=targetLevel,targetDefense=targetDefense,dualWield=dualWield,
    main=Hand(stats.mainSkill),off=Hand(stats.offSkill,stats.talentModifiers and stats.talentModifiers.offHandHit)}
end

-- The sheet includes Defense above level*5 once. Against a different-level NPC,
-- subtract only the level/weapon-skill difference from dodge/parry/block.
-- Reference: vmangos StatSystem.cpp and SpellCaster::RollMeleeOutcomeAgainst.
function AB:CalculateDefenseTable(stats,targetLevel,bonusBlock)
  local level=stats.base.level
  targetLevel=math.max(1,math.min(63,math.floor(tonumber(targetLevel) or 63)))
  local skill=targetLevel*5
  local levelPenalty=(skill-level*5)*0.04
  local t={targetLevel=targetLevel}
  t.miss=Percent(5+(stats.defense-skill)*0.04)
  t.dodge=Percent((stats.dodge or 0)-levelPenalty)
  t.parry=stats.canParry and Percent((stats.parry or 0)-levelPenalty) or 0
  t.block=stats.canBlock and Percent((stats.block or 0)-levelPenalty+(bonusBlock or 0)) or 0
  t.avoidance=Percent(t.miss+t.dodge+t.parry)
  t.rawCoverage=t.miss+t.dodge+t.parry+t.block
  t.coverage=Percent(t.rawCoverage)
  t.capGap=math.max(0,100-t.rawCoverage)
  t.overCap=math.max(0,t.rawCoverage-100)
  -- The familiar 102.4% convention uses same-level sheet values. Each eligible
  -- category loses 0.6 points against a +3-level attacker, unless it floors at 0.
  -- Keep these totals unbounded above 100; the effective table stays separate.
  t.sheetMiss=5+(stats.defense-level*5)*0.04
  t.sheetDodge=stats.dodge or 0
  t.sheetParry=stats.canParry and (stats.parry or 0) or 0
  t.sheetBlock=stats.canBlock and ((stats.block or 0)+(bonusBlock or 0)) or 0
  t.sheetCoverage=t.sheetMiss+t.sheetDodge+t.sheetParry+t.sheetBlock
  local function SheetPenalty(value) return value-math.max(0,value-levelPenalty) end
  t.sheetCap=100+SheetPenalty(t.sheetMiss)+SheetPenalty(t.sheetDodge)
  if stats.canParry then t.sheetCap=t.sheetCap+SheetPenalty(t.sheetParry) end
  if stats.canBlock then t.sheetCap=t.sheetCap+SheetPenalty(t.sheetBlock) end
  t.sheetGap=math.max(0,t.sheetCap-t.sheetCoverage)
  -- Defense suppresses critical chance, but cannot directly remove crushing
  -- blows: their base chance uses Defense capped at the level maximum.
  t.rawCrit=Percent(5+(skill-stats.defense)*0.04)
  local crushDiff=skill-math.min(stats.defense,level*5)
  t.rawCrushing=crushDiff>=15 and Percent(crushDiff*2-15) or 0
  t.crit=math.min(t.rawCrit,math.max(0,100-t.rawCoverage))
  t.crushing=math.min(t.rawCrushing,math.max(0,100-t.rawCoverage-t.crit))
  t.hit=math.max(0,100-t.rawCoverage-t.crit-t.crushing)
  t.modelNote="Frontal physical NPC melee snapshot; active buffs have limited duration and charges. Server-specific mechanics require an in-game check."
  return t
end

function AB:GetDefenseTable(stats,build)
  build=build or self.current
  local s=self:GetDefenseSettings(build)
  local effects=stats.talentModifiers and stats.talentModifiers.activeEffects or {}
  local bonus=0
  if stats.canBlock then
    if build.class=="Paladin" then
      if s.holyShield and effects.holyShield then bonus=bonus+(effects.holyShield.block or 0) end
      if s.redoubt and effects.redoubt then bonus=bonus+(effects.redoubt.block or 0) end
    elseif build.class=="Warrior" and s.shieldBlock and stats.base.level>=16 then bonus=75 end
  end
  local t=self:CalculateDefenseTable(stats,s.targetLevel,bonus)
  t.activeBlock=bonus
  return t
end

function AB:GetCalculationWarnings(build,stats)
  local warnings={}; local i,slot,id,item
  local className=stats.base and stats.base.className or build.class
  local level=stats.base and stats.base.level or self.ValidLevel(build.level)
  if self.IsRaceClassAllowed and not self:IsRaceClassAllowed(build.race,className) then
    table.insert(warnings,tostring(build.race).." / "..className.." is not available on Octo. The saved plan is preserved; choose a compatible CLASS or RACE.")
  end
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]; id=build.items and build.items[slot]; item=id and self:GetItem(id)
    if id and not item then table.insert(warnings,slot..": item #"..id.." is missing from the database; its stats are not counted.") end
    if item then
      local raw=self:GetRawItem(id)
      local reason
      if raw and not self:IsClassAllowedRaw(raw,className) then
        reason="requires a different class than "..className
      elseif item.itemClass==4 then
        local rule=self.ArmorProficiency and self.ArmorProficiency[item.subclass]
        if rule and (not rule[className] or level<rule[className]) then
          reason="cannot be used by "..className.." at level "..level.." (armor or shield proficiency)"
        end
      elseif item.itemClass==2 then
        local weapon=raw and raw[18]
        local rule=self.WeaponProficiency and self.WeaponProficiency[className]
        if weapon and weapon~="" and weapon~="Weapon" and weapon~="Fishing Pole" and rule and not rule[weapon] then
          reason="cannot be used by "..className.." (weapon proficiency)"
        end
      end
      if reason then table.insert(warnings,slot..": "..item.n.." "..reason..". Its stats remain included for preview; check the selected CLASS.") end
    end
    if item and item.shield and not item.shieldBlockKnown then table.insert(warnings,"Native shield Block Value is unknown for "..item.n.."; the displayed total is incomplete.") end
    local enchant=build.enchants and build.enchants[slot]
    if enchant and not self:IsEnchantAllowed(slot,enchant,item) then table.insert(warnings,slot..": incompatible or orphan enchant is not counted.") end
  end
  local notes=stats.talentModifiers and stats.talentModifiers.notes or {}
  for i=1,table.getn(notes) do table.insert(warnings,notes[i]) end
  local slot,native
  for slot,native in pairs(build.unmappedEnchants or {}) do
    table.insert(warnings,slot..": native enchant #"..native.." is not recognized; its stats are not counted.")
  end
  local setId,count,bonus,set
  for setId,count in pairs(self:GetSetCounts(build)) do
    set=self:GetItemSet(setId)
    for i=1,table.getn(set and set.bonuses or {}) do
      bonus=set.bonuses[i]
      local reason=self.StaticSetStatsUnhandled and self.StaticSetStatsUnhandled[bonus[2]]
      if count>=(bonus[1] or 99) and reason then
        table.insert(warnings,(set.name or "Set").." ("..bonus[1].." pieces): "..(bonus[3] or "").." -- conditional or unsupported parts are not included in passive totals.")
      end
    end
  end
  if self.ValidateTalents then
    local valid,reason=self:ValidateTalents(build)
    if not valid then table.insert(warnings,"Invalid talent allocation: "..tostring(reason)) end
  end
  return warnings
end
