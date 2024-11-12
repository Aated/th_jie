local extension = Package:new("LoR_EGO_cards", Package.CardPack)
extension.extensionName = "th_jie"
local LoR_Utility = require "packages/th_jie/LoR_Utility"
local U = require "packages/utility/utility"

Fk:loadTranslationTable {
    ["LoR_EGO_cards"] = "图书馆E.G.O卡组"
}


local slash = Fk:cloneCard("slash")
--尸横遍野：
--基本牌，黑桃K，出牌阶段，你选择任意名其他目标，视为对其使用一张【杀】。若此【杀】造成伤害，则其获得5层【流血-LoR】
local ShiHengBianYe__slash_skill = fk.CreateActiveSkill {
    name = "ShiHengBianYe__slash_skill",
    prompt = "#ShiHengBianYe__slash_skill",
    max_target_num = function()
        return #Fk:currentRoom().alive_players - 1
    end,
    min_target_num = 0,
    can_use = function(self, player, card, extra_data)
        return player.phase ~= Player.Play or (extra_data and extra_data.bypass_times) or
            table.find(Fk:currentRoom().alive_players, function(p1)
                if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 1) then
                    return p1
                end
            end)
    end,
    mod_target_filter = function(self, to_select, selected, user, card)
        return user ~= to_select
    end,
    target_filter = function(self, to_select, selected, _, card)
        return self:modTargetFilter(to_select, selected, Self.id, card)
    end,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
    end,
    on_effect = function(self, room, effect)
        local to = effect.to
        local from = effect.from
        room:damage({
            from = room:getPlayerById(from),
            to = room:getPlayerById(to),
            card = effect.card,
            damage = 1,
            skillName = self.name
        })
    end
}
local ShiHengBianYe_Damage = fk.CreateTriggerSkill {
    name = "ShiHengBianYe_Damage",
    mute = true,
    global = true,
    priority = 0.5,
    events = { fk.Damage },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return data.from == player and data.card and data.card.name == "ShiHengBianYe__slash"
    end,
    on_use = function(self, event, target, player, data)
        player.room:addPlayerMark(data.to, "@LiuXue_LoR", 5)
        player.room:sendLog {
            type = "#MarkChanging"
        }
    end,
}

local ShiHengBianYe__slash = fk.CreateBasicCard {
    name = "ShiHengBianYe__slash",
    number = 13,
    suit = Card.Spade,
    skill = ShiHengBianYe__slash_skill,
    is_damage_card = true,
}

Fk:addSkill(ShiHengBianYe_Damage)

Fk:loadTranslationTable {
    ["ShiHengBianYe__slash"] = "尸横遍野",
    ["ShiHengBianYe_Damage"] = "尸横遍野",
    ["ShiHengBianYe__slash_skill"] = "尸横遍野",
    ["#ShiHengBianYe__slash_skill"] = "尸横遍野:对任意名其他角色使用一张【杀】，若此【杀】造成伤害，则其获得5层【流血-LoR】",
    [":ShiHengBianYe__slash"] = "<b>牌名：</b>尸横遍野<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：任意名其他角色<br /><b>效果</b>：视为对其使用一张【杀】。若此【杀】造成伤害，则其获得5层【流血-LoR】" .. Fk:translate("LiuXue_jieshao"),
}

--血雾弥漫：
--锦囊牌，红桃A，
--你随机弃置其x张牌，令其获得x（向上取整）层【流血-LoR】（x为其当前体力值）


local XueWuMiMan_skill = fk.CreateActiveSkill {
    name = "XueWuMiMan_skill",
    prompt = "#XueWuMiMan_skill",
    mod_target_filter = function(self, to_select, selected, user, card)
        return user ~= to_select
    end,
    target_filter = function(self, to_select, selected, _, card)
        if #selected < self:getMaxTargetNum(Self, card) then
            return self:modTargetFilter(to_select, selected, Self.id, card)
        end
    end,
    target_num = 1,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
    end,
    on_effect = function(self, room, effect)
        local to = room:getPlayerById(effect.to)
        local ids = table.filter(to:getCardIds("he"), function(id)
            return not to:prohibitDiscard(Fk:getCardById(id))
        end)
        room:throwCard(table.random(ids, to.hp), self.name, to)
        room:addPlayerMark(to, "@LiuXue_LoR", to.hp)
    end,
}

