AshenBuilds = AshenBuilds or {}
local AB = AshenBuilds

-- Octo roadmap checked 2026-11-10: phase 2/BWL open, Naxxramas is phase 6.
-- This is a content profile, not a claim that every item in Turtle's catalog is obtainable.
AB.CONTENT_PHASES = {{0,"Base content"},{1,"Phase 1 - Zul'Gurub"},{2,"Phase 2 - Blackwing Lair"},
  {3,"Phase 3 - Emerald Sanctum"},{4,"Phase 4 - Ahn'Qiraj"},{5,"Phase 5 - Timbermaw Hold"},
  {6,"Phase 6 - Naxxramas"},{7,"Phase 7 - Tower of Karazhan"}}
AB.ContentProfileSource = "https://octowow.st/roadmap"
AB.ContentProfileChecked = "2026-11-10"

local phases = {
  ["Molten Core"]=0,["Onyxia's Lair"]=0,["Lower Karazhan Halls"]=0,
  ["Zul'Gurub"]=1,["Blackwing Lair"]=2,["Emerald Sanctum"]=3,
  ["Ruins of Ahn'Qiraj"]=4,["Ahn'Qiraj"]=4,["Temple of Ahn'Qiraj"]=4,
  ["Timbermaw Hold"]=5,["Naxxramas"]=6,["The Upper Necropolis"]=6,["Tower of Karazhan"]=7,
}
-- AtlasLoot records the shared instance, not separate Scarlet Monastery wings.
-- Keep old selections readable while offering only the supported parent filter.
local instanceAliases={
  ["Scarlet Monastery Graveyard"]="Scarlet Monastery",["Scarlet Monastery Library"]="Scarlet Monastery",
  ["Scarlet Monastery Armory"]="Scarlet Monastery",["Scarlet Monastery Cathedral"]="Scarlet Monastery",
  ["Scarlet Monastery (Graveyard)"]="Scarlet Monastery",["Scarlet Monastery (Library)"]="Scarlet Monastery",
  ["Scarlet Monastery (Armory)"]="Scarlet Monastery",["Scarlet Monastery (Cathedral)"]="Scarlet Monastery",
}
local function InstanceName(name) return instanceAliases[name] or name end
AB.NormalizeContentInstance=InstanceName
local baseDungeons={"Ragefire Chasm","Wailing Caverns","The Deadmines","Shadowfang Keep","Blackfathom Deeps",
  "The Stockade","Gnomeregan","Razorfen Kraul","Scarlet Monastery","Razorfen Downs",
  "Uldaman","Zul'Farrak","Maraudon","The Temple of Atal'Hakkar","Blackrock Depths","Blackrock Spire",
  "Dire Maul","Stratholme","Scholomance","Karazhan Crypt"}
local i; for i=1,table.getn(baseDungeons) do phases[baseDungeons[i]]=0 end
AB.CONTENT_INSTANCES={}
local location; for location in pairs(phases) do table.insert(AB.CONTENT_INSTANCES,location) end
table.sort(AB.CONTENT_INSTANCES)

-- Public override tables allow verified server exceptions without changing item IDs or saves.
-- A phase here means every known route requires it; incomplete source lists remain unknown.
AB.ItemAvailabilityOverrides = AB.ItemAvailabilityOverrides or {}
AB.EnchantAvailabilityOverrides = AB.EnchantAvailabilityOverrides or {
  [37]={phase=6,instance="Naxxramas",source="Sapphiron",item=23548},
  [38]={phase=6,instance="Naxxramas",source="Sapphiron"},
  [39]={phase=6,instance="Naxxramas",source="Sapphiron"},
  [40]={phase=6,instance="Naxxramas",source="Sapphiron"},
}

