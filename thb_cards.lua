local extension = Package:new("thb_cards", Package.CardPack)
extension.extensionName = "th_jie"
local LoR_Utility = require "packages/th_jie/LoR_Utility"

Fk:loadTranslationTable {
    ["thb_cards"] = "东方符斗祭卡组"
}
local slash = Fk:cloneCard("slash")
local jink = Fk:cloneCard("jink")
local peach = Fk:cloneCard("peach")

The_jie_path = "./packages/th_jie/"

local thb_weapon_recast = fk.CreateActiveSkill {
    name = "thb_weapon_recast",
    prompt = "#thb_weapon_recast",
    can_use = function(self, player, card, extra_data)
        local room = Fk:currentRoom()
        return player.phase == Player.Play and table.find(room.alive_players, function(p1)
            if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 1) then
                return p1
            end
        end)
    end,
    on_use = function(_, room, effect)
        local player = room:getPlayerById(effect.from)
        player:addCardUseHistory("slash", 1)
        room:recastCard(effect.cards, room:getPlayerById(effect.from))
    end
}


local danmu__slash_skill = fk.CreateActiveSkill {
    name = "danmu__slash_skill",
    prompt = function(self, selected_cards)
        local slash = Fk:cloneCard("slash")
        slash.subcards = Card:getIdList(selected_cards)
        local max_num = self:getMaxTargetNum(Self, slash) -- halberd
        if max_num > 1 then
            local num = #table.filter(Fk:currentRoom().alive_players, function(p)
                return p ~= Self and not Self:isProhibited(p, slash)
            end)
            max_num = math.min(num, max_num)
        end
        slash.subcards = {}
        return max_num > 1 and "#slash_skill_multi:::" .. max_num or "#slash_skill"
    end,
    max_phase_use_time = 1,
    target_num = 1,
    can_use = function(self, player, card, extra_data)
        return (extra_data and extra_data.bypass_times) or player.phase ~= Player.Play or
            table.find(Fk:currentRoom().alive_players, function(p)
                return self:withinTimesLimit(player, Player.HistoryPhase, card, "slash", p)
            end)
    end,
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        local player = Fk:currentRoom():getPlayerById(to_select)
        local from = Fk:currentRoom():getPlayerById(user)
        return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, true, card, player))
    end,
    target_filter = function(self, to_select, selected, _, card, extra_data)
        local count_distances = not (extra_data and extra_data.bypass_distances)
        if #selected < self:getMaxTargetNum(Self, card) then
            local player = Fk:currentRoom():getPlayerById(to_select)
            return self:modTargetFilter(to_select, selected, Self.id, card, count_distances) and
                (
                    #selected > 0 or
                    Self.phase ~= Player.Play or
                    (extra_data and extra_data.bypass_times) or
                    self:withinTimesLimit(Self, Player.HistoryPhase, card, "slash", player)
                )
        end
    end,
    on_effect = function(self, room, effect)
        local from = room:getPlayerById(effect.from)
        local to = room:getPlayerById(effect.to)
        if not to.dead then
            room:damage({
                from = from,
                to = to,
                card = effect.card,
                damage = 1,
                damageType = fk.NormalDamage,
                skillName = self.name
            })
        end
    end
}


local danmu__slash_yuyin = fk.CreateTriggerSkill {
    name = "#danmu__slash_yuyin",
    global = true,
    events = { fk.PreCardUse },
    mute = true,
    priority = 10,
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        local names = { "danmu__slash", "cadan__jink", "yanhui" }
        return target == player and table.contains(names, data.card.name)
    end,

    on_use = function(self, event, target, player, data)
        local room = player.room
        local num
        if data.card.name == "danmu__slash" or data.card.name == "cadan__jink" then
            num = player:usedCardTimes(data.card.name)
            player:addCardUseHistory(data.card.name, 1)
            room:broadcastPlaySound(The_jie_path .. "audio/card/male/" .. data.card.name .. num % 4 + 1)
        else
            room:broadcastPlaySound(The_jie_path .. "audio/card/male/" .. data.card.name .. math.random(3))
        end
    end
}


local danmu__slash = fk.CreateBasicCard {
    name = "danmu__slash",
    is_damage_card = true,
    skill = danmu__slash_skill,
}


local cadan__jink = fk.CreateBasicCard {
    name = "cadan__jink",
    skill = jink.skill,
    is_passive = true,
}


local jiu_skill = fk.CreateActiveSkill {
    name = "jiu_skill",
    prompt = "#jiu_skill",
    mod_target_filter = Util.TrueFunc,
    can_use = function(self, player, card, extra_data)
        return not player:isProhibited(player, card)
    end,
    on_use = function(_, _, use)
        if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
            use.tos = { { use.from } }
        end
    end,
    on_effect = function(_, room, effect)
        local to = room:getPlayerById(effect.to)
        room:setPlayerMark(to, "@@hezui", 1)
    end
}

local jiu_Effect = fk.CreateTriggerSkill {
    name = "jiu_effect",
    global = true,
    priority = 0, -- game rule
    events = { fk.PreCardUse, fk.EventPhaseStart, fk.DamageInflicted },
    can_trigger = function(_, event, target, player, data)
        if target ~= player or player:getMark("@@hezui") == 0 then
            return false
        end
        if event == fk.PreCardUse then
            return data.card.trueName == "slash"
        elseif event == fk.DamageInflicted then
            return data.damage >= player.hp + player.shield
        else
            return player.phase==Player.Start
        end
    end,
    on_trigger = function(_, event, _, player, data)
        local room = player.room
        if event == fk.PreCardUse then
            data.additionalDamage = (data.additionalDamage or 0) + 1
            room:removePlayerMark(player, "@@hezui")
        elseif event == fk.EventPhaseStart then
            room:removePlayerMark(player, "@@hezui")
        else
            data.damage = data.damage - 1
            room:damage {
                from = data.from,
                to = player,
                damage = 1,
                skillName = "jiu",
                isVirtualDMG = true,
            }
            room:removePlayerMark(player, "@@hezui")
        end
    end,
}

local jiu = fk.CreateBasicCard {
    name = "jiu",
    skill = jiu_skill,
}



local exinwan_Effect = fk.CreateTriggerSkill {
    name = "exinwan_effect",
    global = true,
    priority = 0, -- game rule
    events = { fk.AfterCardsMove },
    can_trigger = function(_, event, target, player, data)
        local room = player.room
        local move_event = room.logic:getCurrentEvent()
        local parent_event = move_event.parent
        local card_ids = {}
        if parent_event ~= nil then
            if parent_event.event == GameEvent.Pindian then
                local pindianData = parent_event.data[1]
                if pindianData.from == player then
                    card_ids = room:getSubcardsByRule(pindianData.fromCard)
                else
                    for toId, result in pairs(pindianData.results) do
                        if player.id == toId then
                            card_ids = room:getSubcardsByRule(result.toCard)
                            break
                        end
                    end
                end
            end
        end
        for _, move in ipairs(data) do
            if (move.toArea == Card.Processing or move.toArea == Card.DiscardPile)  then
                if move.from == player.id then
                    for _, info in ipairs(move.moveInfo) do
                        if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                            Fk:getCardById(info.cardId).name == "exinwan" then
                            return true
                        end
                    end
                elseif #card_ids > 0 then
                    for _, info in ipairs(move.moveInfo) do
                        if info.fromArea == Card.Processing and table.contains(card_ids, info.cardId) and
                            Fk:getCardById(info.cardId).name == "exinwan" then
                            return true
                        end
                    end
                end
            end
        end
    end,
    on_trigger = function(_, event, _, player, data)
        local room = player.room
        local to
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/exinwan")
        if room:getPlayerById(data[1].proposer) == nil then
            local targetplayer = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
            if targetplayer == nil then
                to = room:getPlayerById(data.from)
            else
                to = room:getPlayerById(targetplayer.data[1].from)
            end
        else
            to = room:getPlayerById(data[1].proposer)
        end

        if #to:getCardIds("he") > 1 then
            local choose = room:askForChoice(to, { "#exinwan-choose1", "#exinwan-choose2" })
            if choose == "#exinwan-choose1" then
                local targetcard = room:askForCardsChosen(to, to, 2, 2, "he", "exinwan_skill", "#exinwan_skill-choose")
                if #targetcard == 2 then
                    room:throwCard(targetcard, "exinwan_skill", to)
                else
                    room:damage({
                        to = to,
                        damage = 1,
                    })
                end
            else
                room:damage({
                    to = to,
                    damage = 1,
                })
            end
        else
            room:damage({
                to = to,
                damage = 1,
            })
        end
    end,
}

local exinwan = fk.CreateBasicCard {
    name = "exinwan",
}


local mashu__peach = fk.CreateBasicCard {
    name = "mashu__peach",
    skill = peach.skill,
}



