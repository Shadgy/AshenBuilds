-- Tabs are pages inside the main window.
local AB = AshenBuilds
SlashCmdList["ASHENBUILDS"]("")
local oldSet = AB.SetTabActive
AB.SetTabActive = function(self, b, on) b._tabActive = on; return oldSet(self, b, on) end
AB:RefreshTabStates()
local function planner() return AB.plannerPage:IsShown() end
local function active(b) return b._tabActive end

check("starts on the planner", planner() and active(AB.plannerButton))
check("planner has five tabs", table.getn(AB.tabs) == 5)
check("pages live inside the main window", AB.talentFrame:GetParent() == AB.frame and AB.itemBrowser:GetParent() == AB.frame
  and AB.buildBrowser:GetParent() == AB.frame and AB.enchantDatabase:GetParent() == AB.frame)
check("gear, stats and SIM DPS belong to the Planner page", AB.slotButtons.HEAD:GetParent() == AB.plannerPage and AB.simPanel:GetParent() == AB.plannerPage)
check("talent trees fit without scaling", AB.talentFrame:GetScale() == 1 and AB.frame:GetWidth() >= AB.talentFrame:GetWidth())

Click(AB.talentOpenButton)
check("Talents tab hides the planner", AB.talentFrame:IsShown() and not planner() and active(AB.talentOpenButton) and not active(AB.plannerButton))
Click(AB.enchantDatabaseButton)
check("Enchant Database replaces Talents", AB.enchantDatabase:IsShown() and not AB.talentFrame:IsShown())
Click(AB.savedBuildsButton)
check("Saved Builds replaces Enchant Database", AB.buildBrowser:IsShown() and not AB.enchantDatabase:IsShown())
Click(AB.itemDatabaseButton)
check("Item Database replaces Saved Builds", AB.itemBrowser:IsShown() and not AB.buildBrowser:IsShown())
check("full height while a page is open", AB.frame:GetHeight() == 900)
for _, w in ipairs({AB.itemBrowser, AB.buildBrowser, AB.enchantDatabase}) do
  local pts = {}
  for _, q in ipairs(w._points or {}) do table.insert(pts, q[1]) end
  check(w:GetName() .. " fills the page area", table.concat(pts, ",") == "TOPLEFT,BOTTOMRIGHT")
end
Click(AB.plannerButton)
check("Planner tab returns to the planner", planner() and not AB.itemBrowser:IsShown() and active(AB.plannerButton))

local savedName="Planner manual save test"
AB:SaveBuild(savedName)
Click(AB.slotButtons.HEAD)
check("a gear slot opens the Item Database for it", AB.itemBrowser:IsShown() and AB.browserSlot == "HEAD")
local row = AB.itemRows[1]
if row and row.itemID then Click(row) end
check("picking an item returns to the planner", planner() and AB.current.items.HEAD ~= nil)
local picked=AB.current.items.HEAD
check("picking an item only changes the planner draft", AB:HasUnsavedChanges() and not AshenBuildsDB.builds[savedName].items.HEAD)
check("planner shows that edits are unsaved", string.find(AB.saveStateText:GetText(),"Unsaved changes",1,true)~=nil)
AB.nameBox:SetText("Unsaved title")
Fire(AB.nameBox,"OnEnterPressed")
check("Enter in the name field does not save or rename", AB.current.name=="Unsaved title" and AB.current.savedName==savedName and not AshenBuildsDB.builds["Unsaved title"])
AB.nameBox:SetText(savedName)
Click(AB.savedBuildsButton)
local buildRow
for _,candidate in ipairs(AB.buildRows) do if candidate.buildName==savedName then buildRow=candidate end end
Click(buildRow)
check("loading the same saved build prompts before replacing its edited draft", AB.promptDialog:IsShown() and AB.current.items.HEAD==picked)
local cancel
for _,button in ipairs({AB.promptDialog:GetChildren()}) do
  if button:GetText()=="Cancel" then cancel=button; break end
end
Click(cancel)
check("cancelling a build load keeps the edit", AB.current.items.HEAD==picked and not AshenBuildsDB.builds[savedName].items.HEAD)
Click(AB.plannerButton)
check("planner offers the Save Changes action", AB.saveButton:GetText()=="Save Changes")
Click(AB.saveButton)
check("Save Changes commits the selected gear and clears the unsaved state", AshenBuildsDB.builds[savedName].items.HEAD==picked and not AB:HasUnsavedChanges())
check("planner clears its unsaved label after Save Changes", not string.find(AB.saveStateText:GetText(),"Unsaved changes",1,true))

Click(AB.slotButtons.HEAD,"RightButton")
local editedDraft=AB.current
SlashCmdList["ASHENBUILDS"]("reset")
check("reset waits before replacing edits to a saved build", AB.promptDialog:IsShown() and AB.current==editedDraft and AB:HasUnsavedChanges())
Click(AB.promptDialog.accept)
check("discarding the reset draft keeps the saved gear", AB.current~=editedDraft and AshenBuildsDB.builds[savedName].items.HEAD==picked)

local found = false
for _, n in ipairs(UISpecialFrames) do if n == "AshenBuildsItemBrowser" or n == "AshenBuildsTalentFrame" then found = true end end
check("Escape closes the planner, not a single page", not found)

local function walk(f, lvl, bad)
  for _, k in ipairs({f:GetChildren()}) do
    if k:GetFrameLevel() <= lvl then table.insert(bad, k) end
    walk(k, k:GetFrameLevel(), bad)
  end
end
for _, w in ipairs({AB.talentFrame, AB.enchantDatabase, AB.buildBrowser, AB.itemBrowser}) do
  local bad = {}; walk(w, w:GetFrameLevel(), bad)
  check(w:GetName() .. " contents draw above it", table.getn(bad) == 0)
end

local dressed = 0
local oldSV = AB.SetStatsView
AB.SetStatsView = function(self, v) if v == "preview" then dressed = dressed + 1 end; return oldSV(self, v) end
AB:SetStatsView("preview"); dressed = 0
Click(AB.talentOpenButton); Click(AB.plannerButton)
check("3D preview is dressed again on return", dressed == 1)
