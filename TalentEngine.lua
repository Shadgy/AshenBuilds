AshenBuilds = AshenBuilds or {}
local AB = AshenBuilds

AB.CLASS_TOKENS = {Warrior="WARRIOR",Paladin="PALADIN",Hunter="HUNTER",Rogue="ROGUE",Priest="PRIEST",Shaman="SHAMAN",Mage="MAGE",Warlock="WARLOCK",Druid="DRUID"}
AB.TREE_NAMES = {
  WARRIOR={"Arms","Fury","Protection"}, PALADIN={"Holy","Protection","Retribution"}, HUNTER={"Beast Mastery","Marksmanship","Survival"},
  ROGUE={"Assassination","Combat","Subtlety"}, PRIEST={"Discipline","Holy","Shadow"}, SHAMAN={"Elemental","Enhancement","Restoration"},
  MAGE={"Arcane","Fire","Frost"}, WARLOCK={"Affliction","Demonology","Destruction"}, DRUID={"Balance","Feral","Restoration"}
}

local function ensureTalents(build)
  build.talents = build.talents or {}
  build.talents.points = build.talents.points or {}
  return build.talents.points
end
AB.EnsureTalents = ensureTalents

local oldMigrate = AB.MigrateBuild
function AB:MigrateBuild(build)
  oldMigrate(self, build)
  ensureTalents(build)
end

function AB:GetTalentData(className)
  local token=self.CLASS_TOKENS[className] or string.upper(className or "")
  return AshenBuildsTalentData and AshenBuildsTalentData[token], token
end

-- The selected form is independent of the talent preset's display name.
function AB:GetBuildForm(build)
  build=build or self.current
  if not build or build.class~="Druid" then return "humanoid" end
  local form=build.form
  if form=="bear" or form=="direbear" or form=="cat" or form=="moonkin" or form=="tree" or form=="humanoid" then return form end
  if build.spec=="Feral" then return "bear" end
  if build.spec=="Balance" then return "moonkin" end
  return "humanoid"
end

function AB:GetTalentKey(treeIndex,talentIndex) return tostring(treeIndex)..":"..tostring(talentIndex) end
function AB:GetTalentRank(build,treeIndex,talentIndex)
  local p=ensureTalents(build or self.current)
  return tonumber(p[self:GetTalentKey(treeIndex,talentIndex)]) or 0
end
function AB:GetTalentPointsInTree(build,treeIndex)
  local data=self:GetTalentData((build or self.current).class); if not data or not data[treeIndex] then return 0 end
  local total=0; local i
  for i=1,table.getn(data[treeIndex]) do total=total+self:GetTalentRank(build,treeIndex,i) end
  return total
end
function AB:GetTalentPointsSpent(build)
  local total=0; local t
  for t=1,3 do total=total+self:GetTalentPointsInTree(build or self.current,t) end
  return total
end
function AB:GetTalentBudget(build)
  local level=self:GetBuildLevel(build or self.current)
  return math.max(0,level-9)
end
function AB:CanAddTalent(build,treeIndex,talentIndex)
  build=build or self.current
  local data=self:GetTalentData(build.class); local talent=data and data[treeIndex] and data[treeIndex][talentIndex]
  if not talent then return false,"Talent data unavailable" end
  local rank=self:GetTalentRank(build,treeIndex,talentIndex); local max=table.getn(talent.ranks or {})
  if rank>=max then return false,"Maximum rank" end
  if self:GetTalentPointsSpent(build)>=self:GetTalentBudget(build) then return false,"No talent points available" end
  local required=(tonumber(talent.row) or 1)-1; required=required*5
  local below,j=0,nil
  for j=1,table.getn(data[treeIndex]) do
    if (tonumber(data[treeIndex][j].row) or 1)<(tonumber(talent.row) or 1) then below=below+self:GetTalentRank(build,treeIndex,j) end
  end
  if below<required then return false,"Requires "..required.." points in earlier rows" end
  if talent.req then
    local reqRank=self:GetTalentRank(build,treeIndex,tonumber(talent.req))
    local reqTalent=data[treeIndex][tonumber(talent.req)]
    local reqMax=reqTalent and table.getn(reqTalent.ranks or {}) or 1
    if reqRank<reqMax then return false,"Requires "..((reqTalent and reqTalent.name) or "prerequisite talent") end
  end
  return true
