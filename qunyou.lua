local extension = Package:new("qunyou")
extension.extensionName = "th_jie"
Fk:loadTranslationTable {
    ["qunyou"] = "群友包",
    ["qunyou_bao"] = "群友",
}
local LoR_Utility = require "packages/th_jie/LoR_Utility"

local Qunyou_biyanluo = General:new(extension, "Qunyou_biyanluo", "qunyou_bao", 4, 4, 2)
Fk:appendKingdomMap("god", { "qunyou_bao" })

-- 百物语之主 碧烟萝 4/4

-- 　　夜话:每回合限一次，当你/其他角色使用牌指定其他角色/你为目标时，，你可以选择其一张牌扣置在你的武将牌上，称为“话”。

-- 　　起扉:觉醒技，当你的话大于等于5时，你可以回一点体力摸两张牌，获得《纵魉》

-- 　　纵魉:你的回合限一次，你可以移去x张话并摸x张牌，然后对x名角色造成x点伤害。

local Qunyou_biyanluo_yehua = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_yehua",
    anim_type = "special",
    events = { fk.TargetConfirming, fk.TargetSpecifying },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if not player.room:getPlayerById(data.to):isNude() and event == fk.TargetSpecifying and data.to ~= player.id then
                return true
            elseif not player.room:getPlayerById(data.from):isNude() and event == fk.TargetConfirming and data.from ~= player.id then
                return true
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local targetPlayer
        local room = player.room
        if event == fk.TargetSpecifying then
            targetPlayer = player.room:getPlayerById(data.to)
        elseif event == fk.TargetConfirming then
            targetPlayer = player.room:getPlayerById(data.from)
        end

        local chooseCard = room:askForCardChosen(player, targetPlayer, "he", self.name)
        player:addToPile("Qunyou_biyanluo_hua", chooseCard)
    end

}

local Qunyou_biyanluo_qifei = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_qifei",
    frequency = Skill.Wake,
    events = { fk.TargetConfirming, fk.TargetSpecifying },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    can_wake = function(self, event, target, player, data)
        return #player:getPile("Qunyou_biyanluo_hua") >= 5 and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:recover({
            who = player,
            num = 1,
            skillName = self.name
        })
        player:drawCards(2, self.name)
        room:handleAddLoseSkills(player, "Qunyou_biyanluo_zongliang", nil, true, false)
    end
}