local guangxuemicai__eightDiagramSkill = fk.CreateTriggerSkill {
    name = "#guangxuemicai__eight_diagram_skill",
    attached_equip = "guangxuemicai__eight_diagram",
    events = { fk.AskForCardUse, fk.AskForCardResponse },
    can_trigger = function(self, event, target, player, data)
        if not (target == player and player:hasSkill(self) and
                (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")))) then
            return
        end
        if event == fk.AskForCardUse then
            return not player:prohibitUse(Fk:cloneCard("jink"))
        else
            return not player:prohibitResponse(Fk:cloneCard("jink"))
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local judgeData = {
            who = player,
            reason = self.name,
            pattern = ".|.|heart,diamond",
        }
        room:judge(judgeData)

        if judgeData.card.color == Card.Red then
            if event == fk.AskForCardUse then
                data.result = {
                    from = player.id,
                    card = Fk:cloneCard('cadan__jink'),
                }
                data.result.card.skillName = "guangxuemicai__eight_diagram"

                if data.eventData then
                    data.result.toCard = data.eventData.toCard
                    data.result.responseToEvent = data.eventData.responseToEvent
                end
            else
                data.result = Fk:cloneCard('cadan__jink')
                data.result.skillName = "guangxuemicai__eight_diagram"
            end

            return true
        end
    end
}
local guangxuemicai__eight_diagram = fk.CreateArmor {
    name = "guangxuemicai__eight_diagram",
    equip_skill = guangxuemicai__eightDiagramSkill,
}


local tiangoudun__nioh_shield_skill = fk.CreateTriggerSkill {
    name = "#tiangoudun__nioh_shield_skill",
    attached_equip = "tiangoudun__nioh_shield",
    frequency = Skill.Compulsory,
    events = { fk.PreCardEffect },
    can_trigger = function(self, event, target, player, data)
        local effect = data ---@type CardEffectEvent
        return player.id == effect.to and player:hasSkill(self) and
            effect.card.trueName == "slash" and effect.card.color == Card.Black
    end,
    on_use = function(self, event, target, player, data)
        player.room:broadcastPlaySound(The_jie_path .. "audio/card/male/tiangoudun__nioh_shield")
        return true
    end
}


local tiangoudun__nioh_shield = fk.CreateArmor {
    name = "tiangoudun__nioh_shield",
    equip_skill = tiangoudun__nioh_shield_skill,
}

local GreenUFO_skill = fk.CreateDistanceSkill {
    name = "#GreenUFO_skill",
    attached_equip = "GreenUFO",
    correct_func = function(self, from, to)
        if to:hasSkill(self) then
            return 1
        end
    end,
}
Fk:addSkill(GreenUFO_skill)
local GreenUFO = fk.CreateDefensiveRide {
    name = "GreenUFO",
    equip_skill = GreenUFO_skill
}

local RedUFO_skill = fk.CreateDistanceSkill {
    name = "#RedUFO_skill",
    attached_equip = "RedUFO",
    correct_func = function(self, from, to)
        if from:hasSkill(self) then
            return -1
        end
    end,
}
Fk:addSkill(RedUFO_skill)
local RedUFO = fk.CreateOffensiveRide {
    name = "RedUFO",
    equip_skill = RedUFO_skill
}


local louguan_sword__qinggang_sword_skill = fk.CreateTriggerSkill {
    name = "#louguan_sword__qinggang_sword_skill",
    attached_equip = "louguan_sword__qinggang_sword",
    frequency = Skill.Compulsory,
    events = { fk.TargetSpecified },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and
            data.card and data.card.trueName == "slash"
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/louguan_sword__qinggang_sword")
        local to = room:getPlayerById(data.to)
        local use_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
        if use_event == nil then return end
        room:addPlayerMark(to, fk.MarkArmorNullified)
        use_event:addCleaner(function()
            room:removePlayerMark(to, fk.MarkArmorNullified)
        end)
    end,
}


local louguan_sword__qinggang_sword = fk.CreateWeapon {
    name = "louguan_sword__qinggang_sword",
    attack_range = 3,
    equip_skill = louguan_sword__qinggang_sword_skill,
    special_skills = { "thb_weapon_recast" },
}

local bagualu_crossbow_skill = fk.CreateTargetModSkill {
    name = "#bagualu_crossbow_skill",
    attached_equip = "bagualu_crossbow",
    bypass_times = function(self, player, skill, scope, card)
        if player:hasSkill(self) and skill.trueName == "slash_skill" and scope == Player.HistoryPhase then
            --FIXME: 无法检测到非转化的cost选牌的情况，如活墨等
            local cardIds = Card:getIdList(card)
            local crossbows = table.filter(player:getEquipments(Card.SubtypeWeapon), function(id)
                return Fk:getCardById(id).equip_skill == self
            end)
            return #crossbows == 0 or not table.every(crossbows, function(id)
                return table.contains(cardIds, id)
            end)
        end
    end,
}


local bagualu_crossbow = fk.CreateWeapon {
    name = "bagualu_crossbow",
    attack_range = 1,
    equip_skill = bagualu_crossbow_skill,
    special_skills = { "thb_weapon_recast" },
}
local yangsan_skill = fk.CreateTriggerSkill {
    name = "#yangsan_skill",
    attached_equip = "yangsan",
    frequency = Skill.Compulsory,
    events = { fk.DamageInflicted },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and data.card and data.card.type == Card.TypeTrick
    end,
    on_use = function(self, event, target, player, data)
        player.room:broadcastPlaySound(The_jie_path .. "audio/card/male/yangsan")
        return true
    end,
}
local yangsan = fk.CreateArmor {
    name = "yangsan",
    equip_skill = yangsan_skill
}

local ganggenier__spear_skill = fk.CreateViewAsSkill {
    name = "ganggenier__spear_skill",
    prompt = "#ganggenier__spear_skill",
    attached_equip = "ganggenier__spear",
    pattern = "danmu__slash",
    card_filter = function(self, to_select, selected)
        if #selected == 2 then return false end
        return table.contains(Self:getHandlyIds(true), to_select)
    end,
    view_as = function(self, cards)
        if #cards ~= 2 then
            return nil
        end
        local c = Fk:cloneCard("danmu__slash")
        c.skillName = "ganggenier__spear"
        c:addSubcards(cards)
        return c
    end,
}
local ganggenier__spear = fk.CreateWeapon {
    name = "ganggenier__spear",
    attack_range = 3,
    equip_skill = ganggenier__spear_skill,
    special_skills = { "thb_weapon_recast" },
}

local feixiangzhijian__halberd_audio = fk.CreateTriggerSkill {
    name = "#feixiangzhijian__halberd_audio",
    refresh_events = { fk.CardUsing },
    can_refresh = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and
            data.card.trueName == "slash" and #TargetGroup:getRealTargets(data.tos) > 1
    end,
    on_refresh = function(self, event, target, player, data)
        local room = player.room
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/feixiangzhijian__halberd")
    end,
}
local feixiangzhijian__halberd_skill = fk.CreateTargetModSkill {
    name = "#feixiangzhijian__halberd_skill",
    attached_equip = "feixiangzhijian__halberd",
    extra_target_func = function(self, player, skill, card)
        if player:hasSkill(self) and skill.trueName == "slash_skill" then
            local cards = card:isVirtual() and card.subcards or { card.id }
            local handcards = player:getCardIds(Player.Hand)
            if #handcards > 0 and #cards == #handcards and table.every(cards, function(id)
                    return table.contains(
                        handcards, id)
                end) then
                return 2
            end
        end
    end,
}

local feixiangzhijian__halberd = fk.CreateWeapon {
    name = "feixiangzhijian__halberd",
    attack_range = 4,
    equip_skill = feixiangzhijian__halberd_skill,
    special_skills = { "thb_weapon_recast" },
}


local huiwubang_skill = fk.CreateTriggerSkill {
    name = "#huiwubang_skill",
    attached_equip = "huiwubang",
    events = { fk.DamageCaused },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and (not data.chain) and
            data.card and data.card.trueName == "slash" and #data.to:getCardIds("hej") >= 2
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/huiwubang")
        local to = data.to
        for i = 1, 2 do
            if player.dead or to.dead or #data.to:getCardIds("hej") == 0 then break end
            local card = room:askForCardChosen(player, to, "hej", self.name)
            room:throwCard({ card }, self.name, to, player)
        end
        return true
    end
}
local huiwubang = fk.CreateWeapon {
    name = "huiwubang",
    attack_range = 2,
    equip_skill = huiwubang_skill,
    special_skills = { "thb_weapon_recast" },
}


local yichuipiao_skill = fk.CreateTriggerSkill {
    name = "#yichuipiao_skill",
    attached_equip = "yichuipiao",
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.EventPhaseEnd },
    can_trigger = function(self, event, target, player, data)
        local room = player.room
        if player:hasSkill(self) and player == target and player.phase == Player.Play then
            local events = room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
                if e.data[1] == player and e.data[3] == "damage" then
                    local first_damage_event = e:findParent(GameEvent.Damage)
                    if first_damage_event then
                        return false
                    end
                end
                return true
            end, Player.HistoryPhase)
            if #events == 0 then
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:setPlayerMark(player, "@@hezui", 1)
    end,


}

local yichuipiao_install = fk.CreateTriggerSkill {
    name = "#yichuipiao_install",
    global = true,
    frequency = Skill.Compulsory,
    refresh_events = { fk.CardUsing },
    can_refresh = function(self, event, target, player, data)
        return data.card.name == "yichuipiao" and target == player
    end,
    on_refresh = function(self, event, target, player, data)
        player.room:setPlayerMark(player, "@@hezui", 1)
    end,
}

