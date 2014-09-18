--[[ 
    @Package       PercentageHits
    @Description   
    @Author        Robert "Fluxflashor" Veitch <Robert@Fluxflashor.net>
    @Repo          http://github.com/Fluxflashor/PercentageHits
    @File          Core.lua 
    ]]

local PERCENTAGEHITS, PercentageHits = ...
local EventFrame = CreateFrame("FRAME", "PercentageHits_EventFrame");
local PHScrollingTextFrame = CreateFrame("FRAME", "PercentageHits_ScrollingTextFrame");

local NUM_SCROLLING_LINES = 10;
local TEXT_SCROLL_SPEED = 1.6;
local TEXT_FADE_TIME = 1.3;
local TEXT_HEIGHT = 25;

--PHScrollingTextFrame:SetMaxLines(NUM_SCROLLING_LINES);
--PHScrollingTextFrame:SetInsertMode("BOTTOM");
PHScrollingTextFrame:SetPoint("CENTER", 50, 0);

--local WIUToolTip = CreateFrame("GameTooltip", "WIUTooltip", nil, "GameTooltipTemplate")
--WIUToolTip:SetOwner(WorldFrame, "ANCHOR_NONE");

local about = LibStub("tekKonfig-AboutPanel").new(nil, "PercentageHits");

PercentageHits.AddonName = PERCENTAGEHITS;
PercentageHits.Author = GetAddOnMetadata(PERCENTAGEHITS, "Author");
PercentageHits.Version = GetAddOnMetadata(PERCENTAGEHITS, "Version");

PercentageHits.TestMode = false;
PercentageHits.TooltipAppended = false;

local spellcache = setmetatable({}, {__index=function(t,v) local a = {GetSpellInfo(v)} if GetSpellInfo(v) then t[v] = a end return a end})
local function GetSpellInfo(a)
    return unpack(spellcache[a])
end

function split(str, pat)
    local t = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat = "(.-)" .. pat
    local last_end = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

function Set (list)
   local set = {}
   for _, l in ipairs(list) do set[l] = true end
   return set
end

function round(what, precision)
   return math.floor(what*math.pow(10,precision)+0.5) / math.pow(10,precision)
end

function PercentageHits:MessageUser(message)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cfffa8000PercentageHits|r: %s", message));
end

function PercentageHits:RegisterEvents()
    EventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
end

function PercentageHits:Initialize()
    EventFrame:RegisterEvent("ADDON_LOADED");
    EventFrame:SetScript("OnEvent", function(self, event, ...) PercentageHits:EventHandler(self, event, ...) end)
end

function PercentageHits_CombatText_AddMessage(message)
    CombatText_AddMessage(message, CombatText_StandardScroll, 1, 1, 0, 0, true);
end

function PercentageHits_AddSpellScrollingMessage(spell_icon_string, damage_percent, dest_name)
    
end

function PercentageHits:OnCombatLogEvent(self, event, ...)

    local timestamp, combat_event, hide_caster, source_guid, source_name, source_flags, source_raid_flags, dest_guid, dest_name, dest_flags, dest_raid_flags = ...;

    if (CombatLog_Object_IsA(source_flags, COMBATLOG_FILTER_MINE))  then
        if (combat_event == "SPELL_DAMAGE") then
            local spell_id, spellname, _, amount = select(12, ...);

            local my_target_guid = UnitGUID("target");
            local arena1_guid, arena2_guid, arena3_guid, arena4_guid, arena5_guid = UnitGUID("arena1"), UnitGUID("arena2"), UnitGUID("arena3"), UnitGUID("arena4"), UnitGUID("arena5")

            if (my_target_guid == dest_guid) then
                local my_target_max_health = UnitHealthMax("target");
                local damage_percent = round(amount / my_target_max_health * 100, 2);

                spell_icon = select(3, GetSpellInfo(spell_id))
                spell_icon_string = string.format("|T%s:16|t", spell_icon)

                PercentageHits_CombatText_AddMessage(string.format("%s for %s%% on %s", spell_icon_string, damage_percent, dest_name));
                PercentageHits_AddSpellScrollingMessage(spell_icon_string, damage_percent, dest_name);

            end
        end
    end
end

function PercentageHits:EventHandler(self, event, ...)
    if (event == "ADDON_LOADED") then
        local LoadedAddonName = ...;
        if (PercentageHits.TestMode) then
            PercentageHits:MessageUser(string.format("LoadedAddonName is %s", LoadedAddonName));
        end
        if (LoadedAddonName == AddonName) then
            if (PercentageHits.Version == "@project-version@") then
                PercentageHits.Version = "Github Master";
            end
            if (PercentageHits.Author == "@project-author@") then
                PercentageHits.Author = "Fluxflashor (Github)";
            end
            PercentageHits:MessageUser(string.format("Loaded Version is %s. Author is %s.", PercentageHits.Version, PercentageHits.Author));
            if (PercentageHits.TestMode) then
                PercentageHits:MessageUser(string.format("%s is %s.", LoadedAddonName, AddonName));
            end
            if (PercentageHits.AddOnDisabled) then
                if (PercentageHits.TestMode) then
                    PercentageHits:MessageUser("Unregistering Events.");
                end
                if (not PercentageHits.SuppressWarnings) then
                    PercentageHits:WarnUser("PercentageHits is disabled.");
                end
                PercentageHits:Enable(false);
            end
        end
        PercentageHits:RegisterEvents();
    elseif (event == "COMBAT_LOG_EVENT_UNFILTERED") then
        PercentageHits:OnCombatLogEvent(self, event, ...)
        --PercentageHits:MessageUser("CBTTEXTUPDATED");
    end
end

PercentageHits:Initialize()