local Qunyou_biyanluo_zongliang = fk.CreateActiveSkill {
    name = "Qunyou_biyanluo_zongliang",
    anim_type = "offensive",
    expand_pile = "Qunyou_biyanluo_hua",
    min_card_num = 0,
    max_card_num = function()
        return math.min(#Fk:currentRoom().alive_players, #Self:getPile("Qunyou_biyanluo_hua"))
    end,
    can_use = function(self, player)
        return #player:getPile("Qunyou_biyanluo_hua") > 0
    end,
    card_filter = function(self, to_select, selected)
        local a = math.max(1, 1)
        return Self:getPileNameOfId(to_select) == "Qunyou_biyanluo_hua"
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        room:throwCard(effect.cards, self.name, player, player)
        player:drawCards(#effect.cards, self.name)
        local targetplayers = room:askForChoosePlayers(player, table.map(room:getAlivePlayers(), Util.IdMapper),
            #effect.cards, #effect.cards, "#Qunyou_biyanluo_zongliang", self.name, false)
        if targetplayers == nil or #targetplayers <= 0 then
            targetplayers = {}
            table.insertTableIfNeed(targetplayers,
                table.random(table.map(room:getAlivePlayers(), Util.IdMapper), #effect.cards))
        end
        for _, target in ipairs(targetplayers) do
            room:damage({
                to = room:getPlayerById(target),
                damage = #effect.cards,
            })
        end
    end,
}


Qunyou_biyanluo:addSkill(Qunyou_biyanluo_yehua)
Qunyou_biyanluo:addSkill(Qunyou_biyanluo_qifei)
Qunyou_biyanluo:addRelatedSkill(Qunyou_biyanluo_zongliang)


Fk:loadTranslationTable {
    ["Qunyou_biyanluo"] = "碧烟萝",
    ["#Qunyou_biyanluo"] = "百物语之主",
    ["designer:Qunyou_biyanluo"] = "澪汐",
    ["qunyou_bao"] = "群友",

    ["Qunyou_biyanluo_yehua"] = "夜话",
    [":Qunyou_biyanluo_yehua"] = "当你/其他角色使用牌指定其他角色/你为目标时，你可以选择其一张牌扣置在你的武将牌上，称为“话”",


    ["Qunyou_biyanluo_hua"] = "话",

    ["Qunyou_biyanluo_qifei"] = "起扉",
    [":Qunyou_biyanluo_qifei"] = "觉醒技，当你的话大于等于5时，你可以回一点体力摸两张牌，获得【纵魉】",

    ["Qunyou_biyanluo_zongliang"] = "纵魉",
    [":Qunyou_biyanluo_zongliang"] = "你可以移去x张话并摸x张牌，然后令x名角色受到x点无来源伤害。",
    ["#Qunyou_biyanluo_zongliang"] = "请选择任意名角色造成伤害"
}

--rem  3/4

--bug:锁定技，你每使用一张牌，需弃置一张手牌，然后摸一张牌。
--若你弃置的牌与上一次以此法弃置的牌种类不同，你摸一张牌，否则流失一点体力。
--回合结束时，若你以此法弃置过所有种类的牌，你回复一点体力。



--连心:限定技:你进入濒死时，可以将武将牌替换为一张牌名带有“碧烟萝”的武将牌，
--然后复原武将牌，弃置区域内所有牌然后摸四张牌。将体力值回复止2点。
local Qunyou_Rem = General:new(extension, "Qunyou_Rem", "qunyou_bao", 3, 4, 1)

local Qunyou_Rem_bug = fk.CreateTriggerSkill {
    name = "Qunyou_Rem_bug",
    anim_type = "drawcard",
    events = { fk.CardUsing },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_cost = function(self, event, target, player, data)
        if player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
            player.room:setPlayerMark(player, "bug1", 0)
        end
        return true
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local discard = room:askForDiscard(player, 1, 1, false, self.name, false)
        if #discard==0 then
            discard=table.random(player:getCardIds("h"),1)
            room:throwCard(discard,self.name,player,player)
        end
        player:drawCards(1, self.name)
        if Fk:getCardById(discard[1]).type ~= player:getMark("bug1") then
            player:drawCards(1, self.name)
        else
            room:loseHp(player, 1, self.name)
        end
        local mark = player:getTableMark("@bug2")
        room:setPlayerMark(player, "bug1", Fk:getCardById(discard[1]).type)
        room:setPlayerMark(player, "@bug1", LoR_Utility.getBugMarkValue(Fk:getCardById(discard[1]).type))
        if table.insertIfNeed(mark, LoR_Utility.getBugMarkValue(Fk:getCardById(discard[1]).type) .. "_char") then
            room:setPlayerMark(player, "@bug2", mark)
        end
    end,
}

local Qunyou_Rem_bug_turnend = fk.CreateTriggerSkill {
    name = "#Qunyou_Rem_bug_turnend",
    anim_type = "support",
    events = { fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(Qunyou_Rem_bug) and #player:getTableMark("@bug2") > 0
    end,
    on_use = function(self, event, target, player, data)
        if #player:getTableMark("@bug2") == 3 then
            player.room:recover({
                who = player,
                num = 1,
                skillName = "Qunyou_Rem_bug"
            })
        end
        player.room:setPlayerMark(player, "@bug2", 0)
    end
}

local Qunyou_Rem_lianxin = fk.CreateTriggerSkill {
    name = "Qunyou_Rem_lianxin",
    anim_type = "big",
    frequency = Skill.Limited,
    events = { fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local hero = { "Qunyou_biyanluo", "Qunyou_biyanluo_jueti" }
        room:changeHero(player, hero[math.random(2)], false, player.deputyGeneral == "Qunyou_Rem", false)
        player:reset()
        player:throwAllCards("hej")
        player:drawCards(2, self.name)
        room:changeHp(player, 2 - player.hp)
    end,
}

Qunyou_Rem_bug:addRelatedSkill(Qunyou_Rem_bug_turnend)
Qunyou_Rem:addSkill(Qunyou_Rem_bug)
Qunyou_Rem:addSkill(Qunyou_Rem_lianxin)

Fk:loadTranslationTable {
    ["Qunyou_Rem"] = "Rem",
    ["#Qunyou_Rem"] = "Bug小能手",
    ["designer:Qunyou_Rem"] = "澪汐",

    ["Qunyou_Rem_bug"] = "bug",
    ["#Qunyou_Rem_bug_turnend"] = "bug",
    [":Qunyou_Rem_bug"] = "锁定技，你每使用一张牌，需弃置一张手牌，然后摸一张牌。若你弃置的牌与上一次以此法弃置的牌种类不同，你摸一张牌，否则流失一点体力。回合结束时，若你以此法弃置过所有种类的牌，你回复一点体力。",


    ["Qunyou_Rem_lianxin"] = "连心",
    [":Qunyou_Rem_lianxin"] = "限定技:你进入濒死时，可以将武将牌替换为一张牌名带有“碧烟萝”的武将牌，然后复原武将牌，弃置区域内所有牌然后摸四张牌。将体力值回复止2点。",


    ["@bug1"] = "bug1",
    ["@bug2"] = "bug2",
}


-- 　　绝体绝命 碧烟罗  3/7

-- 　　向死:锁定技。每当你失去牌时，你摸|x-y|张牌。每当你获得多于一张牌时，你对自己造成一点伤害。（x为已损失体力值，y为体力值）

-- 　　夕往:每个回合开始时，你可以让一名角色是否交给你x张牌。若交给你牌，则本回合向死失效，回合结束时你回复一点体力。(x为体力值）

-- 　　坏灭:使命技。
--         成功：当你因【夕往】回复体力至体力上限时。修改【夕往】，获得【光道】。
--         失败：当你进入濒死时，你减一点体力上限，将体力值回复至上限。失去【夕往】修改【向死】。

-- 　　向死·改:锁定技。每当你失去牌时，你摸|x-y|张牌。每当你获得多于一张牌时，你对自己与一名角色造成一点伤害。你进入濒死时，扣减一点体力上限，回复体力至一点。

-- 　　夕往·改:每个回合开始时，你可以让一名角色交给你至多y张牌。若交给你牌，回合结束时你回复一点体力。

-- 　　光道:每当你获得牌时，你可以让一名其他角色摸一张牌，每当你回复体力时，你可以令一名其他角色回复一点体力。

local Qunyou_biyanluo_jueti = General:new(extension, "Qunyou_biyanluo_jueti", "qunyou_bao", 3, 7, 2)
local Qunyou_biyanluo_jueti_black = General:new(extension, "Qunyou_biyanluo_jueti_black", "qunyou_bao", 3, 7, 2)
Qunyou_biyanluo_jueti_black.total_hidden = true
local Qunyou_biyanluo_jueti_white = General:new(extension, "Qunyou_biyanluo_jueti_white", "qunyou_bao", 3, 7, 2)
Qunyou_biyanluo_jueti_white.total_hidden = true
local Qunyou_biyanluo_jueti_xiangsi = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_jueti_xiangsi",
    frequency = Skill.Compulsory,
    anim_type = "drawcard",
    events = { fk.AfterCardsMove },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            for _, move in ipairs(data) do
                if move.from == player.id then
                    for _, info in ipairs(move.moveInfo) do
                        if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                            return true
                        end
                    end
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local hp_lost = player.maxHp - player.hp
        local hp_now = player.hp
        player:drawCards(math.abs(hp_lost - hp_now), self.name)
    end,
}

local Qunyou_biyanluo_jueti_xiangsi_damage = fk.CreateTriggerSkill {
    name = "#Qunyou_biyanluo_jueti_xiangsi_damage",
    frequency = Skill.Compulsory,
    anim_type = "drawcard",
    events = { fk.AfterCardsMove },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            for _, move in ipairs(data) do
                if move.to == player.id and move.toArea == Card.PlayerHand then
                    if #move.moveInfo > 1 then
                        return true
                    end
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        player.room:loseHp(player, 1, self.name)
    end,
}

local Qunyou_biyanluo_jueti_xiwang = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_jueti_xiwang",
    anim_type = "control",
    events = { fk.TurnStart, fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and
            ((event == fk.TurnEnd and player:getMark("Qunyou_biyanluo_jueti_xiwang") > 0) or event ~= fk.TurnEnd)
    end,
    on_cost = function(self, event, target, player, data)
        if event == fk.TurnStart then
            local invoke = player.room:askForSkillInvoke(player, self.name)
            if invoke == false then
                return false
            end
            local chooseplayer = player.room:askForChoosePlayers(player,
                table.map(player.room:getOtherPlayers(player), function(e)
                    return e.id
                end), 1, 1, "#Qunyou_biyanluo_jueti_xiwang_player:::" .. player.hp, self.name, true)
            if chooseplayer and #chooseplayer > 0 then
                self.cost_data = player.room:getPlayerById(chooseplayer[1])
                return true
            end
        else
            return true
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TurnStart then
            local chooseplayer = self.cost_data
            local cards = room:askForCardsChosen(chooseplayer, chooseplayer, player.hp, player.hp, "he", self.name,
                "#Qunyou_biyanluo_jueti_xiwang_cards:" .. player.id .. "::" .. player.hp)
            if cards and #cards == player.hp then
                room:moveCardTo(cards, Player.Hand, player.id, fk.ReasonGive, self.name, nil, false, player.id)
                player:addMark("Qunyou_biyanluo_jueti_xiwang-turn", 1)
                player:addMark("Qunyou_biyanluo_jueti_xiwang", 1)
            end
        else
            room:recover({
                who = player,
                num = 1,
                skillName = self.name
            })
            player:removeMark("Qunyou_biyanluo_jueti_xiwang", 1)
        end
    end,
}

local Qunyou_biyanluo_jueti_xiwang_Invalidity = fk.CreateInvaliditySkill {
    name = "#Qunyou_biyanluo_jueti_xiwang _Invalidity",
    invalidity_func = function(self, from, skill)
        return from:getMark("Qunyou_biyanluo_jueti_xiwang-turn") > 0 and skill.name == "Qunyou_biyanluo_jueti_xiangsi"
    end
}

local Qunyou_biyanluo_jueti_huaimie = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_jueti_huaimie",
    frequency = Skill.Wake,
    mute = true,
    events = { fk.HpRecover, fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    end,
    can_wake = function(self, event, target, player, data)
        return (event == fk.HpRecover and player.hp == player.maxHp and data.skillName == "Qunyou_biyanluo_jueti_xiwang") or
            event == fk.EnterDying
    end,
    on_cost = Util.TrueFunc,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.HpRecover then
            LoR_Utility.ChangeGeneral(player, player.general, "Qunyou_biyanluo_jueti_white")
            room:notifySkillInvoked(player, self.name, "big")
            room:broadcastPlaySound("./packages/th_jie/audio/skill/Qunyou_biyanluo_jueti_huaimie1")
            player.room:handleAddLoseSkills(player,
                "-Qunyou_biyanluo_jueti_xiwang|-Qunyou_biyanluo_jueti_xiangsi|Qunyou_biyanluo_jueti_xiwang_gai|Qunyou_biyanluo_jueti_guangdao",
                nil, true, false)
        else
            LoR_Utility.ChangeGeneral(player, player.general, "Qunyou_biyanluo_jueti_black")
            room:changeMaxHp(player, -1)
            room:changeHp(player, 3 - player.hp, nil, self.name)
            room:notifySkillInvoked(player, self.name, "big")
            room:broadcastPlaySound("./packages/th_jie/audio/skill/Qunyou_biyanluo_jueti_huaimie2")
            player.room:handleAddLoseSkills(player,
                "-Qunyou_biyanluo_jueti_xiwang|Qunyou_biyanluo_jueti_xiangsi_gai|-Qunyou_biyanluo_jueti_xiangsi", nil,
                true, false)
        end
    end,
}

local Qunyou_biyanluo_jueti_xiangsi_gai = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_jueti_xiangsi_gai",
    frequency = Skill.Compulsory,
    anim_type = "support",
    events = { fk.AfterCardsMove, fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if event == fk.AfterCardsMove then
                for _, move in ipairs(data) do
                    if move.from == player.id then
                        for _, info in ipairs(move.moveInfo) do
                            if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                                return true
                            end
                        end
                    end
                end
            else
                return target == player and player.hp <= 0
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.AfterCardsMove then
            local hp_lost = player.maxHp - player.hp
            local hp_now = player.hp
            player:drawCards(math.abs(hp_lost - hp_now), self.name)
        elseif event == fk.EnterDying then
            room:changeMaxHp(player, -1)
            if player.maxHp > 0 then
                room:changeHp(player, 1 - player.hp, nil, self.name)
            end
        end
    end,
}
local Qunyou_biyanluo_jueti_xiangsi_gai_damage = fk.CreateTriggerSkill {
    name = "#Qunyou_biyanluo_jueti_xiangsi_gai_damage",
    frequency = Skill.Compulsory,
    anim_type = "drawcard",
    events = { fk.AfterCardsMove },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            for _, move in ipairs(data) do
                if move.to == player.id and move.toArea == Card.PlayerHand then
                    if #move.moveInfo > 1 then
                        return true
                    end
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        player.room:loseHp(player, 1, self.name)
        local chooseplayers = room:askForChoosePlayers(player, table.map(room.alive_players, function(e)
            return e.id
        end), 1, 1, "#Qunyou_biyanluo_jueti_xiangsi_gai-damage", self.name, false)
        local chooseplayer = room:getPlayerById(chooseplayers[1])
        player.room:damage({
            from = player,
            to = chooseplayer,
            damage = 1,
            by_user = false,
            skillName = self.name
        })
    end,
}

local Qunyou_biyanluo_jueti_xiwang_gai = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_jueti_xiwang_gai",
    anim_type = "support",
    events = { fk.TurnStart, fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and
            ((event == fk.TurnEnd and player:getMark("Qunyou_biyanluo_jueti_xiwang_gai") > 0) or event ~= fk.TurnEnd)
    end,
    on_cost = function(self, event, target, player, data)
        if event == fk.TurnStart then
            local invoke = player.room:askForSkillInvoke(player, self.name)
            if invoke == false then
                return false
            end
            local chooseplayer = player.room:askForChoosePlayers(player,
                table.map(player.room:getOtherPlayers(player), function(e)
                    return e.id
                end), 1, 1, "#Qunyou_biyanluo_jueti_xiwang_gai_player:::" .. player.hp, self.name, true)
            if chooseplayer and #chooseplayer > 0 then
                self.cost_data = player.room:getPlayerById(chooseplayer[1])
                return true
            end
        else
            return true
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TurnStart then
            local chooseplayer = self.cost_data
            local cards = room:askForCardsChosen(chooseplayer, chooseplayer, 0, player.hp, "he", self.name,
                "#Qunyou_biyanluo_jueti_xiwang_gai_cards:" .. player.id .. "::" .. player.hp)
            if cards and #cards > 0 then
                room:moveCardTo(cards, Player.Hand, player.id, fk.ReasonGive, self.name, nil, false, player.id)
                player:addMark("Qunyou_biyanluo_jueti_xiwang_gai", 1)
            end
        else
            room:recover({
                who = player,
                num = 1,
                skillName = self.name
            })
            player:removeMark("Qunyou_biyanluo_jueti_xiwang_gai", 1)
        end
    end
}

local Qunyou_biyanluo_jueti_guangdao = fk.CreateTriggerSkill {
    name = "Qunyou_biyanluo_jueti_guangdao",
    anim_type = "support",
    events = { fk.AfterCardsMove, fk.HpRecover },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if event == fk.AfterCardsMove then
                local room = player.room
                for _, move in ipairs(data) do
                    if move.to == player.id and move.toArea == Card.PlayerHand then
                        for _, info in ipairs(move.moveInfo) do
                            local id = info.cardId
                            if room:getCardArea(id) == Card.PlayerHand and room:getCardOwner(id) == player then
                                return true
                            end
                        end
                    end
                end
            elseif target == player then
                return true
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        local prompt
        if event == fk.AfterCardsMove then
            prompt = "#Qunyou_biyanluo_jueti_guangdao_draw"
        else
            prompt = "#Qunyou_biyanluo_jueti_guangdao_recover"
        end
        local invoke = room:askForSkillInvoke(player, self.name)
        if invoke == false then
            return false
        else
            local chooseplayer = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
                return p.id
            end), 1, 1, prompt, self.name, true)
            if chooseplayer and #chooseplayer > 0 then
                self.cost_data = room:getPlayerById(chooseplayer[1])
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local chooseplayer = self.cost_data
        if event == fk.AfterCardsMove then
            chooseplayer:drawCards(1, self.name)
        else
            room:recover({
                who = chooseplayer,
                num = 1,
                skillName = self.name
            })
        end
    end
}


Qunyou_biyanluo_jueti_xiwang:addRelatedSkill(Qunyou_biyanluo_jueti_xiwang_Invalidity)
Qunyou_biyanluo_jueti_xiangsi:addRelatedSkill(Qunyou_biyanluo_jueti_xiangsi_damage)
Qunyou_biyanluo_jueti_xiangsi_gai:addRelatedSkill(Qunyou_biyanluo_jueti_xiangsi_gai_damage)

Qunyou_biyanluo_jueti:addSkill(Qunyou_biyanluo_jueti_xiangsi)
Qunyou_biyanluo_jueti:addSkill(Qunyou_biyanluo_jueti_xiwang)
Qunyou_biyanluo_jueti:addSkill(Qunyou_biyanluo_jueti_huaimie)

Qunyou_biyanluo_jueti:addRelatedSkill(Qunyou_biyanluo_jueti_xiangsi_gai)
Qunyou_biyanluo_jueti:addRelatedSkill(Qunyou_biyanluo_jueti_xiwang_gai)
Qunyou_biyanluo_jueti:addRelatedSkill(Qunyou_biyanluo_jueti_guangdao)

Fk:loadTranslationTable {
    ["Qunyou_biyanluo_jueti"] = "碧烟萝",
    ["Qunyou_biyanluo_jueti_white"] = "碧烟萝",
    ["Qunyou_biyanluo_jueti_black"] = "碧烟萝",
    ["#Qunyou_biyanluo_jueti"] = "绝体绝命",
    ["designer:Qunyou_biyanluo_jueti"] = "澪汐",
    ["~Qunyou_biyanluo_jueti"] = "坠落乃吾之夙愿",
    ["~Qunyou_biyanluo_jueti_white"] = "吾之心，好痛苦",
    ["~Qunyou_biyanluo_jueti_black"] = "吾之心，好悲伤",

    ["Qunyou_biyanluo_jueti_xiangsi"] = "向死",
    [":Qunyou_biyanluo_jueti_xiangsi"] = "锁定技。每当你失去牌时，你摸|x-y|(绝对值)张牌。每当你获得多于一张牌时，你失去一点体力。（x为你已损失体力值，y为你当前体力值）",
    ["$Qunyou_biyanluo_jueti_xiangsi"] = "赤红之力啊",
    ["#Qunyou_biyanluo_jueti_xiangsi_damage"] = "向死",

    ["Qunyou_biyanluo_jueti_xiwang"] = "夕往",
    [":Qunyou_biyanluo_jueti_xiwang"] = "每个回合开始时，你可以让一名角色是否交给你x张牌。若交给你牌，则本回合向死失效，回合结束时你回复一点体力。(x为你当前体力值）",
    ["#Qunyou_biyanluo_jueti_xiwang_player"] = "你可以让一名角色是否交给你%arg张牌",
    ["#Qunyou_biyanluo_jueti_xiwang_cards"] = "你可以交给%src%arg张牌后其技能【向死】本回合无效且在本回合结束时回复一点体力或者不交",
    ["$Qunyou_biyanluo_jueti_xiwang"] = "展翅飞翔这堕落世界吧",


    ["Qunyou_biyanluo_jueti_huaimie"] = "坏灭",
    [":Qunyou_biyanluo_jueti_huaimie"] = "使命技。<br/>成功：当你因【夕往】回复体力至体力上限时。修改【夕往】，获得【光道】。<br/>失败：当你进入濒死时，你减一点体力上限，将体力值回复至上限。失去【夕往】修改【向死】。",
    ["$Qunyou_biyanluo_jueti_huaimie1"] = "现在正是，纯白时间",
    ["$Qunyou_biyanluo_jueti_huaimie2"] = "现在正是，漆黑时间",


    ["Qunyou_biyanluo_jueti_xiangsi_gai"] = "向死",
    [":Qunyou_biyanluo_jueti_xiangsi_gai"] = "锁定技。每当你失去牌时，你摸|x-y|张牌。每当你获得多于一张牌时，你失去一点体力，对一名角色造成一点伤害。你进入濒死时，扣减一点体力上限，回复体力至一点。（x为你已损失体力值，y为你当前体力值）",
    ["#Qunyou_biyanluo_jueti_xiangsi_gai-damage"] = "你选择一名角色令其受到你造成的伤害",
    ["$Qunyou_biyanluo_jueti_xiangsi_gai"] = "漆黑之力啊",
    ["#Qunyou_biyanluo_jueti_xiangsi_gai_damage"] = "向死",

    ["Qunyou_biyanluo_jueti_xiwang_gai"] = "夕往",
    [":Qunyou_biyanluo_jueti_xiwang_gai"] = "每个回合开始时，你可以让一名角色交给你至多x张牌。若交给你牌，回合结束时你回复一点体力。(x为你当前体力值）",
    ["#Qunyou_biyanluo_jueti_xiwang_gai_player"] = "你可以让一名角色至多交给你%arg张牌",
    ["#Qunyou_biyanluo_jueti_xiwang_gai_cards"] = "你可以交给%src至多%arg张牌，其获得牌后本回合结束时回复一点体力",
    ["$Qunyou_biyanluo_jueti_xiwang_gai"] = "吾之灵魂，与纯白共存",

    ["Qunyou_biyanluo_jueti_guangdao"] = "光道",
    [":Qunyou_biyanluo_jueti_guangdao"] = "每当你获得牌时，你可以让一名其他角色摸一张牌，每当你回复体力时，你可以令一名其他角色回复一点体力。",
    ["#Qunyou_biyanluo_jueti_guangdao_draw"] = "你可以令一名其他角色摸一张牌",
    ["#Qunyou_biyanluo_jueti_guangdao_recover"] = "你可以令一名其他角色回复一点体力",
    ["$Qunyou_biyanluo_jueti_guangdao"] = "纯白之力啊",

}


-- 满开の彼岸樱 西行寺·幽幽子 群友包 2/7
-- pve限定

-- 集春：锁定技，一名角色进入濒死时，若你的体力上限大于1，你失去一点体力上限并摸两张牌，然后你获得1个“春”。（春最多为5）

-- 集春·改:锁定技，一名角色进入濒死时，你摸一张牌并获得1个“春”，
-- 若此时你体力上限大于全场存活角色数，你失去一点体力上限。（春最多为5）

-- 绽樱:觉醒技，任意角色回合结束时，若你的“春”不小于3，你修改【集春】，并获得【亡我】、【春眠】和【死蝶】。

-- 亡我:锁定技，当你成为其他人基本牌的目标时，若你体力值不为全场最高，取消之。

-- 春眠:一名角色回合开始时，你可以移除1个“春”，令其直到回合结束前，其使用牌仅能选择你为目标。

-- 死蝶:每回合限两次，当你受到伤害后，你可以选择伤害来源至多一半（向下取整）的手牌置于你的武将牌上，
-- 你的弃牌阶段结束时弃置所有死蝶牌。你可以如手牌般使用或打出死蝶牌。

local Qunyou_ying_uuz = General:new(extension, "Qunyou_ying_uuz", "qunyou_bao", 2, 7, 2)

local Qunyou_ying_uuz_jichun = fk.CreateTriggerSkill {
    name = "Qunyou_ying_uuz_jichun",
    frequency = Skill.Compulsory,
    anim_type = "drawcard",
    events = { fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and player.maxHp > 1
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:changeMaxHp(player, -1)
        player:drawCards(2, self.name)
        local num = player:getMark("@Qunyou_ying_uuz_chun") + 1
        if num > 5 then
            num = 5
        end
        room:setPlayerMark(player, "@Qunyou_ying_uuz_chun", num)
    end
}

local Qunyou_ying_uuz_jichun_gai = fk.CreateTriggerSkill {
    name = "Qunyou_ying_uuz_jichun_gai",
    frequency = Skill.Compulsory,
    anim_type = "special",
    events = { fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and player.maxHp > 1
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        player:drawCards(1, self.name)
        local num = player:getMark("@Qunyou_ying_uuz_chun") + 1
        if num > 5 then
            num = 5
        end
        room:setPlayerMark(player, "@Qunyou_ying_uuz_chun", num)
        if player.maxHp > #room.alive_players then
            room:changeMaxHp(player, -1)
        end
    end
}

local Qunyou_ying_uuz_zhanying = fk.CreateTriggerSkill {
    name = "Qunyou_ying_uuz_zhanying",
    frequency = Skill.Wake,
    anim_type = "big",
    events = { fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    end,
    can_wake = function(self, event, target, player, data)
        return player:getMark("@Qunyou_ying_uuz_chun") >= 3
    end,
    on_use = function(self, event, target, player, data)
        player.room:handleAddLoseSkills(player,
            "-Qunyou_ying_uuz_jichun|Qunyou_ying_uuz_jichun_gai|Qunyou_ying_uuz_wangwo|Qunyou_ying_uuz_chunmian|Qunyou_ying_uuz_sidie",
            nil, true, false)
    end,
}

local Qunyou_ying_uuz_wangwo = fk.CreateTriggerSkill {
    name = "Qunyou_ying_uuz_wangwo",
    frequency = Skill.Compulsory,
    anim_type = "defensive",
    events = { fk.TargetConfirming },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) and data.from ~= player.id and data.card and data.card.type == Card.TypeBasic then
            for _, p in ipairs(player.room:getOtherPlayers(player)) do
                if p.hp > player.hp then
                    return true
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        AimGroup:cancelTarget(data, player.id)
        AimGroup:setTargetDone(data.tos, player.id)
    end,
}

local Qunyou_ying_uuz_chunmian = fk.CreateTriggerSkill {
    name = "Qunyou_ying_uuz_chunmian",
    anim_type = "support",
    prompt = "#Qunyou_ying_uuz_chunmian",
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target ~= player and player:hasSkill(self) and player:getMark("@Qunyou_ying_uuz_chun") > 0
            and player:getMark("@Qunyou_ying_uuz_chunmian-turn") == 0
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:removePlayerMark(player, "@Qunyou_ying_uuz_chun")
        room:setPlayerMark(target, "@Qunyou_ying_uuz_chunmian-turn", 1)
        room:setPlayerMark(player, "@Qunyou_ying_uuz_chunmian-turn", 1)
    end,
}

local Qunyou_ying_uuz_chunmian_prohibit = fk.CreateTriggerSkill {
    name = "#Qunyou_ying_uuz_chunmian_prohibit",
    frequency = Skill.Compulsory,
    mute = true,
    events = { fk.TargetConfirmed },
    can_trigger = function(self, event, target, player, data)
        local room = player.room
        if data.from == nil then
            return false
        end
        local from = room:getPlayerById(data.from)
        if target == player and from:getMark("@Qunyou_ying_uuz_chunmian-turn") > 0 and data.card then
            if player:getMark("@Qunyou_ying_uuz_chunmian-turn") == 0 then
                return true
            else
                if player:hasSkill(Qunyou_ying_uuz_chunmian, true) == false or
                    player:usedSkillTimes("Qunyou_ying_uuz_chunmian", Player.HistoryTurn) == 0 then
                    return true
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local uuz
        for _, p in ipairs(player.room.alive_players) do
            if p:hasSkill(Qunyou_ying_uuz_chunmian) and
                p:usedSkillTimes("Qunyou_ying_uuz_chunmian", Player.HistoryTurn) > 0 then
                uuz = p
            end
        end
        if uuz ~= nil then
            room:notifySkillInvoked(uuz, self.name, "defensive")
        end
        table.insertIfNeed(data.nullifiedTargets, player.id)
        return true
    end,
}

local Qunyou_ying_uuz_sidie = fk.CreateTriggerSkill {
    name = "Qunyou_ying_uuz_sidie",
    anim_type = "control",
    events = { fk.Damaged },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and data.from and #data.from.player_cards[Player.Hand] > 1 and
            player:usedSkillTimes(self.name, Player.HistoryTurn) <= 1
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        return room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local cards = player.room:askForCardsChosen(player, data.from, 0, #data.from.player_cards[Player.Hand] / 2, "h",
            self.name, "#Qunyou_ying_uuz_sidie")
        if #cards > 0 then
            player:addToPile("sidie&", cards, true, self.name)
        end
    end,
}

local Qunyou_ying_uuz_sidie_discard = fk.CreateTriggerSkill {
    name = "#Qunyou_ying_uuz_sidie_discard",
    events = { fk.EventPhaseChanging },
    frequency = Skill.Compulsory,
    mute = true,
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill("Qunyou_ying_uuz_sidie") then return false end
        return target == player and data.to == Player.Finish and #player:getPile("sidie&") > 0
    end,
    on_use = function(self, event, target, player, data)
        player.room:moveCards({
            from = player.id,
            ids = player:getPile("sidie&"),
            toArea = Card.DiscardPile,
            moveReason = fk.ReasonPutIntoDiscardPile,
            skillName = "Qunyou_ying_uuz_sidie",
        })
    end,
}


Qunyou_ying_uuz_chunmian:addRelatedSkill(Qunyou_ying_uuz_chunmian_prohibit)
Qunyou_ying_uuz_sidie:addRelatedSkill(Qunyou_ying_uuz_sidie_discard)

Qunyou_ying_uuz:addSkill(Qunyou_ying_uuz_jichun)
Qunyou_ying_uuz:addRelatedSkill(Qunyou_ying_uuz_jichun_gai)
Qunyou_ying_uuz:addSkill(Qunyou_ying_uuz_zhanying)
Qunyou_ying_uuz:addRelatedSkill(Qunyou_ying_uuz_wangwo)
Qunyou_ying_uuz:addRelatedSkill(Qunyou_ying_uuz_chunmian)
Qunyou_ying_uuz:addRelatedSkill(Qunyou_ying_uuz_sidie)

Fk:loadTranslationTable {
    ["Qunyou_ying_uuz"] = "樱·幽幽子",
    ["#Qunyou_ying_uuz"] = "满开の彼岸樱",
    ["designer:Qunyou_ying_uuz"] = "Yuyuko",

    ["Qunyou_ying_uuz_jichun"] = "集春",
    [":Qunyou_ying_uuz_jichun"] = "锁定技，一名角色进入濒死时，若你的体力上限大于1，你失去一点体力上限并摸两张牌，然后你获得1个“春”。（春最多为5）",
    ["@Qunyou_ying_uuz_chun"] = "春",

    ["Qunyou_ying_uuz_jichun_gai"] = "集春",
    [":Qunyou_ying_uuz_jichun_gai"] = "锁定技，一名角色进入濒死时，你摸一张牌并获得1个“春”，若此时你体力上限大于全场存活角色数，你失去一点体力上限。（春最多为5）",

    ["Qunyou_ying_uuz_zhanying"] = "绽樱",
    [":Qunyou_ying_uuz_zhanying"] = "觉醒技，任意角色回合结束时，若你的“春”不小于3，你修改【集春】，并获得【亡我】、【春眠】和【死蝶】。",

    ["Qunyou_ying_uuz_wangwo"] = "亡我",
    [":Qunyou_ying_uuz_wangwo"] = "锁定技，当你成为其他人基本牌的目标时，若你体力值不为全场最高，取消之。",

    ["Qunyou_ying_uuz_chunmian"] = "春眠",
    [":Qunyou_ying_uuz_chunmian"] = "其他角色回合开始时，你可以移除1个“春”，令其直到回合结束前，其使用牌指定不为你的目标时，失效之。",
    ["@Qunyou_ying_uuz_chunmian-turn"] = "春眠",
    ["#Qunyou_ying_uuz_chunmian"] = "你可以移除1个“春”，令其直到回合结束前，其使用牌指定不为你的目标时，失效之。",
    ["#Qunyou_ying_uuz_chunmian_prohibit"] = "春眠",

    ["Qunyou_ying_uuz_sidie"] = "死蝶",
    [":Qunyou_ying_uuz_sidie"] = "每回合限两次，当你受到伤害后，你可以选择伤害来源至多一半（向下取整）的手牌置于你的武将牌上，你的弃牌阶段结束时弃置所有死蝶牌。你可以如手牌般使用或打出死蝶牌。",
    ["#Qunyou_ying_uuz_sidie"] = "你可以选择伤害来源至多一半（向下取整）的手牌置于你的武将牌上称为“死蝶”",
    ["#Qunyou_ying_uuz_sidie_discard"] = "死蝶",
    ["sidie&"] = "死蝶",
}


-- 万理之终焉 御射军神
-- 3/10
-- pve限定
-- 终幕:当你将要对其他角色造成伤害时，你可以失去一半体力上限（向上取整），使此伤害增加X点（X为你失去的体力上限）
-- 不夜:每轮限一次，回合结束时，若你的武将牌正面朝上，你可以翻面并执行一个额外回合
-- 无终:持恒技，当一名角色将要摸牌时，若其摸牌数大于牌堆与弃牌堆牌数的总和，则你将其此次摸牌数改为0并令其所有技能失效直到本回合结束
-- 必灭:持恒技，当你将要对一名其他角色造成伤害时，若此次伤害大于其体力上限，你可以使其死亡
-- 抹灭:你造成的伤害视为失去体力，当一名角色不因受到伤害死亡时，你摸X+1张牌并增加X+1点体力上限（X为场上死亡的角色数）

local Qunyou_junshen = General:new(extension, "Qunyou_junshen", "qunyou_bao", 3, 10, 2)

local Qunyou_junshen_zhongmu = fk.CreateTriggerSkill {
    name = "Qunyou_junshen_zhongmu",
    anim_type = "offensive",
    events = { fk.PreDamage },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.maxHp > 1
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local lostmaxhp = (player.maxHp + 1) // 2
        local losttrue = 0
        if player.hp > player.maxHp - lostmaxhp then
            losttrue = player.hp - (player.maxHp - lostmaxhp)
        end
        if losttrue > 0 then
            room:changeMaxHp(data.to, -(losttrue + 1) // 2)
        end
        room:changeMaxHp(player, -lostmaxhp)
        data.damage = data.damage + lostmaxhp
    end,
}

local Qunyou_junshen_buye = fk.CreateTriggerSkill {
    name = "Qunyou_junshen_buye",
    anim_type = "control",
    events = { fk.TurnStart, fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.TurnEnd and player.faceup and
                player:usedSkillTimes(self.name, player.HistoryRound) == 0 then
                return true
            elseif event == fk.TurnStart and player:getMark("Qunyou_junshen_buye") > 0 then
                return true
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        if event == fk.TurnStart and player:getMark("Qunyou_junshen_buye") > 0 then
            return true
        elseif event == fk.TurnEnd then
            return player.room:askForSkillInvoke(player, self.name)
        end
    end,
    on_use = function(self, event, target, player, data)
        if event == fk.TurnEnd then
            player:addMark("Qunyou_junshen_buye", 1)
            player:gainAnExtraTurn()
        else
            player:turnOver()
            player:removeMark("Qunyou_junshen_buye", 1)
        end
    end,
}

local Qunyou_junshen_wuzhong = fk.CreateTriggerSkill {
    name = "Qunyou_junshen_wuzhong",
    anim_type = "control",
    events = { fk.BeforeDrawCard },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self, true) and data.num > #player.room.draw_pile + #player.room.discard_pile
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        data.num = 0
        player.room:setPlayerMark(target, "@Qunyou_junshen_wuzhong-turn", 1)
    end,
}

local Qunyou_junshen_wuzhong_invalidity = fk.CreateInvaliditySkill {
    name = "#Qunyou_junshen_wuzhong_invalidity",
    invalidity_func = function(self, from, skill)
        return from:getMark("@Qunyou_junshen_wuzhong-turn") > 0 and not skill:isEquipmentSkill(from)
    end
}

local Qunyou_junshen_bimie = fk.CreateTriggerSkill {
    name = "Qunyou_junshen_bimie",
    anim_type = "offensive",
    events = { fk.PreDamage },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self, true) and data.to ~= player and data.damage > data.to.maxHp
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = data.to
        if player ~= to then
            room:doIndicate(player.id, { to.id })
        end
        room:killPlayer({ who = to.id })
    end
}

local Qunyou_junshen_momie = fk.CreateTriggerSkill {
    name = "Qunyou_junshen_momie",
    anim_type = "offensive",
    events = { fk.PreDamage, fk.Death },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if event == fk.PreDamage then
                return data.from == player
            else
                return data.who ~= player.id and data.damage == nil
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.PreDamage then
            room:loseHp(data.to, data.damage, self.name)
            return true
        else
            local deathplayer = #room.players - #room.alive_players + 1
            player:drawCards(deathplayer, self.name)
            room:changeMaxHp(player, deathplayer)
        end
    end
}

Qunyou_junshen_wuzhong:addRelatedSkill(Qunyou_junshen_wuzhong_invalidity)
Qunyou_junshen:addSkill(Qunyou_junshen_zhongmu)
Qunyou_junshen:addSkill(Qunyou_junshen_buye)
Qunyou_junshen:addSkill(Qunyou_junshen_wuzhong)
Qunyou_junshen:addSkill(Qunyou_junshen_bimie)
Qunyou_junshen:addSkill(Qunyou_junshen_momie)

Fk:loadTranslationTable {
    ["Qunyou_junshen"] = "御射军神",
    ["#Qunyou_junshen"] = "万理之终焉",
    ["designer:Qunyou_junshen"] = "御射军神",

    ["Qunyou_junshen_zhongmu"] = "终幕",
    [":Qunyou_junshen_zhongmu"] = ":当你将要对其他角色造成伤害时，你可以失去一半体力上限（向上取整），使此伤害增加X点，若你因此失去了体力，则使该角色减少X/2（向上取整）的体力上限（X为你失去的体力上限）",

    ["Qunyou_junshen_buye"] = "不夜",
    [":Qunyou_junshen_buye"] = "每轮限一次，回合结束时，若你的武将牌正面朝上，你获得一个额外回合然后翻面",

    ["Qunyou_junshen_wuzhong"] = "无终",
    [":Qunyou_junshen_wuzhong"] = "持恒技，当一名角色将要摸牌时，若其摸牌数大于牌堆与弃牌堆牌数的总和，则你将其此次摸牌数改为0并令其所有技能失效直到本回合结束",
    ["@Qunyou_junshen_wuzhong-turn"] = "无终",

    ["Qunyou_junshen_bimie"] = "必灭",
    [":Qunyou_junshen_bimie"] = "持恒技，当你将要对一名其他角色造成伤害时，若此次伤害大于其体力上限，你可以使其死亡",

    ["Qunyou_junshen_momie"] = "抹灭",
    [":Qunyou_junshen_momie"] = "你造成的伤害视为失去体力，当一名角色不因受到伤害死亡时，你摸X+1张牌并增加X+1点体力上限（X为场上死亡的角色数）",

}

---持恒技：player:hasSkill(self,true)

-- 优雅的鬼族女仆   蕾姆   9999
-- 礼仪:当你使用一张非装备牌或成为一张伤害牌的目标时，你可以展示任意张点数之和为X的牌,你令X+1（X为1-13依次循环）。若成功展示，你观看牌堆顶三张牌，选择一张获得，然后你将其余牌置于武将牌上称为“礼”。

-- 沏茶:出牌阶段限一次，你立即收回你武将牌上所有“礼”，然后令【礼仪】点数-1(点数至少为1)。若“礼”的数量不小于3，你令牌堆顶一张牌称为“礼”置于你武将牌上。

-- 挚爱:游戏开始时，你选择一名其他角色。本局游戏内，若该角色即将死亡时，你可以令其体力值恢复至1，然后你失去所有体力。

-- 鬼化:回合开始时，若“礼”数量不小于5，你可以获得至多3张“礼”，本回合获得【鬼武】 【狂鬼】并【沏茶】失效直至回合结束。

-- 鬼武:本回合【杀】次数+2。出牌阶段开始时，若你没有【流星锤】，则你获得一张【流星锤】与一张【杀】。当你使用【杀】造成伤害时，你可以弃置一张“礼”取消当前所有结算。

-- 狂鬼:弃牌阶段结束时，若你的体力不大于体力上限的一半（向下取整），你可以弃置至多3张“礼”，视为对一名其他角色使用等量的杀。


local Qunyou_Gui_Rem = General:new(extension, "Qunyou_Gui_Rem", "qunyou_bao", 4, 4, 2)
local Qunyou_Gui_Rem_Gui = General:new(extension, "Qunyou_Gui_Rem_Gui", "qunyou_bao", 4, 4, 2)
Qunyou_Gui_Rem_Gui.total_hidden = true
local function cardnumbersum(cardsid) --求牌的点数和
    local num = 0
    for _, id in ipairs(cardsid) do
        num = num + Fk:getCardById(id).number
    end
    return num
end
local function xianjiselect(cardsid, to, n) --选择
    return cardnumbersum(cardsid) + Fk:getCardById(to).number <= n
end
local function xianjifeasible(cardsid, n) --feasible
    return cardnumbersum(cardsid) == n
end
Fk:addPoxiMethod {
    name = "Qunyou_Gui_Rem_poxi",
    card_filter = function(to_select, selected, data, extra_data)
        local card = Fk:getCardById(to_select)
        if card.number == nil then
            return false
        end
        local n = math.max(Self:getMark("@Qunyou_Gui_Rem_liyi"), 1)
        return xianjiselect(selected, to_select, n)
    end,
    feasible = function(selected, data, extra_data)
        local n = math.max(Self:getMark("@Qunyou_Gui_Rem_liyi"), 1)
        return xianjifeasible(selected, n)
    end,
    prompt = function()
        return "#Qunyou_Gui_Rem_poxi_choose:::" .. Self:getMark("@Qunyou_Gui_Rem_liyi")
    end,
}
local Qunyou_Gui_Rem_liyi = fk.CreateTriggerSkill {
    name = "Qunyou_Gui_Rem_liyi",
    anim_type = "drawcard",
    prompt = "#Qunyou_Gui_Rem_liyi",
    events = { fk.CardUsing, fk.TargetConfirmed },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.CardUsing and data.card.type ~= Card.TypeEquip then
                return true
            elseif event == fk.TargetConfirmed and data.card.is_damage_card == true then
                return true
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        if player:getMark("@Qunyou_Gui_Rem_liyi") == 0 then
            player.room:setPlayerMark(player, "@Qunyou_Gui_Rem_liyi", 1)
        end
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local gain = room:askForPoxi(player, "Qunyou_Gui_Rem_poxi", { { player.general, player:getCardIds("h") } }, nil,
            true)
        if #gain > 0 then
            player:showCards(gain)
            local ids = room:getNCards(3)
            room:moveCards({
                ids = ids,
                toArea = Card.Processing,
                moveReason = fk.ReasonPut,
                proposer = player.id,
                skillName = self.name,
            })
            local getcard = room:askForArrangeCards(player, self.name, ids, "#Qunyou_Gui_Rem_liyi-choose", false, 0,
                { 3, 1 }, { 2, 1 })[2]
            if #getcard > 0 then
                room:moveCards({
                    ids = getcard,
                    to = player.id,
                    toArea = Card.PlayerHand,
                    moveReason = fk.ReasonPrey,
                    proposer = player.id,
                    skillName = self.name,
                })
                table.removeOne(ids, getcard[1])
            else
                local getcard_random = ids[math.random(3)]
                room:obtainCard(player, getcard_random, false, fk.ReasonPrey, player.id, self.name)
                table.removeOne(ids, getcard_random)
            end
            player:addToPile("liyi", ids, true, self.name)
        end
        local num = player:getMark("@Qunyou_Gui_Rem_liyi") + 1
        if num > 13 then
            num = 1
        end
        player.room:setPlayerMark(player, "@Qunyou_Gui_Rem_liyi", num)
        return true
    end
}

local Qunyou_Gui_Rem_qicha = fk.CreateActiveSkill {
    name = "Qunyou_Gui_Rem_qicha",
    anim_type = "drawcard",
    target_num = 0,
    prompt = "#Qunyou_Gui_Rem_qicha",
    can_use = function(self, player, card, extra_data)
        return #player:getPile("liyi") > 0 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and
            player:getMark("guihua-turn") == 0
    end,
    on_use = function(self, room, cardEffectEvent)
        local player = room:getPlayerById(cardEffectEvent.from)
        local liyi_num = #player:getPile("liyi")
        player.room:moveCardTo(player:getPile("liyi"), Player.Hand, player, fk.ReasonPrey, self.name)
        local num = player:getMark("@Qunyou_Gui_Rem_liyi") - 1
        if num == 0 then
            num = 1
        end
        room:setPlayerMark(player, "@Qunyou_Gui_Rem_liyi", num)
        if liyi_num >= 3 then
            player:addToPile("liyi", room:getNCards(1), false, self.name, fk.ReasonJustMove)
        end
    end,
}

local Qunyou_Gui_Rem_zhiai = fk.CreateTriggerSkill {
    name = "Qunyou_Gui_Rem_zhiai",
    anim_type = "support",
    events = { fk.GameStart, fk.AskForPeachesDone },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if event == fk.AskForPeachesDone and target:getMark("@Qunyou_Gui_Rem_zhiai") > 0 then
                return true
            elseif event == fk.GameStart and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
                return true
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.GameStart then
            local targetplayer = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
                return p.id
            end), 1, 1, "#Qunyou_Gui_Rem_zhiai-choose", self.name, true)
            if targetplayer and #targetplayer > 0 then
                room:setPlayerMark(room:getPlayerById(targetplayer[1]), "@Qunyou_Gui_Rem_zhiai", 1)
            end
        else
            room:recover({
                who = target,
                num = 1 - target.hp,
                recoverBy = player,
                skillName = self.name
            })
            room:loseHp(player, player.hp, self.name)
        end
    end,
}

local Qunyou_Gui_Rem_guihua = fk.CreateTriggerSkill {
    name = "Qunyou_Gui_Rem_guihua",
    anim_type = "special",
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and #player:getPile("liyi") >= 5
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local choose_cards = room:askForArrangeCards(player, self.name, player:getPile("liyi"),
            "#Qunyou_Gui_Rem_guihua-choose", false, 0, { #player:getPile("liyi"), 3 }, { 0, 0 })[2]
        if #choose_cards > 0 then
            room:moveCards({
                ids = choose_cards,
                from = player.id,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player.id,
                skillName = self.name,
            })
        end
        LoR_Utility.ChangeGeneral(player, "Qunyou_Gui_Rem", "Qunyou_Gui_Rem_Gui")
        room:handleAddLoseSkills(player, "Qunyou_Gui_Rem_guiwu|Qunyou_Gui_Rem_kuanggui", nil, true, false)
        room:setPlayerMark(player, "guihua-turn", 1)
    end,

    refresh_events = { fk.TurnEnd },
    can_refresh = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
    end,
    on_refresh = function(self, event, target, player, data)
        local room = player.room
        LoR_Utility.ChangeGeneral(player, "Qunyou_Gui_Rem_Gui", "Qunyou_Gui_Rem")
        room:handleAddLoseSkills(player, "-Qunyou_Gui_Rem_guiwu|-Qunyou_Gui_Rem_kuanggui", nil, true, false)
    end,
}

local Qunyou_Gui_Rem_guiwu = fk.CreateTriggerSkill {
    name = "Qunyou_Gui_Rem_guiwu",
    anim_type = "offensive",
    events = { fk.EventPhaseStart, fk.Damage },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.EventPhaseStart then
                if player.phase == Player.Play then
                    local Hand_card = table.filter(player.player_cards[Player.Hand], function(c)
                        return Fk:getCardById(c).name == "liuxingchui"
                    end)
                    local Equip_card = table.filter(player.player_cards[Player.Equip], function(c)
                        return Fk:getCardById(c).name == "liuxingchui"
                    end)
                    if #Hand_card == 0 and #Equip_card == 0 then
                        return true
                    end
                end
            else
                return data.card.trueName == "slash"
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.EventPhaseStart then
            local card1 = room:printCard("liuxingchui", 7, Card.Spade)
            room:obtainCard(player, card1, false, fk.ReasonPrey, player.id, self.name)
            room:setCardMark(card1, MarkEnum.DestructIntoDiscard, 1)
            local cards = player.room:getCardsFromPileByRule("slash", 1)
            if #cards > 0 then
                player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
            end
        else
            local choose_cards = room:askForArrangeCards(player, self.name, player:getPile("liyi"),
                "#Qunyou_Gui_Rem_guiwu-choose", false, 0, { #player:getPile("liyi"), 1 },
                { 0, 0 })[2]
            if choose_cards and #choose_cards > 0 then
                room:moveCards({
                    ids = choose_cards,
                    from = player.id,
                    toArea = Card.DiscardPile,
                    moveReason = fk.ReasonDiscard,
                    proposer = player.id,
                    skillName = self.name,
                    moveVisible = true,
                })
                local e = room.logic:getCurrentEvent()
                repeat
                    e = e.parent
                until e.parent.event == GameEvent.Phase or e == nil
                if e == nil then return end
                e:shutdown()
            end
        end
    end
}

local Qunyou_Gui_Rem_guiwu_slashNum = fk.CreateTargetModSkill {
    name = "#Qunyou_Gui_Rem_guiwu_slashNum",
    residue_func = function(self, player, skill, scope, card, to)
        if card.trueName == "slash" and player:hasSkill(Qunyou_Gui_Rem_guiwu) then
            return 2
        else
            return 0
        end
    end
}

local Qunyou_Gui_Rem_kuanggui = fk.CreateTriggerSkill {
    name = "Qunyou_Gui_Rem_kuanggui",
    anim_type = "offensive",
    events = { fk.EventPhaseEnd },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Discard and
            player.hp <= player.maxHp // 2 and #player:getPile("liyi") > 0
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        local invoke = player.room:askForSkillInvoke(player, self.name)
        if invoke then
            local targetplayers = table.map(room:getOtherPlayers(player), function(p)
                if player:inMyAttackRange(p) then
                    return p.id
                end
            end)
            self.cost_data = room:askForChoosePlayers(player, targetplayers, 1, 1, "#Qunyou_Gui_Rem_kuanggui", self.name,
                true)
            return true
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if self.cost_data and #self.cost_data > 0 then
            local targetplayer = self.cost_data[1]
            local choose_cards = room:askForArrangeCards(player, self.name, player:getPile("liyi"),
                "#Qunyou_Gui_Rem_kuanggui-choose", false, 0, { #player:getPile("liyi"), 3 },
                { 0, 0 })[1]
            if choose_cards and #choose_cards > 0 then
                local card = room:printCard("slash")
                room:throwCard(choose_cards, self.name, player)
                for _, c in ipairs(choose_cards) do
                    room:useCard({
                        from = player.id,
                        tos = { { targetplayer } },
                        card = card
                    })
                end
            end
        end
    end,
}


Qunyou_Gui_Rem_guiwu:addRelatedSkill(Qunyou_Gui_Rem_guiwu_slashNum)

Qunyou_Gui_Rem:addSkill(Qunyou_Gui_Rem_liyi)
Qunyou_Gui_Rem:addSkill(Qunyou_Gui_Rem_qicha)
Qunyou_Gui_Rem:addSkill(Qunyou_Gui_Rem_zhiai)
Qunyou_Gui_Rem:addSkill(Qunyou_Gui_Rem_guihua)

Qunyou_Gui_Rem:addRelatedSkill(Qunyou_Gui_Rem_guiwu)
Qunyou_Gui_Rem:addRelatedSkill(Qunyou_Gui_Rem_kuanggui)


Fk:loadTranslationTable {
    ["Qunyou_Gui_Rem"] = "蕾姆",
    ["Qunyou_Gui_Rem_Gui"] = "蕾姆-鬼化",
    ["#Qunyou_Gui_Rem"] = "优雅可爱的鬼族女仆",
    ["designer:Qunyou_Gui_Rem"] = "Rem",

    ["Qunyou_Gui_Rem_liyi"] = "礼仪",
    [":Qunyou_Gui_Rem_liyi"] = "你使用一张非装备牌或成为一张伤害牌的目标时，你可以展示任意张点数之和为X的牌,你令X+1（X为1-13依次循环）。若成功展示，你观看牌堆顶三张牌，选择一张获得，然后你将其余牌置于武将牌上称为“礼”。",
    ["#Qunyou_Gui_Rem_liyi-choose"] = "请选择一张牌获取，其余牌称为“礼”置入武将牌",

    ["Qunyou_Gui_Rem_qicha"] = "沏茶",
    [":Qunyou_Gui_Rem_qicha"] = "出牌阶段限一次，你立即收回你武将牌上所有“礼”，然后令【礼仪】点数-1(点数至少为1)。若“礼”的数量不小于3，你令牌堆顶一张牌称为“礼”置于你武将牌上。",
    ["#Qunyou_Gui_Rem_qicha"] = "你可以收回所有“礼，令【礼仪】点数-1(点数至少为1)",

    ["Qunyou_Gui_Rem_zhiai"] = "挚爱",
    [":Qunyou_Gui_Rem_zhiai"] = "游戏开始时，你选择一名其他角色。本局游戏内，若该角色即将死亡时，你可以令其体力值恢复至1，然后你失去所有体力。",
    ["@Qunyou_Gui_Rem_zhiai"] = "挚爱",
    ["#Qunyou_Gui_Rem_zhiai-choose"] = "请选择你需要【挚爱】的角色",

    ["Qunyou_Gui_Rem_guihua"] = "鬼化",
    [":Qunyou_Gui_Rem_guihua"] = "回合开始时，若“礼”数量不小于5，你可以获得至多3张“礼”，本回合获得【鬼武】 【狂鬼】并【沏茶】失效直至回合结束。",
    ["#Qunyou_Gui_Rem_guihua-choose"] = "请选择需要获取的牌",

    ["Qunyou_Gui_Rem_guiwu"] = "鬼武",
    [":Qunyou_Gui_Rem_guiwu"] = "本回合【杀】次数+2。出牌阶段开始时，若你没有【流星锤】，则你获得一张【流星锤】与一张【杀】。当你使用【杀】造成伤害时，你可以弃置一张“礼”取消当前所有结算。<br><font color='grey'><b>#流星锤</b><br>装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，你使用【杀】对距离大于1的角色造成伤害+1",
    ["#Qunyou_Gui_Rem_guiwu-choose"] = "弃置一张礼仪可以令此【杀】结束当前所有结算",

    ["Qunyou_Gui_Rem_kuanggui"] = "狂鬼",
    [":Qunyou_Gui_Rem_kuanggui"] = "弃牌阶段结束时，若你的体力不大于体力上限的一半（向下取整），你可以弃置至多3张“礼”，视为对一名其他角色使用等量的杀。",
    ["#Qunyou_Gui_Rem_kuanggui"] = "请选择一名角色，对其使用x张【杀】（x为你弃置的礼数量）",
    ["#Qunyou_Gui_Rem_kuanggui-choose"] = "请弃置“礼”，根据弃置的数量对目标使用等量的【杀】（礼至多为3）",


    ["liyi"] = "礼",
    ["#Qunyou_Gui_Rem_poxi_choose"] = "礼仪：展示点数和为%arg的手牌。",
    ["@Qunyou_Gui_Rem_liyi"] = "礼仪",
}


-- 血盟骑士团副团长 亚丝娜 9999

-- 　　闪光:游戏开始时，你将一张【闪烁之光】置入你的装备区。你的回合开始时，你可以摸一张牌然后与一名角色拼点。
-- 若你赢，本回合你与其距离视为一，其本回合防具失效且无法响应你使用的牌。


-- 　　细剑:锁定技。你对距离为一的角色使用牌无次数限制，你对本回合受到伤害的角色造成伤害+1，
-- 结束阶段结束时你摸x张牌。（x为你本回合造成的伤害值且至多为8）


-- 　　闪烁之光:攻击范围3，武器。你的拼点牌点数+6。

local Qunyou_yasina = General:new(extension, "Qunyou_yasina", "qunyou_bao", 4, 4, 2)

local Qunyou_yasina_shanguang = fk.CreateTriggerSkill {
    name = "Qunyou_yasina_shanguang",
    anim_type = "offensive",
    events = { fk.GameStart, fk.TurnStart, fk.TargetSpecified },
    can_trigger = function(self, event, target, player, data)
        if event == fk.GameStart then
            return player:hasSkill(self)
        elseif event == fk.TurnStart then
            return target == player and player:hasSkill(self) and not player:isKongcheng()
        else
            return target == player and player:hasSkill(self) and
                player.room:getPlayerById(data.to):getMark("@shanguang-turn") > 0
        end
    end,
    on_cost = function(self, event, target, player, data)
        if event == fk.TurnStart then
            return player.room:askForSkillInvoke(player, self.name)
        else
            return true
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.GameStart then
            local card = room:printCard("shanshuozhiguang", Card.Diamond, 9)
            room:moveCards({
                ids = { card.id },
                fromArea = Card.Void,
                to = player.id,
                toArea = Card.PlayerEquip,
                moveReason = fk.ReasonJustMove,
                proposer = player.id,
                skillName = self.name,
                moveVisible = true,
            })
        elseif event == fk.TurnStart then
            player:drawCards(1, self.name)
            local targetplayer
            local targetplayers = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), function(p)
                if not p:isKongcheng() then
                    return p.id
                end
            end), 1, 1, "#Qunyou_yasina_shanguang-choose", self.name, false)
            if targetplayers and #targetplayers == 0 then
                return false
            else
                targetplayer = room:getPlayerById(targetplayers[1])
            end
            local pindian = player:pindian({ targetplayer }, self.name)
            if pindian.results[targetplayer.id].winner == player then
                local mark = player.getTableMark(player, "shanguang-turn")
                table.insertIfNeed(mark, targetplayer.id)
                room:setPlayerMark(player, "shanguang-turn", mark)
                room:addPlayerMark(targetplayer, fk.MarkArmorNullified .. "-turn")
                room:setPlayerMark(targetplayer, "@shanguang-turn", 1)
            end
        else
            room:setPlayerMark(room:getPlayerById(data.to), fk.MarkArmorNullified, 1)
            data.disresponsiveList = data.disresponsiveList or {}
            table.insertIfNeed(data.disresponsiveList, data.to)
        end
    end,

    refresh_events = { fk.EventPhaseStart },
    can_refresh = function(self, event, target, player, data)
        return player:hasSkill(self) and player.phase == player.Finish and target == player
    end,
    on_refresh = function(self, event, target, player, data)
        local room = target.room
        table.forEach(target.room.alive_players, function(p)
            if p:getMark("@shanguang-turn") > 0 then room:removePlayerMark(p, fk.MarkArmorNullified) end
        end)
    end
}
local Qunyou_yasina_shanguang_distance = fk.CreateDistanceSkill {
    name = "#Qunyou_yasina_shanguang_distance",
    fixed_func = function(self, from, to)
        local mark = from.getTableMark(from, "shanguang-turn")
        if table.contains(mark, to.id) then
            return 1
        end
    end
}

local Qunyou_yasina_xijian = fk.CreateTriggerSkill {
    name = "Qunyou_yasina_xijian",
    anim_type = "drawcard",
    frequency = Skill.Compulsory,
    events = { fk.PreDamage, fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        local room = player.room
        if target == player and player:hasSkill(self) then
            if player.phase == Player.Finish and event == fk.EventPhaseStart then
                if target == player then
                    local room = player.room
                    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
                    if turn_event == nil then return false end
                    local n = 0
                    LoR_Utility.getActualDamageEvents(room, 1, function(e)
                        local damage = e.data[1]
                        if damage.from == player then
                            n = n + damage.damage
                        end
                    end, nil, turn_event.id)
                    if n > 0 then
                        self.cost_data = n
                        return true
                    end
                end
            end
            if event == fk.PreDamage then
                local events = room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
                    if e.data[1] == data.to and e.data[3] == "damage" then
                        local first_damage_event = e:findParent(GameEvent.Damage)
                        if first_damage_event then
                            return true
                        end
                    end
                    return false
                end, Player.HistoryTurn)
                if events and #events > 0 then
                    return true
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        if event == fk.PreDamage then
            data.damage = (data.damage or 0) + 1
        else
            if self.cost_data > 8 then
                self.cost_data = 8
            end
            player:drawCards(self.cost_data, self.name)
        end
    end,
}

local Qunyou_yasina_xijian_targetmod = fk.CreateTargetModSkill {
    name = "#Qunyou_yasina_xijian_targetmod",
    bypass_times = function(self, player, skill, scope, card, to)
        return player:distanceTo(to) <= 1 and player:hasSkill(Qunyou_yasina_xijian)
    end,
}

Qunyou_yasina_shanguang:addRelatedSkill(Qunyou_yasina_shanguang_distance)
Qunyou_yasina_xijian:addRelatedSkill(Qunyou_yasina_xijian_targetmod)

Qunyou_yasina:addSkill(Qunyou_yasina_shanguang)
Qunyou_yasina:addSkill(Qunyou_yasina_xijian)

Fk:loadTranslationTable {
    ["Qunyou_yasina"] = "亚丝娜",
    ["#Qunyou_yasina"] = "血盟骑士团副团长",
    ["designer:Qunyou_yasina"] = "澪汐",

    ["Qunyou_yasina_shanguang"] = "闪光",
    [":Qunyou_yasina_shanguang"] = "游戏开始时，你将一张【闪烁之光】置入你的装备区。你的回合开始时，你可以摸一张牌然后与一名角色拼点。若你赢，本回合你与其距离视为一，其本回合防具失效且无法响应你使用的牌。" ..
        "<br><font color='grey'><b>#闪烁之光</b><br>装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，你的拼点牌点数+6",
    ["@shanguang-turn"] = "闪光",
    ["#Qunyou_yasina_shanguang-choose"] = "请选择一名角色拼点",

    ["Qunyou_yasina_xijian"] = "细剑",
    [":Qunyou_yasina_xijian"] = "锁定技。你对距离为一的角色使用牌无次数限制，你对本回合受到伤害的角色造成伤害+1，结束阶段结束时你摸x张牌。（x为你本回合造成的伤害值且至多为8）",
}

-- 魅影狐踪   长庚 群 4/4
-- 【盗月】
-- 出牌阶段限一次，你可以选择一种花色并展示手牌，弃置此花色外的所有手牌，然后指定任意名其他角色，从这些角色随机获得共计X张此花色的牌，
-- 若获得不足X张，改为从牌堆获得剩余数量的此花色的牌（X为你以此法弃置的牌数+1）。
-- 【穿心】
-- 你对距离为1的角色使用【杀】不可响应，此【杀】对其造成伤害时若其没有手牌，此伤害+1；
-- 对距离大于1的角色使用【杀】无距离和次数限制，此【杀】对其造成伤害时获得其一张牌。
-- 【知恨】
-- 限定技，每当你杀死一名角色时，你可以获得其所有手牌，夺取随机一个技能（觉醒技，限定技，主公技除外），
-- 令其改为休整一轮，然后当前死亡结算后，结束当前结算和回合，防止你改变体力和体力上限直到其复活。


---根据log_heart系列字符串返回Card.Heart卡牌suit
---@param suit string
---@return Suit @ 返回卡牌花色
function Return_log_heart_Suit(suit)
    if suit == "log_spade" then
        return Card.Spade
    elseif suit == "log_heart" then
        return Card.Heart
    elseif suit == "log_diamond" then
        return Card.Diamond
    elseif suit == "log_club" then
        return Card.Club
    else
        return Card.NoSuit
    end
end

local Qunyou_changgeng = General:new(extension, "Qunyou_changgeng", "qun", 4, 4, 1)

local Qunyou_changgeng_daoyue = fk.CreateActiveSkill {
    name = "Qunyou_changgeng_daoyue",
    anim_type = "drawcard",
    can_use = function(self, player, card, extra_data)
        return not player:isNude() and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
    end,
    on_use = function(self, room, cardUseEvent)
        local player = room:getPlayerById(cardUseEvent.from)
        local chooseSuit = room:askForChoice(player, { "log_spade", "log_heart", "log_diamond", "log_club" }, self.name,
            "#Qunyou_changgeng_daoyue-choose_suit")
        local return_suit = Return_log_heart_Suit(chooseSuit)
        player:showCards(player.player_cards[Player.Hand])
        local cids = table.filter(player.player_cards[Player.Hand], function(cid)
            return Fk:getCardById(cid).suit ~= return_suit
        end)
        local xNum = #cids + 1
        room:throwCard(cids, self.name, player)
        local targetplayer = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1,
            #room:getOtherPlayers(player), "#Qunyou_changgeng_daoyue-choose_target:::" .. chooseSuit, self.name, false)

        local getcard = {}
        for _, pid in ipairs(targetplayer) do
            for _, cid in ipairs(room:getPlayerById(pid):getCardIds("he")) do
                if Fk:getCardById(cid).suit == return_suit then
                    table.insertIfNeed(getcard, cid)
                end
            end
        end
        if #getcard >= xNum then
            getcard = table.random(getcard, xNum)
            room:obtainCard(player, getcard, false, fk.ReasonPrey, player.id, self.name)
        else
            local suit_string = room:printCard("slash", return_suit):getSuitString()
            local cards = player.room:getCardsFromPileByRule(".|.|" .. suit_string, xNum - #getcard)
            room:obtainCard(player, cards, false, fk.ReasonPrey, player.id, self.name)
            room:obtainCard(player, getcard, false, fk.ReasonPrey, player.id, self.name)
        end
    end,
}

local Qunyou_changgeng_chuanxin = fk.CreateTriggerSkill {
    name = "Qunyou_changgeng_chuanxin",
    anim_type = "offensive",
    events = { fk.TargetSpecified, fk.Damage },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.TargetSpecified then
                return player:distanceTo(player.room:getPlayerById(data.to)) <= 1 and data.card and
                    data.card.trueName == "slash"
            else
                return player:distanceTo(data.to) > 1 and data.card and data.card.trueName == "slash"
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to
        if event == fk.TargetSpecified then
            to = room:getPlayerById(data.to)
            data.disresponsive = true
            if to:isKongcheng() then
                data.additionalDamage = (data.additionalDamage or 0) + 1
            end
        else
            to = data.to
            if #player:getCardIds("he") > 0 then
                local getcard = room:askForCardChosen(player, to, "he", self.name,
                    "#Qunyou_changgeng_chuanxin_getcard:" ..
                    to.id)
                room:obtainCard(player, getcard, false, fk.ReasonPrey, player.id, self.name)
            end
        end
    end,
}

local Qunyou_changgeng_zhihen = fk.CreateTriggerSkill {
    name = "Qunyou_changgeng_zhihen",
    anim_type = "big",
    events = { fk.Death },
    frequency = Skill.Limited,
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
            and data.damage and data.damage.from == player and data.damage.to.maxHp > 0
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local to = room:getPlayerById(data.who)
        room:obtainCard(player, to.player_cards[Player.Hand], false, fk.ReasonPrey, player.id, self.name)
        local targetskill = {}
        local ban_types = { Skill.Limited, Skill.Wake, Skill.Quest }
        for _, s in ipairs(to.player_skills) do
            if not (s.attached_equip or s.lordSkill or table.contains(ban_types, s.frequency)) then
                table.insertIfNeed(targetskill, s.name)
            end
        end
        if #targetskill > 0 then
            local chooseSkill = targetskill[math.random(#targetskill)]
            room:handleAddLoseSkills(to, "-" .. chooseSkill, nil, true, false)
            room:handleAddLoseSkills(player, chooseSkill, nil, true, false)
        end
        room:setPlayerMark(to, "@Qunyou_changgeng_zhihen", 1)
        to._splayer:setDied(false)
        room:setPlayerRest(to, 1)
        room:setPlayerMark(player, "@Qunyou_changgeng_zhihen", 1)
        room.logic:breakTurn()
        local e = room.logic:getCurrentEvent()
        repeat
            e = e.parent
        until e.parent.event == GameEvent.Phase or e == nil
        if e == nil then return end
        e:shutdown()
    end,
}

local Qunyou_changgeng_zhihen_defensive = fk.CreateTriggerSkill {
    name = "#Qunyou_changgeng_zhihen_defensive",
    anim_type = "defensive",
    frequency = Skill.Compulsory,
    events = { fk.BeforeHpChanged, fk.BeforeMaxHpChanged },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:getMark("@Qunyou_changgeng_zhihen") > 0 and
            player:hasSkill(Qunyou_changgeng_zhihen)
            and player:usedSkillTimes("Qunyou_changgeng_zhihen", Player.HistoryGame) == 1
    end,
    on_use = function(self, event, target, player, data)
        return true
    end,

    refresh_events = { fk.AfterPlayerRevived },
    can_refresh = function(self, event, target, player, data)
        return target.gender == player.gender and player:getMark("@Qunyou_changgeng_zhihen") > 0 and
            data.reason == "rest"
    end,
    on_refresh = function(self, event, target, player, data)
        local room = player.room
        for _, p in ipairs(room.players) do
            if p:getMark("@Qunyou_changgeng_zhihen") > 0 then
                room:removePlayerMark(p, "@Qunyou_changgeng_zhihen", 1)
            end
        end
    end,
}

Qunyou_changgeng_zhihen:addRelatedSkill(Qunyou_changgeng_zhihen_defensive)

Qunyou_changgeng:addSkill(Qunyou_changgeng_daoyue)
Qunyou_changgeng:addSkill(Qunyou_changgeng_chuanxin)
Qunyou_changgeng:addSkill(Qunyou_changgeng_zhihen)

Fk:loadTranslationTable {
    ["Qunyou_changgeng"] = "长庚",
    ["#Qunyou_changgeng"] = "魅影狐踪",
    ["designer:Qunyou_changgeng"] = "emo公主",

    ["Qunyou_changgeng_daoyue"] = "盗月",
    [":Qunyou_changgeng_daoyue"] = "出牌阶段限一次，你可以选择一种花色并展示手牌，弃置此花色外的所有手牌，然后指定任意名其他角色，从这些角色随机获得共计X张此花色的牌，若获得不足X张，改为从牌堆获得剩余数量的此花色的牌（X为你以此法弃置的牌数+1）。",
    ["#Qunyou_changgeng_daoyue-choose_suit"] = "请选择一种花色",
    ["#Qunyou_changgeng_daoyue-choose_target"] = "请选择任意名目标获取%arg花色的牌",

    ["Qunyou_changgeng_chuanxin"] = "穿心",
    [":Qunyou_changgeng_chuanxin"] = "你对距离为1的角色使用【杀】不可响应，此【杀】对其造成伤害时若其没有手牌，此伤害+1;对距离大于1的角色使用【杀】无距离和次数限制，此【杀】对其造成伤害时获得其一张牌。",
    ["#Qunyou_changgeng_chuanxin_getcard"] = "请获取%src一张牌",

    ["Qunyou_changgeng_zhihen"] = "知恨",
    [":Qunyou_changgeng_zhihen"] = "限定技，当你杀死一名角色时，你可以获得其所有手牌，夺取随机一个技能（觉醒技，限定技，主公技除外），令其改为休整一轮，然后当前死亡结算后，结束当前结算和回合，防止你改变体力和体力上限直到其复活。",
    ["@Qunyou_changgeng_zhihen"] = "知恨",
    ["#Qunyou_changgeng_zhihen_defensive"] = "知恨",
}


-- 傻妞   魔幻手机   999   群友
-- 【维护秩序】每回合每项限一次，当其他角色：
--     1. 造成不小于2点的伤害前，你可令其为1点；
--     2. 使用牌目标数不小于2时，你可调整为1；
--     3. 本回合内发动技能次数不小于4次后，你可令该技能本回合失效；
--     4. 获得技能时，你可删除一项，然后将其改为你获得。
-- 【时空穿梭】出牌阶段限一次，你可以将1名角色的体力、体力上限与手牌数量调整至每轮开始前。
-- 【天女散花】出牌阶段限一次，弃置任意张不同花色的牌，选择一名角色，对其造成X点伤害（X为弃置牌的花色数)。


local Qunyou_shaniu = General:new(extension, "Qunyou_shaniu", "qunyou_bao", 3, 3, 2)

local Qunyou_shaniu_start = fk.CreateTriggerSkill {
    name = "#Qunyou_shaniu_start",
    mute = true,
    global=true,
    events = { fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and (player.general == "Qunyou_shaniu" or player.deputyGeneral == "Qunyou_shaniu") and
            player.phase == Player.Start
    end,
    on_cost = function(self, event, target, player, data)
        player.room:broadcastPlaySound("./packages/th_jie/audio/skill/Qunyou_shaniu_start")
    end
}

local Qunyou_shaniu_weihuzhixu = fk.CreateTriggerSkill {
    name = "Qunyou_shaniu_weihuzhixu",
    anim_type = "special",
    events = { fk.DamageCaused, fk.TargetSpecified, fk.AfterSkillEffect, fk.EventAcquireSkill, fk.BeforeDrawCard },
    can_trigger = function(self, event, target, player, data)
        if target and target ~= player and player:hasSkill(self) then
            if event == fk.DamageCaused and player:getMark("shaniu_damage-turn") == 0 and player:getMark("shaniu_damage") == 0 then
                return data.damage and data.damage >= 2
            elseif event == fk.TargetSpecified and player:getMark("shaniu_target-turn") and player:getMark("shaniu_target") == 0 then
                return data.firstTarget and #AimGroup:getAllTargets(data.tos) >= 2
            elseif event == fk.AfterSkillEffect and player:getMark("shaniu_skilleffect-turn") == 0 and player:getMark("shaniu_skilleffect") == 0 then
                return target:hasSkill(data) and data.visible and
                    target:usedSkillTimes(data.name, Player.HistoryTurn) >= 4
            elseif event == fk.EventAcquireSkill and player:getMark("shaniu_getskill-turn") == 0 and player:getMark("shaniu_getskill") == 0 then
                if player:getMark("shaniu_all") == 0 then
                    player.room:setPlayerMark(player, "shaniu_all",
                        { "1. 造成不小于2点的伤害前，你可令其为1点", "2. 使用牌目标数不小于2时，你可调整为1", "3. 本回合内发动技能次数不小于4次后，你可令该技能本回合失效",
                            "4. 获得技能时，你可删除一项，然后将其改为你获得。", "5. 摸牌数量大于2时，改为2" })
                end
                return data:isPlayerSkill(target) and data.visible
            elseif event == fk.BeforeDrawCard and player:getMark("shaniu_drawcards-turn") and player:getMark("shaniu_drawcards") == 0 then
                return data.num > 2
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        local prompt
        if event == fk.EventAcquireSkill then
            if player:getTableMark("shaniu_all") and #player:getTableMark("shaniu_all") > 0 then
                return player.room:askForSkillInvoke(player, self.name, nil,
                    "#Qunyou_shaniu_weihuzhixu-getSkill:" .. target.id .. "::" .. data.name)
            end
        elseif event == fk.DamageCaused then
            prompt = "造成不小于2点的伤害前，你可令其为1点"
        elseif event == fk.TargetSpecified then
            prompt = "使用牌目标数不小于2时，你可调整为1"
        elseif event == fk.AfterSkillEffect then
            return player.room:askForSkillInvoke(player, self.name, nil,
                "#Qunyou_shaniu_weihuzhixu-skilleffect:" .. target.id .. "::" .. data.name)
        elseif event == fk.BeforeDrawCard then
            prompt = "其摸牌数量大于2时，改为2"
        end
        return player.room:askForSkillInvoke(player, self.name, nil,
            "#Qunyou_shaniu_weihuzhixu:" .. target.id .. "::" .. prompt)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.DamageCaused then
            if data.damage >= 2 then
                data.damage = 1
                room:addPlayerMark(player, "shaniu_damage-turn")
            end
        elseif event == fk.TargetSpecified then
            local target = room:askForChoosePlayers(player, AimGroup:getAllTargets(data.tos), 1, 1,
                "#Qunyou_shaniu_weihuzhixu_target-choose", self.name, false)
            for _, pid in ipairs(AimGroup:getAllTargets(data.tos)) do
                if pid ~= target[1] then
                    AimGroup:cancelTarget(data, pid)
                end
            end
            room:addPlayerMark(player, "shaniu_target-turn")
        elseif event == fk.AfterSkillEffect then
            room:doIndicate(player.id, { target.id })
            if target:getMark("@Qunyou_shaniu_weihuzhixu_skilleffect-turn") == 0 then
                room:setPlayerMark(target, "@Qunyou_shaniu_weihuzhixu_skilleffect-turn", data.name)
            end
            room:addPlayerMark(player, "shaniu_skilleffect-turn")
        elseif event == fk.EventAcquireSkill then
            local mark = player:getTableMark("shaniu_all")
            local choice = room:askForChoice(player, player:getTableMark("shaniu_all"), self.name,
                "#Qunyou_shaniu_weihuzhixu_getskill-choose_skill", false,
                { "1. 造成不小于2点的伤害前，你可令其为1点", "2. 使用牌目标数不小于2时，你可调整为1", "3. 本回合内发动技能次数不小于4次后，你可令该技能本回合失效",
                    "4. 获得技能时，你可删除一项，然后将其改为你获得。", "5. 摸牌数量大于2时，改为2" })
            table.removeOne(mark, choice)
            room:setPlayerMark(player, "shaniu_all", mark)
            if choice == "1. 造成不小于2点的伤害前，你可令其为1点" then
                room:addPlayerMark(player, "shaniu_damage")
            elseif choice == "2. 使用牌目标数不小于2时，你可调整为1" then
                room:addPlayerMark(player, "shaniu_target")
            elseif choice == "3. 本回合内发动技能次数不小于4次后，你可令该技能本回合失效" then
                room:addPlayerMark(player, "shaniu_skilleffect")
            elseif choice == "4. 获得技能时，你可删除一项，然后将其改为你获得。" then
                room:addPlayerMark(player, "shaniu_getskill")
            elseif choice == "5. 摸牌数量大于2时，改为2" then
                room:addPlayerMark(player, "shaniu_drawcards")
            end
            if not player:hasSkill(data.name, true) then
                room:handleAddLoseSkills(player, data.name, nil, true, false)
            end
            room:handleAddLoseSkills(target, "-" .. data.name, nil, true, false)
            room:addPlayerMark(player, "shaniu_getskill-turn")
        elseif event == fk.BeforeDrawCard then
            data.num = 2
        end
    end,
}

local Qunyou_shaniu_weihuzhixu_skilleffect_invalidity = fk.CreateInvaliditySkill {
    name = "#Qunyou_shaniu_weihuzhixu_skilleffect_invalidity",
    invalidity_func = function(self, from, skill)
        return from:getMark("@Qunyou_shaniu_weihuzhixu_skilleffect-turn") ~= 0 and
            skill.name == from:getMark("@Qunyou_shaniu_weihuzhixu_skilleffect-turn")
    end
}

local Qunyou_shaniu_shikongchuansuo = fk.CreateActiveSkill {
    name = "Qunyou_shaniu_shikongchuansuo",
    prompt = "#Qunyou_shaniu_shikongchuansuo",
    anim_type = "control",
    target_num = 1,
    target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
        return #selected < 1
    end,
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.phase == Player.Play
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.tos[1])
        if target:getTableMark("@Qunyou_shaniu_shikongchuansuo_roundstart") and #target:getTableMark("@Qunyou_shaniu_shikongchuansuo_roundstart") > 0 then
            local p_hp = target:getTableMark("@Qunyou_shaniu_shikongchuansuo_roundstart")[1]
            local p_maxhp = target:getTableMark("@Qunyou_shaniu_shikongchuansuo_roundstart")[2]
            local p_handnum = target:getTableMark("@Qunyou_shaniu_shikongchuansuo_roundstart")[3]
            if target.maxHp > p_maxhp then
                room:changeMaxHp(target, -math.abs(target.maxHp - p_maxhp))
            else
                room:changeMaxHp(target, math.abs(target.maxHp - p_maxhp))
            end
            if target.maxHp > p_maxhp then
                room:changeHp(target, -math.abs(target.hp - p_hp))
            else
                room:changeHp(target, math.abs(target.hp - p_hp))
            end
            LoR_Utility.ChangeHandNum(target, p_handnum,
                "#Qunyou_shaniu_shikongchuansuo_roundstart-discard:::" .. p_handnum, self)
        end
    end,
}
local Qunyou_shaniu_shikongchuansuo_roundstart = fk.CreateTriggerSkill {
    name = "#Qunyou_shaniu_shikongchuansuo_roundstart",
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.RoundStart },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(Qunyou_shaniu_shikongchuansuo) then
            for _, p in ipairs(player.room.alive_players) do
                player.room:setPlayerMark(p, "@Qunyou_shaniu_shikongchuansuo_roundstart",
                    { p.hp, p.maxHp, p:getHandcardNum() })
            end
        end
    end,
}


local Qunyou_shaniu_tiannvsanhua = fk.CreateActiveSkill {
    name = "Qunyou_shaniu_tiannvsanhua",
    prompt = "#Qunyou_shaniu_tiannvsanhua",
    anim_type = "offensive",
    target_num = 1,
    target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
        return #selected < 1
    end,
    min_card_num = 1,
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.phase == Player.Play
    end,
    on_use = function(self, room, effect)
        local num = #effect.cards
        local suits = {}
        for _, id in ipairs(effect.cards) do
            local suit = Fk:getCardById(id).suit
            if suit ~= Card.NoSuit then
                table.insertIfNeed(suits, suit)
            end
        end
        local suits1 = #suits
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.tos[1])
        room:throwCard(effect.cards, self.name, player, player)
        room:damage({
            from = player,
            to = target,
            damage = suits1,
            skillName = self.name,
        })
        if num >= suits1 * 2 then
            local mark_all = { "shaniu_damage-turn", "shaniu_target-turn", "shaniu_skilleffect-turn",
                "shaniu_getskill-turn", "shaniu_drawcards-turn", "shaniu_damage", "shaniu_target", "shaniu_skilleffect",
                "shaniu_getskill", "shaniu_drawcards" }
            for name, _ in pairs(player.mark) do
                if table.contains(mark_all, name) then
                    room:removePlayerMark(player, name, player:getMark(name))
                end
            end
            player.room:setPlayerMark(player, "shaniu_all",
                { "1. 造成不小于2点的伤害前，你可令其为1点", "2. 使用牌目标数不小于2时，你可调整为1", "3. 本回合内发动技能次数不小于4次后，你可令该技能本回合失效",
                    "4. 获得技能时，你可删除一项，然后将其改为你获得。", "5. 摸牌数量大于2时，改为2" })
        end
    end
}

Qunyou_shaniu_weihuzhixu:addRelatedSkill(Qunyou_shaniu_weihuzhixu_skilleffect_invalidity)
Qunyou_shaniu_shikongchuansuo:addRelatedSkill(Qunyou_shaniu_shikongchuansuo_roundstart)
Qunyou_shaniu:addSkill(Qunyou_shaniu_weihuzhixu)
Qunyou_shaniu:addSkill(Qunyou_shaniu_shikongchuansuo)
Qunyou_shaniu:addSkill(Qunyou_shaniu_tiannvsanhua)
Fk:addSkill(Qunyou_shaniu_start)

Fk:loadTranslationTable {
    ["Qunyou_shaniu"] = "傻妞",
    ["#Qunyou_shaniu"] = "魔幻手机",
    ["designer:Qunyou_shaniu"] = "失心",

    ["Qunyou_shaniu_weihuzhixu"] = "维护秩序",
    ["$Qunyou_shaniu_weihuzhixu1"] = "请在真人模式或手机模式中，任选一项",
    ["$Qunyou_shaniu_weihuzhixu2"] = "社会秩序维护功能和自卫功能已经同时启动，是否需要报警。",

    [":Qunyou_shaniu_weihuzhixu"] = "每回合每项限一次，当其他角色：" ..
        "<br/>1. 造成不小于2点的伤害前，你可令其为1点；" ..
        "<br/>2. 使用牌目标数不小于2时，你可调整为1；" ..
        "<br/>3. 本回合内发动技能次数不小于4次后，你可令该技能本回合失效；" ..
        "<br/>4. 获得技能时，你可删除一项，然后将其改为你获得。" ..
        "<br/>5. 摸牌数量大于2时，改为2。",
    ["#Qunyou_shaniu_weihuzhixu"] = "维护秩序:目标角色【%src】，%arg",
    ["#Qunyou_shaniu_weihuzhixu-getSkill"] = "维护秩序:目标角色【%src】，其获得技能【%arg】，你可以删除【维护秩序】中的一项，令此技能改为你获得。",
    ["#Qunyou_shaniu_weihuzhixu-skilleffect"] = "维护秩序:目标角色【%src】，你可令技能【%arg】失效。",

    ["#Qunyou_shaniu_weihuzhixu_target-choose"] = "维护秩序:请选择一名此牌目标，此牌仅对其生效",
    ["@Qunyou_shaniu_weihuzhixu_skilleffect-turn"] = "维护秩序",
    ["#Qunyou_shaniu_weihuzhixu_getskill-choose_skill"] = "维护秩序:请选择一项删去",

    ["Qunyou_shaniu_shikongchuansuo"] = "时空穿梭",
    ["#Qunyou_shaniu_shikongchuansuo"] = "时空穿梭:出牌阶段限一次，你可以将1名角色的体力、体力上限与手牌数量调整至每轮开始前。",
    ["$Qunyou_shaniu_shikongchuansuo1"] = "抓紧啊，摔死了我可不管",
    ["$Qunyou_shaniu_shikongchuansuo2"] = "启动，时空穿梭功能。",
    [":Qunyou_shaniu_shikongchuansuo"] = "出牌阶段限一次，你可以将1名角色的体力、体力上限与手牌数量调整至每轮开始前。",
    ["#Qunyou_shaniu_shikongchuansuo_roundstart-discard"] = "时空穿梭:将手牌调整至%arg张",
    ["#Qunyou_shaniu_shikongchuansuo_roundstart"] = "时空穿梭",
    ["@Qunyou_shaniu_shikongchuansuo_roundstart"] = "时空穿梭",

    ["Qunyou_shaniu_tiannvsanhua"] = "天女散花",
    ["#Qunyou_shaniu_tiannvsanhua"] = "天女散花:出牌阶段限一次，弃置任意张不同花色的牌，选择一名角色，对其造成X点伤害（X为弃置牌的花色数)。",
    ["$Qunyou_shaniu_tiannvsanhua"] = "天女散花！",
    [":Qunyou_shaniu_tiannvsanhua"] = "出牌阶段限一次，弃置至少1张牌，选择一名角色，对其造成X点伤害。当你弃置牌的数量不小于X的2倍时，你可以重置【维护秩序】（X为弃置牌的花色数)",

}


-- 神 1勾玉 万佛之祖 悟空
-- 技能：
-- 【永生】：锁定技，共鸣技，其他角色受到伤害时，你增加等同于伤害值的体力上限（至多为99），并失去等量体力。你每次濒死时，
--         若你的“舍利”少于5，则获得一个“舍利”标记并调整体力至1。
-- 【舍利】：锁定技，你跳过判定阶段。摸牌阶段，你摸牌数+X。你的手牌上限+X。你的伤害值增加X（X为“舍利”数且最多为5）。
-- 【万佛】：锁定技，你的回合内，使用牌无次数和距离限制。当你使用牌时，目标角色需交给你一张同类型的牌，否则失去1点体力。
-- 【如来】：觉醒技，共鸣技，当你“舍利”数为5时，你将图像替换为“如来”，同时修改【永生】、【万佛】并获得【三界】。
-- 【永生】:锁定技，其他角色受到伤害时，你增加等同于伤害值的体力上限，并回复等量体力。
-- 【万佛】:锁定技，你使用牌无次数和距离限制。当你使用牌时，可以令一名此牌目标角色随机一个本回合未以此法选择过的技能本回合内失效。
-- 【三界】:锁定技，准备阶段，你从3个技能中选择1个技能获得。

local Qunyou_wukong = General:new(extension, "Qunyou_wukong", "god", 1, 1, 1)

local Qunyou_wukong_yongsheng = fk.CreateTriggerSkill {
    name = "Qunyou_wukong_yongsheng",
    frequency = Skill.Compulsory,
    anim_type = "support",
    events = { fk.Damaged, fk.EnterDying },
    priority = 3,
    can_trigger = function(self, event, target, player, data)
        if player.general == "Qunyou_wukong" or player.deputyGeneral == "Qunyou_wukong"
            or player.general == "Qunyou_rulai" or player.deputyGeneral == "Qunyou_rulai" then
            if event == fk.Damaged then
                return target ~= player and player:hasSkill(self)
            else
                return target == player and player:hasSkill(self) and player:getMark("@Qunyou_wukong_sheli") < 5
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.Damaged then
            if player.maxHp + data.damage < 99 then
                room:changeMaxHp(player, data.damage)
            else
                room:changeMaxHp(player, 99 - player.maxHp)
            end
            if player:getMark("Qunyou_wukong_rulai") > 0 then
                room:recover({
                    who = player,
                    num = data.damage,
                    skillName = self.name,
                    recoverBy = player
                })
            else
                room:loseHp(player, data.damage, self.name)
            end
        else
            room:addPlayerMark(player, "@Qunyou_wukong_sheli")
            room:changeHp(player, 1 - player.hp, nil, self.name, data)
        end
    end
}

local Qunyou_wukong_sheli = fk.CreateTriggerSkill {
    name = "Qunyou_wukong_sheli",
    frequency = Skill.Compulsory,
    anim_type = "special",
    events = { fk.EventPhaseChanging, fk.DrawNCards, fk.DamageCaused },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.EventPhaseChanging then
                return data.to == Player.Judge
            else
                return player:getMark("@Qunyou_wukong_sheli") > 0
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.EventPhaseChanging then
            return true
        elseif event == fk.DrawNCards then
            data.n = data.n + player:getMark("@Qunyou_wukong_sheli")
        else
            data.damage = (data.damage or 0) + player:getMark("@Qunyou_wukong_sheli")
        end
    end
}
local Qunyou_wukong_sheli_MaxCard = fk.CreateMaxCardsSkill {
    name = "#Qunyou_wukong_sheli_MaxCard",
    correct_func = function(self, player)
        if player:hasSkill(Qunyou_wukong_sheli) and player:getMark("@Qunyou_wukong_sheli") > 0 then
            return player:getMark("@Qunyou_wukong_sheli")
        end
    end,
}


Fk:addQmlMark {
    name = "Qunyou_wukong_wanfo",
    how_to_show = function(name, value)
        if type(value) == "table" then
            return tostring(#value)
        end
        return " "
    end,
    qml_path = "packages/sanguokill/qml/ZhidiBox"
}
local Qunyou_wukong_wanfo = fk.CreateTriggerSkill {
    name = "Qunyou_wukong_wanfo",
    frequency = Skill.Compulsory,
    anim_type = "offensive",
    events = { fk.CardUsing },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) and data.card and data.tos and #data.tos > 0 then
            if #data.tos == 1 and data.tos[1][1] == player.id then
                return false
            else
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local targetPlayer
        if player:getMark("Qunyou_wukong_rulai") > 0 then
            local tos, targetPlayers = {}, {}
            for index, value in ipairs(data.tos) do
                table.insertIfNeed(tos, value[1])
            end
            if #tos == 1 and tos[1] == player.id then
                return true
            end
            targetPlayers = room:askForChoosePlayers(player, tos, 1, 1, "#Qunyou_wukong_wanfo-choose_player",
                self.name, true)
            if #targetPlayers > 0 then
                targetPlayer = room:getPlayerById(targetPlayers[1])
                local skills = targetPlayer:getAllSkills()
                local skills_names = table.map(skills, function(skill, index, array)
                    return skill.name
                end)
                local mark = targetPlayer:getTableMark("@[Qunyou_wukong_wanfo]")
                local skills_names2 = table.filter(skills_names, function(skill)
                    return not table.contains(mark, skill)
                end)
                table.insertIfNeed(mark, table.random(skills_names2, 1)[1])
                room:setPlayerMark(targetPlayer, "@[Qunyou_wukong_wanfo]", mark)
            end
        else
            targetPlayer = room:getPlayerById(data.tos[1][1])
            if targetPlayer == player then
                return true
            end
            local preyCard = room:askForCard(targetPlayer, 1, 1, true, self.name, true,
                ".|.|.|.|.|" .. LoR_Utility.getBugMarkValue(data.card.type))
            if #preyCard > 0 then
                room:obtainCard(player, preyCard, false, fk.ReasonGive, player.id, self.name)
            else
                room:loseHp(targetPlayer, 1, self.name)
            end
        end
    end
}

local Qunyou_wukong_wanfo_invalidity = fk.CreateInvaliditySkill {
    name = "#Qunyou_wukong_wanfo_invalidity",
    invalidity_func = function(self, from, skill)
        if #from:getTableMark("@[Qunyou_wukong_wanfo]") > 0 then
            return table.contains(from:getTableMark("@[Qunyou_wukong_wanfo]"), skill.name) and skill:isPlayerSkill(from)
        end
    end
}
local Qunyou_wukong_wanfo_targetMod = fk.CreateTargetModSkill {
    name = "#Qunyou_wukong_wanfo_targetMod",
    frequency = Skill.Compulsory,
    bypass_times = function(self, player, skill, scope)
        return player:hasSkill(Qunyou_wukong_wanfo)
    end,
    bypass_distances = function(self, player, skill, scope)
        return player:hasSkill(Qunyou_wukong_wanfo)
    end,
}

local Qunyou_wukong_rulai = fk.CreateTriggerSkill {
    name = "Qunyou_wukong_rulai",
    frequency = Skill.Wake,
    anim_type = "big",
    events = { fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and
            (player.general == "Qunyou_wukong" or player.deputyGeneral == "Qunyou_wukong")
    end,
    can_wake = function(self, event, target, player, data)
        return player:getMark("@Qunyou_wukong_sheli") == 5
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        LoR_Utility.ChangeGeneral(player, "Qunyou_wukong", "Qunyou_rulai")
        room:addPlayerMark(player, "Qunyou_wukong_rulai")
        room:handleAddLoseSkills(player, "Qunyou_wukong_sanjie", nil, true, false)
    end
}

local Qunyou_wukong_sanjie = fk.CreateTriggerSkill {
    name = "Qunyou_wukong_sanjie",
    frequency = Skill.Compulsory,
    anim_type = "support",
    events = { fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Start
    end,
    on_use = function(self, event, target, player, data)
        LoR_Utility.getSkill(player, self, "#Qunyou_wukong_sanjie-choose_skill", 3)
    end,
}

Qunyou_wukong_sheli:addRelatedSkill(Qunyou_wukong_sheli_MaxCard)
Qunyou_wukong_wanfo:addRelatedSkill(Qunyou_wukong_wanfo_invalidity)
Qunyou_wukong_wanfo:addRelatedSkill(Qunyou_wukong_wanfo_targetMod)

Qunyou_wukong:addSkill(Qunyou_wukong_yongsheng)
Qunyou_wukong:addSkill(Qunyou_wukong_sheli)
Qunyou_wukong:addSkill(Qunyou_wukong_wanfo)
Qunyou_wukong:addSkill(Qunyou_wukong_rulai)
Qunyou_wukong:addRelatedSkill(Qunyou_wukong_sanjie)

local Qunyou_rulai = General:new(extension, "Qunyou_rulai", "god", 1, 1, 1)
Qunyou_rulai.total_hidden = true

Fk:loadTranslationTable {
    ["Qunyou_rulai"] = "佛祖",
    ["Qunyou_wukong"] = "悟空",
    ["#Qunyou_wukong"] = "万佛之祖",
    ["designer:Qunyou_wukong"] = "失心",

    ["Qunyou_wukong_yongsheng"] = "永生",
    ["$Qunyou_wukong_yongsheng1"] = "恶有恶报，善有善报，不是不报，时间未到！",
    ["$Qunyou_wukong_yongsheng2"] = "我不如地狱，谁入地狱!",
    [":Qunyou_wukong_yongsheng"] = "锁定技，共鸣技，其他角色受到伤害时，你增加等同于伤害值的体力上限（至多为99），并失去等量体力。你每次濒死时,若你的“舍利”少于5，则获得一个“舍利”标记并调整体力至1。",
    ["@Qunyou_wukong_sheli"] = "舍利",

    ["Qunyou_wukong_sheli"] = "舍利",
    ["$Qunyou_wukong_sheli"] = "我孙悟空是顶天立地的汉子，凭你们几个虾兵蟹将让我投降，真是笑话",
    [":Qunyou_wukong_sheli"] = "锁定技，你跳过判定阶段。摸牌阶段，你摸牌数+X。你的手牌上限+X。你的伤害值增加X（X为“舍利”数且最多为5）。",

    ["Qunyou_wukong_wanfo"] = "万佛",
    ["@[Qunyou_wukong_wanfo]"] = "万佛",
    ["$Qunyou_wukong_wanfo1"] = "这就是我们的佛祖，他不是不管，而是不想管，你不管，我管！",
    ["$Qunyou_wukong_wanfo2"] = "三界有难，只要牺牲我一个人，能解救三界之难，弟子义不容辞！",
    [":Qunyou_wukong_wanfo"] = "锁定技，你的回合内，使用牌无次数和距离限制。当你使用牌时，目标角色需交给你一张同类型的牌，否则失去1点体力。",
    ["#Qunyou_wukong_wanfo-choose_player"] = "万佛:令此牌目标中的一名角色随机一个本回合未以此法选择过的技能，本回合内失效。",

    ["Qunyou_wukong_rulai"] = "如来",
    ["$Qunyou_wukong_rulai"] = "我今当众宣布新的万佛之祖，南无大圣舍利尊王佛，孙悟空！",
    [":Qunyou_wukong_rulai"] = "觉醒技，共鸣技，当你“舍利”数为5时，你将图像替换为“如来”，同时修改【<a href='Qunyou_wukong_rulai_yongsheng'><font color='red'>永生</a></font>】、【<a href='Qunyou_wukong_rulai_wanfo'><font color='red'>万佛</a></font>】并获得【三界】。",    ["Qunyou_wukong_rulai_yongsheng"] = "锁定技，其他角色受到伤害时，你增加等同于伤害值的体力上限，并回复等量体力。",
    ["Qunyou_wukong_rulai_wanfo"] = "锁定技，你使用牌无次数和距离限制。当你使用牌时，可以令一名此牌目标角色随机一个本回合未以此法选择过的技能本回合内失效。",

    ["Qunyou_wukong_sanjie"] = "三界",
    ["$Qunyou_wukong_sanjie"] = "佛祖！劫数已尽，佛仙归道，此乃三界幸事。",
    [":Qunyou_wukong_sanjie"] = "锁定技，准备阶段，你从3个技能中选择1个技能获得。",
    ["#Qunyou_wukong_sanjie-choose_skill"] = "三界:准备阶段，你从3个技能中选择1个技能获得。",
}

-- 神  狐达四号  9
-- 狐测:锁定技，你跳过摸牌阶段；当你手牌数不为4时，调整至4；你的锦囊牌视为决斗，基本牌视为火杀。

-- 狐动:锁定技，当你成为杀的目标时，随机弃置一张基本牌令其无效；
-- 当你濒死时，随机弃置一张锦囊牌或装备牌视为桃；当你受到伤害后，弃置所有基本牌对伤害来源造成弃置牌数的伤害。
local Qunyou_huda4 = General:new(extension, "Qunyou_huda4", "god", 1, 1, 1)

local Qunyou_huda4_huce = fk.CreateTriggerSkill {
    name = "Qunyou_huda4_huce",
    events = { fk.AfterCardsMove, fk.EventPhaseChanging },
    anim_type = "drawcard",
    frequency = Skill.Compulsory,
    mute = true,
    can_trigger = function(self, event, target, player, data)
        if not player:hasSkill(self) then return false end
        if event == fk.EventPhaseChanging then
            return target == player and data.to == Player.Draw
        elseif player:getHandcardNum() ~= 4 then
            for _, move in ipairs(data) do
                if move.to == player.id and move.toArea == Card.PlayerHand then
                    return true
                elseif move.from == player.id then
                    for _, info in ipairs(move.moveInfo) do
                        if info.fromArea == Card.PlayerHand then
                            return true
                        end
                    end
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        player:broadcastSkillInvoke(self.name)
        if event == fk.EventPhaseChanging then
            room:notifySkillInvoked(player, self.name, "negative")
            return true
        else
            local num = 4 - player:getHandcardNum()
            if num > 0 then
                room:notifySkillInvoked(player, self.name, "drawcard")
                player:drawCards(num, self.name)
            elseif num < 0 then
                room:notifySkillInvoked(player, self.name, "negative")
                room:askForDiscard(player, -num, -num, false, self.name, false)
            end
        end
    end,
}

local Qunyou_huda4_huce_filter = fk.CreateFilterSkill {
    name = "#Qunyou_huda4_huce_filter ",
    mute = true,
    frequency = Skill.Compulsory,
    card_filter = function(self, card, player)
        return player:hasSkill(Qunyou_huda4_huce) and (card.type == Card.TypeBasic or card.type == Card.TypeTrick)
    end,
    view_as = function(self, card)
        if card.type == Card.TypeBasic then
            return Fk:cloneCard("fire__slash", card.suit, card.number)
        else
            return Fk:cloneCard("duel", card.suit, card.number)
        end
    end,
}

local Qunyou_huda4_hudong = fk.CreateTriggerSkill {
    name = "Qunyou_huda4_hudong",
    anim_type = "support",
    frequency = Skill.Compulsory,
    events = { fk.TargetConfirming, fk.Damaged, fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.TargetConfirming then
                return not player:isKongcheng() and data.card and data.card.trueName == "slash" and
                #table.filter(player:getCardIds("h"), function(cid)
                    return Fk:getCardById(cid).type == Card.TypeBasic
                end) > 0
            elseif event == fk.Damaged then
                return not player.dead and data.from and
                #table.filter(player:getCardIds("h"), function(cid)
                    return Fk:getCardById(cid).type == Card.TypeBasic
                end) > 0
            else
                return not player:isNude() and #table.filter(player:getCardIds("he"), function(cid)
                    return Fk:getCardById(cid).type ~= Card.TypeBasic
                end) > 0
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TargetConfirming then
            local targetCards = table.filter(player:getCardIds("h"), function(cid)
                return Fk:getCardById(cid).type == Card.TypeBasic
            end)
            room:throwCard(table.random(targetCards, 1), self.name, player, player)
            data.nullifiedTargets = AimGroup:getAllTargets(data.tos)
        elseif event == fk.Damaged then
            local targetCards=table.filter(player:getCardIds("h"), function(cid)
                return Fk:getCardById(cid).type == Card.TypeBasic
            end)
            room:throwCard(targetCards,self.name,player,player)
            room:damage({
                from = player,
                to = data.from,
                damage = #targetCards,
                skillName = self.name,
            })
        else
            local targetCards = table.filter(player:getCardIds("he"), function(cid)
                return Fk:getCardById(cid).type ~= Card.TypeBasic
            end)
            room:throwCard(targetCards, self.name, player, player)
            room:recover({
                who=player,
                num=#targetCards,
                recoverBy=player,
                skillName=self.name
            })
        end
    end
}

Qunyou_huda4_huce:addRelatedSkill(Qunyou_huda4_huce_filter)
Qunyou_huda4:addSkill(Qunyou_huda4_huce)
Qunyou_huda4:addSkill(Qunyou_huda4_hudong)


Fk:loadTranslationTable {
    ["Qunyou_huda4"] = "狐达四号",
    ["#Qunyou_huda4"] = "狐之高达",
    ["designer:Qunyou_huda4"] = "狐湘狸",

    ["Qunyou_huda4_huce"] = "狐测",
    ["Qunyou_huda4_huce_filter"] = "狐测",
    ["$Qunyou_huda4_huce"] = "当你经过七重的孤独，才能够成为真正的强者。",
    [":Qunyou_huda4_huce"] = "锁定技，你跳过摸牌阶段；当你手牌数不为4时，调整至4；你的锦囊牌视为决斗，基本牌视为火杀。",

    ["Qunyou_huda4_hudong"] = "狐动",
    ["$Qunyou_huda4_hudong"] = "在天堂和地狱之间，没有我所选择的。",
    [":Qunyou_huda4_hudong"] = "锁定技，当你成为杀的目标时，随机弃置一张基本牌令其无效；当你进入濒死时，弃置所有锦囊牌与装备牌并回复等量体力；当你受到伤害后，弃置所有基本牌对伤害来源造成弃置牌数的伤害。",

}

return extension
