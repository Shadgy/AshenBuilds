local A=AshenBuilds
local idx=A.ItemIndex; idx:Finish()
local s=A:GetAvailabilitySettings()
s.profile="Octo"; s.phase=2; s.showFuture=false; s.includeUnknown=false; s.instances={}
local function Has(list,id)
  for _,p in ipairs(list) do if idx.id[p]==id then return true end end
  return false
end
local function Warning(stats,fragment)
  for _,text in ipairs(stats.warnings) do if string.find(text,fragment,1,true) then return true end end
  return false
end

-- The filter dropdown and existing selections must use the same location keys
-- as the recorded acquisition routes. No wing-level evidence is inferred.
local wings={"Graveyard","Library","Armory","Cathedral"}
local parent=A:GetItemAvailability(7717,s)
check("Ravager remains a verified phase2 suggestion",parent.verified and parent.status=="available")
for _,wing in ipairs(wings) do
  local old="Scarlet Monastery "..wing
  s.instances={[old]=true}
  check("old "..wing.." selection matches parent evidence",A:MatchesContentInstances(parent,s))
  s.instances={["Scarlet Monastery ("..wing..")"]=true}
  check("Atlas "..wing.." alias matches parent evidence",A:MatchesContentInstances(parent,s))
  local present=false
  for _,name in ipairs(A.CONTENT_INSTANCES) do if name==old then present=true end end
  check("dropdown omits unsupported "..wing.." option",not present)
end
s.instances={["Scarlet Monastery Armory"]=true,["Scarlet Monastery Library"]=true,["Blackwing Lair"]=true}
local settings=A:GetAvailabilitySettings()
check("stored wing filters migrate to one parent and retain other choices",settings==s and s.instances["Scarlet Monastery"] and s.instances["Blackwing Lair"] and not s.instances["Scarlet Monastery Armory"] and not s.instances["Scarlet Monastery Library"])
s.instances={["Scarlet Monastery"]=true}
local monastery=idx:Query({slot="ALL",availability=s})
check("parent instance filter contains actual wing drops",Has(monastery,7717) and Has(monastery,7718) and Has(monastery,7721))
local fixture=990108
AshenDB.Items[fixture]={"Alias source fixture",3,"TRINKET",1,1,"INV_Misc_QuestionMark",4,0,0,0,-1,-1,0,0,0,0,0,"",{}}
AshenBuildsAtlasLootSources.items[fixture]={routes={{instance="Scarlet Monastery (Armory)",phase=0,kind="dungeon"}}}
check("source-side aliases use the same canonical location",A:GetItemAvailability(fixture,s).instances["Scarlet Monastery"] and A:MatchesContentInstances(A:GetItemAvailability(fixture,s),s))
s.instances={}

-- These are the catalog's declared restrictions, not a new assertion about live
-- Octo exceptions. Recorded exceptions can explicitly replace a single mask.
local frost=A:GetRawItem(17909)
check("Frostwolf fixture retains its declared Horde race mask",frost[12]==434)
for _,race in ipairs({"Orc","Undead","Scourge","Tauren","Troll","Goblin"}) do
  check("Horde mask allows "..race,A:IsRaceAllowedRaw(frost,race,17909))
end
for _,race in ipairs({"Human","Dwarf","Night Elf","NightElf","Gnome","High Elf","HighElf","BloodElf"}) do
  check("Horde mask excludes "..race,not A:IsRaceAllowedRaw(frost,race,17909))
end
local raw={}; raw[12]=-1
check("negative race mask is unrestricted",A:IsRaceAllowedRaw(raw,"High Elf"))
raw[12]=0
check("zero race mask declares no eligible race",not A:IsRaceAllowedRaw(raw,"Human"))
raw[12]=589
check("custom Alliance race uses its client bit",A:IsRaceAllowedRaw(raw,"BloodElf") and not A:IsRaceAllowedRaw(raw,"Goblin"))
check("unrecognized race is not silently guessed",A:IsRaceAllowedRaw(raw,"Unknown race"))
local function Frostwolf(race)
  return idx:Query({slot="TRINKET1",query="frostwolf insignia rank 6",class="Warrior",race=race,level=60,maxReq=60,availability=s})