end
function AB:SetTalentRank(treeIndex,talentIndex,rank)
  local build=self.current; local data=self:GetTalentData(build.class); local talent=data and data[treeIndex] and data[treeIndex][talentIndex]
  if not talent then return end
  local max=table.getn(talent.ranks or {}); rank=math.max(0,math.min(max,tonumber(rank) or 0))
  rank=math.floor(rank)
  if build.class=="Druid" then build.form=self:GetBuildForm(build) end
  local key=self:GetTalentKey(treeIndex,talentIndex); ensureTalents(build)[key]=rank>0 and rank or nil
  build.spec="Custom"; build.updated=time(); self:RefreshUI(); if self.RefreshTalentUI then self:RefreshTalentUI() end
end
function AB:AddTalentPoint(treeIndex,talentIndex)
  local ok,msg=self:CanAddTalent(self.current,treeIndex,talentIndex); if not ok then self.Print(msg); return end
  self:SetTalentRank(treeIndex,talentIndex,self:GetTalentRank(self.current,treeIndex,talentIndex)+1)
end
function AB:RemoveTalentPoint(treeIndex,talentIndex)
  local rank=self:GetTalentRank(self.current,treeIndex,talentIndex); if rank<=0 then return end
  local candidate=self:DeepCopy(self.current)
  ensureTalents(candidate)[self:GetTalentKey(treeIndex,talentIndex)]=rank>1 and rank-1 or nil
  local ok,why=self:ValidateTalents(candidate)
  if not ok then self.Print("Cannot remove talent: "..why.."."); return false end
  self:SetTalentRank(treeIndex,talentIndex,rank-1)
  return true
end
function AB:ResetTalents()
  if self.current.class=="Druid" then self.current.form=self:GetBuildForm(self.current) end
  self.current.talents={points={}}; self.current.spec="Custom"; self.current.updated=time(); self:RefreshUI(); if self.RefreshTalentUI then self:RefreshTalentUI() end
end