function AB:GetAvailabilitySettings()
  if not self.contentInstancesExpanded and AshenBuildsContentSources then
    local seen={}; local i,name,location
    for i=1,table.getn(self.CONTENT_INSTANCES) do seen[self.CONTENT_INSTANCES[i]]=true end
    for _,location in pairs(AshenBuildsContentSources.locations or {}) do
      name=InstanceName(location.name)
      if location.phase~=nil and (location.type==1 or location.type==2) then
        phases[name]=location.phase
        if not seen[name] then table.insert(self.CONTENT_INSTANCES,name); seen[name]=true end
      end
    end
    table.sort(self.CONTENT_INSTANCES); self.contentInstancesExpanded=true
  end
  AshenBuildsDB = AshenBuildsDB or {}
  AshenBuildsDB.settings = AshenBuildsDB.settings or {}
  local s=AshenBuildsDB.settings.availability
  if type(s)~="table" then s={}; AshenBuildsDB.settings.availability=s end
  if s.profile~="Catalog" then s.profile="Octo" end
  s.phase=math.max(0,math.min(7,math.floor(tonumber(s.phase) or 2)))
  -- The user-approved AtlasLoot policy replaces the earlier permissive default.
  -- Migrate once; later explicit choices must survive refreshes and relogging.
  if s.atlasPolicy~=1 then s.includeUnknown=false; s.atlasPolicy=1 end
  if s.includeUnknown==nil then s.includeUnknown=false end
  if type(s.instances)~="table" then s.instances={} end
  local alias,canonical
  for alias,canonical in pairs(instanceAliases) do
    if s.instances[alias] then s.instances[canonical]=true end
    s.instances[alias]=nil
  end
  return s
end

local function Result(status,reason,instances,extra)
  local r=extra or {}; r.status=status; r.reason=reason; r.instances=instances or {}; return r
end
local function CurrentPhase(settings) return tonumber(settings.phase) or 2 end
local function Override(o,settings)
  local locations={}; if o.instance then locations[InstanceName(o.instance)]=true end
  if o.status=="unobtainable" then return Result("unobtainable",o.reason or "Not obtainable in this server profile",locations) end
  local phase=tonumber(o.phase)
  if phase then return Result(phase>CurrentPhase(settings) and "future" or "available",
    (phase>CurrentPhase(settings) and "Requires Octo phase " or "Available by Octo phase ")..phase..(o.source and (" - "..o.source) or ""),locations,{phase=phase}) end
  return Result(o.status or "unknown",o.reason or "Availability is not verified",locations)
end

-- Supplemental summaries are built from every recorded route before the tooltip's
-- eight-source limit. 'l' is a guaranteed minimum phase; 'p' is a resolved route.
-- The distinction preserves a future recipe gate even when a reagent is unknown.
local function FullSources(record,settings)
  local instances={}; local data=AshenBuildsContentSources; local i,location
  for i=1,table.getn(record.z or {}) do
    location=data.locations and data.locations[record.z[i]]
    if location then instances[InstanceName(location.name)]=true end
  end
  local phase=CurrentPhase(settings)
  if record.p and record.p<=phase then
    return Result("available","Source route mapped to Octo phase "..record.p,instances,{phase=record.p,incomplete=record.u,sourceRecord=record})
  end
  if (record.l or 0)>phase then
    local reason="Requires Octo phase "..record.l
    if record.h then reason=reason.." (PvP rank "..record.h..")" end
    return Result("future",reason,instances,{phase=record.l,incomplete=record.u,sourceRecord=record})
  end
  return Result("unknown","Acquisition route or required dependency is not fully mapped",instances,{incomplete=true,sourceRecord=record})
end

