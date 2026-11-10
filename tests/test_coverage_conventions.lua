local A=AshenBuilds
local function Near(a,b) return math.abs(a-b)<0.000001 end
local function Stats()
  return {base={level=60},defense=342,dodge=7.08,parry=11.68,block=8.68,canParry=true,canBlock=true}
end
-- User screenshot: Holy Shield +45 and Redoubt +15 on a level-60 Paladin.
local screenshot=A:CalculateDefenseTable(Stats(),63,60)
check("screenshot preserves individual sheet probabilities",Near(screenshot.sheetMiss,6.68) and Near(screenshot.sheetDodge,7.08) and Near(screenshot.sheetParry,11.68) and Near(screenshot.sheetBlock,68.68))
check("screenshot displays sheet94.12 against102.4",Near(screenshot.sheetCoverage,94.12) and Near(screenshot.sheetCap,102.4))
check("screenshot effective boss probabilities remain unchanged",Near(screenshot.miss,6.08) and Near(screenshot.dodge,6.48) and Near(screenshot.parry,11.08) and Near(screenshot.block,68.08) and Near(screenshot.rawCoverage,91.72))
check("screenshot both conventions leave8.28 points",Near(screenshot.capGap,8.28) and Near(screenshot.sheetGap,8.28))
for target=60,63 do
  local t=A:CalculateDefenseTable(Stats(),target,60)
  check("level"..target.." sheet cap matches four eligible categories",Near(t.sheetCap,100+(target-60)*0.8))
  check("level"..target.." sheet and effective gaps agree",Near(t.sheetGap,t.capGap))
end
local full=Stats();full.block=full.block+8.28
local capped=A:CalculateDefenseTable(full,63,60)
check("102.4 sheet coverage fills the100 effective table",Near(capped.sheetCoverage,102.4) and Near(capped.rawCoverage,100) and Near(capped.sheetGap,0) and Near(capped.capGap,0))
local shaman=Stats();shaman.canParry=false
local st=A:CalculateDefenseTable(shaman,63,60)
check("Shaman excludes unsupported parry from both conventions",st.sheetParry==0 and st.parry==0 and Near(st.sheetCoverage,82.44))
check("Shaman threshold counts three available categories",Near(st.sheetCap,101.8) and Near(st.sheetGap,st.capGap))
local mage=Stats();mage.canParry=false;mage.canBlock=false
local mt=A:CalculateDefenseTable(mage,63,60)
check("Mage ignores block buffs and unsupported abilities",mt.sheetParry==0 and mt.sheetBlock==0 and mt.parry==0 and mt.block==0 and Near(mt.sheetCoverage,13.76))
check("Mage threshold counts miss and dodge only",Near(mt.sheetCap,101.2) and Near(mt.sheetGap,mt.capGap))
local small=Stats();small.dodge=0.2;small.parry=0.3;small.block=0.4
local ft=A:CalculateDefenseTable(small,63,0)
check("low categories floor at zero in the effective table",ft.dodge==0 and ft.parry==0 and ft.block==0)
check("floor correction avoids blindly adding2.4",Near(ft.sheetCap,101.5) and Near(ft.sheetGap,ft.capGap) and Near(ft.sheetGap,93.92))
local over=Stats();over.block=150
local ot=A:CalculateDefenseTable(over,63,0)
check("sheet block and coverage remain unbounded above100",ot.sheetBlock==150 and Near(ot.sheetCoverage,175.44) and Near(ot.sheetCap,102.4))
check("overcap leaves zero gap in both conventions",ot.sheetGap==0 and ot.capGap==0 and ot.coverage==100)
local lower=A:CalculateDefenseTable(Stats(),59,60)
check("lower-level attacker uses a consistent inverse correction",Near(lower.sheetCap,99.2) and Near(lower.sheetGap,lower.capGap))