local XueWuMiMan = fk.CreateTrickCard {
    name = "XueWuMiMan",
    number = 1,
    suit = Card.Heart,
    skill = XueWuMiMan_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["XueWuMiMan"] = "血雾弥漫",
    ["XueWuMiMan_skill"] = "血雾弥漫",
    ["#XueWuMiMan_skill"] = "血雾弥漫:你随机弃置其x张牌，令其获得x层【流血-LoR】(x为其当前体力值)",
    [":XueWuMiMan"] = "<b>牌名：</b>血雾弥漫<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br /><b>效果</b>：你随机弃置其x张牌，令其获得x层【流血-LoR】(x为其当前体力值)" .. Fk:translate("LiuXue_jieshao"),
}


local Malkuth_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Malkuth_Angela_EGO_skill",
    prompt = "#Malkuth_Angela_EGO_skill",
    can_use = Util.AoeCanUse,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
        if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
            cardUseEvent.tos = {}
            for _, player in ipairs(room:getOtherPlayers(room:getPlayerById(cardUseEvent.from))) do
                if not room:getPlayerById(cardUseEvent.from):isProhibited(player, cardUseEvent.card) then
                    TargetGroup:pushTargets(cardUseEvent.tos, player.id)
                end
            end
        end
    end,
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        return user ~= to_select
    end,
    on_effect = function(self, room, effect)
        local cardResponded1 = room:askForResponse(room:getPlayerById(effect.to), "Malkuth_Angela_EGO", 'slash',
        "#Malkuth_Angela_EGO_skill-prompt", true)
        if cardResponded1 then
            room:responseCard({
                from = effect.to,
                card = cardResponded1,
                responseToEvent = effect,
            })
        else
            room:damage({
                from = room:getPlayerById(effect.from),
                to = room:getPlayerById(effect.to),
                card = effect.card,
                damage = 2,
                damageType = fk.FireDamage,
                skillName = self.name,
            })
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_Fire", 2)
            return true
        end
        local cardResponded2 = room:askForResponse(room:getPlayerById(effect.to), "Malkuth_Angela_EGO", 'jink',
        "#Malkuth_Angela_EGO_skill-prompt", true)
        if cardResponded2 then
            room:responseCard({
                from = effect.to,
                card = cardResponded2,
                responseToEvent = effect,
            })
        else
            room:damage({
                from = room:getPlayerById(effect.from),
                to = room:getPlayerById(effect.to),
                card = effect.card,
                damage = 2,
                damageType = fk.FireDamage,
                skillName = self.name,
            })
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_Fire", 2)
        end
    end
}
local Malkuth_Angela_EGO = fk.CreateTrickCard {
    name = "Malkuth_Angela_EGO",
    number = 4,
    suit = Card.Diamond,
    skill = Malkuth_Angela_EGO_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["Malkuth_Angela_EGO"] = "昂首阔步的信念",
    ["Malkuth_Angela_EGO_skill"] = "昂首阔步的信念",
    [":Malkuth_Angela_EGO"] = "<b>牌名：</b>昂首阔步的信念<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有其他角色<br /><b>效果</b>：每名目标角色需打出一张【杀】和一张【闪】，否则受到2点火焰伤害并获得2层【烧伤】。" .. Fk:translate("LoR_Fire_jieshao"),
    ["#Malkuth_Angela_EGO_skill"] = "昂首阔步的信念:所有其他角色需打出一张【杀】和一张【闪】，否则受到2点火焰伤害并获得2层【烧伤】。",
    ["#Malkuth_Angela_EGO_skill-prompt"] = "昂首阔步的信念:你需打出一张【杀】和一张【闪】，否则受到2点火焰伤害并获得2层【烧伤】。"

}


