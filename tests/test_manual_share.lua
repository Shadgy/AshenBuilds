local A=AshenBuilds
local slash=SlashCmdList["ASHENBUILDS"]
local function AdvanceTime()
  for i=1,20 do CLOCK=CLOCK+60; RunFrame(60) end
end
FireEvent("PLAYER_ENTERING_WORLD")
AdvanceTime()
check("startup and timers leave chat and channels untouched",table.getn(TRANSPORT_CALLS)==0)
check("community catalog and synchronization have no entry points",not A.communityFrame and not A.communityButton and not A.RequestCommunitySync and not A.PublishBuild)

-- Simulate a client that is still in the old channel after updating.
function GetChannelName() return 5,"AshenBuilds" end
FireEvent("CHAT_MSG_ADDON","ASHB","Q~0~0~0~1.0.9","GUILD","AnotherTester")
FireEvent("CHAT_MSG_CHANNEL","~ASHB1~Q~0~0~0~1.0.9","AnotherTester","Common","5. AshenBuilds","","",0,5,"AshenBuilds")
for _,command in ipairs({"sync on","sync off","sync status","community","unhide AnotherTester"}) do
  local before=table.getn(CHAT_LOG)
  slash(command)
  local message=CHAT_LOG[before+1] or ""
  check("legacy /ab "..command.." points to manual sharing",table.getn(CHAT_LOG)==before+1 and string.find(message,"Share Build",1,true) and string.find(message,"Import Build",1,true))
end
AdvanceTime()
check("incoming old sync traffic and legacy commands send nothing",table.getn(TRANSPORT_CALLS)==0)

Click(A.minimapButton,"RightButton")
check("minimap right-click opens Saved Builds",A.frame:IsShown() and A.buildBrowser:IsShown() and not A.plannerPage:IsShown())
Click(A.plannerButton)
check("planner has Share Build and Import Build actions",A.shareButton:GetText()=="Share Build" and A.importButton:GetText()=="Import Build")

local hookCalls=0
A.OnBuildSaved=function() hookCalls=hookCalls+1 end
A.OnBuildDeleted=function() hookCalls=hookCalls+1 end
local name="Tank plan"
A.current=A.NewBuildData(name)
A.current.class="Warrior"
A.current.race="Human"
A.current.spec="Custom"
A.current.level=60
A.current.items.MAINHAND=19019
A:RefreshUI()
A:SaveBuild(name)
local savedCode=A:ExportBuild(AshenBuildsDB.builds[name])
A.current.items.HEAD=12640
A:RefreshUI()

local focused,selected
A.codeEdit.SetFocus=function() focused=true end
A.codeEdit.HighlightText=function(edit) selected=edit:GetText() end
Click(A.shareButton)
local draftCode=A.codeEdit:GetText()
check("Share Build shows the current draft in a focused, selected edit box",A.codeDialog:IsShown() and A.codeDialog.title:GetText()=="Share Build" and not A.codeAction:IsShown() and A.codeEdit:GetObjectType()=="EditBox" and focused and selected==draftCode)
check("Share Build tells users how to copy the code",string.find(A.codeDialog.hint:GetText(),"Ctrl+C",1,true)~=nil)
local decoded=A:DecodeBuild(draftCode)
check("toolbar share code contains current unsaved gear",decoded and decoded.items.HEAD==12640 and decoded.items.MAINHAND==19019 and draftCode~=savedCode)
Fire(A.codeEdit,"OnEscapePressed")
check("Escape closes the share dialog",not A.codeDialog:IsShown())

Click(A.savedBuildsButton)
local row
for _,candidate in ipairs(A.buildRows) do if candidate.buildName==name then row=candidate; break end end
local draft=A.current
Click(row.share)
check("saved row Share Build copies the library snapshot",A.codeDialog:IsShown() and A.codeEdit:GetText()==savedCode and not A.codeAction:IsShown())
check("sharing a saved row keeps the planner draft",A.current==draft and A.current.items.HEAD==12640 and A:HasUnsavedChanges() and not AshenBuildsDB.builds[name].items.HEAD)
A.codeDialog:Hide()

focused=false
Click(A.importButton)
check("Import Build opens an empty focused field",A.codeDialog:IsShown() and A.codeDialog.title:GetText()=="Import Build" and A.codeEdit:GetText()=="" and A.codeAction:IsShown() and focused)
check("Import Build tells users how to paste a code",string.find(A.codeDialog.hint:GetText(),"Ctrl+V",1,true)~=nil)
A.codeEdit:SetText("invalid code")
Click(A.codeAction)
check("invalid pasted code leaves the dialog and the draft untouched",A.codeDialog:IsShown() and A.codeEdit:GetText()=="invalid code" and A.current==draft and not (A.promptDialog and A.promptDialog:IsShown()))
A.codeEdit:SetText("  \t"..savedCode.." \t")
Fire(A.codeEdit,"OnEnterPressed")
check("Enter accepts pasted whitespace and asks before replacing the draft",A.promptDialog:IsShown() and A.current==draft and A.codeDialog:IsShown())
Click(A.promptDialog.accept)
check("accepted paste closes the dialog and opens the imported draft in the Planner",not A.codeDialog:IsShown() and A.plannerPage:IsShown() and A.current~=draft and not A.current.items.HEAD and A.current.items.MAINHAND==19019)
check("import creates a draft and keeps the saved library copy",not A.current.savedName and A:ExportBuild(AshenBuildsDB.builds[name])==savedCode)

A:DeleteBuild(name)
FireEvent("PLAYER_LOGOUT")
AdvanceTime()
check("manual shares, imports and library edits leave chat and channels untouched",table.getn(TRANSPORT_CALLS)==0)
check("local save and delete no longer invoke community hooks",hookCalls==0)