local yichuipiao = fk.CreateOffensiveRide {
    name = "yichuipiao",
    equip_skill = yichuipiao_skill
}
local penglaiyuzhi_skill = fk.CreateTriggerSkill {
    name = "#penglaiyuzhi_skill",
    attached_equip = "penglaiyuzhi",
    events = { fk.PreCardEffect },
    priority = 0.01,
    mute = true,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = room:getPlayerById(data.to)
        local cancel = false
        local players = table.filter(room.alive_players, function(p)
            return not table.contains(data.disresponsiveList or Util.DummyTable, p.id) and not
                table.contains(data.unoffsetableList or Util.DummyTable, p.id)
        end)
        local useEvent = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
        if data.disresponsive or data.unoffsetable then
            table.removeOne(players, to)
        end
        local hasNullification = function(p)
            local temp = Fk.currentResponsePattern
            Fk.currentResponsePattern = "nullification"
            local check = function()
                local cardCloned = Fk:cloneCard("nullification")
                if p:prohibitUse(cardCloned) then return false end
                local cards = p:getHandlyIds()
                if table.find(cards, function(cid) return Fk:getCardById(cid).trueName == "nullification" end) then return true end
                Self = p -- for enabledAtResponse
                for _, s in ipairs(table.connect(p.player_skills, p._fake_skills)) do
                    if s.pattern and Exppattern:Parse("nullification"):matchExp(s.pattern) and
                        not (s.enabledAtResponse and not s:enabledAtResponse(p)) then
                        return true
                    end
                end
            end
            local yes = check()
            Fk.currentResponsePattern = temp
            return yes
        end
        players = table.filter(players, function(p)
            return hasNullification(p)
        end)
        if #players > 0 then
            local extra_data = Util.DummyTable
            if useEvent then
                extra_data = { useEventId = useEvent.id, effectTo = data.to }
            end
            local prompt = "#penglaiyuzhi-ask:" .. data.to
            local use = room:askForNullification(players, "nullification", "nullification", prompt, true, extra_data)
            if use then
                use.toCard = data.card
                use.responseToEvent = data
                room:useCard(use)
            end
            if data.isCancellOut then
                cancel = true
            end
        end
        if cancel then
            if room.logic:trigger(fk.CardEffectCancelledOut, target, data) then
                data.isCancellOut = false
                cancel = false
            end
        end
        if cancel then
            return true
        else
            data.unoffsetable = true
        end
    end
}
local penglaiyuzhi = fk.CreateWeapon {
    name = "penglaiyuzhi",
    attack_range = 1,
    equip_skill = penglaiyuzhi_skill,
    special_skills = { "thb_weapon_recast" },
}

--巫女服测试完毕
local wunvfu_skill = fk.CreateViewAsSkill {
    name = "wunvfu_skill",
    attached_equip = "wunvfu",
    pattern = "nullification",
    prompt = "#wunvfu__skill-prompt",
    card_filter = Util.FalseFunc,
    view_as = function(self, cards)
        local card = Fk:cloneCard("nullification")
        card.skillName = self.name
        return card
    end,
    before_use = function(self, player, use)
        local room = player.room
        local current_event = room.logic:getCurrentEvent()
        local parent_event = current_event.parent
        if parent_event and parent_event.data[1].card and parent_event.data[1].card.name == "nullification" then
            return self.name
        end
        local judgeData = {
            who = player,
            reason = self.name,
            pattern = ".|9~13",
        }
        room:judge(judgeData)
        if judgeData.card.number < 9 then
            return self.name
        end
    end,
    enabled_at_response = function(self, player, response)
        return not response
    end,

    after_use = function(self, player, use)

    end,
}
local wunvfu = fk.CreateArmor {
    name = "wunvfu",
    equip_skill = wunvfu_skill,
}


local bailoujian_skill = fk.CreateTriggerSkill {
    name = "#bailoujian_skill",
    attached_equip = "bailoujian",
    events = { fk.TargetSpecified },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self.name) and data.card.trueName == "slash" and
            data.card.suit == Card.Club
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = room:getPlayerById(data.to)
        local choose
        if to:isKongcheng() then
            choose = "bailoujian-choose2"
        else
            choose = room:askForChoice(to, { "#bailoujian-choose1", "#bailoujian-choose2:" .. player.id }, self.name)
        end
        if choose == "bailoujian-choose1" then
            local targetcard = room:askForCardChosen(to, to, "h", self.name, "#bailoujian-choose_card")
            room:throwCard(targetcard, self.name, to, player)
        else
            player:drawCards(1, self.name)
        end
    end
}

local bailoujian = fk.CreateWeapon {
    name = "bailoujian",
    attack_range = 2,
    equip_skill = bailoujian_skill,
    special_skills = { "thb_weapon_recast" },
}

local tuanshan_skill = fk.CreateTriggerSkill {
    name = "#tuanshan_skill",
    attached_equip = "tuanshan",
    events = { fk.Damage },
    mute = true,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
            #data.to.player_cards[Player.Equip] > 0
            and not player:isKongcheng()
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/tuanshan" .. math.random(2))
        local throwCard_player = room:askForCardChosen(player, player, "h", self.name, "#tuanshan-throwCard")
        room:throwCard(throwCard_player, self.name, player, player)
        local throwCard_to = room:askForCardChosen(player, data.to, "e", self.name, "#tuanshan-throwCard")
        room:throwCard(throwCard_to, self.name, data.to, player)
    end
}
local tuanshan = fk.CreateWeapon {
    name = "tuanshan",
    attack_range = 5,
    equip_skill = tuanshan_skill,
    special_skills = { "thb_weapon_recast" },
}


--念写机测试完毕
local thb_card_visible = fk.CreateVisibilitySkill {
    name = 'thb_card_visible',
    frequency = Skill.Compulsory,
    global = true,
    mute = true,
    card_visible = function(self, player, card)
        if card:getMark("thb_mingpai") > 0 and Fk:currentRoom():getCardArea(card) == Card.PlayerHand then
            return true
        end
    end
}


local nianxieji_skill = fk.CreateTriggerSkill {
    name = "#nianxieji_skill",
    attached_equip = "nianxieji",
    events = { fk.Damage },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self.name) and data.card and data.card.trueName == "slash" and
            not data.to:isKongcheng()
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = data.to
        local showCard = table.random(to.player_cards[Player.Hand], math.min(#to.player_cards[Player.Hand], 2))
        for _, c in ipairs(showCard) do
            room:addCardMark(Fk:getCardById(c), "thb_mingpai")
        end
    end
}

local nianxieji = fk.CreateWeapon {
    name = "nianxieji",
    attack_range = 4,
    equip_skill = nianxieji_skill,
    special_skills = { "thb_weapon_recast" },
}



local laiwating__axe_skill = fk.CreateTriggerSkill {
    name = "#laiwating__axe_skill",
    attached_equip = "laiwating__axe",
    events = { fk.CardEffectCancelledOut },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and data.from == player.id and data.card.trueName == "slash" and
            not player.room:getPlayerById(data.to).dead
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        local cards = {}
        for _, id in ipairs(player:getCardIds("he")) do
            if not player:prohibitDiscard(id) and
                not (table.contains(player:getEquipments(Card.SubtypeWeapon), id) and Fk:getCardById(id).trueName == "axe") then
                table.insert(cards, id)
            end
        end
        cards = room:askForDiscard(player, 2, 2, true, self.name, true, ".|.|.|.|.|.|" .. table.concat(cards, ","),
            "#laiwating-invoke::" .. data.to, true)
        if #cards > 0 then
            self.cost_data = cards
            return true
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:throwCard(self.cost_data, "laiwating__axe", player, player)
        return true
    end,
}
local laiwating__axe = fk.CreateWeapon {
    name = "laiwating__axe",
    attack_range = 3,
    equip_skill = laiwating__axe_skill,
    special_skills = { "thb_weapon_recast" },
}

local sishenliandao__guding_blade_skill = fk.CreateTriggerSkill {
    name = "#sishenliandao__guding_blade_skill",
    attached_equip = "sishenliandao__guding_blade",
    frequency = Skill.Compulsory,
    events = { fk.DamageCaused },
    can_trigger = function(self, _, target, player, data)
        local logic = player.room.logic
        if target == player and player:hasSkill(self) and
            data.to:isKongcheng() and data.card and data.card.trueName == "slash" then
            return data.by_user
        end
    end,
    on_use = function(_, _, _, _, data)
        data.damage = data.damage + 1
    end,
}

local sishenliandao__guding_blade = fk.CreateWeapon {
    name = "sishenliandao__guding_blade",
    attack_range = 2,
    equip_skill = sishenliandao__guding_blade_skill,
    special_skills = { "thb_weapon_recast" },
}

local yaoshi_all = fk.CreateTriggerSkill {
    name = "#yaoshi_all",
    frequency = Skill.Compulsory,
    global = true,
    mute = true,
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and #player:getCardIds(Player.Judge) > 0 and #player:getCardIds(Player.Equip) > 0
            and table.find(player:getCardIds(Player.Judge), function(cid)
                if Fk:getCardById(cid).trueName == "lightning" then
                    self.cost_data = cid
                    return true
                end
            end) and table.find(player:getCardIds(Player.Equip), function(cid)
                return Fk:getCardById(cid).name == "yaoshi"
            end)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/yaoshi")
        room:moveCards({
            ids = { self.cost_data },
            from = player.id,
            to = player.next.id,
            toArea = Card.PlayerJudge,
            proposer = player.id,
            moveVisible = true,
            skillName = self.name,
            moveReason = fk.ReasonJustMove
        })
    end,
}
local yaoshi_skill = fk.CreateDistanceSkill {
    name = "#yaoshi_skill",
    attached_equip = "yaoshi",
    correct_func = function(self, from, to)
        if to:hasSkill(self) then
            return 1
        end
    end,
}

local yaoshi = fk.CreateDefensiveRide {
    name = "yaoshi",
    equip_skill = yaoshi_skill,
}

local monvsaoba_distance = fk.CreateDistanceSkill {
    name = "#monvsaoba_distance",
    attached_equip = "monvsaoba",
    correct_func = function(self, from, to)
        if from:hasSkill(self) then
            return -2
        end
    end,
}
local monvsaoba = fk.CreateOffensiveRide {
    name = "monvsaoba",
    equip_skill = monvsaoba_distance,
}

local yinyangyu_skill = fk.CreateTriggerSkill {
    name = "#yinyangyu_skill",
    events = { fk.AskForRetrial },
    priority = 0.1,
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and data.who == player
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, "#yinyangyu_skill")
    end,
    on_use = function(self, event, target, player, data)
        local card = table.filter(player:getCardIds(Player.Equip), function(cid)
            return Fk:getCardById(cid).name == "yinyangyu"
        end)
        player.room:retrial(Fk:getCardById(card[1]), player, data, self.name, true)
    end,
}


