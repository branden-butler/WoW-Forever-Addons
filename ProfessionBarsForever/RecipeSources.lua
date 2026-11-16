-- Curated factual recipe acquisition references from WoW Forever guides.
-- Primary keys are spell IDs matched uniquely against CatalogData.lua (Forever build 70862).
-- Keep normalized-name aliases for compatibility. ID matching does not verify acquisition claims.
-- Only documented acquisition details are filled; missing values remain unknown.
PBFRecipeSources = PBFRecipeSources or {}
local guide="https://www.icy-veins.com/wow-forever/cooking-leveling-guide"
local overview="https://www.icy-veins.com/wow-forever/cooking"
local function add(spellID,name,skill,kind,details,location,url)
 local metadata={requiredSkill=skill,source=kind,details=details,location=location,reference=url}
 PBFRecipeSources[spellID]=metadata
 PBFRecipeSources[string.lower(name)]=metadata
end
add(2540,"Roasted Boar Meat",1,"Starter / Trainer","Starting Cooking recipe","Cooking profession",guide)
add(2538,"Charred Wolf Meat",1,"Starter / Trainer","Starting Cooking recipe","Cooking profession",guide)
add(2541,"Coyote Steak",50,"Trainer","Cooking trainer (Journeyman)","Multiple eligible trainers",guide)
add(6499,"Boiled Clams",50,"Trainer","Cooking trainer (Journeyman)","Multiple eligible trainers",guide)
add(2546,"Dry Pork Ribs",80,"Trainer","Cooking trainer","Multiple eligible trainers",guide)
add(3376,"Curiously Tasty Omelet",130,"Vendor","Keena (Horde); Kendor Kabonka (Alliance)","Hammerfall, Arathi Highlands (Horde); Old Town, Stormwind (Alliance)",guide)
add(15855,"Roast Raptor",175,"Vendor","Keena (Horde); Hammon Karwn (Alliance)","Hammerfall, Arathi Highlands (Horde); Refuge Pointe, Arathi Highlands (Alliance)",guide)
add(22480,"Tender Wolf Steak",225,"Vendor","Dirge Quikcleave","Gadgetzan inn, Tanaris",guide)
add(15933,"Monster Omelet",225,"Vendor","Himmik","Everlook, Winterspring",guide)
add(13028,"Goldthorn Tea",175,"Trainer","Henry Stern","Razorfen Downs",overview)
add(18241,"Filet of Redgill",225,"Vendor","Kelsey Yance","Booty Bay, Stranglethorn Vale",overview)
add(8238,"Savory Deviate Delight",85,"World Drop","World drop","The Barrens",overview)
add(1252566,"Savory Whimsyfin Delight",85,"World Drop","World drop","Redridge Mountains",overview)
add(18240,"Grilled Squid",240,"Vendor","Gikkix","Tanaris",overview)
add(18242,"Hot Smoked Bass",240,"Vendor","Kelsey Yance","Booty Bay, Stranglethorn Vale",overview)
add(18244,"Poached Sunscale Salmon",250,"Vendor","Gikkix","Tanaris",overview)
add(18246,"Mightfish Steak",275,"Vendor","Vivianna (Alliance); Sheendra Tallgrass (Horde)","Feralas",overview)
add(18247,"Baked Salmon",275,"Vendor","Vivianna (Alliance); Sheendra Tallgrass (Horde)","Feralas",overview)
add(18245,"Lobster Stew",275,"Vendor","Vivianna (Alliance); Sheendra Tallgrass (Horde)","Feralas",overview)
add(1249968,"Wicked Smoothie",250,"Reputation Vendor","Kalsey Sanden (Alliance); Aza'bek (Horde); Honored reputation required","Redridge Mountains (Alliance); The Barrens (Horde)",overview)
add(15906,"Dragonbreath Chili",200,"Vendor","Helenia Olden (Alliance); Ogg'marr (Horde); Super-Seller 680","Dustwallow Marsh; Desolace",overview)
add(9513,"Thistle Tea",60,"Quest","Rogue quest reward; Smudge Thunderwood may also offer recipe","Alliance: Klaven's Tower; Horde: Mission: Possible But Not Probable",overview)
add(25659,"Dirge's Kickin' Chimaerok Chops",300,"Quest","Scepter of the Shifting Sands quest chain","Quest chain",overview)
add(24801,"Smoked Desert Dumplings",285,"Quest","Sharing the Knowledge","Quest reward",overview)

-- Additional Forever-specific Cooking overview facts; leave undocumented details blank.
add(1250147,"Bear Bruscitti",275,"Recipe item","Recipe: Bear Bruscitti (seller not documented)","Not documented",overview)
add(1250148,"Steaming Stag Steak",275,"Recipe item","Recipe: Steaming Stag Steak (seller not documented)","Not documented",overview)
add(1250149,"Swiftstrike Steak",275,"Recipe item","Recipe: Swiftstrike Steak; Merchant's Favor cost documented","Not documented",overview)
add(1249962,"Sage's Tea",250,"Recipe item","Recipe: Sage's Tea (seller not documented)","Not documented",overview)
add(1319313,"Plated Armorfish",225,"Recipe item","Recipe: Plated Armorfish (seller not documented)","Not documented",overview)
add(1294014,"Sweetpaw Jam",275,"Recipe item","Recipe: Sweetpaw Jam (seller not documented)","Not documented",overview)
