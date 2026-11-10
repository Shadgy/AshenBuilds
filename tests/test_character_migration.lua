-- SavedVariables serializes shared references as separate tables between logins.
local A=AshenBuilds
local oldName,oldClass,oldRace,oldDB,oldCurrent=UnitName,UnitClass,UnitRace,AshenBuildsDB,A.current
local function Login(name,class,token,race)
  UnitName=function() return name end
  UnitClass=function() return class,token end
  UnitRace=function() return race,race end
  A:InitializeDB()
end
local function Serialize(v)
  if type(v)=="table" then
    local out,k,x={}
    for k,x in pairs(v) do table.insert(out,"["..Serialize(k).."]="..Serialize(x)) end
    return "{"..table.concat(out,",").."}"
  elseif type(v)=="string" then return string.format("%q",v)
  else return tostring(v) end
end
local function ReloadSavedVariables()
  local code="return "..Serialize(AshenBuildsDB)
  AshenBuildsDB=nil
  AshenBuildsDB=assert(loadstring(code))()
end

AshenBuildsDB=nil
Login("FirstWarrior","Warrior","WARRIOR","Human")
A.current.items.MAINHAND=19019
A:SaveBuild("First warrior plan",true)
FireEvent("PLAYER_LOGOUT")
ReloadSavedVariables()
check("fresh installation records per-character migration",AshenBuildsDB.perCharacterMigration==1)
check("second character has no persisted plan before its first login",not AshenBuildsDB.currentByChar["SecondWarrior-Realm"])
Login("SecondWarrior","Warrior","WARRIOR","Human")
check("fresh same-class alt does not inherit another plan",not A.current.items.MAINHAND and not A.current.savedName and A.current.name=="New Build")
A.current.notes="Second character draft";A:RefreshUI()
check("editing the alt cannot change the first character library entry",AshenBuildsDB.builds["First warrior plan"].items.MAINHAND==19019 and AshenBuildsDB.builds["First warrior plan"].notes~="Second character draft")
Login("FirstWarrior","Warrior","WARRIOR","Human")
check("first character retains its own serialized equipment and saved link",A.current.items.MAINHAND==19019 and A.current.savedName=="First warrior plan")

local legacy=A.NewBuildData("Old shared warrior plan")
legacy.class="Warrior";legacy.race="Human";legacy.items={MAINHAND=19019}
AshenBuildsDB={current=legacy,builds={},settings={}}
Login("FirstMage","Mage","MAGE","Gnome")
check("legacy plan of another class is held separately",A.current.class=="Mage" and AshenBuildsDB.legacySharedCurrent.items.MAINHAND==19019 and not AshenBuildsDB.sharedCurrentClaimed)
FireEvent("PLAYER_LOGOUT");ReloadSavedVariables()
Login("LegacyWarrior","Warrior","WARRIOR","Human")
check("legacy matching class can claim the original plan after another login",A.current.name=="Old shared warrior plan" and A.current.items.MAINHAND==19019)
check("legacy migration is consumed exactly once",AshenBuildsDB.sharedCurrentClaimed and not AshenBuildsDB.legacySharedCurrent)
ReloadSavedVariables();Login("ThirdWarrior","Warrior","WARRIOR","Human")
check("later same-class alt cannot claim legacy or last active plan",not A.current.items.MAINHAND and not A.current.savedName)

-- Upgrade from 1.0.7: an existing per-character map is already authoritative.
local existing=A.NewBuildData("Existing per-character plan");existing.class="Warrior";existing.items.MAINHAND=19019
AshenBuildsDB={builds={},settings={},current=A:DeepCopy(existing),currentByChar={["Existing-Realm"]=existing}}
Login("NewAfterUpgrade","Warrior","WARRIOR","Human")
check("upgrade does not reinterpret last active character as legacy",not A.current.items.MAINHAND and not AshenBuildsDB.legacySharedCurrent)
check("upgrade preserves existing per-character entries",AshenBuildsDB.currentByChar["Existing-Realm"].items.MAINHAND==19019)

UnitName=oldName;UnitClass=oldClass;UnitRace=oldRace;AshenBuildsDB=oldDB;A.current=oldCurrent
