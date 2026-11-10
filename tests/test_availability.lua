local A=AshenBuilds
local s=A:GetAvailabilitySettings()
check("content profile defaults to Octo phase 2",s.profile=="Octo" and s.phase==2)
check("AtlasLoot policy defaults to verified sources only",s.includeUnknown==false and s.atlasPolicy==1)
check("Sapphiron enchant is future in phase 2",A:GetEnchantAvailability(37).status=="future" and not A:MatchesAvailability(A:GetEnchantAvailability(37)))
s.phase=6
check("Sapphiron enchant opens with Naxx phase",A:GetEnchantAvailability(37).status=="available" and A:MatchesAvailability(A:GetEnchantAvailability(37)))
s.phase=2

local function Item(id,sources,cats)
  AshenDB.Items[id]={"Bulwark Example",4,"SHIELD",60,70,"INV_Shield_01",4,6,2000,0,-1,-1,1,0,0,0,0,"",{},cats or {}}
  AshenDB.ItemSources[id]=sources
  local routes,complete={},sources and table.getn(sources)>0 and not cats
  for _,source in ipairs(sources or {}) do
    local phase=({["Blackwing Lair"]=2,["Naxxramas"]=6,["Molten Core"]=0})[source[4] or ""]
    if source[1]=="drop" and phase then table.insert(routes,{instance=source[4],phase=phase,kind="raid",source=source[3],table="Fixture"}) else complete=false end
  end
  if complete then AshenBuildsAtlasLootSources.items[id]={routes=routes} end
end
Item(990001,{{"drop",1,"Nefarian","Blackwing Lair"},{"drop",2,"Sapphiron","Naxxramas"}})
Item(990002,{{"drop",2,"Sapphiron","Naxxramas"}})
Item(990003,{{"drop",2,"Sapphiron","Naxxramas"},{"more",2}})
Item(990004,nil)
Item(990005,{{"drop",1,"Nefarian","Blackwing Lair"}},{"unobtainable"})
check("one current acquisition route is enough",A:GetItemAvailability(990001).status=="available")
check("complete future-only sources can be filtered",A:GetItemAvailability(990002).status=="future" and not A:MatchesAvailability(A:GetItemAvailability(990002)))
s.includeUnknown=true
check("truncated sources are not treated as future-only",A:GetItemAvailability(990003).status=="unknown" and A:MatchesAvailability(A:GetItemAvailability(990003)))
check("missing source is unknown rather than unavailable",A:GetItemAvailability(990004).status=="unknown" and A:MatchesAvailability(A:GetItemAvailability(990004)))
check("catalog flags without Atlas evidence remain unverified",A:GetItemAvailability(990005).status=="unknown" and A:GetItemAvailability(990005).catalogUnavailable)
s.includeUnknown=false
check("verified-only mode excludes unknowns",not A:MatchesAvailability(A:GetItemAvailability(990004)))
s.includeUnknown=true; s.instances={["Blackwing Lair"]=true}
check("instance selection matches a currently open route",A:MatchesContentInstances(A:GetItemAvailability(990001)))
s.instances={["Naxxramas"]=true}
check("an open BWL alternative cannot bypass a closed Naxx selection",not A:MatchesContentInstances(A:GetItemAvailability(990001)))
s.phase=6
check("Naxx route matches when its selected phase opens",A:MatchesContentInstances(A:GetItemAvailability(990001)))
s.phase=2; s.showFuture=true
check("future view explicitly permits a closed selected route",A:MatchesContentInstances(A:GetItemAvailability(990001)))
s.showFuture=false
Item(990006,{{"drop",1,"Boss","Molten Core"},{"drop",2,"Sapphiron","Naxxramas"}})
s.instances={["Molten Core"]=true,["Naxxramas"]=true}
check("mixed selection keeps an actual open MC route",A:MatchesContentInstances(A:GetItemAvailability(990006)))
s.instances={["Naxxramas"]=true}
check("unknown routes cannot bypass an entirely closed selection",not A:MatchesContentInstances(A:GetItemAvailability(990003)))
s.instances={["Molten Core"]=true}
check("instance selection excludes verified unrelated routes",not A:MatchesContentInstances(A:GetItemAvailability(990001)))
check("incomplete sources remain explicitly eligible when requested",A:MatchesContentInstances(A:GetItemAvailability(990003)))
s.instances={}; s.profile="Catalog"
check("full catalog permits future content",A:MatchesAvailability(A:GetItemAvailability(990002)))
s.profile="Octo"