function AB:GetCatalogItemAvailability(id,settings)
  if type(settings)~="table" then settings=self:GetAvailabilitySettings() end; id=tonumber(id)
  local o=self.ItemAvailabilityOverrides[id]; if o then return Override(o,settings) end
  local raw=self:GetRawItem(id); if not raw then return Result("unknown","Item is not in this data pack") end
  local cats=raw[20] or {}; local j
  for j=1,table.getn(cats) do if cats[j]=="unobtainable" then return Result("unobtainable","Catalog marks this item as unobtainable") end end
  local full=AshenBuildsContentSources and AshenBuildsContentSources.items and AshenBuildsContentSources.items[id]
  if full then return FullSources(full,settings) end
  local sources=AshenDB and AshenDB.ItemSources and AshenDB.ItemSources[id]
  local instances,unknown,known,earliest={},false,false,nil
  if not sources or table.getn(sources)==0 then return Result("unknown","Acquisition sources are not verified",instances,{incomplete=true}) end
  for j=1,table.getn(sources) do
    local source=sources[j]; local zone=InstanceName((source[1]=="drop" and source[4]) or nil)
    local phase=zone and phases[zone]
    if zone and zone~="" then instances[InstanceName(zone)]=true end
    if phase then
      known=true; if not earliest or phase<earliest then earliest=phase end
    else
      -- 'more' means source export was truncated. A missing route can be an earlier one.
      unknown=true
    end
  end
  if known and earliest<=CurrentPhase(settings) then return Result("available","Has a source open by Octo phase "..earliest,instances,{phase=earliest,incomplete=unknown}) end
  if unknown then return Result("unknown","Some acquisition routes are unverified or omitted",instances,{incomplete=true,phase=earliest}) end
  return Result("future","Requires Octo phase "..earliest,instances,{phase=earliest})
end

function AB:GetCatalogEnchantAvailability(id,settings)
  if type(settings)~="table" then settings=self:GetAvailabilitySettings() end
  local o=self.EnchantAvailabilityOverrides[tonumber(id)]
  if o then return Override(o,settings) end
  local full=AshenBuildsContentSources and AshenBuildsContentSources.enchants and AshenBuildsContentSources.enchants[tonumber(id)]
  if full then return FullSources(full,settings) end
  return Result("unknown","Enchant acquisition source is not verified",{}, {incomplete=true})
end

local function AtlasAvailability(record,full,settings,isEnchant)
  if not record or table.getn(record.routes or {})==0 then return nil end
  local instances,instancePhases={},{}
  local earliest,minimum,unresolved=nil,tonumber(isEnchant and full and full.l) or 0,false
  local unresolvedMinimum
  local i,route,phase,bound,location
  for i=1,table.getn(record.routes) do
    route=record.routes[i]; phase=tonumber(route.phase)
    bound=math.max(minimum,tonumber(route.minimumPhase) or 0)
    if phase then phase=math.max(phase,bound)
    else
      unresolved=true
      if not unresolvedMinimum or bound<unresolvedMinimum then unresolvedMinimum=bound end
    end
    if phase and (not earliest or phase<earliest) then earliest=phase end
    location=InstanceName(route.instance)
    if location then
      instances[location]=true
      if phase and (not instancePhases[location] or phase<instancePhases[location]) then instancePhases[location]=phase end
    end
  end
  if isEnchant and full then
    local locations=AshenBuildsContentSources and AshenBuildsContentSources.locations or {}
    for i=1,table.getn(full.z or {}) do
      location=locations[full.z[i]]
      if location and location.phase~=nil then instances[InstanceName(location.name)]=true end
    end
  end
  local extra={verified=true,verification="AtlasLoot",atlasRecord=record,sourceRecord=full,
    phase=earliest,minPhase=earliest or unresolvedMinimum or minimum,instancePhases=instancePhases,phaseUnresolved=unresolved}
  if earliest then
    local future=earliest>CurrentPhase(settings)
    if future and unresolvedMinimum and unresolvedMinimum<earliest then
      extra.phase=nil; extra.knownSourcePhase=earliest; extra.minPhase=unresolvedMinimum; extra.incomplete=true
      return Result("unknown","AtlasLoot has a phase "..earliest.." route and another route whose phase is unresolved",instances,extra)
    end
    return Result(future and "future" or "available","AtlasLoot acquisition source; "..
      (future and "requires Octo phase " or "available by Octo phase ")..earliest,instances,extra)
  end
  extra.incomplete=true
  return Result("unknown","AtlasLoot source is recorded, but its phase is not fully established",instances,extra)
end

