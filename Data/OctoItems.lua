-- Octo items outside the base AshenDB snapshot. See docs/octo-item-audit.md.
local additions={
  {58247,{"Champion's Insignia",4,"TRINKET",60,65,"INV_Misc_ArmorKit_03",4,0,0,0,-1,-1,1,1,0,0,0,"",{sta=10},{}}},
  {83605,{"Bloody Gladiator's Lamellar Girdle",3,"WAIST",60,66,"INV_Misc_QuestionMark",4,4,425,792,-1,-1,1,0,0,0,0,"",
    {armor=425,sta=21,int=12,spellPower=15,healing=15,fireRes=5,natureRes=5,frostRes=5,shadowRes=5,arcaneRes=5},{}}},
  {83608,{"Bloody Gladiator's Lamellar Bracers",3,"WRIST",60,68,"INV_Misc_QuestionMark",4,4,349,792,-1,-1,1,0,0,0,0,"",
    {armor=349,sta=14,int=11,spellPower=13,healing=13},{}}},
  {90051,{"Bokken",1,"MAINHAND",1,2,"INV_Sword_41",2,7,0,0,-1,-1,0,0,1900,1,3,"Sword",{dps=1.1},{}}},
  {90053,{"Simple Katana",1,"WEAPON",10,15,"INV_Sword_10",2,7,0,0,-1,-1,0,0,2200,10,20,"Sword",{dps=6.8},{"vendor"}}},
  {90060,{"Ring of Friendship",3,"FINGER",1,1,"INV_Jewelry_Ring_33",4,0,0,0,-1,-1,1,1,0,0,0,"",{}, {}}},
  {90061,{"Ring of Friendship",3,"FINGER",1,1,"INV_Jewelry_Ring_33",4,0,0,0,-1,-1,1,1,0,0,0,"",{}, {}}},
  {93223,{"Simple Bronze Katana",2,"WEAPON",18,24,"INV_Sword_10",2,7,0,0,-1,-1,0,0,1500,12.8,19,"Sword",{dps=10.6},{"crafted"}}},
}
for _,entry in ipairs(additions) do
  local id=entry[1]
  if not AshenDB.Items[id] then
    AshenDB.Items[id]=entry[2]
    table.insert(AshenDB.ItemOrder,id)
  end
end
AshenDB.Manifest.itemCount=table.getn(AshenDB.ItemOrder)

local sources=AshenDB.ItemSources
sources[90053]=sources[90053] or {
  {"vendor",1287,"Marda Weller","Stormwind City",-1},
  {"vendor",3314,"Urtharo","Orgrimmar",-1},
  {"vendor",3534,"Wallace the Blind","Silverpine Forest",-1},
}
sources[93223]=sources[93223] or {{"craft",65210,"Simple Bronze Katana","Blacksmithing",155,155,0,{
  {2841,"Bronze Bar",11},{3466,"Strong Flux",2},{3478,"Coarse Grinding Stone",2},{2319,"Medium Leather",1},
}}}

local details=AshenDB.ItemDetails
details[58247]=details[58247] or {"Binds when picked up",0,0,"",0,0,0,0,{{0,"Dispels all types of crowd control effects.",52317}}}
details[83605]=details[83605] or {"Binds when picked up",45,0,"",0,0,0,0,{
  {1,"Increases spell damage and healing by up to 15.",9344},
  {1,"Reduces damage taken from critical hits by 1%.",59505},
}}
details[83608]=details[83608] or {"Binds when picked up",45,0,"",0,0,0,0,{
  {1,"Increases spell damage and healing by up to 13.",9342},
  {1,"Reduces damage taken from damage over time effects by 2%.",59511},
}}
details[90051]=details[90051] or {"",0,7,"",0,0,0,0}
details[90053]=details[90053] or {"",50,404,"",0,0,0,0}
details[90060]=details[90060] or {"Binds when picked up",0,0,"",0,0,0,0,{{0,"Summons the members of your fellowship. (24-hour cooldown)",65312}}}
details[90061]=details[90061] or {"Binds when picked up",0,0,"",0,0,0,0,{{0,"Summons the members of your fellowship. (1-hour cooldown)",65312}}}
details[93223]=details[93223] or {"",65,1945,"",0,0,0,0}
