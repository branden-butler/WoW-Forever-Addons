-- Curated factual recipe acquisition references from WoW Forever guides.
-- Keys are normalized crafted spell names, NOT item IDs. Never guess spell IDs.
-- Only documented acquisition details are filled; missing values remain unknown.
PBFRecipeSources = PBFRecipeSources or {}
local guide="https://www.icy-veins.com/wow-forever/cooking-leveling-guide"
local overview="https://www.icy-veins.com/wow-forever/cooking"
local function add(name,skill,kind,details,location,url)
 PBFRecipeSources[string.lower(name)]={requiredSkill=skill,source=kind,details=details,location=location,reference=url}
end
add("Roasted Boar Meat",1,"Starter / Trainer","Starting Cooking recipe","Cooking profession",guide)
add("Charred Wolf Meat",1,"Starter / Trainer","Starting Cooking recipe","Cooking profession",guide)
add("Coyote Steak",50,"Trainer","Cooking trainer (Journeyman)","Multiple eligible trainers",guide)
add("Boiled Clams",50,"Trainer","Cooking trainer (Journeyman)","Multiple eligible trainers",guide)
add("Dry Pork Ribs",80,"Trainer","Cooking trainer","Multiple eligible trainers",guide)
add("Curiously Tasty Omelet",130,"Vendor","Keena (Horde); Kendor Kabonka (Alliance)","Hammerfall, Arathi Highlands (Horde); Old Town, Stormwind (Alliance)",guide)
add("Roast Raptor",175,"Vendor","Keena (Horde); Hammon Karwn (Alliance)","Hammerfall, Arathi Highlands (Horde); Refuge Pointe, Arathi Highlands (Alliance)",guide)
add("Tender Wolf Steak",225,"Vendor","Dirge Quikcleave","Gadgetzan inn, Tanaris",guide)
add("Monster Omelet",225,"Vendor","Himmik","Everlook, Winterspring",guide)
add("Goldthorn Tea",175,"Trainer","Henry Stern","Razorfen Downs",overview)
add("Filet of Redgill",225,"Vendor","Kelsey Yance","Booty Bay, Stranglethorn Vale",overview)
add("Savory Deviate Delight",85,"World Drop","World drop","The Barrens",overview)
add("Savory Whimsyfin Delight",85,"World Drop","World drop","Redridge Mountains",overview)
add("Grilled Squid",240,"Vendor","Gikkix","Tanaris",overview)
add("Hot Smoked Bass",240,"Vendor","Kelsey Yance","Booty Bay, Stranglethorn Vale",overview)
add("Poached Sunscale Salmon",250,"Vendor","Gikkix","Tanaris",overview)
add("Mightfish Steak",275,"Vendor","Vivianna (Alliance); Sheendra Tallgrass (Horde)","Feralas",overview)
add("Baked Salmon",275,"Vendor","Vivianna (Alliance); Sheendra Tallgrass (Horde)","Feralas",overview)
add("Lobster Stew",275,"Vendor","Vivianna (Alliance); Sheendra Tallgrass (Horde)","Feralas",overview)
add("Wicked Smoothie",250,"Reputation Vendor","Kalsey Sanden (Alliance); Aza'bek (Horde); Honored reputation required","Redridge Mountains (Alliance); The Barrens (Horde)",overview)
add("Dragonbreath Chili",200,"Vendor","Helenia Olden (Alliance); Ogg'marr (Horde); Super-Seller 680","Dustwallow Marsh; Desolace",overview)
add("Thistle Tea",60,"Quest","Rogue quest reward; Smudge Thunderwood may also offer recipe","Alliance: Klaven's Tower; Horde: Mission: Possible But Not Probable",overview)
add("Dirge's Kickin' Chimaerok Chops",300,"Quest","Scepter of the Shifting Sands quest chain","Quest chain",overview)
add("Smoked Desert Dumplings",285,"Quest","Sharing the Knowledge","Quest reward",overview)

-- Additional Forever-specific Cooking overview facts; leave undocumented details blank.
add("Bear Bruscitti",275,"Recipe item","Recipe: Bear Bruscitti (seller not documented)","Not documented",overview)
add("Steaming Stag Steak",275,"Recipe item","Recipe: Steaming Stag Steak (seller not documented)","Not documented",overview)
add("Swiftstrike Steak",275,"Recipe item","Recipe: Swiftstrike Steak; Merchant's Favor cost documented","Not documented",overview)
add("Sage's Tea",250,"Recipe item","Recipe: Sage's Tea (seller not documented)","Not documented",overview)
add("Plated Armorfish",225,"Recipe item","Recipe: Plated Armorfish (seller not documented)","Not documented",overview)
add("Sweetpaw Jam",275,"Recipe item","Recipe: Sweetpaw Jam (seller not documented)","Not documented",overview)