local function Unverified(catalog,full)
  local flagged=catalog.status=="unobtainable"
  if full and catalog.sourceRecord~=full then catalog=FullSources(full,{phase=0}); catalog.sourceRecord=full end
  local minimum=tonumber(full and full.l) or 0
  if full and full.u==false and full.p then minimum=math.max(minimum,full.p)
  elseif not full and not catalog.incomplete and catalog.phase then minimum=math.max(minimum,catalog.phase) end
  catalog.knownSourcePhase=(full and full.p) or catalog.phase; catalog.phase=nil; catalog.minPhase=minimum
  catalog.status="unknown"; catalog.verified=false; catalog.catalogUnavailable=flagged
  catalog.reason="No verified AtlasLoot acquisition source"
  if flagged then catalog.reason=catalog.reason.."; catalog marks this item unavailable" end
  if minimum>0 then catalog.reason=catalog.reason.."; known requirements start at Octo phase "..minimum end
  return catalog
end

local function Curated(o,settings)
  local result=Override(o,settings)
  result.verified=result.status=="available" or result.status=="future"
  result.verification="Recorded server exception"
  result.minPhase=result.phase
  return result
end

function AB:GetItemAvailability(id,settings)
  if type(settings)~="table" then settings=self:GetAvailabilitySettings() end
  id=tonumber(id)
  local o=self.ItemAvailabilityOverrides[id]; if o then return Curated(o,settings) end
  if not self:GetRawItem(id) then return Result("unknown","Item is not in this data pack",{}, {verified=false,incomplete=true}) end
  local full=AshenBuildsContentSources and AshenBuildsContentSources.items[id]
  local atlas=AshenBuildsAtlasLootSources and AshenBuildsAtlasLootSources.items[id]
  local result=AtlasAvailability(atlas,full,settings,false)
  if result then return result end
  return Unverified(self:GetCatalogItemAvailability(id,settings),full)
end

function AB:GetEnchantAvailability(id,settings)
  if type(settings)~="table" then settings=self:GetAvailabilitySettings() end
  id=tonumber(id)
  local o=self.EnchantAvailabilityOverrides[id]; if o then return Curated(o,settings) end
  local full=AshenBuildsContentSources and AshenBuildsContentSources.enchants[id]
  local atlas=AshenBuildsAtlasLootSources and AshenBuildsAtlasLootSources.enchants[id]
  local result=AtlasAvailability(atlas,full,settings,true)
  if result then return result end
  return Unverified(self:GetCatalogEnchantAvailability(id,settings),full)
end

function AB:MatchesAvailability(result,settings,showHidden)
  if type(settings)~="table" then settings=self:GetAvailabilitySettings() end
  if result.status=="unobtainable" then return showHidden and true or false end
  if settings.profile=="Catalog" then return true end
  if (result.minPhase or 0)>CurrentPhase(settings) and not settings.showFuture then return false end
  if result.status=="future" then return settings.showFuture and true or false end
  if result.status=="unknown" then return settings.includeUnknown~=false end
  return true
end

function AB:MatchesContentInstances(result,settings)
  if type(settings)~="table" then settings=self:GetAvailabilitySettings() end
  local selection=settings.instances or {}
  if not next(selection) then return true end
  local zone,selected,eligible=nil,nil,false
  for selected in pairs(selection) do
    zone=InstanceName(selected)
    local phase=phases[zone]
    if settings.profile=="Catalog" or settings.showFuture or not phase or phase<=CurrentPhase(settings) then
      eligible=true
      local routePhase=result.instancePhases and result.instancePhases[zone]
      if result.instances and result.instances[zone] and
        (settings.profile=="Catalog" or settings.showFuture or not routePhase or routePhase<=CurrentPhase(settings)) then return true end
    end
  end
  -- An omitted route cannot make a known closed instance eligible at this phase.
  return eligible and result.status=="unknown" and result.incomplete and settings.includeUnknown~=false and true or false
end

function AB:GetAvailabilityLabel()
  local s=self:GetAvailabilitySettings()
  if s.profile=="Catalog" then return "Full catalog" end
  return "Octo: phase "..s.phase..(s.showFuture and " + future" or "")
end

function AB:AvailabilityNote(result)
  local labels={available="Verified source",future="Future phase",unobtainable="Unavailable",unknown="Unverified"}
  return (labels[result.status] or "Unverified")..": "..(result.reason or "")
end
