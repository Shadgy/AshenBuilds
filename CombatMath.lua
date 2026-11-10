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
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]; id=build.items and build.items[slot]; item=id and self:GetItem(id)
    if id and not item then table.insert(warnings,slot..": item #"..id.." is missing from the database; its stats are not counted.") end
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
