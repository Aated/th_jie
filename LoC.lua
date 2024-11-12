local extension = Package:new("LoC")
extension.extensionName = "th_jie"
local LoR_Utility = require "packages/th_jie/LoR_Utility"

Fk:loadTranslationTable {
    ["LoC"] = "脑叶公司"
}

Fk:appendKingdomMap("god", { "LoC" })


-- 脑叶公司AI助理  安吉拉  3/3 脑叶公司
-- 奇点T:每当你使用3种不同类型的牌时，你摸一张牌；每当你使用4种不同花色的牌时，你下一张牌额外结算一次；每当你使用13种点数不同的牌时，本回合结束时获得一个额外回合。

-- 奇点K:每回合限一次，当你即将受到伤害时，你记录当前体力值与体力上限，然后将体力与体力上限修改为上次记录的数据（若无数据则无法防止伤害）。

-- 奇点R:限定技，当你进入濒死时，你需弃置所有牌，将体力与体力上限修改为3/3，本局游戏你造成的伤害+1，7回合之后，你死亡。

-- 夺光:你的回合开始时，若场上拥有【光之种】标记，你可以夺取之。

local LoC__angela = General:new(extension, "LoC__angela", "LoC", 3, 3, 2)

Fk:addQmlMark {
    name = "Qidian_T",
    how_to_show = function(name, value)
        if type(value) == "table" then
            return tostring(#value)
        end
        return " "
    end,
    qml_path = "packages/sanguokill/qml/ZhidiBox"
}

local LoC__angela_qidian_T = fk.CreateTriggerSkill {
    name = "LoC__angela_qidian_T",
    events = { fk.CardUsing },
    anim_type = "special",
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return player == target and player:hasSkill(self) and data.card
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local mark = player.getTableMark(player, "@[Qidian_T]")
        if #mark == 0 then
            mark = { {}, {}, {} }
        end
        table.insertIfNeed(mark[1], Fk:translate(data.card:getTypeString() .. "_char"))
        if #mark[1] == 3 then
            player:drawCards(1, self.name)
            mark[1] = {}
        end
        if data.card.suit ~= Card.NoSuit then
            table.insertIfNeed(mark[2], Fk:translate(data.card:getSuitString(true)))
            if #mark[2] == 4 then
                room:addPlayerMark(player, "@Qidian_T_1")
                mark[2] = {}
            end
        end
        if data.card.number > 0 then
            if #mark[3] > 0 then
                for i, value in ipairs(mark[3]) do
                    if value > data.card.number then
                        if not table.contains(mark[3], data.card.number) then
                            table.insert(mark[3], i, data.card.number)
                        end
                        break
                    end
                    if i == #mark[3] then
                        if not table.contains(mark[3], data.card.number) then
                            table.insert(mark[3], data.card.number)
                        end
                    end
                end
            else
                table.insertIfNeed(mark[3], data.card.number)
            end

            if #mark[3] == 13 then
                room:setPlayerMark(player, "@@Qidian_T_2", 1)
                mark[3] = {}
            end
        end
        room:setPlayerMark(player, "@[Qidian_T]", mark)
    end,
}

local LoC__angela_qidian_T_trigger = fk.CreateTriggerSkill {
    name = "#LoC__angela_qidian_T_trigger",
    frequency = Skill.Compulsory,
    anim_type = "special",
    events = { fk.TargetSpecified, fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(LoC__angela_qidian_T) then
            if event == fk.TargetSpecified then
                return player:getMark("@Qidian_T_1") > 0
            else
                return player:getMark("@@Qidian_T_2") > 0
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TargetSpecified then
            data.additionalEffect = (data.additionalEffect or 0) + 1
            room:removePlayerMark(player, "@Qidian_T_1")
        else
            room:removePlayerMark(player, "@@Qidian_T_2")
            player:gainAnExtraTurn(true)
        end
    end,

}

local LoC__angela_qidian_K = fk.CreateTriggerSkill {
    name = "LoC__angela_qidian_K",
    prompt = "#LoC__angela_qidian_K",
    anim_type = "defensive",
    events = { fk.DamageInflicted },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.getTableMark(player, "@Qidian_K") and
        #player.getTableMark(player, "@Qidian_K") > 0 and player:usedSkillTimes(self.name,Player.HistoryTurn)==0
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local p_hp = player.getTableMark(player, "@Qidian_K")[1]
        local p_maxhp = player.getTableMark(player, "@Qidian_K")[2]
        room:changeMaxHp(player, p_maxhp - player.maxHp)
        room:changeHp(player, p_hp - player.hp)
        return true
    end,
}
local LoC__angela_qidian_K_turnend = fk.CreateTriggerSkill {
    name = "#LoC__angela_qidian_K_turnend",
    prompt = "#LoC__angela_qidian_K_turnend_prompt",
    anim_type = "special",
    events = { fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        player.room:setPlayerMark(player, "@Qidian_K", { player.hp, player.maxHp })
    end,
}

local LoC__angela_qidian_R = fk.CreateTriggerSkill {
    name = "LoC__angela_qidian_R",
    prompt = "#LoC__angela_qidian_R",
    anim_type = "big",
    events = { fk.EnterDying },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        player:throwAllCards("he")
        player:drawCards(3, self.name)
        room:changeMaxHp(player, 3 - player.maxHp)
        room:changeHp(player, 3 - player.hp)
        room:addPlayerMark(player, "Qidian_R")
        room:addPlayerMark(player, "@Qidian_R", 7)
    end,

    refresh_events = { fk.DamageCaused, fk.TurnEnd },
    can_refresh = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player:getMark("@Qidian_R") > 0
    end,
    on_refresh = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TurnEnd then
            room:notifySkillInvoked(player, self.name, "special")
            room:removePlayerMark(player, "@Qidian_R")
            if player:getMark("@Qidian_R") == 0 then
                room:killPlayer({
                    who = player.id,
                    damage = {}
                })
            end
        else
            room:notifySkillInvoked(player, self.name, "offensive")
            data.damage = (data.damage or 0) + 1
        end
    end
}

local LoC__angela_duoguang = fk.CreateTriggerSkill {
    name = "LoC__angela_duoguang",
    anim_type = "special",
    prompt = "#LoC__angela_duoguang",
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            for _, p in ipairs(player.room:getOtherPlayers(player)) do
                if p:getMark("@guangzhizhong") > 0 then
                    return true
                end
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        for _, p in ipairs(player.room:getOtherPlayers(player)) do
            if p:getMark("@guangzhizhong") > 0 then
                room:addPlayerMark(player, "@guangzhizhong", p:getMark("@guangzhizhong"))
                room:removePlayerMark(p, "@guangzhizhong", p:getMark("@guangzhizhong"))
            end
        end
    end,
}

LoC__angela_qidian_T:addRelatedSkill(LoC__angela_qidian_T_trigger)
LoC__angela_qidian_K:addRelatedSkill(LoC__angela_qidian_K_turnend)

LoC__angela:addSkill(LoC__angela_qidian_T)
LoC__angela:addSkill(LoC__angela_qidian_K)
LoC__angela:addSkill(LoC__angela_qidian_R)
LoC__angela:addSkill(LoC__angela_duoguang)

Fk:loadTranslationTable {
    ["LoC__angela"] = "安吉拉",
    ["#LoC__angela"] = "脑叶公司AI助理",
    ["~LoC__angela"] = "安吉拉，我只是个普通人",
    ["designer:LoC__angela"] = "Rem",

    ["LoC__angela_qidian_T"] = "奇点T",
    ["#LoC__angela_qidian_T_trigger"] = "奇点T",
    ["$LoC__angela_qidian_T"] = "我会用你熟悉的方式……向你展示。",
    [":LoC__angela_qidian_T"] = "锁定技，每当你使用3种不同类型的牌时，你摸一张牌；每当你使用4种不同花色的牌时，你下一张牌额外结算一次；每当你使用13种点数不同的牌时，本回合结束时获得一个额外回合。",
    ["@[Qidian_T]"] = "奇点T",
    ["@Qidian_T_1"] = "奇点T_1",
    ["@@Qidian_T_2"] = "奇点T_2",

    ["LoC__angela_qidian_K"] = "奇点K",
    ["$LoC__angela_qidian_K"] = "我悄悄告诉人们生命的真谛，他们便会珍惜自己的情感。",
    ["#LoC__angela_qidian_K"] = "奇点K:当你受到伤害时，你将体力与体力上限修改为记录的数据，然后防止本次伤害。",
    [":LoC__angela_qidian_K"] = "每回合限一次，当你即将受到伤害时，将体力与体力上限修改为记录的数据并防止本次伤害（若无数据则无法防止伤害）。你的回合结束时，你可以记录当前体力与体力上限。",
    ["@Qidian_K"] = "奇点K",
    ["#LoC__angela_qidian_K_turnend"]="奇点K",
    ["#LoC__angela_qidian_K_turnend_prompt"]="奇点K：你可以记录当前体力值与体力上限",

    ["LoC__angela_qidian_R"] = "奇点R",
    ["$LoC__angela_qidian_R"] = "毕竟，人只爱自己。",
    ["#LoC__angela_qidian_R"] = "奇点R:你需弃置所有牌，将体力与体力上限修改为3/3，本局游戏你造成的伤害+1，7回合之后，你死亡。",
    [":LoC__angela_qidian_R"] = "限定技，当你进入濒死时，你需弃置所有牌，将体力与体力上限修改为3/3，本局游戏你造成的伤害+1，7回合之后，你死亡。",
    ["@Qidian_R"] = "奇点R",

    ["LoC__angela_duoguang"] = "夺光",
    ["$LoC__angela_duoguang"] = "真是可怜，压抑了自己的情感，还让自己深陷其中......",
    ["#LoC__angela_duoguang"] = "夺光:若场上拥有【光之种】标记，你可以夺取之",
    [":LoC__angela_duoguang"] = "你的回合开始时，若场上拥有【<a href='Guangzhizhong_jieshao'>光之种</a>】标记，你可以夺取之",

}

return extension