end
check("usable Human suggestions exclude catalog Horde-only trinket",not Has(Frostwolf("Human"),17909))
check("usable Orc suggestions retain catalog-compatible trinket",Has(Frostwolf("Orc"),17909))
check("omitting race permits deliberate unrestricted browsing",Has(Frostwolf(nil),17909))
local b=A.NewBuildData("Race restriction preview")
b.class="Warrior"; b.race="Human"; b.level=60; b.items={TRINKET1=17909}; b.enchants={}
A.EnsureTalents(b)
local before=A:GetBuildPayloadSignature(b)
local stats=A:GetDerivedStats(b)
check("incompatible saved item stays equipped with explicit race warning",b.items.TRINKET1==17909 and Warning(stats,"catalog race restrictions") and stats.gear.dodge==2 and A:GetBuildPayloadSignature(b)==before)
A.ItemRaceMaskOverrides[17909]=-1
check("recorded item exception applies without rebuilding search index",Has(Frostwolf("Human"),17909) and not Warning(A:GetDerivedStats(b),"catalog race restrictions"))
A.ItemRaceMaskOverrides[17909]=nil
b.enchants.TRINKET1=999999999
check("unknown imported enchant has a specific missing-data warning",Warning(A:GetDerivedStats(b),"enchant #999999999 is missing from the database"))

-- Compare ordered results against independent acquisition filtering of indexed
-- candidates, then count expensive calls instead of asserting host timings.
local cases={
  {slot="ALL",query="thunderfury"}, {slot="ALL",query="no_such_item_108"},
  {slot="ALL",query="thunderfury",class="Paladin",race="Human",level=60,maxReq=60},
  {slot="ALL",query="defense"}, {slot="ALL",query="blockvalue"},
  {slot="ALL",query="onyxia",source=2}, {slot="ALL",stats={{"blockValue",50}}},
}
for n,f in ipairs(cases) do
  local candidates=idx:Query(f); local expected={}
  for _,p in ipairs(candidates) do
    local result=A:GetItemAvailability(idx.id[p],s)
    if A:MatchesAvailability(result,s,f.showHidden) and A:MatchesContentInstances(result,s) then table.insert(expected,p) end
  end
  f.availability=s
  local actual=idx:Query(f); local same=table.getn(expected)==table.getn(actual)
  for i,p in ipairs(expected) do if actual[i]~=p then same=false end end
  check("ordered acquisition filtering is preserved for query "..n,same)
end
local original=A.GetItemAvailability; local calls=0
A.GetItemAvailability=function(self,...) calls=calls+1; return original(self,unpack(arg)) end
local thunder=idx:Query({slot="ALL",query="thunderfury",availability=s})
check("specific-name search resolves availability only for its candidate",Has(thunder,19019) and calls==1)
calls=0; idx:Query({slot="ALL",query="no_such_item_108",availability=s})
check("absent name performs no acquisition lookups",calls==0)
calls=0; idx:Query({slot="ALL",stats={{"blockValue",999999}},availability=s})
check("impossible numeric threshold performs no acquisition lookups",calls==0)
A.GetItemAvailability=original

-- Exercise the real browser wiring as well as the index API. Either usability
-- checkbox opts into the build's race restrictions; both off allows exploration.
A.current=b; A:OpenItemBrowser("TRINKET1")
A.itemSearch:SetText("frostwolf insignia rank 6")
A.itemFilter.classOnly=true; A.itemFilter.usable=true; A:RefreshItemResults()
check("item browser passes the current race into usable suggestions",not Has(A.itemMatches,17909))
A.itemFilter.classOnly=false; A.itemFilter.usable=false; A:RefreshItemResults()
check("item browser can deliberately disable race restrictions",Has(A.itemMatches,17909))
