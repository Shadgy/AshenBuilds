local A=AshenBuilds
local s=A:GetAvailabilitySettings();s.profile="Octo";s.phase=2;s.showFuture=false;s.instances={};s.includeUnknown=false
local atlas=AshenBuildsAtlasLootSources
check("bundled AtlasLoot evidence records snapshot provenance",atlas and atlas.meta.version=="3.4.6" and atlas.meta.files["Database/Instances.lua"] and atlas.meta.enchantCount>200)
for _,id in ipairs({55285,55098,55278,55283}) do
  local r=A:GetItemAvailability(id)
  check("Tower item"..id.." is verified phase7",r.status=="future" and r.verified and r.phase==7 and r.instances["Tower of Karazhan"])
  check("phase2 excludes Tower item"..id,not A:MatchesAvailability(r,s))
  s.includeUnknown=true
  check("Unverified cannot bypass Tower phase for"..id,not A:MatchesAvailability(r,s))
  s.includeUnknown=false
end
local idx=A.ItemIndex;idx:Reset();idx:Finish()
local function Has(list,id) for _,p in ipairs(list) do if idx.id[p]==id then return true end end return false end
local raid=idx:Query({slot="HANDS",source=2,availability=s})
check("actual raid picker excludes Tower in phase2",not Has(raid,55285) and not Has(raid,55098) and not Has(raid,55278) and not Has(raid,55283))
check("actual raid picker retains BWL gear",A:GetItemAvailability(19349).status=="available" and A:GetItemAvailability(19349).verified)
for _,id in ipairs({12584,18877}) do
  local r=A:GetItemAvailability(id)
  check("rank14 header keeps weapon"..id.." atphase6",r.verified and r.status=="future" and r.phase==6)
  s.includeUnknown=true
  check("Unverified cannot unlock rank14 weapon"..id,not A:MatchesAvailability(r,s))
  s.includeUnknown=false
end
local event=A:GetItemAvailability(22999)
check("a generic Tabards collection cannot override actual Scourge phase",event.status=="future" and event.phase==6)
local helm=A:GetItemAvailability(47016)
s.instances={["Blackwing Lair"]=true}
check("an early T2 helmet does not gain a false BWL source",helm.phase==0 and not A:MatchesContentInstances(helm,s))
s.instances={}
s.phase=7
local later=idx:Query({slot="HANDS",source=2,availability=s})
check("Tower opens in phase7 without Unverified",Has(later,55285) and Has(later,55098))
s.phase=6
local corrupted=A:GetItemAvailability(22691)
check("Corrupted Ashbringer is verified Naxx loot",corrupted.verified and corrupted.status=="available" and corrupted.phase==6)
local naxx=idx:Query({slot="ALL",source=2,query="ashbringer",availability=s})
check("Atlas source fills missing Raid category for Corrupted Ashbringer",Has(naxx,22691) and not Has(naxx,13262))
s.phase=2
for _,id in ipairs({13262,18582,18583,18584}) do
  local r=A:GetItemAvailability(id)
  check("showcase weapon"..id.." has no verified source",r.status=="unknown" and not r.verified)
  check("showcase weapon"..id.." is hidden in normal suggestions",not A:MatchesAvailability(r,s,true))
  s.includeUnknown=true
  check("showcase weapon"..id.." is available only by explicit Unverified",A:MatchesAvailability(r,s,false))
  s.includeUnknown=false
end
local plain=idx:Query({slot="ALL",query="ashbringer",availability=s,showHidden=true})
check("Show hidden alone cannot enable original Ashbringer",not Has(plain,13262))
s.includeUnknown=true
local uncertain=idx:Query({slot="ALL",query="ashbringer",availability=s})
check("Unverified exposes original without Show hidden",Has(uncertain,13262) and not Has(uncertain,22691))
s.includeUnknown=false
for _,row in ipairs({{37,6},{38,6},{39,6},{40,6},{48,4},{66,4},{146602,3},{157119,3},{149018,5},{149020,5}}) do
  local r=A:GetEnchantAvailability(row[1])
  check("Atlas enchant"..row[1].." keeps required phase"..row[2],r.verified and r.status=="future" and r.phase==row[2] and not A:MatchesAvailability(r,s))
end
atlas.enchants[990777]={routes={{kind="craft",phase=0,table="Fixture"}}}
AshenBuildsContentSources.enchants[990777]={l=6,u=true,z={533}}
local craft=A:GetEnchantAvailability(990777)
check("generic profession presence cannot erase required future materials",craft.verified and craft.status=="future" and craft.phase==6)
s.includeUnknown=true
check("Unverified still cannot bypass a verified enchant phase",not A:MatchesAvailability(craft,s))
s.phase=6
check("mandatory future recipe opens at its required phase",A:GetEnchantAvailability(990777).status=="available")
atlas.enchants[990778]={routes={{kind="raid",phase=6,instance="Naxxramas"},{kind="craft"}}}
s.phase=2;s.includeUnknown=false
local alternative=A:GetEnchantAvailability(990778)
check("an unresolved earlier alternative is not asserted to require Naxx",alternative.status=="unknown" and alternative.verified and alternative.minPhase==0 and alternative.knownSourcePhase==6 and not A:MatchesAvailability(alternative,s))
s.includeUnknown=true
check("explicit Unverified can inspect a genuinely unknown alternative",A:MatchesAvailability(alternative,s))
atlas.enchants[990778].routes[2].minimumPhase=6
local bounded=A:GetEnchantAvailability(990778)
check("a necessary bound on every alternative still blocks future content",bounded.status=="future" and bounded.phase==6 and not A:MatchesAvailability(bounded,s))
local settings=AshenBuildsDB.settings
settings.availability={profile="Octo",phase=2,includeUnknown=true}
local migrated=A:GetAvailabilitySettings()
check("old permissive defaults migrate once to verified-only",migrated.includeUnknown==false and migrated.atlasPolicy==1)
migrated.includeUnknown=true
check("explicit Unverified choice survives subsequent refresh",A:GetAvailabilitySettings().includeUnknown==true)
local current=A.current;local original=current.items.MAINHAND;current.items.MAINHAND=13262
migrated.includeUnknown=false;A:RefreshUI()
check("source filtering never removes a saved planned weapon",current.items.MAINHAND==13262)
current.items.MAINHAND=original
