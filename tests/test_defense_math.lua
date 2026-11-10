local AB=AshenBuilds
local function Close(a,b) return math.abs(a-b)<0.000001 end
local function Build(class)
  local b=AB.NewBuildData("Defense regression"); b.class=class; b.race="Human"; b.level=60
  b.items={MAINHAND=19019,OFFHAND=19349}; b.enchants={}; AB.EnsureTalents(b)
  return b
end
local function Talent(b,name,rank)
  local data=AB:GetTalentData(b.class)
  for t=1,3 do for i,v in ipairs(data[t]) do if v.name==name then b.talents.points[AB:GetTalentKey(t,i)]=rank end end end
end
for _,class in ipairs({"Warrior","Paladin"}) do
  local b=Build(class); local a=AB:GetDerivedStats(b)
  local original=AB.GetGearTotals
  AB.GetGearTotals=function(self,build) local g=original(self,build); g.defense=(g.defense or 0)+10; return g end
  local plus=AB:GetDerivedStats(b); AB.GetGearTotals=original
  for _,stat in ipairs({"dodge","parry","block","miss"}) do check(class.." +10 Defense adds 0.4 to "..stat,Close(plus[stat]-a[stat],0.4)) end
  local d60=AB:CalculateDefenseTable(a,60,0); local d63=AB:CalculateDefenseTable(a,63,0)
  for _,stat in ipairs({"dodge","parry","block","miss"}) do check(class.." boss3levels subtracts0.6 "..stat,Close(d60[stat]-d63[stat],0.6)) end
  check(class.." Defense counted once in avoidance",Close(plus.defenseTable.avoidance-a.defenseTable.avoidance,1.2))
  check(class.." Defense counted once in coverage",Close(plus.defenseTable.rawCoverage-a.defenseTable.rawCoverage,1.6))
  check(class.." equallevelcannotcrush",d60.rawCrushing==0 and d60.crushing==0)
  check(class.." level63crushbase15",d63.rawCrushing==15)
  b.items.OFFHAND=nil; local noShield=AB:GetDerivedStats(b)
  check(class.." no shield means no block or BV",noShield.block==0 and noShield.blockValue==0 and noShield.defenseTable.block==0)
  b.items.MAINHAND=nil; check(class.." no weapon means no parry",AB:GetDerivedStats(b).parry==0)
end
local b=Build("Warrior"); local d=AB:GetDerivedStats(b)
check("native54 + equip19 + strength are counted once",d.gear.blockValue==73 and d.blockValue==78)
Talent(b,"Toughness",5); check("Warrior Toughness scales completeBV by15percent",AB:GetDerivedStats(b).blockValue==89)
local p=Build("Paladin"); local plain=AB:GetDerivedStats(p)
Talent(p,"Shield Specialization",3); local specialized=AB:GetDerivedStats(p)
check("PaladinShieldSpec30percent scales completeBV",specialized.blockValue==math.floor((plain.gear.blockValue+plain.str/20-1)*1.3))
Talent(p,"Holy Shield",1); local passive=AB:GetDerivedStats(p)
check("HolyShieldtalentisnotpassiveblock",Close(passive.block,plain.block))
AB:SetDefenseSetting("holyShield",true,p); local active=AB:GetDerivedStats(p)
check("HolyShieldexplicitstateadds45",Close(active.defenseTable.rawCoverage-passive.defenseTable.rawCoverage,45))
check("buffpreviewdoesnotmutatepassivesheet",Close(active.block,passive.block))
AB:SetDefenseSetting("shieldBlock",true,b); local blocked=AB:GetDerivedStats(b)
check("ShieldBlockpreviewadds75",blocked.defenseTable.activeBlock==75)
local full=AB:CalculateDefenseTable(d,63,150)
check("effectivecoverageiscapped100",full.coverage==100 and full.capGap==0 and full.crit==0 and full.crushing==0)
local original=AB.GetGearTotals
AB.GetGearTotals=function(self,build) local g=original(self,build); g.defense=140; return g end
local capped=AB:GetDerivedStats(Build("Warrior")); AB.GetGearTotals=original
check("440Defense removeslevel63crit",capped.defenseTable.rawCrit==0)
check("Defensealonecannotremovethebasecrushchance",capped.defenseTable.rawCrushing==15)
local orphan=Build("Warrior"); orphan.items.HEAD=nil; orphan.enchants.HEAD=25
check("orphanenchantnotcounted",AB:GetDerivedStats(orphan).gear.blockValue==73)
local armored=Build("Warrior"); armored.items.CHEST=14624; armored.items.HANDS=14622; armored.items.WAIST=14620
armored.items.BACK=13340; armored.enchants.BACK=43
local ag=AB:GetGearTotals(armored)
check("setandcloakflatarmorareseparatefromitemarmor",ag.bonusArmor==120)
Talent(armored,"Toughness",5); local ad=AB:GetDerivedStats(armored)
check("Toughnessscalesitemarmorbutnotflatsetorenchantarmor",ad.armor==math.floor(ag.armor*1.1+120+ad.agi*2))
local bear=AB.NewBuildData("form"); bear.class="Druid"; bear.spec="Feral"; bear.form="bear"; AB.EnsureTalents(bear)
Talent(bear,"Feral Swiftness",2); local bd=AB:GetDerivedStats(bear)
bear.form="direbear"; local db=AB:GetDerivedStats(bear)
check("direbearretainsferaltalentstats",Close(bd.dodge,db.dodge) and bd.attackPower==db.attackPower and bd.meleeCrit==db.meleeCrit)
