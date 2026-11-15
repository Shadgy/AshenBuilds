local A=AshenBuilds
local resistanceKeys={"arcaneRes","fireRes","frostRes","natureRes","shadowRes"}
local function AllResistances(id,expected)
  local stats=A:GetItemStatTotals(id)
  for _,key in ipairs(resistanceKeys) do
    if (stats[key] or 0)~=expected then return false end
  end
  return true
end

check("Ring of Binding applies its unconditional Equip effect to all five schools",
  AllResistances(18813,5) and A:GetItemStatTotals(18813).defense==6)
check("passive resistance already included in item stats is counted once",AllResistances(83597,5))
check("temporary and player-only resistance effects stay out of gear totals",
  AllResistances(10418,0) and AllResistances(15867,0) and AllResistances(83585,0))
check("single-school Equip resistance is recovered for Encrusted Gemstone Ring and Demon's Blood",
  A:GetItemStatTotals(56031).arcaneRes==5 and A:GetItemStatTotals(10779).shadowRes==10
    and A:GetItemStatTotals(10779).defense==3)

local build=A.NewBuildData("Passive gear stats")
build.class="Paladin"; build.race="Human"; build.level=60; build.spec="Custom"
build.items={}
local naked=A:GetDerivedStats(build)
check("Human Paladin base Spirit is 75 before the racial and 78 after it",naked.base.spi==75 and naked.spi==78)

build.items={HANDS=47020,LEGS=47022,WAIST=47029,MAINHAND=19360,FINGER1=18813}
local totals=A:GetDerivedStats(build)
check("Human Spirit applies once to raw base plus equipped Spirit",totals.gear.spi==28 and totals.spi==108)
check("derived resistances include the recovered passive and native item stats",
  totals.resistances.fire==15 and totals.resistances.frost==5 and totals.resistances.nature==5
    and totals.resistances.shadow==25 and totals.resistances.arcane==15)

build.class="Hunter"; build.items={}
check("a Human Hunter borrowed base uses the raw Human racial offset",A:GetBaseProfile(build).spi==70)
build.class="Paladin"; build.race="HighElf"
check("a non-Human Paladin borrowing a Human row discards the Human racial",
  A:GetDerivedStats(build).spi==74)
