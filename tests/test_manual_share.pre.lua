-- Observe all transports from startup, including a previous opt-in to sync.
AshenBuildsDB={settings={syncChannel=true}}
TRANSPORT_CALLS={}
function SendChatMessage() table.insert(TRANSPORT_CALLS,"SendChatMessage") end
function SendAddonMessage() table.insert(TRANSPORT_CALLS,"SendAddonMessage") end
function JoinChannelByName() table.insert(TRANSPORT_CALLS,"JoinChannelByName") end
function LeaveChannelByName() table.insert(TRANSPORT_CALLS,"LeaveChannelByName") end
function IsInGuild() return true end
function GetNumRaidMembers() return 10 end
CLOCK=1000
function GetTime() return CLOCK end