local Yesod_Angela_EGO__slash_skill = fk.CreateActiveSkill {
    name = "Yesod_Angela_EGO__slash_skill",
    prompt = "#Yesod_Angela_EGO__slash_skill",
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
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
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
local Yesod_Angela_EGO__slash = fk.CreateBasicCard {
    name = "Yesod_Angela_EGO__slash",
    number = 3,
    suit = Card.Club,
    skill = Yesod_Angela_EGO__slash_skill,
    is_damage_card = true,
}
local Yesod_Angela_EGO_skill_trigger = fk.CreateTriggerSkill {
    name = "#Yesod_Angela_EGO_skill_trigger",
    mute = true,
    global = true,
    frequency = Skill.Compulsory,
    events = { fk.TargetSpecified, fk.CardUsing, fk.CardEffectFinished },
    can_trigger = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TargetSpecified then
            if data.card and data.card.name == "Yesod_Angela_EGO__slash" then
                return target == player
            end
        elseif event == fk.CardUsing then
            return data.card and data.card.trueName == "jink" and target == player and player:getMark("LoR_Yesod") > 0 and
                data.toCard and data.toCard.name == "Yesod_Angela_EGO__slash"
        else
            return data.card and data.card.name == "Yesod_Angela_EGO__slash" and
                room:getPlayerById(data.to):getMark("LoR_Yesod") > 0
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TargetSpecified then
            data.fixedResponseTimes = data.fixedResponseTimes or {}
            data.fixedResponseTimes["jink"] = 3
            room:addPlayerMark(room:getPlayerById(data.to), "LoR_Yesod", 3)
        elseif event == fk.CardUsing then
            room:removePlayerMark(player, "LoR_Yesod")
        else
            room:addPlayerMark(room:getPlayerById(data.to), "@LoR_Hunluan",
                room:getPlayerById(data.to):getMark("LoR_Yesod"))
            room:removePlayerMark(room:getPlayerById(data.to), "LoR_Yesod",
                room:getPlayerById(data.to):getMark("LoR_Yesod"))
        end
    end,
}

Fk:addSkill(Yesod_Angela_EGO_skill_trigger)


Fk:loadTranslationTable {
    ["Yesod_Angela_EGO__slash"] = "卓尔不凡的理性",
    ["Yesod_Angela_EGO__slash_skill"] = "卓尔不凡的理性",
    ["#Yesod_Angela_EGO_skill_trigger"] = "卓尔不凡的理性",
    ["#Yesod_Angela_EGO__slash_skill"] = "卓尔不凡的理性:视为普通【杀】，需要3张【闪】抵消，[命中时]令目标获得X层【混乱】（X为3-你使用的【闪】数量）",
    [":Yesod_Angela_EGO__slash"] = "<b>牌名：</b>卓尔不凡的理性<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br /><b>效果</b>：视为普通【杀】，需要3张【闪】抵消，[命中时]令目标获得X层【混乱】（X为3-你使用的【闪】数量）" .. Fk:translate("LoR_Hunluan_jieshao"),
}



local Hod_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Hod_Angela_EGO_skill",
    prompt = "#Hod_Angela_EGO_skill",
    mod_target_filter = function(self, to_select, selected, user, card)
        return user ~= to_select
    end,
    target_filter = function(self, to_select, selected, _, card)
        if #selected < self:getMaxTargetNum(Self, card) then
            return self:modTargetFilter(to_select, selected, Self.id, card)
        end
    end,
    target_num = 1,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
    end,
    on_effect = function(self, room, effect)
        local to = room:getPlayerById(effect.to)
        room:addPlayerMark(to, "@LoR_aiyi", 3)
        room:addPlayerMark(to, "@LiuXue_LoR", 3)
        room:addPlayerMark(to, "@LoR_Fire", 3)
        room:addPlayerMark(to, "@LoR_Hunluan", 3)
    end,
}

local Hod_Angela_EGO = fk.CreateTrickCard {
    name = "Hod_Angela_EGO",
    number = 12,
    suit = Card.Club,
    skill = Hod_Angela_EGO_skill,
}

Fk:loadTranslationTable {
    ["Hod_Angela_EGO"] = "愈加善良的希望",
    [":Hod_Angela_EGO"] = "<b>牌名：</b>愈加善良的希望<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br /><b>效果</b>：令其获得【流血】【爱意】【烧伤】【混乱】各3层"
        .. Fk:translate("LiuXue_jieshao") .. Fk:translate("LoR_Aiyi_jieshao") .. Fk:translate("Shaoshang_jieshao") .. Fk:translate("LoR_Hunluan_jieshao"),
    ["Hod_Angela_EGO_skill"] = "愈加善良的希望",
    ["#Hod_Angela_EGO_skill"] = "愈加善良的希望：令一名其他角色获得【流血】【爱意】【烧伤】【混乱】各3层",
}