-- Explicit passive effects keyed by class and the talent's first-rank spell ID.
-- Values follow the bundled talent dataset. Text is never evaluated as a formula:
-- active, pet-only and spell/school-limited effects must not inflate passive totals.
local EFFECTS={
  WARRIOR={
    [16462]={stats={parry={1,2,3,4,5}}}, -- Deflection
    [12163]={stats={twoHandSkill={1,2,3}},note="Two-handed damage bonus is separate from weapon skill."},
    [12320]={stats={meleeCrit={1,2,3,4,5}}}, -- Cruelty
    [23584]={stats={offHandHit={2,4,6,8,10}}}, -- Dual Wield Specialization: off-hand only
    [12298]={stats={block={1,2,3,4,5}}}, -- Shield Specialization
    [12297]={stats={defense={7,14,20}}}, -- Anticipation
    [12299]={stats={armorPct={2,4,6,8,10},blockValuePct={3,6,9,12,15}}}, -- Toughness
    [12975]={active={key="lastStand",healthPct={30},duration=20},note="Last Stand requires activation; not included in passive health."},
    [12328]={note="Death Wish is an active timed effect; not included in passive stats."},
    [51598]={active={key="improvedShieldSlam",block={35,70},duration=4.5,charges=1},note="The extra block chance follows Shield Slam and applies to the next attack only."},
    [54023]={note="Master Strike's weapon-dependent effects require an active attack."},
    [51644]={scope="Axes only (Master of Arms)",scoped={meleeCrit={1,2,3,4,5}},note="Master of Arms is weapon-specific; not added to generic crit."},
  },
  PALADIN={
    [20262]={stats={strPct={2,4,6,8,10}}}, -- Divine Strength
    [20257]={stats={intPct={2,4,6,8,10}}}, -- Divine Intellect
    [20189]={stats={hit={1,2,3},spellHit={1,2,3}}}, -- Precision
    [20143]={stats={armorPct={2,4,6,8,10}}}, -- Toughness
    [20148]={stats={blockValuePct={10,20,30}}}, -- Shield Specialization
    [20096]={stats={defense={7,14,20}}}, -- Anticipation
    [20060]={stats={parry={1,2,3,4,5}}}, -- Deflection
    [20117]={stats={meleeCrit={1,2,3,4,5}}}, -- Conviction
    [20111]={stats={twoHandSkill={1,2,3}},note="Two-handed damage bonus is separate from weapon skill."},
    [51310]={stats={itemArmorToHealingPct={1,2}},note="Ironclad converts item armor into healing, not spell damage."},
    [45818]={active={key="redoubt",block={3,6,9,12,15},duration=10,charges=5},note="Redoubt requires an active proc; not included in passive block."},
    [20925]={active={key="holyShield",block={45},duration=10,charges=4},note="Holy Shield requires activation and charges; not included in passive block."},
    [20217]={note="Blessing of Kings requires an applied blessing; learning it alone does not grant stats."},
    [20138]={note="Improved Devotion Aura requires the corresponding active aura."},
    [20234]={note="Improved Lay on Hands grants a timed armor buff, not passive armor."},
    [51312]={scope="Holy Shock only",scoped={spellCrit={10,20,30,40,50}}},
    [5923]={scope="Holy Light and Flash of Light only",scoped={spellCrit={2,4,6}}},
  },
  DRUID={
    [45715]={stats={hit={1,2,3},spellHit={1,2,3}},note="Natural Weapons' physical damage bonus is separate from hit chance."},
    [16929]={stats={armorPct={3,6,10}}}, -- Thick Hide
    [17002]={stats={feralDodge={2,4}}}, -- Feral Swiftness
    [16942]={stats={feralCrit={2,4,6}}}, -- Sharpened Claws
    [16972]={stats={feralAPPct={3,6,10}}}, -- Predatory Strikes
    [24858]={form="moonkin",stats={moonkinArmorPct={180},spellCrit={3}},note="Moonkin bonuses apply only while planning Moonkin Form."},
    [17007]={form="feral",stats={meleeCrit={3},rangedCrit={3}},note="Leader of the Pack requires Cat, Bear or Dire Bear Form."},
    [45708]={active={key="berserk",bearHealthPct={20},duration=20},note="Berserk is an active form-dependent effect; not included in passive health."},
    [45705]={form="tree",stats={treeArmorPct={180},spiritToHealingPct={20}},note="Tree of Life bonuses require Tree Form."},
  },
  HUNTER={
    [19426]={stats={rangedCrit={1,2,3,4,5}}}, -- Lethal Shots
    [19295]={stats={parry={1,2},haste={1,2}}}, -- Swift Reflexes
    [19255]={stats={healthPct={2,4,6,8,10}}}, -- Survivalist
    [19370]={stats={meleeCrit={1,2,3},rangedCrit={1,2,3}}}, -- Killer Instinct
    [19168]={stats={agiPct={2,4,6,8,10},agiToAPPct={20,40,60,80,100}}}, -- Lightning Reflexes
    [19290]={stats={hit={1,2,3}},scope="Additional hit while dual wielding",scoped={hit={1,2,3}}},
    [19263]={active={key="deterrence",dodge={25},parry={25},duration=10},note="Deterrence requires activation; not included in passive avoidance."},
    [19609]={note="Thick Hide affects the pet's armor, not the hunter's character-sheet armor."},
    [19549]={note="Improved Primal Aspects requires an active Aspect of the Monkey/Wolf."},
  },
  ROGUE={
    [14138]={stats={meleeCrit={1,2,3,4,5},rangedCrit={1,2,3,4,5}}}, -- Malice
    [13712]={stats={dodge={1,2,3,4,5}}}, -- Lightning Reflexes
    [13713]={stats={parry={1,2,3,4,5}}}, -- Deflection
    [13705]={stats={hit={1,2,3,4,5}}}, -- Precision
    [30919]={stats={axeSkill={3,5},daggerSkill={3,5},fistSkill={3,5},maceSkill={3,5},swordSkill={3,5}}},
    [13706]={scope="Maces, Daggers and Fist Weapons",scoped={meleeCrit={2,5}}},
    [14177]={note="Cold Blood requires activation and affects selected abilities only."},
  },
  PRIEST={
    [18551]={stats={intPct={3,6,10}},note="Mental Strength's casting speed bonus is separate from attack haste."},
    [18544]={stats={spellDamagePct={1,2,3,4,5},offensiveSpellCrit={1,2,3,4,5}},scope="Offensive spells only",scoped={spellCrit={1,2,3,4,5}},note="Force of Will changes spell damage and offensive crit; it does not add flat spell power or healing crit."},
    [14901]={stats={spiritToSpellPct={5,10,15,20,25}}}, -- Spiritual Guidance
    [20711]={stats={spiPct={10}}}, -- Spirit of Redemption's passive component
    [14889]={scope="Holy and Discipline spells",scoped={spellCrit={1,2,3,4,5}}}, -- Divinity
    [51462]={scope="Holy and Discipline spells",scoped={spellHit={2,4,6}}}, -- Piercing Light
    [15260]={scope="Shadow spells",scoped={spellHit={2,4,6,8,10}}}, -- Shadow Focus
    [15259]={scope="Shadow damage",scoped={spellDamagePct={2,4,6,8,10}}}, -- Darkness
    [14751]={note="Inner Focus requires activation and affects the next spell only."},
    [15270]={note="Spirit Tap requires an active proc; not included in passive Spirit."},
    [15473]={note="Shadowform is an active form; its damage and mitigation are not passive stat bonuses."},
  },
  MAGE={
    [29441]={stats={allResistances={4,7,10}}}, -- Magic Absorption
    [11242]={scope="Arcane spells",scoped={spellCrit={2,4,6}}}, -- Arcane Impact
    [11115]={scope="Fire spells",scoped={spellCrit={2,4,6}}}, -- Critical Mass
    [11124]={scope="Fire damage",scoped={spellDamagePct={2,4,6,8,10}}}, -- Fire Power
    [29438]={scope="Fire and Frost spells",scoped={spellHit={2,4,6}}}, -- Elemental Precision
    [12042]={note="Arcane Power requires activation; not included in passive stats."},
    [11129]={note="Combustion requires activation and changing stacks; not included in passive crit."},
    [11170]={scope="Frozen targets only",scoped={spellCrit={7,14,21,28,35}}}, -- Shatter
  },
  WARLOCK={
    [18697]={stats={staPct={3,6,9,12,15},spiPct={-1,-2,-3,-4,-5}}}, -- Demonic Embrace
    [18174]={scope="Affliction spells",scoped={spellHit={2,4,6,8,10}}}, -- Suppression
    [18130]={scope="Destruction spells",scoped={spellCrit={1,2,3,4,5}}}, -- Devastation
    [18731]={note="Fel Intellect affects the demon, not the warlock's Intellect."},
    [18748]={note="Fel Stamina affects the demon, not the warlock's Stamina."},
    [23785]={note="Master Demonologist depends on the active demon; not included without that state."},
    [18788]={note="Demonic Sacrifice requires an active sacrifice effect."},
  },
  SHAMAN={
    [30160]={stats={hit={1,2,3},spellHit={1,2,3}},note="Elemental Devastation's additional spell hit requires an active melee-crit proc."},
    [17485]={stats={strPct={1,2,3,4,5},agiPct={1,2,3,4,5},staPct={1,2,3,4,5},intPct={1,2,3,4,5},spiPct={1,2,3,4,5}}},
    [16253]={stats={block={1,2,3,4,5},blockValuePct={6,12,18,24,30}}}, -- Shield Specialization
    [16255]={stats={meleeCrit={1,2,3,4,5},rangedCrit={1,2,3,4,5}}}, -- Thundering Strikes
    [45545]={stats={armorPct={5,10,15},dodge={2,4,6}}}, -- Ancestral Guardian
    [45951]={stats={shieldArmorPct={15,30}}}, -- Spirit Armor
    [16041]={scope="Lightning Bolt and Chain Lightning only",scoped={spellCrit={1,2,3,4,6}}},
    [16194]={scope="Healing and lightning spells",scoped={spellCrit={1,2,3,4,5}}},
    [56556]={scope="Fire, Frost and Nature damage",scoped={spellDamagePct={5,10}}},
    [45509]={note="Bloodlust requires activation; not included in passive haste."},
    [16176]={note="Ancestral Healing requires an active proc on the healed target."},
  },
}
AB.TALENT_EFFECTS=EFFECTS

