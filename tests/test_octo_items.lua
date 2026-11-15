local A=AshenBuilds
local settings=A:GetAvailabilitySettings()
settings.profile="Octo"; settings.phase=2; settings.includeUnknown=false; settings.showFuture=false
local picker=A.ItemIndex
picker:Reset(); picker:Finish()

local function Find(id,query,slot,level,source)
  local matches=picker:Query({query=query,slot=slot,maxReq=level,level=level,source=source,availability=settings})
  for _,position in ipairs(matches) do
    if picker.id[position]==id then return true end
  end
  return false
end

check("Spellwoven Nobility Drape is visible in the phase 2 crafted cloak picker",
  Find(55056,"spellwoven nobility drape","BACK",60,16))
check("the Dire Maul source search includes the corrected Grandstaff",
  Find(55060,"dire maul","MAINHAND",60,16))
check("Shen'dralar vendor stock is included in reputation search",
  Find(58257,"elisandra spellbinder","MAINHAND",60,32))
check("Ring of the Academy appears with quest and level filters in place",
  Find(60622,"ring of the academy","FINGER1",60,4))
check("Ring of the Academy is usable at the acceptance level, not the display level",
  Find(60622,"ring of the academy","FINGER1",58,4) and not Find(60622,"ring of the academy","FINGER1",57,4))
for _,id in ipairs({60624,60625,60626}) do
  check("Ending Arc'Tiras reward "..id.." is indexed at its acceptance level",
    Find(id,"ending arc'tiras","ALL",58,4))
end
settings.instances={["Stormwind Vault"]=true}
check("verified ring matches the Stormwind Vault instance filter",
  Find(60622,"ring of the academy","FINGER1",60,4))
check("the Stormwind Vault filter excludes the Dire Maul cloak",
  not Find(55056,"spellwoven nobility drape","BACK",60,16))
settings.instances={}

local katana=A:GetItem(93223)
check("the Octo-only crafted katana has confirmed native damage, speed and source",
  katana and katana.minDamage==12.8 and katana.maxDamage==19 and katana.speed==1.5
    and A:GetItemSources(93223)[1][2]==65210)
local katanaCount=0
for _,id in ipairs(AshenDB.ItemOrder) do if id==93223 then katanaCount=katanaCount+1 end end
check("the new katana is indexed once and searchable by crafting source",
  Find(93223,"blacksmithing","MAINHAND",18,16) and katanaCount==1)
check("the newly added vendor sword respects the required level",
  Find(90053,"simple katana","MAINHAND",10,256) and not Find(90053,"simple katana","MAINHAND",9,256))
check("unverified PvP entries are hidden by default",
  A:GetItem(58247).stats.sta==10 and not Find(58247,"champion's insignia","TRINKET1",60,0))
settings.includeUnknown=true
check("unverified entries can be inspected explicitly",
  Find(58247,"champion's insignia","TRINKET1",60,0) and Find(83605,"lamellar girdle","WAIST",60,0))
check("reviewing unverified gear does not open Tower of Karazhan",
  not Find(55285,"","ALL",60,0) and A:GetItemAvailability(55285).phase==7)
local girdle=A:GetItem(83605)
check("girdle damage reduction does not count as crit chance reduction",
  girdle.stats.spellPower==15 and not girdle.stats.critTakenReduction and not next(A:GetItemEffectStats(83605)))