local Netzach_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Netzach_Angela_EGO_skill",
    prompt = "#Netzach_Angela_EGO_skill",
    mod_target_filter = function(self, to_select, selected, user, card)
        return user ~= to_select
    end,
    target_filter = function(self, to_select, selected, _, card)
        if #selected < self:getMaxTargetNum(Self, card) then
            return self:modTargetFilter(to_select, selected, Self.id, card)
        end
    end,
    max_target_num = function()
        return #Fk:currentRoom().alive_players - 1
    end,
    min_target_num = 1,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
    end,
    on_effect = function(self, room, effect)
        local cardResponded1 =room:askForResponse(room:getPlayerById(effect.to), "Netzach_Angela_EGO", 'jink',
        "#Netzach_Angela_EGO_skill-prompt", true)
        if cardResponded1 then
            room:responseCard({
                from = effect.to,
                card = cardResponded1,
                responseToEvent = effect,
            })
        else
            room:damage({
                from = room:getPlayerById(effect.from),
                to = room:getPlayerById(effect.to),
                card = effect.card,
                damage = 1,
                damageType = fk.FireDamage,
                skillName = self.name,
            })
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_aiyi", 1)
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_XuRuo", 1)
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_PoZhan", 1)
            return true
        end

        local cardResponded2 = room:askForResponse(room:getPlayerById(effect.to), "Netzach_Angela_EGO", 'jink',
        "#Netzach_Angela_EGO_skill-prompt", true)
        if cardResponded2 then
            room:responseCard({
                from = effect.to,
                card = cardResponded2,
                responseToEvent = effect,
            })
        else
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_aiyi", 1)
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_XuRuo", 1)
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_PoZhan", 1)
            return true
        end

        local cardResponded3 = room:askForResponse(room:getPlayerById(effect.to), "Netzach_Angela_EGO", 'jink',
        "#Netzach_Angela_EGO_skill-prompt", true)
        if cardResponded3 then
            room:responseCard({
                from = effect.to,
                card = cardResponded3,
                responseToEvent = effect,
            })
        else
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_XuRuo", 1)
            return true
        end
    end,
}
local Netzach_Angela_EGO = fk.CreateBasicCard {
    name = "Netzach_Angela_EGO",
    number = 5,
    suit = Card.Heart,
    skill = Netzach_Angela_EGO_skill,
}

Fk:loadTranslationTable {
    ["Netzach_Angela_EGO"] = "生存下去的勇气",
    [":Netzach_Angela_EGO"] = "<b>牌名：</b>生存下去的勇气<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：至少一名其他角色<br /><b>效果</b>：其需要打出3张【闪】才能完全抵消。打出0张【闪】时，受到1点伤害，获得【爱意】【虚弱】【破绽】各1层；" ..
        "仅打出1张【闪】时，获得【爱意】【虚弱】【破绽】各1层；仅打出2张【闪】时，获得1层【虚弱】" .. Fk:translate("LoR_Aiyi_jieshao") .. Fk:translate("LoR_XuRuo_jieshao") .. Fk:translate("LoR_PoZhan_jieshao"),
    ["Netzach_Angela_EGO_skill"] = "生存下去的勇气",
    ["#Netzach_Angela_EGO_skill"] = "生存下去的勇气：其需要打出3张【闪】才能完全抵消，否则根据其使用【闪】的数量，执行不同效果",
    ["#Netzach_Angela_EGO_skill-prompt"] = "生存下去的勇气：你需要打出3张【闪】才能完全抵消，否则根据其使用【闪】的数量，执行不同效果",
}


