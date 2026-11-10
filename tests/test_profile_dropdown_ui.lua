local A=AshenBuilds
local frameMethods=getmetatable(UIParent)
local oldColor,oldEnable,oldDisable=frameMethods.SetTextColor,frameMethods.Enable,frameMethods.Disable
frameMethods.SetTextColor=function(self,r,g,b) self._testColor={r,g,b};if oldColor then oldColor(self,r,g,b) end end
frameMethods.Enable=function(self) self._testDisabled=false;if oldEnable then oldEnable(self) end end
frameMethods.Disable=function(self) self._testDisabled=true;if oldDisable then oldDisable(self) end end

-- Capture the actual skin calls while rebuilding this suite's isolated UI.
local oldSkin=A.SkinButton
local styles={}
A.SkinButton=function(self,button,style) styles[button]=style;return oldSkin(self,button,style) end
A.frame=nil;A:CreateUI();A.SkinButton=oldSkin
check("all profile selectors retain the pointed cycle art",styles[A.classButton]=="cycle" and styles[A.raceButton]=="cycle" and styles[A.specButton]=="cycle")
check("profile selectors retain their existing header geometry",A.classButton:GetWidth()==105 and A.raceButton:GetWidth()==105 and A.specButton:GetWidth()==125 and A.classButton:GetHeight()==22)

local function Build(class,race)
  local b=A.NewBuildData("Profile menu");b.class=class;b.race=race;b.level=60;b.spec=A.SPECS[class][1]
  b.items={};b.enchants={};A.EnsureTalents(b);return b
end
local function Row(value)
  if not AshenBuildsDropdownList:IsShown() then return nil end
  for _,row in ipairs(AshenBuildsDropdownList.rows) do if row:IsShown() and row.value==value then return row end end
end
local b=Build("Warrior","Human");A.current=b;A:RefreshUI()
local before=A:GetBuildPayloadSignature(b)
A.classButton:Click()
check("class click opens the menu without cycling the class",AshenBuildsDropdownList:IsShown() and AshenBuildsDropdownList.owner==A.classButton and b.class=="Warrior" and A:GetBuildPayloadSignature(b)==before)
check("class menu contains every class with current selection checked",table.getn(AshenBuildsDropdownList.items)==table.getn(A.CLASSES) and Row("Warrior").check:IsShown())
Row("Mage"):Click()
check("one menu selection chooses class and refreshes the header",b.class=="Mage" and A.classButton:GetText()=="Mage" and A.specButton:GetText()==A.SPECS.Mage[1] and not AshenBuildsDropdownList:IsShown())

local race=b.race;A.raceButton:Click("RightButton")
check("right click also opens the race menu without cycling",b.race==race and AshenBuildsDropdownList.owner==A.raceButton)
Row("Gnome"):Click()
check("race can be selected directly",b.race=="Gnome" and A.raceButton:GetText()=="Gnome")
local spec=b.spec;A.specButton:Click()
check("build click opens presets without cycling",b.spec==spec and AshenBuildsDropdownList.owner==A.specButton)
Row("Frost"):Click()
check("build preset can be selected directly",b.spec=="Frost" and A.specButton:GetText()=="Frost")

local tauren=Build("Warrior","Tauren");A.current=tauren;A:RefreshUI();A.classButton:Click()
local rogue=Row("Rogue");local color=rogue.text._testColor
check("Tauren Rogue remains visible grey and unavailable with hover enabled",rogue.disabled and not rogue._testDisabled and color and color[1]==.45 and color[2]==.45 and color[3]==.45)
local sig=A:GetBuildPayloadSignature(tauren);rogue:Click()
check("even a dispatched disabled row click cannot select Tauren Rogue",tauren.class=="Warrior" and A:GetBuildPayloadSignature(tauren)==sig and AshenBuildsDropdownList:IsShown())
check("disabled class has a reason",type(rogue.reason)=="string" and rogue.reason~="")
Fire(rogue,"OnEnter")
check("unavailable choice exposes its reason on hover",GameTooltip:GetText()=="Rogue")
A.CloseDropdown();A.specButton:Click()
check("reused rows are enabled again for valid build choices",not Row("Fury").disabled and not Row("Fury")._testDisabled and Row("Fury").text._testColor[1]==1)

local humanRogue=Build("Rogue","Human");A.current=humanRogue;A:RefreshUI();A.raceButton:Click()
local disabledRace=Row("Tauren");disabledRace:Click()
check("the race menu also blocks the impossible pairing",disabledRace.disabled and humanRogue.race=="Human")
Row("Dwarf"):Click()
check("valid race alternatives remain selectable",humanRogue.race=="Dwarf")
local dwarf=Build("Warrior","Dwarf");A.current=dwarf;A:RefreshUI();A.classButton:Click()
check("Octo Dwarf Warlock is not disabled by vanilla-only rules",not Row("Warlock").disabled)
A.CloseDropdown()

local invalid=Build("Rogue","Tauren");A.current=invalid;A:RefreshUI();A.classButton:Click();Row("Warrior"):Click()
check("legacy invalid combinations can be repaired through a valid class choice",invalid.class=="Warrior" and invalid.race=="Tauren")

local talented=Build("Warrior","Human")
local data=A:GetTalentData("Warrior")
for tree=1,3 do for index,talent in ipairs(data[tree]) do if talent.name=="Deflection" then talented.talents.points[A:GetTalentKey(tree,index)]=1 end end end
A.current=talented;A:RefreshUI();A.classButton:Click()
local paladin=Row("Paladin")
check("class switches blocked by talents are visibly disabled",paladin.disabled and type(paladin.reason)=="string")
local savedSignature=A:GetBuildPayloadSignature(talented);paladin:Click()
check("disabled class choice preserves the talent plan",talented.class=="Warrior" and A:GetBuildPayloadSignature(talented)==savedSignature)
A.CloseDropdown()
local context=Build("Warrior","Human");A.current=context;A:RefreshUI();A.classButton:Click()
A.current=Build("Warrior","Tauren");A:RefreshUI()
check("an open class menu refreshes after a programmatic build switch",AshenBuildsDropdownList:IsShown() and Row("Rogue").disabled)
A.current=Build("Warrior","Human");A:RefreshUI()
check("open profile rows regain availability when context permits",not Row("Rogue").disabled)
A.CloseDropdown();A.specButton:Click()
A.current=Build("Mage","Gnome");A:RefreshUI()
check("an open build menu replaces another class presets",Row("Frost") and not Row("Fury") and table.getn(AshenBuildsDropdownList.items)==4)
A.CloseDropdown()
local multi=A:CreateDropdown(A.frame,100,{getText=function() return "Other choices" end,items=function() return {{value="a",text="A"},{value="b",text="B"}} end,onSelect=function() end,multi=true})
multi:Click();A:RefreshUI();Row("a"):Click()
check("profile refresh does not close unrelated multi-select menus",AshenBuildsDropdownList:IsShown() and AshenBuildsDropdownList.owner==multi)
A.CloseDropdown()

check("weapon quest checkbox keeps its existing position",A.weaponSkillQuestCheck._points[table.getn(A.weaponSkillQuestCheck._points)][4]==446)
frameMethods.SetTextColor=oldColor;frameMethods.Enable=oldEnable;frameMethods.Disable=oldDisable
