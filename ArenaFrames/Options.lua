local _, addon = ...;

function SweepyBoop:TestArena()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    if GladiusEx then
        local frame = _G["GladiusExButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            GladiusEx:SetTesting(3);
        end
    elseif Gladius then
        local frame = _G["GladiusButtonFramearena1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            if SlashCmdList["GLADIUS"] then
                SlashCmdList["GLADIUS"]("test 3")
            end
        end
    elseif sArena then
        local frame = _G["sArenaEnemyFrame1"];
        if ( not frame ) or ( not frame:IsShown() ) then
            sArena:Test();
        end
    else
        -- Use Blizzard arena frames
        if ( not CompactArenaFrame:IsShown() ) then
            CompactArenaFrame:Show();
            for i = 1, addon.MAX_ARENA_SIZE do
                _G["CompactArenaFrameMember" .. i]:Show();
            end
        end
    end

    self:TestArenaCooldownTracker();
end

function SweepyBoop:TestArenaStandalone()
    if IsInInstance() then
        addon.PRINT("Test mode can only be used outside instances");
        return;
    end

    self:TestArenaStandaloneBars();
end

addon.SetupAllSpells = function (profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        -- By default only check burst and defensives
        if spellEntry.default then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

addon.UncheckAllSpells = function (profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        profile[tostring(spellID)] = false;
    end
end

addon.SetupInterrupts = function (profile, spellList)
    for spellID, spellEntry in pairs(spellList) do
        local category = spellEntry.category;
        -- By default only check interrupts
        if ( category == addon.SPELLCATEGORY.INTERRUPT ) or ( spellID == 78675 ) then
            profile[tostring(spellID)] = true;
        else
            profile[tostring(spellID)] = false;
        end
    end
end

addon.GetArenaFrameOptions = function(order)
    addon.importDialogs = addon.importDialogs or {};
    addon.importDialogs["arenaFrames"] = addon.CreateImportDialog("arenaFrames");
    addon.exportDialog = addon.exportDialog or addon.CreateExportDialog(); -- One shared dialog for exporting

    local optionGroup = {
        order = order,
        type = "group",
        childGroups = "tab",
        name = "Arena cooldowns",
        handler = SweepyBoop, -- for running SweepyBoop:TestArena()
        get = function(info) return SweepyBoop.db.profile.arenaFrames[info[#info]] end,
        set = function(info, val)
            SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
            SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
        end,
        args = {
            import = {
                order = 1,
                type = "execute",
                width = 0.75,
                name = "Import",
                desc = "Import a profile from an export string",
                func = function()
                    SweepyBoop:ShowImport("arenaFrames");
                end,
            },

            export = {
                order = 2,
                type = "execute",
                width = 0.75,
                name = "Export",
                desc = "Export your profile to a string",
                func = function()
                    SweepyBoop:ShowExport();
                end,
            },

            arenaFrameBars = {
                order = 3,
                type = "group",
                childGroups = "tab",
                name = "Arena frames",
                args = {
                    testmode = {
                        order = 1,
                        type = "execute",
                        name = "Test",
                        func = "TestArena",
                        width = "half",
                    },
                    hidetest = {
                        order = 2,
                        type = "execute",
                        name = "Hide",
                        func = "HideTestArenaCooldownTracker",
                        width = "half",
                    },

                    tooltipTestIcons = {
                        order = 3,
                        type = "description",
                        fontSize = "medium",
                        width = "full",
                        name = addon.EXCLAMATION .. " Test icons showing arena 1 only, arena 2 & 3 will be automatically set up",
                    },

                    general = {
                        order = 5,
                        type = "group",
                        childGroups = "tab",
                        name = "Settings",
                        args = {
                            arenaCooldownTrackerEnabled = {
                                order = 6,
                                width = 1,
                                type = "toggle",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Spell_holy_powerinfusion")) .. " Enabled",
                            },
                            arenaCooldownSecondaryBar = {
                                order = 7,
                                width = 1.5,
                                type = "toggle",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("Spell_holy_painsupression")) .. " Enable secondary bar",
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownTrackerEnabled );
                                end
                            },

                            breaker1 = {
                                order = 8,
                                type = "description",
                                name = "",
                            },

                            hideCountDownNumbers = {
                                order = 9,
                                type = "toggle",
                                width = "full",
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("ability_racial_timeismoney")) .. " Hide countdown numbers",
                                desc = "Hide countdown numbers but show a more visible swiping edge",
                            },

                            hideBorder = {
                                order = 10,
                                type = "toggle",
                                width = "full",
                                name = addon.FORMAT_ATLAS("UI-HUD-ActionBar-IconFrame") .. " Hide border",
                            },

                            showUnusedIcons = {
                                order = 11,
                                type = "toggle",
                                width = 1,
                                name = addon.FORMAT_TEXTURE(addon.ICON_PATH("spell_deathknight_iceboundfortitude")) .. " Always show icons",
                                desc = "Show icons for abilities that are not on cooldown\nAbilities that are not baseline will only show after they are detected",
                            },

                            unusedIconAlpha = {
                                order = 12,
                                type = "range",
                                width = 0.8,
                                isPercent = true,
                                min = 0.5,
                                max = 1,
                                step = 0.1,
                                name = "Off-cooldown alpha",
                                hidden = function ()
                                    return ( not SweepyBoop.db.profile.arenaFrames.showUnusedIcons );
                                end
                            },

                            usedIconAlpha = {
                                order = 13,
                                type = "range",
                                width = 0.8,
                                isPercent = true,
                                min = 0.5,
                                max = 1,
                                step = 0.1,
                                name = "On-cooldown alpha",
                                hidden = function ()
                                    return ( not SweepyBoop.db.profile.arenaFrames.showUnusedIcons );
                                end
                            },

                            breaker2 = {
                                order = 14,
                                type = "description",
                                name = "",
                            },

                            arenaCooldownTrackerIconSize = {
                                order = 15,
                                type = "range",
                                width = 0.75,
                                min = 16,
                                max = 64,
                                step = 1,
                                name = "Icon size",
                                desc = "Size of arena defensive cooldown icons",
                            },

                            arenaCooldownTrackerIconSizeSecondary = {
                                order = 16,
                                type = "range",
                                width = 1,
                                min = 16,
                                max = 64,
                                step = 1,
                                name = "Icon size (secondary bar)",
                                desc = "Size of arena defensive cooldown icons",
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },

                            arenaCooldownTrackerIconPadding = {
                                order = 17,
                                type = "range",
                                width = 0.75,
                                min = 0,
                                max = 10,
                                step = 1,
                                name = "Padding",
                                desc = "Space between icons",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker(true);
                                end
                            },

                            breaker3 = {
                                order = 18,
                                type = "description",
                                name = "",
                            },

                            headerPosition = {
                                order = 19,
                                type = "header",
                                name = "Positioning",
                            },

                            arenaCooldownGrowDirection = {
                                order = 20,
                                type = "select",
                                width = 0.75,
                                name = "Grow direction",
                                values = {
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT] = "Right",
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT] = "Left",
                                },
                            },

                            arenaCooldownOffsetX = {
                                order = 21,
                                type = "range",
                                min = -300,
                                max = 300,
                                step = 1,
                                name = "X offset",
                                desc = "Horizontal offset of the arena cooldown icon group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end
                            },
                            arenaCooldownOffsetY = {
                                order = 22,
                                type = "range",
                                width = 0.8,
                                min = -150,
                                max = 150,
                                step = 1,
                                name = "Y offset",
                                desc = "Vertical offset of the arena cooldown icon group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end
                            },

                            headerPosition2 = {
                                order = 23,
                                type = "header",
                                name = "Secondary bar positioning",
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },

                            arenaCooldownGrowDirectionSecondary = {
                                order = 24,
                                type = "select",
                                width = 0.75,
                                name = "Grow direction",
                                values = {
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT] = "Right",
                                    --[addon.ARENA_COOLDOWN_GROW_DIRECTION.RIGHT_UP] = "Right up",
                                    [addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT] = "Left",
                                    --[addon.ARENA_COOLDOWN_GROW_DIRECTION.LEFT_UP] = "Left up",
                                },
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },

                            arenaCooldownOffsetXSecondary = {
                                order = 25,
                                type = "range",
                                min = -300,
                                max = 300,
                                step = 1,
                                name = "X offset",
                                desc = "Horizontal offset of the arena cooldown defensive group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end,
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },
                            arenaCooldownOffsetYSecondary = {
                                order = 26,
                                type = "range",
                                width = 0.8,
                                min = -150,
                                max = 150,
                                step = 1,
                                name = "Y offset",
                                desc = "Vertical offset of the arena cooldown defensive group relative to the right edge of the arena frame",
                                set = function (info, val)
                                    SweepyBoop.db.profile.arenaFrames[info[#info]] = val;
                                    SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                    SweepyBoop:RepositionArenaCooldownTracker();
                                end,
                                hidden = function()
                                    return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                                end
                            },
                        },
                    },

                    spellCatPriority = {
                        order = 6,
                        type = "group",
                        name = "Priority",
                        args = {}, -- Fill this programatically later
                    },

                    spellList = {
                        order = 7,
                        type = "group",
                        name = "Spells",
                        desc = "Select which abilities to track cooldown inside arenas",
                        get = function(info) return SweepyBoop.db.profile.arenaFrames.spellList[info[#info]] end,
                        set = function(info, val) SweepyBoop.db.profile.arenaFrames.spellList[info[#info]] = val end,
                        args = {
                            restoreDefaults = {
                                order = 1,
                                type = "execute",
                                name = "Restore default",
                                func = function ()
                                    addon.SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.SpellData);
                                end
                            },

                            uncheckAll = {
                                order = 2,
                                type = "execute",
                                name = "Uncheck all",
                                func = function ()
                                    addon.UncheckAllSpells(SweepyBoop.db.profile.arenaFrames.spellList, addon.SpellData);
                                end
                            },
                        },
                    },

                    spellList2 = {
                        order = 8,
                        type = "group",
                        name = "Secondary bar spells",
                        desc = "Select which abilities to track cooldown inside arenas",
                        get = function(info) return SweepyBoop.db.profile.arenaFrames.spellList2[info[#info]] end,
                        set = function(info, val) SweepyBoop.db.profile.arenaFrames.spellList2[info[#info]] = val end,
                        args = {
                            restoreDefaults = {
                                order = 1,
                                type = "execute",
                                name = "Restore default",
                                func = function ()
                                    addon.SetupAllSpells(SweepyBoop.db.profile.arenaFrames.spellList2, addon.SpellData);
                                end
                            },

                            unsetAll = {
                                order = 2,
                                type = "execute",
                                name = "Uncheck all",
                                func = function ()
                                    addon.UncheckAllSpells(SweepyBoop.db.profile.arenaFrames.spellList2, addon.SpellData);
                                end
                            },
                        },
                        hidden = function()
                            return ( not SweepyBoop.db.profile.arenaFrames.arenaCooldownSecondaryBar );
                        end
                    }
                },
            },

            standaloneBars = {
                order = 4,
                type = "group",
                childGroups = "tab",
                name = "Standalone bars",
                args = {
                    testmode = {
                        order = 1,
                        type = "execute",
                        name = "Test all",
                        func = "TestArenaStandalone",
                        width = "half",
                    },
                    hidetest = {
                        order = 2,
                        type = "execute",
                        name = "Hide all",
                        func = "HideTestArenaStandaloneBars",
                        width = "half",
                    },
                },
            },

            -- TODO: Tab for shared top player profiles for quicker import
        },
    };

    -- Append options for standalone bars
    for i = 1, 6 do
        local groupName = "Bar " .. i;
        optionGroup.args.standaloneBars.args[groupName] = {
            order = i,
            type = "group",
            childGroups = "tab",
            name = function(info)
                return SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].name;
            end,
            get = function(info)
                return SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName][info[#info]];
            end,
            set = function(info, val)
                SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName][info[#info]] = val;
                SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
            end,
            args = {
                general = {
                    order = 1,
                    type = "group",
                    name = "Settings",
                    args = {
                        name = {
                            order = 1,
                            type = "input",
                            name = "Name",
                        },

                        enabled = {
                            order = 2,
                            type = "toggle",
                            name = "Enabled",
                        },

                        iconSize = {
                            order = 3,
                            type = "range",
                            min = 16,
                            max = 64,
                            step = 1,
                            name = "Icon size",
                        },

                        iconPadding = {
                            order = 4,
                            type = "range",
                            min = 0,
                            max = 10,
                            step = 1,
                            name = "Padding",
                            set = function(info, val)
                                SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName][info[#info]] = val;
                                SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                SweepyBoop:RepositionArenaStandaloneBar(groupName, true);
                            end
                        },

                        breaker1 = {
                            order = 5,
                            type = "description",
                            name = "",
                        },

                        growDirection = {
                            order = 6,
                            type = "select",
                            width = 0.75,
                            name = "Grow direction",
                            values = {
                                [addon.STANDALONE_GROW_DIRECTION.CENTER] = "Center",
                                [addon.STANDALONE_GROW_DIRECTION.LEFT] = "Left",
                                [addon.STANDALONE_GROW_DIRECTION.RIGHT] = "Right",
                            },
                        },

                        columns = {
                            order = 7,
                            type = "range",
                            width = 0.75,
                            min = 1,
                            max = 16,
                            step = 1,
                            name = "Columns",
                        },

                        growUpward = {
                            order = 8,
                            type = "toggle",
                            name = "Grow upward",
                        },

                        breaker2 = {
                            order = 9,
                            type = "description",
                            name = "",
                        },

                        offsetX = {
                            order = 10,
                            type = "range",
                            min = -2500,
                            max = 2500,
                            step = 1,
                            name = "X offset",
                            set = function(info, val)
                                SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName][info[#info]] = val;
                                SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                SweepyBoop:RepositionArenaStandaloneBar(groupName);
                            end
                        },

                        offsetY = {
                            order = 11,
                            type = "range",
                            min = -1500,
                            max = 1500,
                            step = 1,
                            name = "Y offset",
                            set = function(info, val)
                                SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName][info[#info]] = val;
                                SweepyBoop.db.profile.arenaFrames.lastModified = GetTime();
                                SweepyBoop:RepositionArenaStandaloneBar(groupName);
                            end
                        },

                        breaker3 = {
                            order = 12,
                            type = "description",
                            name = "",
                        },

                        hideBorder = {
                            order = 13,
                            type = "toggle",
                            name = "Hide border",
                        },

                        showTargetHighlight = {
                            order = 14,
                            type = "toggle",
                            name = "Highlight target",
                        },

                        breaker4 = {
                            order = 15,
                            type = "description",
                            name = "",
                        },

                        showUnusedIcons = {
                            order = 16,
                            type = "toggle",
                            name = "Always show icons",
                            width = 0.9,
                            desc = "Show icons for abilities that are not on cooldown\nAbilities that are not baseline will only show after they are detected",
                        },

                        unusedIconAlpha = {
                            order = 17,
                            type = "range",
                            width = 0.8,
                            isPercent = true,
                            min = 0.5,
                            max = 1,
                            step = 0.1,
                            name = "Off-cooldown alpha",
                            hidden = function()
                                return ( not SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].showUnusedIcons );
                            end
                        },

                        usedIconAlpha = {
                            order = 18,
                            type = "range",
                            width = 0.8,
                            isPercent = true,
                            min = 0.5,
                            max = 1,
                            step = 0.1,
                            name = "On-cooldown alpha",
                            hidden = function()
                                return ( not SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].showUnusedIcons );
                            end
                        },
                    },
                },

                spellList = {
                    order = 2,
                    type = "group",
                    name = "Spells",
                    get = function(info) return SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].spellList[info[#info]] end,
                    set = function(info, val) SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].spellList[info[#info]] = val end,
                    args = {
                        restoreDefaults = {
                            order = 1,
                            type = "execute",
                            name = "Restore default",
                            func = function ()
                                addon.SetupInterrupts(SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].spellList, addon.SpellData);
                            end
                        },

                        uncheckAll = {
                            order = 2,
                            type = "execute",
                            name = "Uncheck all",
                            func = function ()
                                addon.UncheckAllSpells(SweepyBoop.db.profile.arenaFrames.standaloneBars[groupName].spellList, addon.SpellData);
                            end
                        },
                    },
                },
            },
        };
    end

    local indexInClassGroup = {};
    local groupIndex = 3;
    -- Ensure one group for each class, in order
    for _, classID in ipairs(addon.CLASSORDER) do
        local classInfo = C_CreatureInfo.GetClassInfo(classID);
        optionGroup.args.arenaFrameBars.args.spellList.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };
        optionGroup.args.arenaFrameBars.args.spellList2.args[classInfo.classFile] = {
            order = groupIndex,
            type = "group",
            icon = addon.ICON_ID_CLASSES,
            iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
            name = classInfo.className,
            args = {},
        };
        for i = 1, 6 do
            local groupName = "Bar " .. i;
            optionGroup.args.standaloneBars.args[groupName].args.spellList.args[classInfo.classFile] = {
                order = groupIndex,
                type = "group",
                icon = addon.ICON_ID_CLASSES,
                iconCoords = CLASS_ICON_TCOORDS[classInfo.classFile],
                name = classInfo.className,
                args = {},
            };
        end

        indexInClassGroup[classInfo.classFile] = 1;
        groupIndex = groupIndex + 1;
    end
    local function AppendSpellOptions(group, spellList)
        for spellID, spellInfo in pairs(spellList) do
            if ( not spellInfo.parent ) then
                local classFile = spellInfo.class;
                local classGroup = group.args[classFile];
                local icon, name = C_Spell.GetSpellTexture(spellID), C_Spell.GetSpellName(spellID);
                -- https://warcraft.wiki.gg/wiki/SpellMixin
                local spell = Spell:CreateFromSpellID(spellID);
                spell:ContinueOnSpellLoad(function()
                    addon.SPELL_DESCRIPTION[spellID] = spell:GetSpellDescription();
                end)
                classGroup.args[tostring(spellID)] = {
                    order = indexInClassGroup[classFile],
                    type = "toggle",
                    width = "full", -- otherwise the icon might look strange vertically
                    name = addon.FORMAT_TEXTURE(icon) .. " " .. name,
                    desc = function ()
                        return addon.SPELL_DESCRIPTION[spellID] or "";
                    end
                };

                indexInClassGroup[classFile] = indexInClassGroup[classFile] + 1;
            end
        end
    end

    local function AppendSpellCategoryPriority(group)
        for i = 1, 12 do -- Can we not hard-code this
            group[tostring(i)] = {
                order = i,
                type = "range",
                name = addon.SPELLCATEGORY_NAME[i],
                min = 1,
                max = 100,
                step = 1,
                get = function(info)
                    return SweepyBoop.db.profile.arenaFrames.spellCatPriority[tostring(i)];
                end,
                set = function(info, val)
                    SweepyBoop.db.profile.arenaFrames.spellCatPriority[tostring(i)] = val;
                end,
            }
        end
    end

    AppendSpellOptions(optionGroup.args.arenaFrameBars.args.spellList, addon.SpellData);
    AppendSpellOptions(optionGroup.args.arenaFrameBars.args.spellList2, addon.SpellData);
    AppendSpellCategoryPriority(optionGroup.args.arenaFrameBars.args.spellCatPriority.args);

    for i = 1, 6 do
        local groupName = "Bar " .. i;
        AppendSpellOptions(optionGroup.args.standaloneBars.args[groupName].args.spellList, addon.SpellData);
    end

    return optionGroup;
end