local Tiphereth_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Tiphereth_Angela_EGO_skill",
    prompt = "#Tiphereth_Angela_EGO_skill",
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        return user ~= to_select
    end,
    can_use = function(self, player, card)
        return #LoR_Utility.GetEnemies(Fk:currentRoom(), player) > 0
    end,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
        if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
            cardUseEvent.tos = {}
            local player = room:getPlayerById(cardUseEvent.from)
            for _, p in ipairs(LoR_Utility.GetEnemies(room,player)) do
                if not player:isProhibited(p, cardUseEvent.card) then
                    TargetGroup:pushTargets(cardUseEvent.tos, p.id)
                end
            end
        end
    end,
    on_effect = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local cardResponded1 = room:askForResponse(room:getPlayerById(effect.to), "Tiphereth_Angela_EGO", 'slash|9~13',
            "#Tiphereth_Angela_EGO_skill-prompt:" .. player.id, true)
        if cardResponded1 then
            room:responseCard({
                from = effect.to,
                card = cardResponded1,
                responseToEvent = effect,
            })
        else
            if not room:getPlayerById(effect.to):isNude() then
                room:throwCard(table.random(room:getPlayerById(effect.to):getCardIds("he"), 1), self.name,
                    room:getPlayerById(effect.to), room:getPlayerById(effect.from))
            end
            room:addPlayerMark(room:getPlayerById(effect.from), "@qiangzhuang", 1)
        end
    end
}
local Tiphereth_Angela_EGO = fk.CreateTrickCard {
    name = "Tiphereth_Angela_EGO",
    number = 7,
    suit = Card.Diamond,
    skill = Tiphereth_Angela_EGO_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["Tiphereth_Angela_EGO"] = "存在意义的憧憬",
    ["Tiphereth_Angela_EGO_skill"] = "存在意义的憧憬",
    [":Tiphereth_Angela_EGO"] = "<b>牌名：</b>存在意义的憧憬<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有敌方角色<br /><b>效果</b>：每名目标角色需打出一张不小于9点的【杀】，否则其随机弃置一张牌，你增加一层【强壮】。" .. Fk:translate("qiangzhuang_jieshao"),
    ["#Tiphereth_Angela_EGO_skill"] = "存在意义的憧憬:每名目标角色需打出一张不小于9点的【杀】，否则其随机弃置一张牌，然后你增加一层【强壮】。",
    ["#Tiphereth_Angela_EGO_skill-prompt"] = "存在意义的憧憬:你需打出一张不小于9点的【杀】，否则你随机弃置一张牌，然后%src增加一层【强壮】。"

}


local Gebura_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Gebura_Angela_EGO_skill",
    prompt = "#Gebura_Angela_EGO_skill",
    can_use = Util.AoeCanUse,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
        if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
            cardUseEvent.tos = {}
            for _, player in ipairs(room:getOtherPlayers(room:getPlayerById(cardUseEvent.from))) do
                if not room:getPlayerById(cardUseEvent.from):isProhibited(player, cardUseEvent.card) then
                    TargetGroup:pushTargets(cardUseEvent.tos, player.id)
                end
            end
        end
    end,
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        return user ~= to_select
    end,
    on_effect = function(self, room, effect)
        local player=room:getPlayerById(effect.from)
        local cardResponded1 = room:askForResponse(room:getPlayerById(effect.to), "Gebura_Angela_EGO", 'slash,jink|13',
        "#Gebura_Angela_EGO_skill-prompt:"..player.id, true)
        if cardResponded1 then
            room:responseCard({
                from = effect.to,
                card = cardResponded1,
                responseToEvent = effect,
            })
        else
            local pa = ".|13"
            local judge = {
                who = room:getPlayerById(effect.to),
                pattern = pa,
                reason = self.name
            }
            room:judge(judge)
            if judge.card.number < 13 then
                room:damage({
                    from = room:getPlayerById(effect.from),
                    to = room:getPlayerById(effect.to),
                    card = effect.card,
                    damage = 2,
                    skillName = self.name,
                })
                room:addPlayerMark(room:getPlayerById(effect.from), "@qiangzhuang", 1)
                room:addPlayerMark(room:getPlayerById(effect.to), "@qiangzhuang", 1)
                room:addPlayerMark(room:getPlayerById(effect.to), "@LiuXue_LoR", 5)
            end
        end
    end
}
local Gebura_Angela_EGO = fk.CreateTrickCard {
    name = "Gebura_Angela_EGO",
    number = 13,
    suit = Card.Heart,
    skill = Gebura_Angela_EGO_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["Gebura_Angela_EGO"] = "守护他人的决意",
    ["Gebura_Angela_EGO_skill"] = "守护他人的决意",
    [":Gebura_Angela_EGO"] = "<b>牌名：</b>守护他人的决意<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有其他角色<br /><b>效果</b>：" ..
        "每名目标角色需打出一张K点的【杀】或【闪】，否则进行一次判定，若判定点数小于K，你对其造成2点伤害，获得1层【强壮】，目标获得1层【强壮】和5层【流血】。"
        .. Fk:translate("qiangzhuang_jieshao") .. Fk:translate("LiuXue_jieshao"),
    ["#Gebura_Angela_EGO_skill"] = "守护他人的决意:每名其他角色需打出一张K点的【杀】或【闪】，否则进行一次判定，若判定点数小于K，你对其造成2点伤害，获得1层【强壮】，目标获得1层【强壮】和5层【流血】。",
    ["#Gebura_Angela_EGO_skill-prompt"] = "守护他人的决意:你需打出一张K点的【杀】或【闪】，否则进行一次判定，若判定点数小于K，%src对你造成2点伤害，%src获得1层【强壮】，你获得1层【强壮】和5层【流血】。"
}



