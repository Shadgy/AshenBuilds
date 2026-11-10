local A=AshenBuilds
local s=A:GetAvailabilitySettings()
check("normal content view starts with unverified sources off",s.includeUnknown==false and not A.availabilityBrowser.unknown:GetChecked())
check("content explanation distinguishes AtlasLoot evidence from selected phase",string.find(A.availabilityBrowser.note:GetText(),"AtlasLoot",1,true) and string.find(A.availabilityBrowser.note:GetText(),"phase still applies",1,true))
check("content explanation names unverified-only catalog artifacts",string.find(A.availabilityBrowser.note:GetText(),"original Ashbringer",1,true) and string.find(A.availabilityBrowser.note:GetText(),"Azzinoth",1,true))
local itemButton=A.itemAvailabilityButton;local p=itemButton._points[table.getn(itemButton._points)]
check("item content control lives in the filter toolbar rather than CLASS header",itemButton:GetParent()==A.itemBrowser and p[1]=="TOPRIGHT" and p[3]=="TOPRIGHT" and p[4]==-26 and p[5]==-160)
local enchantButton=A.enchantAvailabilityButton
check("enchant content control remains in its separate picker",enchantButton:GetParent()==A.enchantBrowser and enchantButton:GetParent()~=A.frame)
for _,row in ipairs(A.itemRows) do
  check("item row reserves non-overlapping single-line heights",row.name:GetHeight()==14 and row.meta:GetHeight()==12 and row.stats:GetHeight()==12 and row:GetHeight()==36)
end
check("enchant row also has bounded name and description lines",A.enchantRows[1].text:GetHeight()==14 and A.enchantRows[1].desc:GetHeight()==12)

local font=A.frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");font:SetWidth(80)
font.GetStringWidth=function(self)
  local text=string.gsub(string.gsub(self:GetText(),"|c%x%x%x%x%x%x%x%x",""),"|r","")
  return string.len(text)*8
end
local full="|cffffa040"..string.rep("W",35).."|r\nfull source"
A:SetPickerLine(font,full)
check("long picker text is ellipsized within its original width",font.truncated and font:GetStringWidth()<=80 and font:GetWidth()==80 and string.sub(font:GetText(),-3)=="...")
check("shortening retains the complete text for tooltips",font.fullText==full and not string.find(font:GetText(),"\n",1,true))
A:SetPickerLine(font,"Short")
check("short picker text resets truncation state",not font.truncated and font:GetText()=="Short")

local oldAtlas=AshenBuildsAtlasLootSources
AshenBuildsAtlasLootSources={items={},enchants={}}
local function Fixture(id,name,zone)
  AshenDB.Items[id]={name,4,"HANDS",60,88,"INV_Gauntlets_05",4,4,100,0,-1,-1,1,0,0,0,0,"",{str=5},{"drop"}}
  AshenDB.ItemSources[id]={{"drop",1,"UI fixture boss",zone}}
  table.insert(AshenBuildsItemOrder,id)
end
Fixture(990201,"AtlasLoot-UI Tower gloves","Tower of Karazhan")
Fixture(990202,"AtlasLoot-UI unknown gloves","Molten Core")
AshenBuildsAtlasLootSources.items[990201]={routes={{kind="drop",instance="Tower of Karazhan",phase=7}}}
A.ItemIndex:Reset();A.ItemIndex:Finish()
s.profile="Octo";s.phase=2;s.includeUnknown=false;s.showFuture=false;s.instances={}
A:OpenItemBrowser("HANDS");A.itemSearch:SetText("atlasloot-ui");A:RefreshItemResults()
local function Has(id)
  for _,index in ipairs(A.itemMatches) do if A.ItemIndex.id[index]==id then return true end end
  return false
end
check("phase2 picker hides known Tower loot and unverified entries",not Has(990201) and not Has(990202))
A.availabilityBrowser.unknown:SetChecked(1);A.availabilityBrowser.unknown:Click()
check("Unverified checkbox updates suggestions without unlocking Tower",s.includeUnknown and Has(990202) and not Has(990201))
A.availabilityBrowser.phase.opts.onSelect(7)
check("Tower item becomes selectable in phase7",Has(990201))
local tower
for _,row in ipairs(A.itemRows) do if row.itemID==990201 then tower=row end end
check("phase-open verified item loses the Unverified label",tower and not string.find(tower.stats:GetText(),"Unverified",1,true))
A.availabilityBrowser.unknown:SetChecked(nil);A.availabilityBrowser.unknown:Click()
check("turning Unverified off hides unknowns but keeps mapped phase7 loot",not Has(990202) and Has(990201))
A.availabilityBrowser.phase.opts.onSelect(2);A.itemFilter.showHidden=true;A:RefreshItemResults()
check("Show hidden cannot bypass the Unverified or future-phase controls",not Has(990202) and not Has(990201))

AshenBuildsEnchants[990203]={n="UI phase-unknown enchant",slots={HEAD=true},stats={sta=1},tip="A recorded enchant with an unmapped learning phase."}
AshenBuildsAtlasLootSources.enchants[990203]={routes={{kind="profession"}}}
s.includeUnknown=true;A.enchantSlot="HEAD";A.enchantCandidates={990203};A.enchantFilter.group="all";A.enchantFilter.lower=true
A.enchantSearch:SetText("");A:FilterEnchants()
check("verified source with unknown phase is labelled accurately",A.enchantRows[1].enchantID==990203 and string.find(A.enchantRows[1].desc:GetText(),"[Unverified phase]",1,true))
AshenBuildsAtlasLootSources=oldAtlas
