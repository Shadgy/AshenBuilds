-- Native shield block is a separate, sourced property, not block chance or Equip BV.
local AB=AshenBuilds
local count,missing=0,0
local id,raw,value,known
for id,raw in pairs(AshenDB.Items) do
  if raw[3]=="SHIELD" then
    count=count+1; value,known=AB:GetNativeShieldBlockValue(id,raw)
    if not known or type(value)~="number" or value<0 then missing=missing+1 end
  end
end
check("native shield data covers the complete embedded shield catalog",count==454 and missing==0)
check("native shield source records coverage and exact snapshot",AB.ShieldBlockMeta and AB.ShieldBlockMeta.count==count and AB.ShieldBlockMeta.sourceVersion=="3ab59b9aab18")
local shield=AB:GetItem(19349)
check("Elementium Reinforced Bulwark retains native 54 block",shield.shieldBlockKnown and shield.shieldBaseBlockValue==54)
check("native block remains separate from the additional Equip 19 BV",AB:GetItemEffectStats(19349).blockValue==19)
value,known=AB:GetNativeShieldBlockValue(999999999,{[3]="SHIELD",[21]=0})
check("new export explicit zero is known rather than missing",known and value==0)
value,known=AB:GetNativeShieldBlockValue(999999999,{[3]="SHIELD"})
check("unknown shield block is reported as unknown, never silently zero",not known and value==nil)
value,known=AB:GetNativeShieldBlockValue(19349,{[3]="SHIELD",[21]=61})
check("new export native field takes precedence over older supplement",known and value==61)
check("ordinary GOLD COLD and SMOLDERING item names are not hidden",not AB:IsHiddenRaw({[1]="Gold Lion Shield"}) and not AB:IsHiddenRaw({[1]="Coldridge Hammer"}) and not AB:IsHiddenRaw({[1]="Smoldering Robe"}))
check("ordinary Old name and Testament are not substring matches",not AB:IsHiddenRaw({[1]="Old Leather Belt"}) and not AB:IsHiddenRaw({[1]="Testament of Hope"}))
check("explicit placeholder and deprecated markers remain hidden",AB:IsHiddenRaw({[1]="Naxxramas Polearm [PH]"}) and AB:IsHiddenRaw({[1]="OLD Test Shield"}) and AB:IsHiddenRaw({[1]="QA Shield"}))
check("unobtainable source flag is honored independently of the name",AB:IsHiddenRaw({[1]="Ordinary name",[20]={"unobtainable"}}))