local Chesed_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Chesed_Angela_EGO_skill",
    prompt = "#Chesed_Angela_EGO_skill",
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        return user ~= to_select
    end,
    can_use = function(self, player, card)
        local room = Fk:currentRoom()
        return #LoR_Utility.GetEnemies(room,Self)>0
    end,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
        if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
            cardUseEvent.tos = {}
            local player = room:getPlayerById(cardUseEvent.from)
            for _, p in ipairs(LoR_Utility.GetEnemies(room,player)) do
                if not player:isProhibited(p, cardUseEvent.card) then
                    TargetGroup:pushTargets(cardUseEvent.tos, p.id)
                end
            end
        end
    end,
    on_effect = function(self, room, effect)
        local player=room:getPlayerById(effect.from)
        local cardResponded1 = room:askForResponse(room:getPlayerById(effect.to), "Chesed_Angela_EGO", 'jink|.|heart',
        "#Chesed_Angela_EGO_skill-prompt:" .. player.id, true)
        if cardResponded1 then
            room:responseCard({
                from = effect.to,
                card = cardResponded1,
                responseToEvent = effect,
            })
        else
            local player = room:getPlayerById(effect.from)
            room:drawCards(table.random(LoR_Utility.GetFriends(room,player), 1)[1], 1, self.name)
            room:addPlayerMark(room:getPlayerById(effect.to), "@LoR_Hunluan", 1)
        end
    end
}
local Chesed_Angela_EGO = fk.CreateTrickCard {
    name = "Chesed_Angela_EGO",
    number = 10,
    suit = Card.Heart,
    skill = Chesed_Angela_EGO_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["Chesed_Angela_EGO"] = "值得托付的信任",
    ["Chesed_Angela_EGO_skill"] = "值得托付的信任",
    [":Chesed_Angela_EGO"] = "<b>牌名：</b>值得托付的信任<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有敌方角色<br /><b>效果</b>：每名目标角色需打出一张<font color='red'>♥</font>红桃【闪】，否则我方随机一名角色摸一张牌，目标角色获得一层【混乱】" .. Fk:translate("LoR_Hunluan_jieshao"),
    ["#Chesed_Angela_EGO_skill"] = "值得托付的信任:每名敌方角色需打出一张<font color='red'>♥</font>红桃【闪】，否则我方随机一名角色摸一张牌且目标角色获得一层【混乱】",
    ["#Chesed_Angela_EGO_skill-prompt"] = "值得托付的信任:你需打出一张<font color='red'>♥</font>红桃【闪】，否则%src友方随机一名角色摸一张牌且你获得一层【混乱】"

}