local function add(m,key,value)
  if value and value~=0 then m[key]=(m[key] or 0)+value end
end
local function valuesAtRank(values,rank)
  local out={}; local key,series
  for key,series in pairs(values or {}) do
    if type(series)=="table" then out[key]=series[rank] else out[key]=series end
  end
  return out
end
local function formMatches(form,required)
  if not required then return true end
  if required=="feral" then return form=="bear" or form=="direbear" or form=="cat" end
  return form==required
end

function AB:GetTalentModifiers(build)
  build=build or self.current
  local data,token=self:GetTalentData(build.class)
  local m={notes={},sources={},activeEffects={},scopedEffects={}}
  if not data then return m end
  local definitions=EFFECTS[token] or {}; local form=self:GetBuildForm(build)
  local ti,i,talent,rank,entry,key,value,stats,applied,active,scope
  for ti=1,3 do
    for i=1,table.getn(data[ti] or {}) do
      talent=data[ti][i]; rank=self:GetTalentRank(build,ti,i)
      entry=definitions[talent.ranks and talent.ranks[1]]
      if entry and rank==math.floor(rank) and rank>0 and rank<=table.getn(talent.ranks or {}) then
        applied={}
        if formMatches(form,entry.form) then
          stats=valuesAtRank(entry.stats,rank)
          for key,value in pairs(stats) do add(m,key,value); if value and value~=0 then table.insert(applied,key) end end
        end
        if entry.active then
          active=valuesAtRank(entry.active,rank); key=active.key; active.key=nil
          m.activeEffects[key]=active; table.insert(applied,"active effect (not passive)")
        end
        if entry.scoped then
          scope={name=talent.name,rank=rank,scope=entry.scope,stats=valuesAtRank(entry.scoped,rank)}
          table.insert(m.scopedEffects,scope); table.insert(applied,entry.scope or "restricted effect")
          table.insert(m.notes,talent.name..": "..(entry.scope or "restricted effect").."; excluded from generic spell statistics.")
        end
        if entry.note then table.insert(m.notes,talent.name..": "..entry.note) end
        if entry.form and not formMatches(form,entry.form) then table.insert(m.notes,talent.name..": requires "..entry.form.." form.") end
        if table.getn(applied)>0 then table.sort(applied); table.insert(m.sources,{name=talent.name,rank=rank,effects=table.concat(applied,", ")}) end
      end
    end
  end
  return m
