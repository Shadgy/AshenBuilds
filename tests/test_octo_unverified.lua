local A=AshenBuilds
local pending=AshenDB.OctoUnverifiedItems or {}
local index=A.ItemIndex
index:Reset(); index:Finish()
local settings=A:GetAvailabilitySettings()
local count,loaded,unknown=0,0,0
local orderCounts={}
for _,id in ipairs(AshenDB.ItemOrder) do orderCounts[id]=(orderCounts[id] or 0)+1 end
for id in pairs(pending) do
  count=count+1
  if A:GetItem(id) and A:GetItemDetail(id) and orderCounts[id]==1 then loaded=loaded+1 end
  local result=A:GetItemAvailability(id)
  if result.status=="unknown" and not result.verified and result.requiresUnverified and table.getn(A:GetItemSources(id))==0 then
    unknown=unknown+1
  end
end
check("the audited items load once with complete catalog records",count==180 and loaded==count)
check("confirmed stats alone never verify acquisition",count==180 and unknown==count)
check("the fresh settings default to hiding unverified entries",settings.includeUnknown==false)
check("the item count includes the supplemental definitions",AshenDB:GetItemCount()==table.getn(AshenDB.ItemOrder))

local function CountPending()
  local total=0
  for _,position in ipairs(index:Query({slot="ALL",showHidden=true,availability=settings})) do
    if pending[index.id[position]] then total=total+1 end
  end
  return total
end
settings.showFuture=true
check("Show hidden and Show future leave the pending items out",CountPending()==0)
settings.profile="Catalog"
check("Full catalog still requires explicit Unverified opt-in for the pending items",CountPending()==0)
settings.includeUnknown=true
check("opt-in shows all audited items in Full catalog",CountPending()==count)
settings.profile="Octo"; settings.showFuture=false
check("opt-in shows the batch in the Octo profile",CountPending()==count)
check("Unverified does not open known Tower of Karazhan loot",not A:MatchesAvailability(A:GetItemAvailability(55285),settings,true))

local medic=A:GetItem(33218)
check("Field Medic's Band retains the Octo tooltip stats and slot",
  medic and medic.slot=="FINGER" and medic.stats.sta==10 and medic.stats.int==6
    and medic.stats.healing==26 and medic.stats.mp5==3)
local phaseZero={profile="Octo",phase=0,includeUnknown=false,showFuture=false}
for _,id in ipairs({3008,7338,33218}) do
  local availability=A:GetItemAvailability(id,phaseZero)
  check("item "..id.." remains Unverified and hidden by default in phase 0",
    availability.status=="unknown" and not A:MatchesAvailability(availability,phaseZero,true))
end
local helm=A:GetItem(83585)
check("player-only armor effects stay out of generic stats",
  helm and helm.stats.armor==393 and helm.stats.crit==1
    and not helm.stats.arcaneRes and not helm.stats.critTakenReduction)
local shoulders=A:GetItem(33417)
check("confirmed Octo values and class mask take precedence over the older snapshot",
  shoulders and shoulders.armor==627 and shoulders.stats.sta==31
    and A:IsClassAllowedRaw(A:GetRawItem(33417),"Warrior") and not A:IsClassAllowedRaw(A:GetRawItem(33417),"Paladin"))
local gloves=A:GetItem(33713)
check("unconditional spell penetration is counted",
  gloves and gloves.stats.spellPen==10 and gloves.stats.spellPower==22 and gloves.stats.healing==22)