local yinyangyu = fk.CreateTreasure {
    name = "yinyangyu",
    equip_skill = yinyangyu_skill,
}


local qingwamao_voice = fk.CreateTriggerSkill {
    name = "#qingwamao_voice",
    anim_type = "support",
    priority = 0.1,
    events = { fk.TurnEnd },
    global = true,
    mute = true,
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target == player and #table.filter(player:getCardIds(Player.Equip), function(id)
            return Fk:getCardById(id).name == "qingwamao"
        end) > 0
    end,
    on_use = function(self, event, target, player, data)
        player.room:broadcastPlaySound(The_jie_path .. "audio/card/male/qingwamao")
    end,
}
local qingwamao_skill = fk.CreateMaxCardsSkill {
    name = "#qingwamao_skill",
    correct_func = function(self, player)
        if player:hasSkill(self) and
            #table.filter(player:getCardIds(Player.Equip), function(id)
                return Fk:getCardById(id).name == "qingwamao"
            end) > 0 then
            return 2
        end
    end
}
local qingwamao = fk.CreateTreasure {
    name = "qingwamao",
    equip_skill = qingwamao_skill,
}

local banling_skill = fk.CreateTriggerSkill {
    name = "#banling_skill",
    attached_equip = "banling",
    anim_type = "support",
}


local banling = fk.CreateTreasure {
    name = "banling",
    equip_skill = banling_skill,
    on_install = function(self, room, player)
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/banling")
        player.room:changeMaxHp(player, 1)
    end,
    on_uninstall = function(self, room, player)
        room:broadcastPlaySound(The_jie_path .. "audio/card/male/banling")
        player.room:changeMaxHp(player, -1)
        player.room:changeHp(player, 1, "recover")
    end
}

local jiudechibang_skill = fk.CreateTriggerSkill {
    name = "#jiudechibang_skill",
    frequency = Skill.Compulsory,
    mute = true,
    global = true,
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        if target == player and #player:getCardIds(Player.Judge) > 0 and #player:getCardIds(Player.Equip) > 0
            and table.find(player:getCardIds(Player.Equip), function(cid)
                return Fk:getCardById(cid).name == "jiudechibang"
            end)
        then
            self.cost_data = table.map(player:getCardIds("j"), function(cid)
                if Fk:getCardById(cid).trueName == "supply_shortage" or Fk:getCardById(cid).trueName == "indulgence" then
                    return cid
                end
            end)
            return #self.cost_data > 0
        end
    end,
    on_use = function(self, event, target, player, data)
        player.room:broadcastPlaySound(The_jie_path .. "audio/card/male/jiudechibang")
        player.room:throwCard(self.cost_data, self.name, player)
    end
}

local jiudechibang_distance = fk.CreateDistanceSkill {
    name = "#jiudechibang_distance",
    attached_equip = "jiudechibang",
    correct_func = function(self, from, to)
        if from:hasSkill(self) then
            return -1
        end
    end,
}


local jiudechibang = fk.CreateOffensiveRide {
    name = "jiudechibang",
    equip_skill = jiudechibang_distance,
}


local modaoshu_skill = fk.CreateActiveSkill {
    name = "modaoshu_skill",
    anim_type = "special",
    attached_equip = "modaoshu",
    prompt = function(self, selected_cards, selected_targets)
        if #selected_cards > 0 then
            if Fk:getCardById(selected_cards[1]).suit == Card.Club then
                return "#archery_attack_skill"
            elseif Fk:getCardById(selected_cards[1]).suit == Card.Heart then
                return "#yanhui_skill"
            elseif Fk:getCardById(selected_cards[1]).suit == Card.Diamond then
                return "#amazing_grace_skill"
            elseif Fk:getCardById(selected_cards[1]).suit == Card.Spade then
                return "#savage_assault_skill"
            end
        end
        return ""
    end,
    target_num = 0,
    target_filter = Util.FalseFunc,
    card_num = 1,
    card_filter = function(self, to_select, selected, selected_targets)
        return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select)) and
            Fk:getCardById(to_select).suit ~= Card.NoSuit
    end,
    can_use = function(self, player, card, extra_data)
        return player.phase == Player.Play and
            table.find(Fk:currentRoom().alive_players, function(p1)
                if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 1) then
                    return p1
                end
            end) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local card = Fk:getCardById(effect.cards[1])
        room:throwCard(effect.cards, self.name, player, player)
        if card.suit == Card.Club then
            room:useCard({
                from = player.id,
                tos = { table.map(room:getOtherPlayers(player), Util.IdMapper) },
                card = Fk:cloneCard("archery_attack")
            })
        elseif card.suit == Card.Spade then
            room:useCard({
                from = player.id,
                tos = { table.map(room:getOtherPlayers(player), Util.IdMapper) },
                card = Fk:cloneCard("savage_assault")
            })
        elseif card.suit == Card.Diamond then
            room:useCard({
                from = player.id,
                tos = { table.map(room.alive_players, Util.IdMapper) },
                card = Fk:cloneCard("amazing_grace")
            })
        elseif card.suit == Card.Heart then
            room:useCard({
                from = player.id,
                tos = { table.map(room.alive_players, Util.IdMapper) },
                card = Fk:cloneCard("yanhui")
            })
        end
    end,
}

local modaoshu = fk.CreateWeapon {
    name = "modaoshu",
    attack_range = 1,
    equip_skill = modaoshu_skill,
    special_skills = { "thb_weapon_recast" },
}




local toutao_choose = fk.CreateTriggerSkill {
    name = "#toutao_choose",
    mute = true,
    frequency = Skill.Compulsory,
    global = true,
    events = { fk.CardUsing },
    can_trigger = function(self, event, target, player, data)
        return target == player and data.card.name == "toutao" and data.from == player.id
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local chooseplayers=table.filter(room.alive_players, function(p)
            return player:distanceTo(p) and player:distanceTo(p) <= 2
        end)
        local targetplayer = room:askForChoosePlayers(player,table.map(chooseplayers,Util.IdMapper) , 1, 1, "#toutao-choose", "toutao_skill", true)
        if #targetplayer==0 then
            return true
        end
        LoR_Utility.moveCardIntoEquip(room, room:getPlayerById(targetplayer[1]), data.card.id, self.name, true, player)
    end,
}

local toutao_skill = fk.CreateTriggerSkill {
    name = "toutao_skill",
    attached_equip = "toutao",
    events = { fk.EventPhaseEnd },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Judge
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local judgeData = {
            who = player,
            reason = self.name,
            pattern = ".|1~8|spade",
        }
        room:judge(judgeData)
        local toutao = Fk:getCardById(table.filter(player:getCardIds(Player.Equip), function(cid)
            return Fk:getCardById(cid).name == "toutao"
        end)[1])
        if judgeData.card.suit == Card.Spade and judgeData.card.number <= 8 then
            room:damage({
                to = player,
                card = judgeData.card,
                damage = 2,
            })
            room:moveCardTo(toutao, Card.PlayerHand, player, fk.ReasonJustMove, self.name)
        end
    end,
}

local toutao = fk.CreateArmor {
    name = "toutao",
    equip_skill = toutao_skill,
}
------------------------------------测试警戒线，以上均测试完毕
--城管执法测试完毕
local dismantlement = Fk:cloneCard("dismantlement")
local chengguanzhifa__dismantlement = fk.CreateTrickCard {
    name = "chengguanzhifa__dismantlement",
    skill = dismantlement.skill
}

--好人卡测试完毕
local nullification = Fk:cloneCard("nullification")
local haorenka__nullification = fk.CreateTrickCard {
    name = "haorenka__nullification",
    skill = nullification.skill
}

