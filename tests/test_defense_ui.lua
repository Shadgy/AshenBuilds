local A=AshenBuilds
check("defense details fit both coverage conventions",A.defenseBrowser and A.defenseBrowser:GetWidth()==540 and A.defenseBrowser:GetHeight()==520)
check("content settings are shared by both pickers",table.getn(A.availabilityButtons)==2 and A.availabilityBrowser)
local b=A.NewBuildData("Defense display"); b.class="Warrior"; b.race="Human"; b.level=60; b.items={OFFHAND=19349}; b.enchants={}; A.EnsureTalents(b); A.current=b
A.defenseBrowser:Show(); A:RefreshDefenseBrowser()
check("warrior sees Shield Block control",A.defenseBrowser.shieldBlock:IsShown() and not A.defenseBrowser.holyShield:IsShown())
A.defenseBrowser.target.opts.onSelect(60)
check("target dropdown updates per-build defense setting",A:GetDefenseSettings(b).targetLevel==60)
local d=A:GetDerivedStats(b); A:RefreshDefenseBrowser(d)
local values={}; local i,row
for i=1,table.getn(A.defenseBrowser.rows) do row=A.defenseBrowser.rows[i]; values[row.key]=row.value:GetText() end
check("defense display shows effective avoidance and coverage",values.avoidance==string.format("%.2f%%",d.defenseTable.avoidance) and values.coverage==string.format("%.2f / 100%%",d.defenseTable.coverage))
check("defense display shows sheet coverage and dynamic cap",values.sheetCoverage==string.format("%.2f / %.2f%%",d.defenseTable.sheetCoverage,d.defenseTable.sheetCap))
check("defense display exposes miss separately",values.miss==string.format("%.2f%%",d.defenseTable.miss))
b.class="Paladin"; A:RefreshDefenseBrowser()
check("paladin sees Holy Shield and Redoubt controls",A.defenseBrowser.holyShield:IsShown() and A.defenseBrowser.redoubt:IsShown() and not A.defenseBrowser.shieldBlock:IsShown())
A:OpenItemBrowser("OFFHAND"); A.itemFilter.sort="blockValue"; A.itemFilter.classOnly=false; A.itemFilter.usable=false; A:RefreshItemResults()
local sorted=true; local last
for i=1,table.getn(A.itemMatches) do
  local value=A.ItemIndex.stats[A.itemMatches[i]].blockValue or 0
  if last and value>last then sorted=false end; last=value
end
check("item browser sorts descending normalized Block Value",sorted and table.getn(A.itemMatches)>0)