end

-- Talents in build codes (AB3). An AB3 code is the AB2 gear code followed by
-- one token per talent tree. Each character packs two talents' ranks (0-5) as
-- first*6+second, and trailing all-zero characters are trimmed, so a full
-- build adds about 30 characters and still fits in one chat message.
local function encodeTree(build,data,tree)
  local out,i,a,b="",nil,nil,nil
  for i=1,table.getn(data[tree] or {}),2 do
    a=AB:GetTalentRank(build,tree,i); b=AB:GetTalentRank(build,tree,i+1)
    out=out..AB.EncodeNumber(a*6+b)
  end
  out=string.gsub(out,"0+$","")
  if out=="" then out="0" end
  return out
end

local function decodeTree(token,points,tree)
  local k,v
  for k=1,string.len(token) do
    v=AB.DecodeNumber(string.sub(token,k,k))
    if not v or v>35 then return false end
    if math.floor(v/6)>0 then points[AB:GetTalentKey(tree,k*2-1)]=math.floor(v/6) end
    if math.mod(v,6)>0 then points[AB:GetTalentKey(tree,k*2)]=math.mod(v,6) end
  end
  return true
end

-- Checks a finished allocation the way the talent UI would have built it:
-- known talents only, ranks within max, enough points in lower rows, maxed
-- prerequisites, and no more points than the level allows.
function AB:ValidateTalents(build)
  local points=ensureTalents(build); local data=self:GetTalentData(build.class)
  local key,rank,tree,index,talent,below,i,other,_
  for key,rank in pairs(points) do
    _,_,tree,index=string.find(key,"^(%d+):(%d+)$"); tree=tonumber(tree); index=tonumber(index)
    talent=data and tree and data[tree] and data[tree][index]
    if not talent then return false,"unknown talent "..key end
    rank=tonumber(rank) or 0
    if rank~=math.floor(rank) or rank<1 or rank>table.getn(talent.ranks or {}) then return false,talent.name.." has an invalid rank" end
    below=0
    for i=1,table.getn(data[tree]) do
      other=data[tree][i]
      if (tonumber(other.row) or 1)<(tonumber(talent.row) or 1) then below=below+self:GetTalentRank(build,tree,i) end
    end
    if below<((tonumber(talent.row) or 1)-1)*5 then return false,talent.name.." needs more points in earlier rows" end
    if talent.req then
      other=data[tree][tonumber(talent.req)]
      if not other or self:GetTalentRank(build,tree,tonumber(talent.req))<table.getn(other.ranks or {}) then return false,talent.name.." is missing its prerequisite" end
    end
  end
  if self:GetTalentPointsSpent(build)>self:GetTalentBudget(build) then return false,"more talent points than level "..self:GetBuildLevel(build).." allows" end
  return true