local Binah_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Binah_Angela_EGO_skill",
    prompt = "#Binah_Angela_EGO_skill",
    can_use = Util.AoeCanUse,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
        if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
            cardUseEvent.tos = {}
            for _, player in ipairs(room:getOtherPlayers(room:getPlayerById(cardUseEvent.from))) do
                if not room:getPlayerById(cardUseEvent.from):isProhibited(player, cardUseEvent.card) then
                    TargetGroup:pushTargets(cardUseEvent.tos, player.id)
                end
            end
        end
    end,
    mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
        return user ~= to_select
    end,
    on_effect = function(self, room, effect)
        local cardResponded1 = room:askForResponse(room:getPlayerById(effect.to), "Binah_Angela_EGO", 'jink|1~8',
        "#Binah_Angela_EGO_skill-prompt", true)
        if cardResponded1 then
            room:responseCard({
                from = effect.to,
                card = cardResponded1,
                responseToEvent = effect,
            })
        else
            local player = room:getPlayerById(effect.from)
            local damage = 1
            if player.hp <= player.maxHp // 2 then
                damage = damage + 1
            end
            if room:getPlayerById(effect.to).hp <= room:getPlayerById(effect.to).maxHp // 2 then
                damage = damage + 1
            end
            room:damage({
                from = room:getPlayerById(effect.from),
                to = room:getPlayerById(effect.to),
                card = effect.card,
                damage = damage,
                skillName = self.name,
            })
        end
    end
}
local Binah_Angela_EGO = fk.CreateTrickCard {
    name = "Binah_Angela_EGO",
    number = 1,
    suit = Card.Club,
    skill = Binah_Angela_EGO_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["Binah_Angela_EGO"] = "直面恐惧 斩断循环",
    ["Binah_Angela_EGO_skill"] = "直面恐惧 斩断循环",
    [":Binah_Angela_EGO"] = "<b>牌名：</b>直面恐惧 斩断循环<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有其他角色<br /><b>效果</b>：" ..
        "每名目标角色需打出一张1~8点的【闪】，否则受到1点伤害。若使用者当前体力不大于体力上限一半（向下取整），本次伤害+1；若目标角色的当前体力不大于体力上限一半（向下取整），本次伤害+1。"
        .. Fk:translate("qiangzhuang_jieshao") .. Fk:translate("LiuXue_jieshao"),
    ["#Binah_Angela_EGO_skill"] = "直面恐惧 斩断循环:每名目标角色需打出一张1~8点的【闪】，否则将会受到1~3点的基础伤害（具体看卡牌效果）。",
    ["#Binah_Angela_EGO_skill-prompt"] = "直面恐惧 斩断循环:你需打出一张1~8点的【闪】，否则将会受到1~3点的基础伤害（具体看卡牌效果）。"

}


local Hokma_Angela_EGO_skill = fk.CreateActiveSkill {
    name = "Hokma_Angela_EGO_skill",
    prompt = "#Hokma_Angela_EGO_skill",
    can_use = function(self, player, card)
        local room = Fk:currentRoom()
        for _, p in ipairs(LoR_Utility.GetFriends(room,Self)) do
            if not (card and player:isProhibited(p, card)) then
                return true
            end
        end
    end,
    on_use = function(self, room, cardUseEvent)
        room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
        if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
            cardUseEvent.tos = {}
            local player = room:getPlayerById(cardUseEvent.from)
            for _, p in ipairs(LoR_Utility.GetFriends(room,player)) do
                if not player:isProhibited(p, cardUseEvent.card) then
                    TargetGroup:pushTargets(cardUseEvent.tos, p.id)
                end
            end
        end
    end,
    on_effect = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.to)
        if target:getMark("@LoR_Hunluan") > 0 then
            room:removePlayerMark(target, "@LoR_Hunluan", math.min(target:getMark("@LoR_Hunluan"), 5))
        end
        if target:isWounded() then
            room:recover({
                who = target,
                num = 2,
                recoverBy = player,
                skillName = self.name,
                card = effect.card
            })
        end
    end
}
local Hokma_Angela_EGO = fk.CreateTrickCard {
    name = "Hokma_Angela_EGO",
    number = 5,
    suit = Card.Diamond,
    skill = Hokma_Angela_EGO_skill,
    is_damage_card = true,
}

Fk:loadTranslationTable {
    ["Hokma_Angela_EGO"] = "拥抱过去 创造未来",
    ["Hokma_Angela_EGO_skill"] = "拥抱过去 创造未来",
    [":Hokma_Angela_EGO"] = "<b>牌名：</b>拥抱过去 创造未来<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：所有我方角色<br /><b>效果</b>：每名目标角色回复2点体力；若拥有【混乱】，则移除至多5层【混乱】" .. Fk:translate("LoR_Hunluan_jieshao"),
    ["#Hokma_Angela_EGO_skill"] = "拥抱过去 创造未来:每名目标角色回复2点体力；若拥有【混乱】，则移除至多5层【混乱】。"
}


extension:addCards {
    ShiHengBianYe__slash,
    XueWuMiMan,
    Malkuth_Angela_EGO,
    Yesod_Angela_EGO__slash,
    Hod_Angela_EGO,
    Netzach_Angela_EGO,
    Tiphereth_Angela_EGO,
    Gebura_Angela_EGO,
    Chesed_Angela_EGO,
    Binah_Angela_EGO,
    Hokma_Angela_EGO,
}
return extension
