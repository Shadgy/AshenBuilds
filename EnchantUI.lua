-- Browse every recorded enchant without requiring an equipped item first.
local A=AshenBuilds
local ROWS=15
local function Button(parent,text,width)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
  b:SetWidth(width); b:SetHeight(22); b:SetText(text); A:SkinButton(b,"ember")
  return b
end
local function GroupLabel(key)
  local _,g
  for _,g in ipairs(A.ENCHANT_GROUPS) do if g[1]==key then return g[2] end end
  return "All Stats"
end
function A:GetEnchantSlotText(e)
  local out,i,slot={}
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]
    if e.slots[slot] then table.insert(out,self.SLOT_LABELS[slot]) end
  end
  local text=table.concat(out,", ")
  if e.req=="twohand" then text=text.." (two-handed only)"
  elseif e.req=="shield" then text=text.." (shield only)"
  elseif e.req=="weapon" then text=text.." (weapon only)" end
  if e.minIlvl then text=text.."; item level "..e.minIlvl.."+" end
  return text
end
function A:GetEnchantTargets(id)
  local out,i,slot,item,e={}; e=AshenBuildsEnchants[id]
  if not e then return out end
  for i=1,table.getn(self.SLOTS) do
    slot=self.SLOTS[i]
    if e.slots[slot] and (self.enchantDatabaseFilter.slot=="ALL" or self.enchantDatabaseFilter.slot==slot) then
      item=self:GetItem(self.current.items[slot] or 0)
      local allowed=item and self:IsEnchantAllowed(slot,id,item)
      table.insert(out,{value=slot,text=self.SLOT_LABELS[slot]..": "..(item and item.n or "No equipped item"),
        disabled=not allowed,reason=not item and "Equip an item in this slot first." or "This enchant cannot be applied to the equipped item."})
    end
  end
  return out