end

-- "31/20/0"-style point split, used by the community list.
function AB:GetTalentSplit(build)
  return self:GetTalentPointsInTree(build,1).."/"..self:GetTalentPointsInTree(build,2).."/"..self:GetTalentPointsInTree(build,3)
end

local baseExport=AB.ExportBuild
function AB:ExportBuild(build)
  build=build or self.current
  local code=baseExport(self,build)
  local data=self:GetTalentData(build.class)
  if not data then return code end
  return "AB3."..string.sub(code,5).."."..encodeTree(build,data,1).."."..encodeTree(build,data,2).."."..encodeTree(build,data,3)
end

local baseDecode=AB.DecodeBuild
function AB:DecodeBuild(code)
  if type(code)~="string" or string.sub(code,1,4)~="AB3." then
    local build,err=baseDecode(self,code)
    if build then ensureTalents(build) end
    return build,err
  end
  local tokens=self:SplitBuildCode(code)
  if not tokens then return nil,"Invalid build code fields." end
  local n=table.getn(tokens)
  if n<8 then return nil,"Incomplete build code." end
  local build,err=baseDecode(self,"AB2."..table.concat(tokens,".",2,n-3))
  if not build then return nil,err end
  local points={}; local tree
  for tree=1,3 do
    if not decodeTree(tokens[n-3+tree],points,tree) then return nil,"Invalid talents in build code." end
  end
  build.talents={points=points}
  local ok,why=self:ValidateTalents(build)
  if not ok then return nil,"Invalid talents in build code ("..why..")." end
  return build
end