--封魔阵测试完毕
local indulgence_target = fk.CreateProhibitSkill {
    name = "#indulgence_target",
    global = true,
    is_prohibited = function(self, from, to, card)
        local delayed = { "indulgence", "supply_shortage", "lightning" }
        return card and table.contains(delayed, card.trueName) and #to:getCardIds(Player.Judge) > 0 and
            table.find(to:getCardIds(Player.Judge), function(cid)
                return Fk:getCardById(cid).trueName == card.trueName
            end)
    end,
}

local fengmozhen__indulgence_skill = fk.CreateActiveSkill {
    name = "fengmozhen__indulgence_skill",
    prompt = "#fengmozhen__indulgence_skill",
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        return user ~= to_select
    end,
    target_filter = function(self, to_select, selected, _, card)
        return #selected == 0 and self:modTargetFilter(to_select, selected, Self.id, card, true)
    end,
    target_num = 1,
    on_effect = function(self, room, effect)
        local to = room:getPlayerById(effect.to)
        local judge = {
            who = to,
            pattern = ".|.|spade,club,diamond",
        }
        room:judge(judge)
        local result = judge.card
        if result.suit ~= Card.Heart then
            to:skip(Player.Play)
        end
        self:onNullified(room, effect)
    end,
    on_nullified = function(self, room, effect)
        room:moveCards {
            ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonUse
        }
    end,
}
local fengmozhen__indulgence = fk.CreateDelayedTrickCard {
    name = "fengmozhen__indulgence",
    skill = fengmozhen__indulgence_skill
}
--冻青蛙测试完毕
local dongqingwa__supply_shortage_skill = fk.CreateActiveSkill {
    name = "dongqingwa__supply_shortage_skill",
    prompt = "#dongqingwa__supply_shortage_skill",
    distance_limit = 1,
    mod_target_filter = function(self, to_select, _, user, card, distance_limited)
        local player = Fk:currentRoom():getPlayerById(to_select)
        local from = Fk:currentRoom():getPlayerById(user)
        return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, false, card, player))
    end,
    target_filter = function(self, to_select, selected, _, card, extra_data)
        local count_distances = not (extra_data and extra_data.bypass_distances)
        return #selected == 0 and self:modTargetFilter(to_select, selected, Self.id, card, count_distances)
    end,
    target_num = 1,
    on_effect = function(self, room, effect)
        local to = room:getPlayerById(effect.to)
        local judge = {
            who = to,
            reason = "supply_shortage",
            pattern = ".|.|club,heart,diamond",
        }
        room:judge(judge)
        local result = judge.card
        if result.suit ~= Card.Spade then
            to:skip(Player.Draw)
        end
        self:onNullified(room, effect)
    end,
    on_nullified = function(self, room, effect)
        room:moveCards {
            ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonUse
        }
    end,
}
local dongqingwa__supply_shortage = fk.CreateDelayedTrickCard {
    name = "dongqingwa__supply_shortage",
    skill = dongqingwa__supply_shortage_skill,
}

--寻龙尺已测试
local ex_nihilo = Fk:cloneCard("ex_nihilo")
local xunlongchi__ex_nihilo = fk.CreateTrickCard {
    name = "xunlongchi__ex_nihilo",
    skill = ex_nihilo.skill
}

--罪袋测试完毕
local zuidai__lightning_skill = fk.CreateActiveSkill {
    name = "zuidai__lightning_skill",
    prompt = "#zuidai__lightning_skill",
    mod_target_filter = Util.TrueFunc,
    can_use = function(self, player, card)
        return not player:isProhibited(player, card)
    end,
    on_use = function(self, room, use)
        if not use.tos or #TargetGroup:getRealTargets(use.tos) == 0 then
            use.tos = { { use.from } }
        end
    end,
    on_effect = function(self, room, effect)
        local to = room:getPlayerById(effect.to)
        local judge = {
            who = to,
            reason = "lightning",
            pattern = ".|1~8|spade",
        }
        room:judge(judge)
        local result = judge.card
        if result.suit == Card.Spade and result.number <= 8 then
            room:broadcastPlaySound(The_jie_path .. "audio/card/male/zuidai__lightning_effect")
            room:damage {
                to = to,
                damage = 3,
                card = effect.card,
                skillName = self.name,
            }

            room:moveCards {
                ids = Card:getIdList(effect.card),
                toArea = Card.DiscardPile,
                moveReason = fk.ReasonUse
            }
        else
            self:onNullified(room, effect)
        end
    end,
    on_nullified = function(self, room, effect)
        local to = room:getPlayerById(effect.to)
        local nextp = to
        repeat
            nextp = nextp:getNextAlive(true)
            if nextp == to then
                if nextp:isProhibited(nextp, effect.card) then
                    room:moveCards {
                        ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
                        toArea = Card.DiscardPile,
                        moveReason = fk.ReasonPut
                    }
                    return
                end
                break
            end
        until not nextp:isProhibited(nextp, effect.card)
        if effect.card:isVirtual() then
            nextp:addVirtualEquip(effect.card)
        end

        room:moveCards {
            ids = room:getSubcardsByRule(effect.card, { Card.Processing }),
            to = nextp.id,
            toArea = Card.PlayerJudge,
            moveReason = fk.ReasonPut
        }
    end,
}
local zuidai__lightning = fk.CreateDelayedTrickCard {
    name = "zuidai__lightning",
    skill = zuidai__lightning_skill,
}

--隙间测试完毕
local snatch = Fk:cloneCard("snatch")

local xijian__snatch = fk.CreateTrickCard {
    name = "xijian__snatch",
    skill = snatch.skill
}


--弹幕战测试完毕
local duel = Fk:cloneCard("duel")
local danmuzhan__duel = fk.CreateTrickCard {
    name = "danmuzhan__duel",
    skill = duel.skill
}

--地图炮测试完毕
local archery_attack = Fk:cloneCard("archery_attack")

local ditupao__archery_attack = fk.CreateTrickCard {
    name = "ditupao__archery_attack",
    skill = archery_attack.skill
}

--百鬼夜行测试完毕
local savage_assault = Fk:cloneCard("savage_assault")
local baiguiyexing__savage_assault = fk.CreateTrickCard {
    name = "baiguiyexing__savage_assault",
    skill = savage_assault.skill
}

--宴会测试完毕
local yanhui_skill = fk.CreateActiveSkill {
    name = "yanhui_skill",
    prompt = "#yanhui_skill",
    can_use = Util.GlobalCanUse,
    on_use = Util.GlobalOnUse,
    mod_target_filter = Util.TrueFunc,
    on_effect = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.to)
        if target:isWounded() and not target.dead then
            room:recover({
                who = target,
                num = 1,
                recoverBy = player,
                card = effect.card,
                skillName = self.name,
            })
        elseif target.hp == target.maxHp then
            room:setPlayerMark(target, "@@hezui", 1)
        end
    end
}

local yanhui = fk.CreateTrickCard {
    name = "yanhui",
    skill = yanhui_skill
}


--五谷丰登测试完毕
local amazing_grace = Fk:cloneCard("amazing_grace")
local wugufengdeng__amazing_grace = fk.CreateTrickCard {
    name = "wugufengdeng__amazing_grace",
    skill = amazing_grace.skill
}

--人形操控测试完毕
local collateral = Fk:cloneCard("collateral")
local renxingcaokong__collateral = fk.CreateTrickCard {
    name = "renxingcaokong__collateral",
    skill = collateral.skill
}


--赛钱箱有问题
local saiqianxiang_skill = fk.CreateActiveSkill {
    name = "saiqianxiang_skill",
    prompt = "#saiqianxiang_skill",
    max_target_num = 2,
    min_target_num = 1,
    mod_target_filter = function(self, to_select, selected, user, card)
        return user ~= to_select and not Fk:currentRoom():getPlayerById(to_select):isAllNude()
    end,
    target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
        return #selected < 2 and self:modTargetFilter(to_select, selected, Self.id, card)
    end,
    on_effect = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.to)
        local card = room:askForCard(target, 1, 1, true, self.name, false)
        room:obtainCard(player, card, true, fk.ReasonPrey, player.id, self.name, "thb_mingpai")
    end,
}

local saiqianxiang = fk.CreateTrickCard {
    name = "saiqianxiang",
    skill = saiqianxiang_skill
}
Fk:addSkill(indulgence_target)
Fk:addSkill(thb_weapon_recast)
Fk:addSkill(danmu__slash_yuyin)
Fk:addSkill(jiu_Effect)
Fk:addSkill(exinwan_Effect)
Fk:addSkill(guangxuemicai__eightDiagramSkill)
Fk:addSkill(tiangoudun__nioh_shield_skill)
Fk:addSkill(louguan_sword__qinggang_sword_skill)
Fk:addSkill(bagualu_crossbow_skill)
feixiangzhijian__halberd_skill:addRelatedSkill(feixiangzhijian__halberd_audio)
Fk:addSkill(feixiangzhijian__halberd_skill)
Fk:addSkill(laiwating__axe_skill)
Fk:addSkill(sishenliandao__guding_blade_skill)
Fk:addSkill(yangsan_skill)
Fk:addSkill(huiwubang_skill)
Fk:addSkill(yichuipiao_install)
Fk:addSkill(yichuipiao_skill)
Fk:addSkill(penglaiyuzhi_skill)
Fk:addSkill(wunvfu_skill)
Fk:addSkill(bailoujian_skill)
Fk:addSkill(tuanshan_skill)
Fk:addSkill(nianxieji_skill)
Fk:addSkill(yaoshi_all)
Fk:addSkill(yaoshi_skill)
Fk:addSkill(monvsaoba_distance)
Fk:addSkill(yinyangyu_skill)
Fk:addSkill(qingwamao_voice)
Fk:addSkill(qingwamao_skill)
Fk:addSkill(banling_skill)
Fk:addSkill(jiudechibang_distance)
Fk:addSkill(jiudechibang_skill)
Fk:addSkill(modaoshu_skill)
Fk:addSkill(toutao_skill)
Fk:addSkill(toutao_choose)
Fk:addSkill(ganggenier__spear_skill)
Fk:addSkill(saiqianxiang_skill)
Fk:addSkill(thb_card_visible)
Fk:loadTranslationTable {
    ["hezui"] = "<br><font color='black'><b>#喝醉</b><br>效果：你使用的下一张【杀】的伤害值基数+1；受到致命伤害-1。你的准备阶段开始时/触发任意效果后失去此状态，【喝醉】不可叠加",
}