end
function A:CreateEnchantDatabase()
  local f=CreateFrame("Frame","AshenBuildsEnchantDatabase",UIParent)
  f:SetWidth(1036); f:SetHeight(798); f:Hide(); self.enchantDatabase=f
  self.enchantDatabaseFilter={slot="ALL",group="all",lower=true}; self.enchantDatabasePage=1
  local title=f:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
  title:SetPoint("TOP",f,"TOP",0,-17); title:SetText("ENCHANT DATABASE"); self:AddChrome(f,title)
  local search=CreateFrame("EditBox","AshenBuildsEnchantDatabaseSearch",f,"InputBoxTemplate")
  search:SetWidth(330); search:SetHeight(24); search:SetPoint("TOPLEFT",f,"TOPLEFT",32,-66); search:SetAutoFocus(false)
  self.enchantDatabaseSearch=search
  search:SetScript("OnTextChanged",function() A:RefreshEnchantDatabase() end)
  search:SetScript("OnEnterPressed",function() this:ClearFocus() end)
  search:SetScript("OnEscapePressed",function() this:ClearFocus() end)
  self:Caption(f,"Search (name or effect)",search,-6,4)
  local clear=Button(f,"Clear Filters",96); clear:SetPoint("LEFT",search,"RIGHT",8,0)
  clear:SetScript("OnClick",function()
    A.enchantDatabaseFilter={slot="ALL",group="all",lower=true}
    A.enchantDatabaseSearch:SetText(""); A:RefreshEnchantDatabase()
  end)
  self.enchantDatabaseLower=self:CreateCheck(f,"Show lower ranks",function(v) A.enchantDatabaseFilter.lower=v; A:RefreshEnchantDatabase() end)
  self.enchantDatabaseLower:SetPoint("LEFT",clear,"RIGHT",14,0)
  self.enchantDatabaseSlot=self:CreateDropdown(f,170,{
    items=function()
      local out={{value="ALL",text="All Slots"}}; local i,slot
      for i=1,table.getn(A.SLOTS) do slot=A.SLOTS[i]; if AshenBuildsEnchantSlots[slot] then table.insert(out,{value=slot,text=A.SLOT_LABELS[slot]}) end end
      return out
    end,
    getText=function() local slot=A.enchantDatabaseFilter.slot; return slot=="ALL" and "All Slots" or A.SLOT_LABELS[slot] end,
    isChecked=function(v) return A.enchantDatabaseFilter.slot==v end,
    onSelect=function(v) A.enchantDatabaseFilter.slot=v; A:RefreshEnchantDatabase() end})
  self.enchantDatabaseSlot:SetPoint("TOPLEFT",f,"TOPLEFT",26,-118); self:Caption(f,"Equipment Slot",self.enchantDatabaseSlot)
  self.enchantDatabaseGroup=self:CreateDropdown(f,190,{
    items=function() local out,_,g={}; for _,g in ipairs(A.ENCHANT_GROUPS) do table.insert(out,{value=g[1],text=g[2]}) end; return out end,
    getText=function() return GroupLabel(A.enchantDatabaseFilter.group) end,
    isChecked=function(v) return A.enchantDatabaseFilter.group==v end,
    onSelect=function(v) A.enchantDatabaseFilter.group=v; A:RefreshEnchantDatabase() end})
  self.enchantDatabaseGroup:SetPoint("LEFT",self.enchantDatabaseSlot,"RIGHT",20,0); self:Caption(f,"Stat",self.enchantDatabaseGroup)
  self.enchantDatabaseAvailability=self:CreateAvailabilityButton(f,"TOPRIGHT",-26,-118)
  self:Caption(f,"Content / phases",self.enchantDatabaseAvailability)
  self.enchantDatabaseRows={}
  local i
  for i=1,ROWS do
    local r=CreateFrame("Button",nil,f); r:SetHeight(36)
    r:SetPoint("TOPLEFT",f,"TOPLEFT",26,-160-(i-1)*38); r:SetPoint("RIGHT",f,"RIGHT",-26,0)
    r:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    r.text=r:CreateFontString(nil,"OVERLAY","GameFontHighlight"); r.text:SetPoint("TOPLEFT",r,"TOPLEFT",8,-3); r.text:SetWidth(500); r.text:SetHeight(14); r.text:SetJustifyH("LEFT")
    r.meta=r:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); r.meta:SetPoint("TOPRIGHT",r,"TOPRIGHT",-8,-3); r.meta:SetWidth(450); r.meta:SetHeight(14); r.meta:SetJustifyH("RIGHT")
    r.desc=r:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); r.desc:SetPoint("BOTTOMLEFT",r,"BOTTOMLEFT",8,3); r.desc:SetWidth(960); r.desc:SetHeight(12); r.desc:SetJustifyH("LEFT"); r.desc:SetTextColor(.3,.95,.3)
    self:BindDropdown(r,{
      items=function() return A:GetEnchantTargets(r.enchantID) end,
      getText=function() return "" end,listWidth=560,
      onSelect=function(slot)
        local id=r.enchantID; local item=A:GetItem(A.current.items[slot] or 0)
        if id and item and A:IsEnchantAllowed(slot,id,item) then A:ApplyEnchant(slot,id); A:ShowTab("planner") end
      end},function() end)
    r:SetScript("OnEnter",function()
      local e=this.enchantID and AshenBuildsEnchants[this.enchantID]
      if e then
        GameTooltip:SetOwner(this,"ANCHOR_RIGHT"); GameTooltip:SetText(e.n,1,.82,0)
        GameTooltip:AddLine(A:GetEnchantSlotText(e),.8,.8,.8,true)
        if e.tip and e.tip~="" then GameTooltip:AddLine(e.tip,.1,1,.1,true) end
        A:AddAvailabilityTooltip(A:GetEnchantAvailability(this.enchantID))
        GameTooltip:AddLine("Click to choose an equipped item.",1,.82,.28,true); GameTooltip:Show()
      end
    end)
    r:SetScript("OnLeave",function() GameTooltip:Hide() end)
    self.enchantDatabaseRows[i]=r
  end
  local prev=Button(f,"Previous",90); prev:SetPoint("BOTTOMLEFT",f,"BOTTOMLEFT",26,12)
  prev:SetScript("OnClick",function() A:ScrollEnchantDatabase(1) end); f.prev=prev
  local next=Button(f,"Next",90); next:SetPoint("LEFT",prev,"RIGHT",10,0)
  next:SetScript("OnClick",function() A:ScrollEnchantDatabase(-1) end); f.next=next
  f.count=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall"); f.count:SetPoint("LEFT",next,"RIGHT",16,0)
  local hint=f:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
  hint:SetPoint("BOTTOMRIGHT",f,"BOTTOMRIGHT",-26,17); hint:SetText("Click an enchant to choose an equipped item")
  f:EnableMouseWheel(true); f:SetScript("OnMouseWheel",function() A:ScrollEnchantDatabase(arg1) end)
  f:SetScript("OnHide",function() A:CloseDropdownFor(f) end)
