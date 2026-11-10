local A=AshenBuilds
local s=A:GetAvailabilitySettings()
s.profile="Octo";s.phase=2;s.includeUnknown=false;s.showFuture=false;s.instances={}
A.current=A.NewBuildData("Catalog test");A.current.items={};A.current.enchants={};A:RefreshUI()
local function Has(id)
  for _,v in ipairs(A.enchantDatabaseMatches or {}) do if v==id then return true end end
  return false
end
Click(A.enchantDatabaseButton)
check("enchant tab opens a full page without equipped items",A.enchantDatabase:IsShown() and not A.plannerPage:IsShown() and not A.itemBrowser:IsShown() and table.getn(A.enchantDatabaseMatches)>0)
check("catalog is embedded alongside item database",A.enchantDatabase:GetParent()==A.frame and A.enchantDatabase.embedded and table.getn(A.tabs)==6)
check("catalog starts with all slots and every rank",A.enchantDatabaseFilter.slot=="ALL" and A.enchantDatabaseFilter.lower==true)
local widths=0
for _,tab in ipairs(A.tabs) do widths=widths+tab.button:GetWidth() end
check("six tabs leave room for level and class controls",A.frame:GetWidth()-24-widths-(table.getn(A.tabs)-1)*3>=422+8)
check("catalog respects the current phase",not Has(37))
A.availabilityBrowser:Show();A:OpenDropdown(A.availabilityBrowser.instances)
Click(AshenBuildsDropdownList.rows[2])
local firstZone=AshenBuildsDropdownList.rows[2].value
check("catalog refresh keeps the content multi-select open",AshenBuildsDropdownList:IsShown() and s.instances[firstZone])
Click(AshenBuildsDropdownList.rows[3])
check("multiple content locations can be selected in one menu",AshenBuildsDropdownList:IsShown() and s.instances[AshenBuildsDropdownList.rows[3].value])
s.instances={};A:CloseDropdown();A.availabilityBrowser:Hide();A:RefreshContentViews()
local first=A.enchantDatabaseRows[1]
local targets=A:GetEnchantTargets(first.enchantID);local disabled=true
for _,target in ipairs(targets) do if not target.disabled then disabled=false end end
check("catalog application targets explain missing equipment",table.getn(targets)>0 and disabled)
local sig=A:GetBuildPayloadSignature(A.current)
Click(first)
check("browsing or opening target menu cannot mutate equipment",A:GetBuildPayloadSignature(A.current)==sig and A.enchantDatabase:IsShown())
A:CloseDropdown()
if A.enchantDatabasePages>1 then Click(A.enchantDatabase.next) end
check("next page changes the visible enchant rows",A.enchantDatabasePages==1 or A.enchantDatabasePage==2)
A.enchantDatabaseSlot.opts.onSelect("SHOULDER")
local shoulders=true
for _,id in ipairs(A.enchantDatabaseMatches) do if not AshenBuildsEnchants[id].slots.SHOULDER then shoulders=false end end
check("slot selection filters results and resets paging",shoulders and A.enchantDatabasePage==1)
s.phase=6;A:RefreshContentViews()
check("opening Naxx phase exposes Sapphiron enchants",Has(37))

local function Fixture(id,name,slot,sta,phase)
  AshenBuildsEnchants[id]={n=name,slots={[slot]=true},stats={sta=sta},tip="Catalog regression"}
  table.insert(AshenBuildsEnchantOrder,id)
  if phase then A.EnchantAvailabilityOverrides[id]={phase=phase} end
end
Fixture(990801,"Catalog unknown fixture","HEAD",1)
A.enchantDatabaseSlot.opts.onSelect("ALL");A.enchantDatabaseSearch:SetText("Catalog unknown fixture")
check("catalog excludes unverified by default",not Has(990801))
s.includeUnknown=true;A:RefreshContentViews()
check("shared Unverified control refreshes the enchant catalog",Has(990801) and string.find(A.enchantDatabaseRows[1].desc:GetText(),"Unverified source",1,true))
s.includeUnknown=false
Fixture(990802,"Scope chest low","CHEST",3,0)
Fixture(990803,"Scope feet","FEET",4,0)
Fixture(990804,"Scope chest high","CHEST",5,0)
local out=A:QueryEnchants({990802,990803,990804},{group="all",lower=false},"",nil,true)
check("catalog dominance respects application slots",table.getn(out)==2 and out[1]==990803 and out[2]==990804)
Fixture(990805,"Scope future high","CHEST",50,7)
s.phase=2;s.showFuture=true
out=A:QueryEnchants({990804,990805},{group="sta",lower=false},"",nil,true)
check("future enchant cannot hide an available catalog choice",table.getn(out)==2)
s.showFuture=false

A.current.items.HEAD=12640
A.enchantDatabaseFilter={slot="HEAD",group="all",lower=true}
A.enchantDatabaseSearch:SetText(AshenBuildsEnchants[25].n)
local row
for _,r in ipairs(A.enchantDatabaseRows) do if r.enchantID==25 then row=r end end
check("known enchant is searchable by its name",row~=nil)
if row then
  Click(row)
  local list=AshenBuildsDropdownList;local head
  for _,r in ipairs(list.rows) do if r.value=="HEAD" then head=r end end
  check("target menu enables a compatible equipped item",head and not head.disabled)
  if head then Click(head) end
end
check("catalog applies enchant to chosen slot and returns to planner",A.current.enchants.HEAD==25 and A.plannerPage:IsShown() and not A.enchantDatabase:IsShown())
A:OpenEnchantBrowser("HEAD")
check("existing equipment enchant picker remains separate and functional",A.enchantBrowser:IsShown() and A.enchantSlot=="HEAD")
A.enchantBrowser:Hide()
A.current.items.HEAD=999999999;A.current.enchants.HEAD=999999998;A:RefreshUI()
check("unknown imported item and enchant have explicit labels",A.slotButtons.HEAD.itemText:GetText()=="Unknown item #999999999" and A.slotButtons.HEAD.enchantText:GetText()=="Unknown enchant #999999998")
Fire(A.slotButtons.HEAD,"OnEnter")
check("hover preserves the unknown enchant label",A.slotButtons.HEAD.enchantText:GetText()=="Unknown enchant #999999998" and A.slotButtons.HEAD.hasEnchant)

local incoming=A.NewBuildData("Incoming");local code=A:ExportBuild(incoming)
local pending;A.ShowPrompt=function(_,p) pending=p end
A:ShowCodeDialog("Import",code,true);Click(A.codeAction)
check("import dialog remains open while discard is pending",pending and A.codeDialog:IsShown() and A.current.items.HEAD==999999999)
pending.onAccept()
check("accepted import closes dialog through completion callback",not A.codeDialog:IsShown() and not A.current.items.HEAD)