Fk:loadTranslationTable {
    ["thb_weapon_recast"] = "重铸",
    [":thb_weapon_recast"] = "你可以消耗一次使用【杀】次数，将此牌置入弃牌堆，然后摸一张牌。",
    ["#thb_weapon_recast"] = "消耗一次使用【杀】次数，将此牌置入弃牌堆，然后摸一张牌。",

    ["danmu__slash"] = "弹幕",
    [":danmu__slash"] = "<b>牌名：</b>弹幕<br/><b>类型：</b>基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：攻击范围内的一名角色<br /><b>效果</b>：对目标角色造成1点伤害。(算作普通【杀】)",

    ["cadan__jink"] = "擦弹",
    [":cadan__jink"] = "<b>牌名：</b>擦弹<br/><b>类型：</b>基本牌<br /><b>时机</b>：【杀】对你生效时<br /><b>目标</b>：此【杀】<br /><b>效果</b>：抵消此【杀】的效果。",

    ["jiu"] = "酒(符斗祭版)",
    [":jiu"] = "<b>牌名：</b>酒(符斗祭版)<br/><b>类型：</b>基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：使用后立即获得【<a href='hezui'>喝醉</a>】状态。",
    ["#jiu_skill"] = "你于使用的下一张【杀】的伤害值基数+1，受到致命伤害-1，回合开始前所有效果消失，不可叠加",
    ["@@hezui"] = "喝醉",

    ["exinwan"] = "恶心丸",
    [":exinwan"] = "<b>牌名：</b>恶心丸<br/><b>类型：</b>基本牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：令此牌置入弃牌堆的角色（主动使用视为自己）<br /><b>效果</b>：令此牌置入弃牌堆的角色需选择一项：1，弃置两张牌；2，受到一点无来源伤害。",
    ["#exinwanX_skill-choose"] = "选择一项：1，弃置两张牌；2，受到一点无来源伤害。",
    ["#exinwanX_skill"] = "负面效果卡牌，令此牌被弃置的角色需选择一项：1，弃置两张牌；2，受到一点无来源伤害。",
    ["#exinwan-choose1"] = "弃置两张牌",
    ["#exinwan-choose2"] = "受到一点无来源伤害。",

    ["mashu__peach"] = "麻薯",
    [":mashu__peach"] = "<b>牌名：</b>麻薯<br/><b>类型：</b>基本牌<br /><b>时机</b>：出牌阶段/一名角色处于濒死状态时<br /><b>目标</b>：已受伤的你/处于濒死状态的角色<br /><b>效果</b>：目标角色回复1点体力。",

    ["guangxuemicai__eight_diagram"] = "光学迷彩",
    [":guangxuemicai__eight_diagram"] = "<b>牌名：</b>光学迷彩<br/><b>类型：</b>装备牌·防具<br /><b>防具技能</b>：当你需要使用或打出一张【闪】时，你可以进行判定：若结果为红色，视为你使用或打出了一张【闪】。",
    ["#guangxuemicai__eight_diagram_skill"] = "光学迷彩",

    ["tiangoudun__nioh_shield"] = "天狗盾",
    [":tiangoudun__nioh_shield"] = "<b>牌名：</b>天狗盾<br/><b>类型：</b>装备牌·防具<br /><b>防具技能</b>：锁定技，黑色【杀】对你无效。",
    ["#tiangoudun__nioh_shield_skill"] = "天狗盾",

    ["GreenUFO"] = "绿色UFO",
    [":GreenUFO"] = "<b>牌名：</b>绿色UFO<br/><b>类型：</b>装备牌·坐骑<br /><b>坐骑技能</b>：其他角色与你的距离+1。",

    ["RedUFO"] = "红色UFO",
    [":RedUFO"] = "<b>牌名：</b>红色UFO<br/><b>类型：</b>装备牌·坐骑<br /><b>坐骑技能</b>：你与其他角色的距离-1。",

    ["louguan_sword__qinggang_sword"] = "楼观剑",
    [":louguan_sword__qinggang_sword"] = "<b>牌名：</b>楼观剑<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：3<br /><b>武器技能</b>：锁定技，你的【杀】无视目标角色的防具。",
    ["#louguan_sword__qinggang_sword_skill"] = "楼观剑",

    ["bagualu_crossbow"] = "八卦炉",
    [":bagualu_crossbow"] = "<b>牌名：</b>八卦炉<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：１<br /><b>武器技能</b>：锁定技，你于出牌阶段内使用【杀】无次数限制。",
    ["#bagualu_crossbow_skill"] = "八卦炉",

    ["yangsan"] = "阳伞",
    [":yangsan"] = "<b>牌名：</b>阳伞<br/><b>类型：</b>装备牌·防具<br /><b>防具技能</b>：当你即将受到锦囊牌的伤害时，防止之",
    ["#yangsan_skill"] = "阳伞",

    ["ganggenier__spear"] = "冈格尼尔",
    [":ganggenier__spear"] = "<b>牌名：</b>冈格尼尔<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：你可以将两张手牌当【杀】使用或打出。",
    ["ganggenier__spear_skill"] = "冈格尼尔",
    ["#ganggenier__spear_skill"] = "你可以将两张手牌当【杀】使用或打出。",

    ["feixiangzhijian__halberd"] = "绯想之剑",
    [":feixiangzhijian__halberd"] = "<b>牌名：</b>绯想之剑<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：４<br /><b>武器技能</b>：锁定技，你使用最后的手牌【杀】可以额外选择至多两名目标。",
    ["#feixiangzhijian__halberd_skill"] = "绯想之剑",
    ["#feixiangzhijian__halberd_audio"] = "绯想之剑",

    ["huiwubang"] = "悔悟棒",
    [":huiwubang"] = "<b>牌名：</b>悔悟棒<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：当你使用【杀】对目标角色造成伤害时，若该角色区域内有牌，你可以防止此伤害，然后依次弃置其两张牌。",
    ["#huiwubang_skill"] = "悔悟棒",

    ["yichuipiao"] = "伊吹瓢",
    [":yichuipiao"] = "<b>牌名：</b>伊吹瓢<br/><b>类型：</b>装备牌·坐骑<br /><b>坐骑技能</b>：你与其他角色的距离不变。装备后：获得立即【喝醉】状态。并且，若你在出牌阶段没有造成过伤害，在回合结束阶段获得【<a href='hezui'>喝醉</a>】状态。",
    ["#yichuipiao_skill"] = "伊吹瓢",
    ["#yichuipiao_distance"] = "伊吹瓢",

    ["penglaiyuzhi"] = "蓬莱玉枝",
    ["#penglaiyuzhi_skill"] = "蓬莱玉枝",
    [":penglaiyuzhi"] = "<b>牌名：</b>蓬莱玉枝<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：1<br /><b>武器技能</b>：你可以令你的【杀】仅能被【无懈可击】抵消",
    ["#penglaiyuzhi-ask"] = "蓬莱玉枝：你可以使用【无懈可击】抵消对 %src 使用的【杀】",

    ["wunvfu"] = "巫女服",
    [":wunvfu"] = "<b>牌名：</b>巫女服<br/><b>类型：</b>装备牌·防具<br /><b>防具技能</b>：当你需要使用【无懈可击】抵消非【无懈可击】的锦囊时，你可以进行一次判定，若判定结果不小于9，你视为使用之",
    ["wunvfu_skill"] = "巫女服",
    ["#wunvfu__skill-prompt"] = "巫女服：你可以进行一次判定，若判定结果不小于9，你视为使用一张【无懈可击】",

    ["bailoujian"] = "白楼剑",
    ["#bailoujian_skill"] = "白楼剑",
    [":bailoujian"] = "<b>牌名：</b>白楼剑<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：2<br /><b>武器技能</b>：你使用的♣️【杀】指定一名目标角色后，你可以令其选择一项：1，弃置一张手牌；2，令你摸一张牌。",
    ["#bailoujian-choose1"] = "弃置一张手牌",
    ["#bailoujian-choose2"] = "令%src摸一张牌",
    ["#bailoujian-choose_card"] = "白楼剑：选择一张手牌弃置",

    ["tuanshan"] = "团扇",
    ["#tuanshan_skill"] = "团扇",
    [":tuanshan"] = "<b>牌名：</b>团扇<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：5<br /><b>武器技能</b>：你使用的【杀】对目标角色造成伤害后，你可以弃置一张手牌，然后弃置其装备区里一张牌。",
    ["#tuanshan-throwCard"] = "团扇：请选择一张牌弃置",

    ["nianxieji"] = "念写机",
    ["#nianxieji_skill"] = "念写机",
    [":nianxieji"] = "<b>牌名：</b>念写机<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：4<br /><b>武器技能</b>：你使用的【杀】对目标角色造成伤害后，可以展示其两张手牌。",
    ["@$showCard"] = "明牌",

    ["laiwating__axe"] = "莱瓦汀",
    [":laiwating__axe"] = "<b>牌名：</b>莱瓦汀<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：当你使用的【杀】被【闪】抵消后，你可以弃置两张牌，则此【杀】继续造成伤害。",
    ["#laiwating__axe_skill"] = "莱瓦汀",
    ["#laiwating-invoke"] = "莱瓦汀：你可以弃置两张牌令此【杀】对%dest依然生效",

    ["sishenliandao__guding_blade"] = "死神镰刀",
    [":sishenliandao__guding_blade"] = "<b>牌名：</b>死神镰刀<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：２<br /><b>武器技能</b>：锁定技。每当你使用【杀】对目标角色造成伤害时，若该角色没有手牌，此伤害+1。",
    ["#sishenliandao__guding_blade_skill"] = "死神镰刀",

    ["yaoshi"] = "要石",
    [":yaoshi"] = "<b>牌名：</b>要石<br/><b>类型：</b>装备牌·坐骑<br /><b>坐骑技能</b>：其他角色与你的距离+1。当你判定区拥有【闪电】时，移动至下家",
    ["#yaoshi_skill"] = "要石",

    ["monvsaoba"] = "魔女扫把",
    [":monvsaoba"] = "<b>牌名：</b>魔女扫把<br/><b>类型：</b>装备牌·坐骑<br /><b>坐骑技能</b>：你与其他角色的距离-2。",
    ["#monvsaoba_distance"] = "魔女扫把",

    ["yinyangyu"] = "阴阳玉",
    ["#yinyangyu_skill"] = "阴阳玉",
    [":yinyangyu"] = "<b>牌名：</b>阴阳玉<br/><b>类型：</b>装备牌·宝物<br/><b>宝物技能</b>：你的判定牌生效前，你可以用装备区内的【阴阳玉】替换之。",

    ["qingwamao"] = "青蛙帽",
    ["#qingwamao_skill"] = "青蛙帽",
    ["#qingwamao_voice"] = "青蛙帽",
    [":qingwamao"] = "<b>牌名：</b>青蛙帽<br/><b>类型：</b>装备牌·宝物<br/><b>宝物技能</b>：你的手牌上限+2",

    ["banling"] = "半灵",
    [":banling"] = "<b>牌名：</b>半灵<br/><b>类型：</b>装备牌·宝物<br/><b>宝物技能</b>：装备后：增加1点体力上限，当失去装备区里的【半灵】时，你失去1点体力上限并回复1点体力。",
    ["#banling_skill"] = "半灵",

    ["jiudechibang"] = "9的翅膀",
    [":jiudechibang"] = "<b>牌名：</b>9的翅膀<br/><b>类型：</b>装备牌·坐骑<br /><b>坐骑技能</b>：判定阶段开始时，弃置你判定区的【乐不思蜀】和【兵粮寸断】",
    ["#jiudechibang_skill"] = "9的翅膀",

    ["modaoshu"] = "魔导书",
    [":modaoshu"] = "<b>牌名：</b>魔导书<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：1<br /><b>武器技能</b>：出牌阶段限一次，你可以消耗一次使用【杀】次数，将不同花色当做以下牌使用："
        .. "<br/><font color='red'>>></font>黑桃♠视为【百鬼夜行】。<font color='grey'>PS:南蛮入侵</font>"
        .. "<br/><font color='red'>>></font>红桃♥视为【宴会】。<font color='grey'>PS:特殊桃园结义，满血角色会获得【<a href='hezui'>喝醉</a>】状态</font>"
        .. "<br/><font color='red'>>></font>梅花♣视为【地图炮】。<font color='grey'>PS:万箭齐发</font>"
        .. "<br/><font color='red'>>></font>方片♦视为【五谷丰登】。",
    ["modaoshu_skill"] = "魔导书",
    [":modaoshu_skill"] = "出牌阶段限一次，你可以消耗一次使用【杀】次数，根据花色将一张牌视为以下牌："
        .. "<br/><font color='red'>>></font>黑桃♠视为【百鬼夜行】。<font color='grey'>PS:南蛮入侵</font>"
        .. "<br/><font color='red'>>></font>红桃♥视为【宴会】。<font color='grey'>PS:特殊桃园结义，满血角色会获得【<a href='hezui'>喝醉</a>】状态</font>"
        .. "<br/><font color='red'>>></font>梅花♣视为【地图炮】。<font color='grey'>PS:万箭齐发</font>"
        .. "<br/><font color='red'>>></font>方片♦视为【五谷丰登】。",

    ["toutao"] = "罪袋的头套",
    [":toutao"] = "<b>牌名：</b>罪袋的头套<br/><b>类型：</b>装备牌·防具<br /><b>防具技能</b>：对距离2以内的一名角色使用。装备【罪袋的头套】的角色需在判定阶段后进行一次判定，若为黑桃1-8，则目标角色受到2点伤害，并且将【罪袋的头套】收入手牌。",
    ["toutao_skill"] = "罪袋的头套",
    ["#toutao-choose"] = "罪袋的头套：对一名角色使用，判定阶段结束时进行判定，若为♠1~8，对该角色造成2点无来源伤害，并将其收入手牌",

    ["chengguanzhifa__dismantlement"] = "城管执法",
    [":chengguanzhifa__dismantlement"] = "<b>牌名：</b>城管执法<br/><b>类型：</b>" .. Fk:translate(":dismantlement"),

    ["haorenka__nullification"] = "好人卡",
    [":haorenka__nullification"] = "<b>牌名：</b>好人卡<br/><b>类型：</b>" .. Fk:translate(":nullification"),

    ["fengmozhen__indulgence"] = "封魔阵",
    [":fengmozhen__indulgence"] = "<b>牌名：</b>封魔阵<br/><b>类型：</b>" .. Fk:translate(":indulgence"),
    ["#fengmozhen__indulgence_skill"] = "封魔阵:对一名其他角色使用，令其进行判定，不为♥则跳过其出牌阶段",
    ["fengmozhen__indulgence_skill"] = "封魔阵",

    ["dongqingwa__supply_shortage"] = "冻青蛙",
    [":dongqingwa__supply_shortage"] = "<b>牌名：</b>冻青蛙<br/><b>类型：</b>" .. Fk:translate(":indulgence"),
    ["#dongqingwa__supply_shortage_skill"] = "选择距离1的一名角色，将此牌置于其判定区内。其判定阶段判定：<br />若结果不为♠，其跳过摸牌阶段",
    ["dongqingwa__supply_shortage_skill"] = "冻青蛙",

    ["xunlongchi__ex_nihilo"] = "寻龙尺",
    [":xunlongchi__ex_nihilo"] = "<b>牌名：</b>寻龙尺<br/><b>类型：</b>" .. Fk:translate(":ex_nihilo"),

    ["zuidai__lightning"] = "罪袋",
    [":zuidai__lightning"] = "<b>牌名：</b>罪袋<br/><b>类型：</b>" .. "延时锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：你<br /><b>效果</b>：将此牌置于目标角色判定区内。其判定阶段进行判定：若结果为♠1-8，其受到3点雷电伤害并将【罪袋】置入弃牌堆，否则将【罪袋】移动至其下家判定区内。",
    ["#zuidai__lightning_skill"] = "将此牌置于你的判定区内。目标角色判定阶段判定：<br />若结果为♠1-8，其受到3点雷电伤害并将【罪袋】置入弃牌堆，否则将【罪袋】移动至其下家判定区内",
    ["zuidai__lightning_skill"] = "罪袋",

    ["xijian__snatch"] = "隙间",
    [":xijian__snatch"] = "<b>牌名：</b>隙间<br/><b>类型：</b>" .. Fk:translate(":snatch"),

    ["danmuzhan__duel"] = "弹幕战",
    [":danmuzhan__duel"] = "<b>牌名：</b>弹幕战<br/><b>类型：</b>" .. Fk:translate(":duel"),

    ["ditupao__archery_attack"] = "地图炮",
    [":ditupao__archery_attack"] = "<b>牌名：</b>地图炮<br/><b>类型：</b>" .. Fk:translate(":archery_attack"),

    ["baiguiyexing__savage_assault"] = "百鬼夜行",
    [":baiguiyexing__savage_assault"] = "<b>牌名：</b>百鬼夜行<br/><b>类型：</b>" .. Fk:translate(":savage_assault"),

    ["yanhui"] = "宴会",
    ["#yanhui"] = "宴会:所有受伤角色回复1点体力，未受伤角色获得【喝醉】状态",
    [":yanhui"] = "<b>牌名：</b>宴会<br/><b>类型：</b>" .. "锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：所有角色<br /><b>效果</b>：所有受伤角色回复1点体力，未受伤角色获得【<a href='hezui'>喝醉</a>】状态",

    ["wugufengdeng__amazing_grace"] = "五谷丰登",
    [":wugufengdeng__amazing_grace"] = "<b>牌名：</b>五谷丰登<br/><b>类型：</b>" .. Fk:translate("amazing_grace"),

    ["renxingcaokong__collateral"] = "人形操控",
    [":renxingcaokong__collateral"] = "<b>牌名：</b>人形操控<br/><b>类型：</b>" .. Fk:translate("collateral"),

    ["saiqianxiang"] = "赛钱箱",
    [":saiqianxiang"] = "<b>牌名：</b>赛钱箱<br/><b>类型：</b>锦囊牌<br /><b>时机</b>：出牌阶段<br /><b>目标</b>：至多两名拥有手牌与装备的其他角色<br /><b>效果</b>：每名目标角色需交给你一张牌且你将这些牌明置",
    ["saiqianxiang_skill"] = "赛钱箱",
    ["#saiqianxiang_skill"] = "赛钱箱：每名目标角色需交给你一张牌且你将这些牌明置",
}
extension:addCards({
    danmu__slash:clone(Card.Club, 2),
    danmu__slash:clone(Card.Club, 3),
    danmu__slash:clone(Card.Club, 3),
    danmu__slash:clone(Card.Club, 3),
    danmu__slash:clone(Card.Club, 3),
    danmu__slash:clone(Card.Diamond, 3),
    danmu__slash:clone(Card.Club, 4),
    danmu__slash:clone(Card.Club, 4),
    danmu__slash:clone(Card.Spade, 4),
    danmu__slash:clone(Card.Diamond, 4),
    danmu__slash:clone(Card.Club, 5),
    danmu__slash:clone(Card.Club, 6),
    danmu__slash:clone(Card.Heart, 6),
    danmu__slash:clone(Card.Club, 7),
    danmu__slash:clone(Card.Spade, 7),
    danmu__slash:clone(Card.Diamond, 7),
    danmu__slash:clone(Card.Club, 8),
    danmu__slash:clone(Card.Club, 8),
    danmu__slash:clone(Card.Spade, 8),
    danmu__slash:clone(Card.Spade, 8),
    danmu__slash:clone(Card.Diamond, 8),
    danmu__slash:clone(Card.Spade, 10),
    danmu__slash:clone(Card.Spade, 10),
    danmu__slash:clone(Card.Heart, 10),
    danmu__slash:clone(Card.Diamond, 10),
    danmu__slash:clone(Card.Club, 10),
    danmu__slash:clone(Card.Club, 10),
    danmu__slash:clone(Card.Club, 10),
    danmu__slash:clone(Card.Club, 11),
    danmu__slash:clone(Card.Club, 11),
    danmu__slash:clone(Card.Club, 11),
    danmu__slash:clone(Card.Heart, 11),
    danmu__slash:clone(Card.Heart, 11),
    danmu__slash:clone(Card.Spade, 11),
    danmu__slash:clone(Card.Spade, 11),
    danmu__slash:clone(Card.Heart, 12),
    danmu__slash:clone(Card.Spade, 12),
    danmu__slash:clone(Card.Spade, 12),


    cadan__jink:clone(Card.Heart, 2),
    cadan__jink:clone(Card.Diamond, 2),
    cadan__jink:clone(Card.Diamond, 2),
    cadan__jink:clone(Card.Diamond, 2),
    cadan__jink:clone(Card.Heart, 3),
    cadan__jink:clone(Card.Diamond, 3),
    cadan__jink:clone(Card.Heart, 4),
    cadan__jink:clone(Card.Diamond, 4),
    cadan__jink:clone(Card.Diamond, 6),
    cadan__jink:clone(Card.Diamond, 7),
    cadan__jink:clone(Card.Diamond, 8),
    cadan__jink:clone(Card.Diamond, 8),
    cadan__jink:clone(Card.Diamond, 9),
    cadan__jink:clone(Card.Heart, 9),
    cadan__jink:clone(Card.Heart, 10),
    cadan__jink:clone(Card.Diamond, 10),
    cadan__jink:clone(Card.Heart, 11),
    cadan__jink:clone(Card.Diamond, 11),
    cadan__jink:clone(Card.Heart, 12),

    jiu:clone(Card.Spade, 9),
    jiu:clone(Card.Club, 9),
    jiu:clone(Card.Club, 9),
    jiu:clone(Card.Diamond, 9),
    jiu:clone(Card.Diamond, 9),

    exinwan:clone(Card.Diamond, 11),
    exinwan:clone(Card.Club, 12),

    mashu__peach:clone(Card.Heart, 3),
    mashu__peach:clone(Card.Heart, 4),
    mashu__peach:clone(Card.Heart, 5),
    mashu__peach:clone(Card.Heart, 6),
    mashu__peach:clone(Card.Heart, 7),
    mashu__peach:clone(Card.Heart, 8),
    mashu__peach:clone(Card.Heart, 8),
    mashu__peach:clone(Card.Heart, 9),
    mashu__peach:clone(Card.Diamond, 3),
    mashu__peach:clone(Card.Diamond, 4),
    mashu__peach:clone(Card.Diamond, 12),

    guangxuemicai__eight_diagram:clone(Card.Spade, 2),
    tiangoudun__nioh_shield:clone(Card.Club, 2),
    GreenUFO:clone(Card.Diamond, 13),
    GreenUFO:clone(Card.Heart, 13),
    GreenUFO:clone(Card.Club, 13),
    RedUFO:clone(Card.Diamond, 13),
    RedUFO:clone(Card.Club, 13),
    louguan_sword__qinggang_sword:clone(Card.Spade, 4),
    bagualu_crossbow:clone(Card.Diamond, 1),
    yangsan:clone(Card.Club, 2),
    ganggenier__spear:clone(Card.Spade, 6),
    feixiangzhijian__halberd:clone(Card.Diamond, 5),
    huiwubang:clone(Card.Spade, 3),
    yichuipiao:clone(Card.Club, 9),
    penglaiyuzhi:clone(Card.Diamond, 1),
    wunvfu:clone(Card.Club, 12),
    bailoujian:clone(Card.Spade, 5),
    tuanshan:clone(Card.Heart, 5),
    nianxieji:clone(Card.Diamond, 10),
    laiwating__axe:clone(Card.Diamond, 11),
    sishenliandao__guding_blade:clone(Card.Spade, 2),
    yaoshi:clone(Card.Spade, 13),
    monvsaoba:clone(Card.Spade, 13),
    yinyangyu:clone(Card.Spade, 13),
    yinyangyu:clone(Card.Heart, 13),
    qingwamao:clone(Card.Club, 1),
    banling:clone(Card.Club, 1),
    jiudechibang:clone(Card.Spade, 9),
    modaoshu:clone(Card.Diamond, 12),
    toutao:clone(Card.Heart, 2),

    chengguanzhifa__dismantlement:clone(Card.Spade, 3),
    chengguanzhifa__dismantlement:clone(Card.Spade, 4),
    chengguanzhifa__dismantlement:clone(Card.Club, 4),
    chengguanzhifa__dismantlement:clone(Card.Club, 8),
    chengguanzhifa__dismantlement:clone(Card.Heart, 12),

    haorenka__nullification:clone(Card.Spade, 2),
    haorenka__nullification:clone(Card.Heart, 2),
    haorenka__nullification:clone(Card.Spade, 12),
    haorenka__nullification:clone(Card.Club, 12),
    haorenka__nullification:clone(Card.Diamond, 12),
    haorenka__nullification:clone(Card.Heart, 13),

    fengmozhen__indulgence:clone(Card.Spade, 9),
    fengmozhen__indulgence:clone(Card.Spade, 10),
    fengmozhen__indulgence:clone(Card.Heart, 10),

    dongqingwa__supply_shortage:clone(Card.Club, 5),
    dongqingwa__supply_shortage:clone(Card.Club, 6),

    xunlongchi__ex_nihilo:clone(Card.Heart, 7),
    xunlongchi__ex_nihilo:clone(Card.Heart, 8),
    xunlongchi__ex_nihilo:clone(Card.Heart, 9),

    zuidai__lightning:clone(Card.Heart, 1),
    zuidai__lightning:clone(Card.Spade, 1),

    xijian__snatch:clone(Card.Spade, 5),
    xijian__snatch:clone(Card.Diamond, 5),
    xijian__snatch:clone(Card.Spade, 6),
    xijian__snatch:clone(Card.Diamond, 6),

    danmuzhan__duel:clone(Card.Spade, 1),
    danmuzhan__duel:clone(Card.Club, 1),
    danmuzhan__duel:clone(Card.Diamond, 1),

    ditupao__archery_attack:clone(Card.Heart, 1),

    baiguiyexing__savage_assault:clone(Card.Spade, 7),
    baiguiyexing__savage_assault:clone(Card.Club, 7),
    baiguiyexing__savage_assault:clone(Card.Spade, 8),

    yanhui:clone(Card.Heart, 1),

    wugufengdeng__amazing_grace:clone(Card.Heart, 3),
    wugufengdeng__amazing_grace:clone(Card.Heart, 4),

    renxingcaokong__collateral:clone(Card.Club, 13),
    renxingcaokong__collateral:clone(Card.Diamond, 13),

    saiqianxiang:clone(Card.Spade, 1),
    saiqianxiang:clone(Card.Spade, 11),

})
return extension