-- Availability must be applied before the stronger-enchant dominance pass.
AshenBuildsEnchants[990010]={n="Current stamina",slots={SHOULDER=true},stats={sta=10},tip=""}
AshenBuildsEnchants[990011]={n="Future stamina",slots={SHOULDER=true},stats={sta=20},tip=""}
A.EnchantAvailabilityOverrides[990010]={phase=0}
A.EnchantAvailabilityOverrides[990011]={phase=6}
A.enchantCandidates={990010,990011}; A.enchantSlot="SHOULDER"; A.enchantFilter.group="all"; A.enchantFilter.lower=false
A.enchantSearch:SetText(""); A.current.enchants.SHOULDER=nil; A:FilterEnchants()
check("future stronger enchant cannot hide current lower enchant",table.getn(A.enchantMatches)==1 and A.enchantMatches[1]==990010)
s.phase=6; A:FilterEnchants()
check("stronger enchant dominates only after it is available",table.getn(A.enchantMatches)==1 and A.enchantMatches[1]==990011)
A.current.enchants.SHOULDER=990011; s.phase=2; A:FilterEnchants()
check("filtering keeps existing saved enchant intact",A.current.enchants.SHOULDER==990011)
A.EnchantAvailabilityOverrides[990010]={phase=0,instance="Molten Core"}
A.EnchantAvailabilityOverrides[990011]={phase=0,instance="Blackwing Lair"}
s.instances={["Molten Core"]=true}; A:FilterEnchants()
check("instance selection filters enchants before dominance",table.getn(A.enchantMatches)==1 and A.enchantMatches[1]==990010)
s.instances={}
A.EnchantAvailabilityOverrides[990011]=nil
A.current.enchants.SHOULDER=nil; A:FilterEnchants()
check("unverified stronger enchant cannot hide a mapped current option",table.getn(A.enchantMatches)==2 and A.enchantMatches[1]==990010 and A.enchantMatches[2]==990011)
s.profile="Catalog"; A:FilterEnchants()
check("full catalog retains pure stat dominance ranking",table.getn(A.enchantMatches)==1 and A.enchantMatches[1]==990011)
s.profile="Octo"

-- Block Value is numeric item contribution, including shield base and Equip effects.
local stats=A:GetItemStatTotals(19349)
check("normalized shield stats include base and equip block value",stats.blockValue==73)
local idx=A.ItemIndex; idx:Reset(); idx:Finish()
local function HasID(list,id) local i; for i=1,table.getn(list) do if idx.id[list[i]]==id then return true end end; return false end
local high=idx:Query({slot="OFFHAND",stats={{"blockValue",70}}})
check("Block Value filter finds shield base plus Equip value",HasID(high,19349))
local higher=idx:Query({slot="OFFHAND",stats={{"blockValue",74}}})
check("Block Value filter does not include character strength",not HasID(higher,19349))
local search=idx:Query({slot="OFFHAND",query="block value"})
check("Block Value search alias uses normalized numeric stat",HasID(search,19349))

local content=AshenBuildsContentSources
check("complete acquisition supplement retains all catalog IDs",content and content.meta.itemCount==16069 and content.meta.enchantCount==263)
local hiddenLocation=false
for i=1,table.getn(A.CONTENT_INSTANCES) do if A.CONTENT_INSTANCES[i]=="CashTest" then hiddenLocation=true end end
check("hidden maps are absent from content dropdown and metadata",not hiddenLocation and content.locations[29]==nil)
local oldSources=AshenDB.ItemSources[22691]
AshenDB.ItemSources[22691]={{"more",100,"tooltip excerpt omitted"}}
local ashbringer=A:GetItemAvailability(22691)
check("full Naxx source summary supersedes a clipped tooltip",ashbringer.status=="future" and ashbringer.phase==6 and ashbringer.sourceRecord~=nil)
AshenDB.ItemSources[22691]=oldSources
check("full source summary maps current BWL gear",A:GetItemAvailability(19349).status=="available" and A:GetItemAvailability(19349).phase==2)
check("AQ enchant recipes require phase 4",A:GetEnchantAvailability(48).status=="future" and A:GetEnchantAvailability(48).phase==4 and A:GetEnchantAvailability(66).phase==4)
check("Emerald Sanctum enchant recipes require phase 3",A:GetEnchantAvailability(146602).phase==3 and A:GetEnchantAvailability(157119).phase==3)
check("Timbermaw enchant recipes require phase 5",A:GetEnchantAvailability(149018).phase==5 and A:GetEnchantAvailability(149020).phase==5)
check("PvP rank 13 gear requires phase 3",A:GetItemAvailability(16466).status=="future" and A:GetItemAvailability(16466).phase==3)
content.enchants[990012]={l=4,u=true,z={531},r=1}
local necessary=A:GetEnchantAvailability(990012)
check("unverified source cannot bypass a necessary future recipe",necessary.status=="unknown" and necessary.minPhase==4 and not A:MatchesAvailability(necessary))
s.phase=4
check("mapped AQ recipe opens with selected phase",A:GetEnchantAvailability(48).status=="available")
s.phase=2