end
function A:OpenEnchantDatabase()
  self.enchantBrowser:Hide(); self:RefreshEnchantDatabase(); self.enchantDatabase:Show()
end
function A:RefreshEnchantDatabase()
  if not self.enchantDatabaseRows then return end
  local candidates,_,id={},nil,nil; local filter=self.enchantDatabaseFilter
  for _,id in ipairs(AshenBuildsEnchantOrder) do
    local e=AshenBuildsEnchants[id]
    if e and (filter.slot=="ALL" or e.slots[filter.slot]) then table.insert(candidates,id) end
  end
  self.enchantDatabaseMatches,self.enchantDatabaseHidden=self:QueryEnchants(candidates,filter,self.enchantDatabaseSearch:GetText(),nil,true)
  if not (filter.group and filter.group~="all" and filter.group~="other") then
    table.sort(self.enchantDatabaseMatches,function(x,y) return AshenBuildsEnchants[x].n<AshenBuildsEnchants[y].n end)
  end
  self.enchantDatabasePage=1
  self.enchantDatabaseSlot:Refresh(); self.enchantDatabaseGroup:Refresh(); self.enchantDatabaseLower:SetChecked(filter.lower and 1 or nil)
  self:RenderEnchantDatabase()
end
function A:ScrollEnchantDatabase(delta)
  self.enchantDatabasePage=math.max(1,math.min(self.enchantDatabasePages or 1,self.enchantDatabasePage+(delta<0 and 1 or -1)))
  self:RenderEnchantDatabase()
end
function A:RenderEnchantDatabase()
  self:CloseDropdownFor(self.enchantDatabase)
  local matches=self.enchantDatabaseMatches or {}; local total=table.getn(matches)
  self.enchantDatabasePages=math.max(1,math.ceil(total/ROWS)); local page=self.enchantDatabasePage
  local i,r,id,e,desc,result
  for i=1,ROWS do
    r=self.enchantDatabaseRows[i]; id=matches[(page-1)*ROWS+i]; e=id and AshenBuildsEnchants[id]
    r.enchantID=id
    if e then
      self:SetPickerLine(r.text,e.n); self:SetPickerLine(r.meta,self:GetEnchantSlotText(e))
      desc=self:StatSummary(e.stats); if desc=="" then desc=e.tip or "" end
      result=self:GetEnchantAvailability(id)
      if result.status=="future" then desc="[Phase "..result.phase.."]  "..desc
      elseif result.status=="unknown" then desc="[Unverified "..(result.verified and "phase" or "source").."]  "..desc end
      self:SetPickerLine(r.desc,desc); r:Show()
    else r:Hide() end
  end
  local hidden=self.enchantDatabaseHidden or 0
  self.enchantDatabase.count:SetText("Page "..page.." / "..self.enchantDatabasePages.."  ("..total.." enchants)"..(hidden>0 and ("; "..hidden.." lower ranks hidden") or ""))
  if page>1 then self.enchantDatabase.prev:Enable() else self.enchantDatabase.prev:Disable() end
  if page<self.enchantDatabasePages then self.enchantDatabase.next:Enable() else self.enchantDatabase.next:Disable() end
end
