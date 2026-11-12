local A=AshenBuilds
local oldCurrent,oldDB,oldPrompt=A.current,AshenBuildsDB,A.ShowPrompt
local function Build(name)
  local b=A.NewBuildData(name);b.class="Warrior";b.race="Human";b.level=60;b.spec="Custom";A.EnsureTalents(b);return b
end
local function ReplaceToken(code,n,value)
  local tokens=A:SplitBuildCode(code);tokens[n]=value;return table.concat(tokens,".")
end
local incoming=Build("Incoming");incoming.items.MAINHAND=19019
local code=A:ExportBuild(incoming)
local draft=Build("Never saved");draft.items.HEAD=12640
A.current=draft;A:RefreshUI()
local pending,prompts,callbacks=nil,0,0
A.ShowPrompt=function(_,p) pending=p;prompts=prompts+1 end
check("import waits for unsaved-plan confirmation",A:ImportBuild(code,function() callbacks=callbacks+1 end)==false and pending and prompts==1)
check("pending or cancelled import keeps the original draft",A.current==draft and A.current.items.HEAD==12640 and callbacks==0)
pending.onAccept()
check("accepted import replaces gear and invokes completion once",A.current~=draft and A.current.items.MAINHAND==19019 and not A.current.items.HEAD and callbacks==1)

A.current=A.NewBuildData("New Build");A:RefreshUI();pending=nil;prompts=0
check("empty plan imports immediately without confirmation",A:ImportBuild(code,function() callbacks=callbacks+1 end)==true and not pending and prompts==0 and callbacks==2)
local before=A.current
check("invalid code is rejected before asking about draft",A:ImportBuild(ReplaceToken(code,2,"!"))==false and A.current==before and prompts==0)
A.current=Build("Notes-only draft");A.current.notes="Keep these notes";A:RefreshUI();pending=nil
check("notes-only draft is protected from import too",A:ImportBuild(code)==false and pending and A.current.notes=="Keep these notes")

local unknown=Build("New database content")
unknown.items={HEAD=999999999,MAINHAND=19019};unknown.enchants={HEAD=999999998,MAINHAND=10}
local decoded,err=A:DecodeBuild(A:ExportBuild(unknown))
check("AB3 preserves unknown positive item and enchant IDs",decoded and decoded.items.HEAD==999999999 and decoded.enchants.HEAD==999999998 and not err)
check("AB3 preserves known neighboring item and enchant IDs",decoded.items.MAINHAND==19019 and decoded.enchants.MAINHAND==10)
local warnings=A:GetDerivedStats(decoded).warnings
local missing=false
for _,warning in ipairs(warnings) do if string.find(warning,"999999999",1,true) then missing=true end end
check("unknown imported equipment remains explicitly incomplete",missing)
local tokens=A:SplitBuildCode(A:ExportBuild(unknown));local count=table.getn(tokens)
local ab2="AB2."..table.concat(tokens,".",2,count-3)
decoded=A:DecodeBuild(ab2)
check("AB2 also preserves unknown IDs",decoded and decoded.items.HEAD==999999999 and decoded.enchants.HEAD==999999998)

local invalids={
  ReplaceToken(code,2,"0"),ReplaceToken(code,3,"!"),ReplaceToken(code,4,"0"),
  ReplaceToken(code,4,A.EncodeNumber(61)),ReplaceToken(code,5,"_"),
  ReplaceToken(code,6,"!"),ReplaceToken(code,7,"!"),
  ReplaceToken(code,6,A.EncodeNumber(4294967296)),ReplaceToken(code,7,A.EncodeNumber(4294967296)),
  ReplaceToken(code,6,string.rep("_",50)),ReplaceToken(code,6,""),code..".",
  (string.gsub(code,"AB3%.","AB3..",1))
}
for i,bad in ipairs(invalids) do
  local value=A:DecodeBuild(bad)
  check("malformed code is rejected atomically "..i,value==nil)
end
check("numeric decoder rejects oversized or empty tokens",not A.DecodeNumber(string.rep("_",50)) and not A.DecodeNumber(""))
check("numeric encoder cannot loop on infinity or invalid fractions",A.EncodeNumber(math.huge)=="0" and A.EncodeNumber(1.5)=="0")

local legacyParts={"AB1"}
for i,slot in ipairs(A.SLOTS) do table.insert(legacyParts,A.EncodeNumber(unknown.items[slot] or 0)) end
local legacy=table.concat(legacyParts,".")
A.current=Build("Unsaved legacy destination");A.current.items.HEAD=12640;A:RefreshUI();pending=nil
check("legacy import also protects unsaved plans",A:ImportLegacyBuild(legacy)==false and pending and A.current.items.HEAD==12640)
pending.onAccept()
check("legacy import retains positive unknown IDs",A.current.items.HEAD==999999999 and A.current.items.MAINHAND==19019)
local legacyBuild=A:DecodeLegacyBuild(ReplaceToken(legacy,2,"!"))
check("malformed legacy item rejects the entire legacy build",not legacyBuild)

-- The old 17-slot representation still maps the final weapon slots correctly.
local oldSlots={"HEAD","NECK","SHOULDER","BACK","CHEST","WRIST","HANDS","WAIST","LEGS","FEET","FINGER1","FINGER2","TRINKET1","TRINKET2","MAINHAND","OFFHAND","RANGED"}
local oldParts={"AB2",A.EncodeNumber(A.IndexOf(A.CLASSES,"Warrior")),A.EncodeNumber(1),A.EncodeNumber(60),A.EncodeNumber(4)}
for _,slot in ipairs(oldSlots) do table.insert(oldParts,A.EncodeNumber(unknown.items[slot] or 0));table.insert(oldParts,A.EncodeNumber(unknown.enchants[slot] or 0)) end
decoded=A:DecodeBuild(table.concat(oldParts,"."))
check("17-slot AB2 remains compatible",decoded and decoded.items.MAINHAND==19019 and decoded.items.HEAD==999999999 and decoded.enchants.MAINHAND==10)

A.ShowPrompt=oldPrompt;A.current=oldCurrent;AshenBuildsDB=oldDB
