-- Regressions for missing tank effects and inconsistent simulator item rules.
local A,S=AshenBuilds,AshenSim
local W=S.Warrior
local function Close(a,b) return math.abs(a-b)<0.000001 end
local function Build(class)
  local b=A.NewBuildData("1.0.8 calculations")
  b.class=class; b.race="Human"; b.level=60; b.spec="Custom"
  b.items={MAINHAND=19019,OFFHAND=19349,CHEST=11726}; b.enchants={}; b.talents={points={}}
  b.defense={targetLevel=63,holyShield=false,redoubt=false,shieldBlock=false}
  return b
end

local b=Build("Paladin")
local base=A:GetDerivedStats(b)
check("Divine Strength fixture has expected base stats",base.str==118 and base.attackPower==396 and base.blockValue==77)
local rank
for rank=1,5 do
  b.talents.points["1:1"]=rank
  local d=A:GetDerivedStats(b)
  local str=math.floor(base.str*(1+rank*0.02)+0.5)
  check("Divine Strength rank "..rank.." is a legal allocation",A:ValidateTalents(b)==true)
  check("Divine Strength rank "..rank.." scales Strength",d.str==str)
  check("Divine Strength rank "..rank.." feeds attack power",d.attackPower==base.attackPower+(str-base.str)*2)
  check("Divine Strength rank "..rank.." feeds shield block value",d.blockValue==math.floor(d.gear.blockValue+str/20-1))
end
local d=A:GetDerivedStats(b)
check("Divine Strength 5/5 repairs tank totals",d.str==130 and d.attackPower==420 and d.blockValue==78)

local _,class
for _,class in ipairs({"Paladin","Warrior"}) do
  b=Build(class); b.items.SHOULDER=16953
  local before=A:GetDerivedStats(b)
  local t0=A:GetDefenseTable(before,b)
  b.enchants.SHOULDER=157185
  local after=A:GetDerivedStats(b)
  local t1=A:GetDefenseTable(after,b)
  check(class.." Sigil is allowed on shoulders",A:IsEnchantAllowed("SHOULDER",157185,A:GetItem(16953)))
  check(class.." Sigil exposes three points of crit reduction",after.critTakenReduction==3)
  check(class.." Sigil reduces raw received critical chance",Close(t1.rawCrit,t0.rawCrit-3))
  check(class.." Sigil reduces received critical chance below coverage cap",Close(t1.crit,t0.crit-3))
  check(class.." Sigil does not invent avoidance or coverage",t0.avoidance==t1.avoidance and t0.rawCoverage==t1.rawCoverage and t0.sheetCoverage==t1.sheetCoverage and t0.capGap==t1.capGap)
  after.defense=500
  check(class.." received crit reduction floors at zero",A:CalculateDefenseTable(after,63,0).rawCrit==0)
  b.items.SHOULDER=nil
  check(class.." orphan Sigil is not counted",A:GetDerivedStats(b).critTakenReduction==0)
end

b=Build("Warrior"); b.enchants.MAINHAND=84
local cfg=W.DefaultSettings(); cfg.buffs={}
local c=W.BuildCharacter(b,cfg)
check("two-handed enchant is rejected on Thunderfury",not A:IsEnchantAllowed("MAINHAND",84,A:GetItem(19019)))
check("simulator does not apply rejected flat weapon damage",c.mh.bonus==0 and not c.mh.enchantName)
b.enchants.MAINHAND=75
check("simulator still applies valid flat weapon damage",W.BuildCharacter(b,cfg).mh.bonus==5)
b.enchants.MAINHAND=10
check("simulator still applies valid weapon procs",W.BuildCharacter(b,cfg).mh.enchantProc~=nil)
-- A future two-hand-only proc must follow the same compatibility rules as damage.
AshenBuildsEnchants[999999]={n="Two-hand proc fixture",slots={MAINHAND=true},req="twohand",spell=20034,stats={}}
b.enchants.MAINHAND=999999
c=W.BuildCharacter(b,cfg)
check("simulator rejects incompatible proc enchants too",not c.mh.enchantProc and not c.mh.enchantName)
AshenBuildsEnchants[999999]=nil

-- Use real boss events with a fixed hit/damage roll, and no player attacks.
b=Build("Warrior");b.items.OFFHAND=nil
cfg=W.DefaultSettings();cfg.buffs={};cfg.rotation="custom";cfg.custom={};cfg.useHeroicStrike=false
cfg.tanking="on";cfg.bossSpeed=100;cfg.bossMin=1200;cfg.bossMax=1200;cfg.duration=3
c=W.BuildCharacter(b,cfg)
c.defenseTable={miss=0,dodge=0,parry=0,block=0,rawCrit=0,rawCrushing=0}
local hits,actor={},nil
local model={Setup=function(sim,char,settings) actor=W.Setup(sim,char,settings);return actor end,Finish=W.Finish}
model.Start=function(sim,a)
  W.Start(sim,a)
  local boss=a.bossEvent.fn
  local i;for i=1,sim.queue.n do sim.queue.items[i].dead=true end
  sim.rng.Next=function() return 0.99 end
  sim.rng.Range=function() return 1200 end
  a.stance="battle";a.dodge=0
  local function Hit(s,arg)
    local before=s.counters.damageTaken or 0
    boss(s,arg)
    table.insert(hits,(s.counters.damageTaken or 0)-before)
  end
  sim:At(0.5,Hit,a)
  sim:At(1,function(s,arg) arg.auras["Death Wish"]:Apply(0.5);Hit(s,arg) end,a)
  sim:At(2,Hit,a)
end
local fight=S.RunFight(model,c,cfg,1)
local function Damage(armor) return 1200*(1-math.min(armor/(armor+400+85*cfg.targetLevel),0.75)) end
check("controlled boss events produced three ordinary hits",table.getn(hits)==3 and fight.counters["boss.hit"]==3)
check("incoming hit uses normal armor before Death Wish",Close(hits[1],Damage(c.playerArmor)))
check("incoming hit uses twenty percent less armor during Death Wish",Close(hits[2],Damage(c.playerArmor*0.8)) and hits[2]>hits[1])
check("incoming armor returns after Death Wish expires",Close(hits[3],hits[1]) and not actor.auras["Death Wish"].active)
check("damage-taken rage includes Death Wish penalty",Close(fight.counters["rage.gen.damageTaken"],(hits[1]+hits[2]+hits[3])/actor.rageConv*2.5))
