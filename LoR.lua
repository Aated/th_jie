local extension = Package:new("LoR")
extension.extensionName = "th_jie"
local U = require "packages/utility/utility"
local LoR_Utility = require "packages/th_jie/LoR_Utility"

Fk:loadTranslationTable {
    ["LoR"] = "Library Of Runia",
    ["LoR_shu"] = "书"
}
local SiShu_EGO = { "Malkuth_Angela_EGO", "Yesod_Angela_EGO__slash", "Hod_Angela_EGO", "Netzach_Angela_EGO",
    "Tiphereth_Angela_EGO", "Gebura_Angela_EGO", "Chesed_Angela_EGO", "Binah_Angela_EGO", "Hokma_Angela_EGO" }
local Angela_Cards = { "LoR_angela_haixiu", "LoR_angela_youyi", "LoR_angela_xueyi__slash", "LoR_angela_aiyi",
    "LoR_angela_guanjiu__slash" }
Fk:appendKingdomMap("god", { "LoR_shu" })

local LoR_luolan = General:new(extension, "LoR_luolan", "LoR_shu", 5, 5, 1)

local LoR_luolan_qiheijinmo = fk.CreateTriggerSkill {
    name = "LoR_luolan_qiheijinmo",
    frequency = Skill.Compulsory,
    mute = true,
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_cost = function(self, event, target, player, data)
        if player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
            local bgm = player.room:askForChoices(player, { "playerbgm", "dontplayerbgm" }, 1, 1, self.name, "tipsbgm",
                false)
            if bgm[1] == "playerbgm" then
                player.room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_luolan_qiheijinmo2")
            end
        end
        return true
    end,
    on_use = function(self, event, target, player, data)
        player.room:notifySkillInvoked(player, self.name, "drawcard")
        player.room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_luolan_qiheijinmo1")
        player:drawCards(2, self.name)
    end
}
local LoR_luolan_qiheijinmo_threeCards = fk.CreateTriggerSkill {
    name = "#LoR_luolan_qiheijinmo_threeCards",
    frequency = Skill.Compulsory,
    events = { fk.CardUsing },
    mute = true,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_trigger = function(self, event, target, player, data)
        player.room:addPlayerMark(player, "@LuoLan_Jin", 1)
        if player:getMark("@LuoLan_Jin") % 3 == 0 then
            data.additionalDamage = 1
            data.additionalRecover = 1
            player.room:broadcastPlaySound(The_jie_path .. "audio/skill/LoR_luolan_qiheijinmo1")
            player.room:doAnimate("InvokeSkill", {
                name = "LoR_luolan_qiheijinmo",
                player = player.id,
                skill_type = "special",
            })
            player.room:setPlayerMark(player, "@LuoLan_Jin", 0)
        end
    end
}

local LoR_luolan_JuShu = fk.CreateTriggerSkill {
    name = "LoR_luolan_JuShu",
    anim_type = "drawcard",
    events = { fk.TargetSpecifying },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target ~= player and player:hasSkill(self) and data.card.trueName == "slash" and data.to == player.id
    end,
    on_use = function(self, event, target, player, data)
        player.room:doAnimate("InvokeSkill", {
            name = "LoR_luolan_JuShu",
            player = player.id,
            skill_type = "drawcard",
        })
        player:drawCards(1, self.name)
    end
}

local LoR_luolan_langya = fk.CreateTriggerSkill {
    name = "LoR_luolan_langya",
    anim_type = "drawcard",
    events = { fk.CardResponding },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        player:drawCards(1, self.name)
    end
}

local LoR_luolan_oldboy = fk.CreateActiveSkill {
    name = "LoR_luolan_oldboy",
    anim_type = "drawcard",
    prompt = "#LoR_luolan_oldboy",
    can_use = function(self, player)
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end,
    on_use = function(self, room, cardUseEvent)
        local player = room:getPlayerById(cardUseEvent.from)
        room:changeMaxHp(player, 1)
        player:drawCards(2, self.name)
    end
}

local LoR_luolan_alasi = fk.CreateTriggerSkill {
    name = "LoR_luolan_alasi",
    events = { fk.DamageCaused },
    prompt = "#LoR_luolan_alasi",
    anim_type = "special",
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) and player:usedSkillTimes(self.name) == 0 then
            if data.from == target and data.to == player then
                self.cost_data = 0
                return true
            end
            if target == player then
                self.cost_data = 1
                return true
            end
        else
            return false
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local num
        if self.cost_data == 0 then
            data.damage = data.damage - 1
        elseif self.cost_data == 1 then
            data.damage = data.damage + 1
        end
        num = data.damage
        if num > 5 then
            num = 5
        end
        player:drawCards(num, self.name)
    end
}

local LoR_luolan_mo = fk.CreateTriggerSkill {
    name = "LoR_luolan_mo",
    events = { fk.DamageCaused },
    anim_type = "special",
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and
            player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local skills = {}
        for _, s in ipairs(player.player_skills) do
            local str = Fk:translate(":" .. s.name)
            if not (s.attached_equip or s.name[#s.name] == "&" or s.frequency == Skill.Wake or s.frequency == Skill.Quest or s.frequency == Skill.Limited)
                and (string.find(str, "阶段限.-次") or string.find(str, "回合限.-次")) and s.name ~= self.name then
                table.insertIfNeed(skills, s.name)
            end
        end
        if #skills > 0 then
            local skill = room:askForChoices(player, skills, 1, 1, self.name)
            if #skill > 0 then
                table.contains(skill, self.name)
                for _, skill_name in ipairs(skill) do
                    local ids = Fk.skills[skill_name]
                    local scope_type = ids.scope_type
                    if scope_type == nil then
                        scope_type = Player.HistoryPhase
                    end
                    if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
                        player:setSkillUseHistory(skill_name, 0, scope_type)
                    end
                end
                for _, skill_name in ipairs(skill) do
                    local ids = Fk.skills[skill_name]
                    local scope_type = ids.scope_type
                    if scope_type == nil then
                        scope_type = Player.HistoryTurn
                    end
                    if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
                        player:setSkillUseHistory(skill_name, 0, scope_type)
                    end
                end
            end
        end
    end
}

local LoR_luolan_luoji = fk.CreateTriggerSkill {
    name = "LoR_luolan_luoji",
    anim_type = "offensive",
    events = { fk.AskForCardUse, fk.AskForCardResponse },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and target == player and
            (data.cardName == "jink" or (data.pattern and Exppattern:Parse(data.pattern):matchExp("jink|0|nosuit|none")))
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local drawcard = player:drawCards(1, self.name)
        local discard = room:askForDiscard(player, 1, 1, true, self.name, false)
        if Fk:getCardById(drawcard[1]).type ~= Fk:getCardById(discard[1]).type then
            local card = Fk:cloneCard("jink")
            card.skillName = "LoR_luolan_luoji"
            if event == fk.AskForCardUse then
                data.result = { from = player.id, card = card }
                if data.eventData then
                    data.result.toCard = data.eventData.toCard
                    data.result.responseToEvent = data.eventData.responseToEvent
                end
            else
                data.result = card
            end
        end
    end

}

local LoR_luolan_dulan = fk.CreateTriggerSkill {
    name = "LoR_luolan_dulan",
    anim_type = "offensive",
    frequency = Skill.Compulsory,
    events = { fk.TargetSpecifying },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and target == player and data.card.trueName == "slash"
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if data.additionalDamage == nil then
            data.additionalDamage = 0
        end
        if player:getMark("@dulan") < 1 then
            data.additionalDamage = (data.additionalDamage or 0) - 1
            player.room:setPlayerMark(player, "@dulan", 1)
            if player:getHandcardNum() > 0 then
                if #room:getPlayerById(data.to):getCardIds("he") > 0 then
                    local targeycard = room:askForCardChosen(player, room:getPlayerById(data.to), "he", self.name)
                    room:throwCard(targeycard, self.name, room:getPlayerById(data.to), player)
                end
            end
        elseif player:getMark("@dulan") == 1 then
            data.additionalDamage = data.additionalDamage + 2
            player.room:setPlayerMark(player, "@dulan", 0)
        end
    end
}

local LoR_luolan_kalisita = fk.CreateTriggerSkill {
    name = "LoR_luolan_kalisita",
    anim_type = "support",
    events = { fk.ChainStateChanged, fk.TurnedOver },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) and target == player then
            return ((event == fk.TurnedOver and not target.faceup) or (event == fk.ChainStateChanged and target.chained)) and
                #player:getCardIds("he") > 1 and player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        player:drawCards(1, self.name)
        local room = player.room
        room:askForDiscard(player, 2, 2, true, self.name, false)
        player:setChainState(false)
        if not player.faceup then
            player:turnOver()
        end
        if #player:getCardIds("h") < player.maxHp then
            player:drawCards(player.maxHp - player:getHandcardNum(), self.name)
        elseif #player:getCardIds("h") == player.maxHp then
            local playerids = {}
            for _, value in ipairs(room:getOtherPlayers(player)) do
                table.insertIfNeed(playerids, value.id)
            end
            local target1 = room:askForChoosePlayers(player, playerids, 1, 1, "#LoR_luolan_kalisita", self.name, true)
            player.room:damage({
                from = player,
                to = room:getPlayerById(target1[1]),
                damage = 1
            })
        elseif #player:getCardIds("h") > player.maxHp then
            room:recover({
                who = player,
                num = player.maxHp,
                skillName = self.name
            })
        end
    end
}

local LoR_luolan_lunpan = fk.CreateTriggerSkill {
    name = "LoR_luolan_lunpan",
    anim_type = "control",
    events = { fk.TargetConfirmed },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and data.card.trueName == "slash" and not player:isKongcheng() and
            not player.room:getPlayerById(data.from):isKongcheng()
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local pindian = player:pindian({ room:getPlayerById(data.from) }, self.name)
        if pindian.results[data.from].winner == player then
            room:useCard({
                from = player.id,
                tos = { { data.from } },
                card = Fk:cloneCard("slash")
            })
        elseif pindian.results[data.from].winner ~= player then
            player.room:obtainCard(player.id, pindian.fromCard)
        end
    end
}

--漆黑噤默：罗兰 5/5
--漆黑噤默：锁定技，准备阶段开始时，你摸两张牌。每当你使用三张牌时，该牌伤害+1或回复+1。
--Furioso:锁定技，游戏开始时，你获得9个储备技能，然后你选择一个技能获得之。回合开始时，失去以此法获得的技能，然后从储备技能里选择一个未被选择过的技能。若储备技能均被选择过，你获得全部储备技能与【Furioso-解】并失去此技能。
--榉树工坊：锁定技，当你使用杀时，摸一张牌。
--琅琊工坊：锁定技，当你打出一张牌时，摸一张牌。
--老男孩工坊：出牌阶段限一次，你可以回复三点体力并摸一张牌。
--阿拉斯工坊：每回合限一次，当你造成/受到伤害时，令伤害值+1/-1.
--墨工坊：每轮限一次，当你使用杀造成伤害时，你可以摸一张牌并重置一个有回合限制的技能。
--逻辑工作室：当你使用或打出闪时，你摸一张牌并弃置一张牌，若弃置牌与你摸的一张牌类型一致，则你可以获得一张其他角色的一张牌
--杜兰达尔：当你使用杀时，你可以令此杀伤害-1并收回此杀。若如此做，你的下一张杀造成的伤害+2。
--卡莉斯塔工作室：每轮限一次，当你被横置或翻至背面时，你可以摸一张牌，然后弃置两张牌复原武将牌，若你的手牌小于/等于/大于体力上限，将手牌摸至体力上限/对一名角色造成一点伤害/体力回复至手牌数量。
--轮盘重工：当你成为杀的目标时，你可以与其拼点，若你赢，则此杀对你无效并且视为你对其使用一张杀，若你没赢，你获得所有拼点牌。
--Furioso-EX：限定技：出牌阶段，你可以令一名其他角色的非锁定技失效直到本回合结束，然后你与对方进行拼点，若你没赢，你获得其一个技能，否则你令其失去当前所有牌与体力。

--PVP禁将。

local LoR_luolan_skills = { "LoR_luolan_JuShu", "LoR_luolan_langya", "LoR_luolan_oldboy", "LoR_luolan_alasi",
    "LoR_luolan_mo", "LoR_luolan_luoji", "LoR_luolan_dulan", "LoR_luolan_kalisita", "LoR_luolan_lunpan" }


local LoR_luolan_Furioso = fk.CreateTriggerSkill {
    name = "LoR_luolan_Furioso",
    mute = true,
    events = { fk.GameStart, fk.TurnStart },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if event == fk.GameStart then
                return true
            else
                return target == player
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.GameStart then
            for _, skill in ipairs(LoR_luolan_skills) do
                player:addMark(skill, 1)
            end
        end
        local LoR_luolan_removeskills = {}
        for _, skill in ipairs(LoR_luolan_skills) do
            if player:getMark(skill) > 0 then
                table.insertIfNeed(LoR_luolan_removeskills, skill)
            end
            if table.contains(player.player_skills, Fk.skills[skill]) then
                player.room:handleAddLoseSkills(player, "-" .. skill, nil, true, false)
            end
        end
        if #LoR_luolan_removeskills > 0 then
            local chooseSkill = player.room:askForChoice(player, LoR_luolan_removeskills, self.name,
                "#LoR_luolan_Furioso-choose", true)
            if chooseSkill == nil then
                chooseSkill = table.random(LoR_luolan_removeskills, 1)[1]
            end
            room:handleAddLoseSkills(player, chooseSkill, nil, true, false)
            player:removeMark(chooseSkill, 1)
        else
            room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_luolan_Furioso")
            LoR_Utility.EGOChangeGeneral(player, "LoR_luolan", "LoR_luolan_new__black")
        end
    end,
}

local LoR_luolan_FuriosoEX = fk.CreateActiveSkill {
    name = "LoR_luolan_FuriosoEX",
    anim_type = "big",
    target_num = 1,
    frequency = Skill.Limited,
    target_filter = function(self, to_select, selected)
        if #selected == 0 then
            return not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
        end
    end,
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryGame) == 0
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.tos[1])
        room:setPlayerMark(target, "@FuriosoEX-turn")
        local pindian = player:pindian({ target }, self.name)

        if pindian.results[target.id].winner == player then
            target:throwAllCards("he")
            room:loseHp(target, target.hp, self.name)
        elseif pindian.results[target.id].winner ~= player then
            local targetskill = {}
            for _, s in ipairs(target.player_skills) do
                if not (s.attached_equip) then
                    table.insertIfNeed(targetskill, s.name)
                end
            end
            local chooseSkill = player.room:askForChoice(player, targetskill, self.name,
                "#LoR_luolan_FuriosoEX-choose", true)
            player.room:handleAddLoseSkills(player, chooseSkill, nil, true, false)
        end
    end
}

local LoR_luolan_FuriosoEX_Invalidity = fk.CreateInvaliditySkill {
    name = "#LoR_luolan_FuriosoEX_Invalidity",
    invalidity_func = function(self, from, skill)
        if from:getMark("@FuriosoEX-turn") ~= 0 then
            return table.contains(from:getMark("@FuriosoEX-turn"), skill.name) and
                (skill.frequency ~= Skill.Compulsory and skill.frequency ~= Skill.Wake) and not skill.name:endsWith("&")
        end
    end
}

LoR_luolan_FuriosoEX:addRelatedSkill(LoR_luolan_FuriosoEX_Invalidity)
LoR_luolan_qiheijinmo:addRelatedSkill(LoR_luolan_qiheijinmo_threeCards)
LoR_luolan:addSkill(LoR_luolan_qiheijinmo)

Fk:addSkill(LoR_luolan_JuShu)
Fk:addSkill(LoR_luolan_langya)
Fk:addSkill(LoR_luolan_oldboy)
Fk:addSkill(LoR_luolan_alasi)
Fk:addSkill(LoR_luolan_mo)
Fk:addSkill(LoR_luolan_luoji)
Fk:addSkill(LoR_luolan_dulan)
Fk:addSkill(LoR_luolan_kalisita)
Fk:addSkill(LoR_luolan_lunpan)

for _, value in ipairs(LoR_luolan_skills) do
    LoR_luolan:addRelatedSkill(value)
end
LoR_luolan:addRelatedSkill(LoR_luolan_FuriosoEX)

LoR_luolan:addSkill(LoR_luolan_Furioso)


Fk:loadTranslationTable {
    ["LoR_luolan"] = "罗兰",
    ["#LoR_luolan"] = "漆黑噤默",
    ["designer:LoR_luolan"] = "Rem",
    ["~LoR_luolan"] = "呃.....我不太习惯这种场合",
    ["cv:LoR_luolan"] = "Son Soo-ho",

    ["@LuoLan_Jin"] = "噤",

    ["LoR_luolan_qiheijinmo"] = "漆黑噤默",
    ["#LoR_luolan_qiheijinmo_threeCards"] = "漆黑噤默触发技",
    ["$LoR_luolan_qiheijinmo1"] = "一码归一码",
    ["$LoR_luolan_qiheijinmo2"] = "罗兰解放战主题曲",
    [":LoR_luolan_qiheijinmo"] = "锁定技，准备阶段开始时，你摸两张牌。每当你使用三张牌时，该牌伤害+1或回复+1。",


    ["LoR_luolan_JuShu"] = "榉树工坊",
    [":LoR_luolan_JuShu"] = "锁定技，当你成为【杀】的目标时，摸一张牌。",


    ["LoR_luolan_langya"] = "琅琊工坊",
    [":LoR_luolan_langya"] = "锁定技，当你因响应而打出牌时，摸一张牌。",

    ["LoR_luolan_oldboy"] = "老男孩工坊",
    ["#LoR_luolan_oldboy"] = "你可以增加一点体力上限，并摸两张牌。",
    [":LoR_luolan_oldboy"] = "出牌阶段限一次，你可以增加一点体力上限并摸两张牌。",

    ["LoR_luolan_alasi"] = "阿拉斯工坊",
    [":LoR_luolan_alasi"] = "每回合限一次，当你造成/受到伤害时，令伤害值+1/-1，然后你摸此次伤害值的牌(至多为5)",

    ["LoR_luolan_mo"] = "墨工坊",
    [":LoR_luolan_mo"] = "每回合限一次，当你造成伤害时，你可以重置你的一个有回合限制的技能。(本技能和觉醒/限定/使命/主公技除外)",

    ["LoR_luolan_luoji"] = "逻辑工作室",
    [":LoR_luolan_luoji"] = "当你需要使用或打出【闪】时，你摸一张牌并弃置一张牌，若弃置牌与你摸的一张牌类型不一致，你视为使用或打出【闪】",
    ["#LoR_luolan_luoji"] = "请选择一名角色，然后获得其一张牌",

    ["@dulan"] = "杜兰",
    ["LoR_luolan_dulan"] = "杜兰达尔",
    [":LoR_luolan_dulan"] = "锁定技，当你使用【杀】时，若你没有“杜兰”，你令此【杀】伤害-1并弃置目标一张手牌,然后获得“杜兰”。若你拥有“杜兰”，使用【杀】造成的伤害+2，然后失去“杜兰”。",

    ["LoR_luolan_kalisita"] = "卡莉斯塔",
    [":LoR_luolan_kalisita"] = "每回合限一次，当你被横置或翻至背面时，你可以摸一张牌，然后弃置两张牌复原武将牌，若你的手牌小于/等于/大于体力上限，将手牌摸至体力上限/对一名其他角色造成一点伤害/体力回复至手牌数量。",
    ["#LoR_luolan_kalisita"] = "请选择一名其他玩家造成一点伤害",

    ["LoR_luolan_lunpan"] = "轮盘重工",
    [":LoR_luolan_lunpan"] = "当你成为【杀】的目标时，你可以与其拼点，若你赢，则视为你对其使用一张【杀】，若你没赢，你收回你的拼点牌。",

    ["LoR_luolan_Furioso"] = "Furioso",
    ["#LoR_luolan_Furioso-choose"] = "请选择一把罗兰的武器",
    [":LoR_luolan_Furioso"] = "锁定技，游戏开始时，你获得9个储备技能，然后你选择一个技能获得之。回合开始时，失去以此法获得的技能，然后从储备技能里选择一个未被选择过的技能。若储备技能均被选择过，你获得全部储备技能与【Furioso-EX】并失去此技能。",
    ["$LoR_luolan_Furioso"] = "漆黑噤默主题曲",

    ["LoR_luolan_FuriosoEX"] = "Furioso-EX",
    ["#LoR_luolan_FuriosoEX-choose"] = "请选择一个技能获取之",
    ["@FuriosoEX-turn"] = "Furioso-EX",
    [":LoR_luolan_FuriosoEX"] = "限定技：出牌阶段，你可以令一名角色的非锁定技失效直到回合结束，然后你与对方进行拼点，若你没赢，你获得其武将牌上一个技能，否则你令其失去当前所有体力与牌。",


    ["playerbgm"] = "播放罗兰解放战第一阶段BGM",
    ["dontplayerbgm"] = "不播放BGM",
    ["tipsbgm"] = "是否要播放BGM(算作技能音效，房间内播放)",
}



local LoR_luolan_new__black = General:new(extension, "LoR_luolan_new__black", "LoR_shu", 5, 5, 1)

LoR_luolan_new__black.total_hidden = true

local LoR_luolan_qiheijinmo_black = fk.CreateTriggerSkill {
    name = "LoR_luolan_qiheijinmo_black",
    anim_type = "drawcards",
    frequency = Skill.Compulsory,
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        player:drawCards(2, self.name)
    end
}
local LoR_luolan_qiheijinmo_threeCards_black = fk.CreateTriggerSkill {
    name = "#LoR_luolan_qiheijinmo_threeCards_black",
    frequency = Skill.Compulsory,
    events = { fk.CardUsing },
    mute = true,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        player.room:addPlayerMark(player, "@LuoLan_Jin", 1)
        if player:getMark("@LuoLan_Jin") % 3 == 0 then
            data.additionalDamage = 1
            data.additionalRecover = 1
            player:broadcastSkillInvoke("LoR_luolan_qiheijinmo_black")
            player.room:doAnimate("InvokeSkill", {
                name = "LoR_luolan_qiheijinmo",
                player = player.id,
                skill_type = "special",
            })
            player.room:setPlayerMark(player, "@LuoLan_Jin", 0)
        end
    end
}

LoR_luolan_qiheijinmo_black:addRelatedSkill(LoR_luolan_qiheijinmo_threeCards_black)
LoR_luolan_new__black:addSkill(LoR_luolan_qiheijinmo_black)
for _, value in ipairs(LoR_luolan_skills) do
    LoR_luolan_new__black:addSkill(value)
end
LoR_luolan_new__black:addSkill("LoR_luolan_FuriosoEX")


Fk:loadTranslationTable {
    ["LoR_luolan_new"] = "漆黑噤默",
    ["LoR_luolan_new__black"] = "漆黑噤默",
    ["#LoR_luolan_new__black"] = "十二收尾人",
    ["~LoR_luolan_new__black"] = "只顾及眼前，满足于当下结果……秉持着利己主义的愚蠢之徒……那是你。也是我……",
    ["designer:LoR_luolan_new__black"] = "Rem",
    ["illustrator:LoR_luolan_new__black"] = "ProjectMoon",
    ["cv:LoR_luolan_new__black"] = "Son Soo-ho",

    ["LoR_luolan_qiheijinmo_black"] = "漆黑噤默",
    ["#LoR_luolan_qiheijinmo_threeCards_black"] = "漆黑噤默触发技",
    ["$LoR_luolan_qiheijinmo_black"] = "我会将一切尽数奉还给你的…",
    [":LoR_luolan_qiheijinmo_black"] = "锁定技，准备阶段开始时，你摸两张牌。每当你使用三张牌时，该牌伤害+1或回复+1。",

}

--语言层司书     卡莉    99999

--卡莉：锁定技：摸牌阶段额外摸牌+1。你每受到1点伤害，获得1层【混乱】。
--若你于出牌阶段造成的伤害不大于4点，你的【混乱】层数+4。当你体力值为不大于1时，失去所有【混乱】，
--然后进入【E.G.O展现】状态。你的回合开始或结束时，若你的【混乱】层数等于10，则你立即失去所有【混乱】层数并进入【E.G.O展现】状态。
--(混乱:层数至多为10)

--#E.G.O.展现：将你的体力调整至体力上限，立即执行一个额外回合。修改武将为《最强之人》

--后发制敌：出牌回合限一次，你获得一层4至8点的【反击】。

--#反击：当你成为伤害牌的目标时，你进行一次判定:若判定点数不大于【反击】点数，则你视为对其使用一张【杀】；否则你失去一层【反击】。
local LoR_kali = General:new(extension, "LoR_kali", "LoR_shu", 5, 5, General.Female)

local LoR_kali_kali = fk.CreateTriggerSkill {
    name = "LoR_kali_kali",
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.DrawNCards, fk.Damaged },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:notifySkillInvoked(player, self.name, "special")
        if event == fk.DrawNCards then
            room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_kali_kali2")
            data.n = data.n + 1
        else
            room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_kali_kali2")
            local num = player:getMark("@HunLuan_LoR") + data.damage
            if num > 10 then
                num = 10
            end
            room:setPlayerMark(player, "@HunLuan_LoR", num)
        end
    end,
}
local LoR_kali_kali_turn = fk.CreateTriggerSkill {
    name = "#LoR_kali_kali_turn",
    frequency = Skill.Compulsory,
    mute = true,
    events = { fk.EventPhaseStart, fk.EventPhaseEnd },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(LoR_kali_kali) then
            if player.phase == Player.Start and event == fk.EventPhaseStart and player:getMark("@HunLuan_LoR") == 10 then
                return true
            elseif event == fk.EventPhaseEnd and player.phase == Player.Play and player:getMark("LoR_kali_damage-turn") <= 4 then
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.EventPhaseStart then
            room:notifySkillInvoked(player, "LoR_kali_kali", "special")
            room:removePlayerMark(player, "@HunLuan_LoR", player:getMark("@HunLuan_LoR"))
            room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_kali_kali1")

            LoR_Utility.EGOChangeGeneral(player, "LoR_kali", "LoR_kali_RedMist")
        else
            room:notifySkillInvoked(player, "LoR_kali_kali", "special")
            room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_kali_kali2")
            local num = player:getMark("@HunLuan_LoR") + 4
            if num > 10 then
                num = 10
            end
            room:setPlayerMark(player, "@HunLuan_LoR", num)
        end
    end
}
local LoR_kali_kali_damage = fk.CreateTriggerSkill {
    name = "#LoR_kali_kali_damage",
    anim_type = "special",
    frequency = Skill.Compulsory,
    events = { fk.Damage, fk.HpChanged },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(LoR_kali_kali) then
            if player.phase == Player.Play and event == fk.Damage then
                return true
            elseif event == fk.HpChanged and player.hp <= 1 then
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.HpChanged then
            room:removePlayerMark(player, "@HunLuan_LoR", player:getMark("@HunLuan_LoR"))
            room:broadcastPlaySound("./packages/th_jie/audio/skill/LoR_kali_kali2")
            LoR_Utility.EGOChangeGeneral(player, "LoR_kali", "LoR_kali_RedMist")
        elseif event == fk.Damage then
            player:addMark("LoR_kali_damage-turn", 1)
        end
    end
}

local LoR_kali_houfa = fk.CreateActiveSkill {
    name = "LoR_kali_houfa",
    anim_type = "offensive",
    prompt = "#LoR_kali_houfa",
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
    end,
    on_use = function(self, room, cardUseEvent)
        local player = room:getPlayerById(cardUseEvent.from)
        local mark = player.getTableMark(player, "@Fanji_LoR")
        local mark_all = player.getTableMark(player, "Fanji_All")
        mark = { #player.getTableMark(player, "Fanji_All") + 1, math.random(4, 8) }
        table.insert(mark_all, mark)
        room:setPlayerMark(player, "Fanji_All", mark_all)


        room:setPlayerMark(player, "@Fanji_LoR", mark)
    end,
}



LoR_kali_kali:addRelatedSkill(LoR_kali_kali_turn)
LoR_kali_kali:addRelatedSkill(LoR_kali_kali_damage)
LoR_kali:addSkill(LoR_kali_kali)
LoR_kali:addSkill(LoR_kali_houfa)



Fk:loadTranslationTable {
    ["LoR_kali"] = "卡莉",
    ["#LoR_kali"] = "语言层司书",
    ["~LoR_kali"] = "果然不会轻易告诉我吗……",
    ["designer:LoR_kali"] = "Rem",

    ["LoR_kali_kali"] = "卡莉",
    [":LoR_kali_kali"] = "锁定技：摸牌阶段额外摸牌+1。你每受到1点伤害，获得1层【混乱】。" ..
        "若你于出牌阶段造成的伤害不大于4点，你的【混乱】层数+4。当你体力值为不大于1时，失去所有【混乱】，" ..
        "然后进入【E.G.O展现】状态。你的回合开始或结束时，若你的【混乱】层数等于10，则你立即失去所有【混乱】层数并进入【E.G.O展现】状态。"
        .. "(混乱:层数至多为10)" .. Fk:translate("EGOShow"),
    ["$LoR_kali_kali1"] = "殷红迷雾战斗曲",
    ["$LoR_kali_kali2"] = "喂，我的忍耐也是有极限的",

    ["@HunLuan_LoR"] = "混乱",
    ["#LoR_kali_kali_turn"] = "卡莉",
    ["#LoR_kali_kali_damage"] = "卡莉",

    ["LoR_kali_houfa"] = "后发制敌",
    ["#LoR_kali_houfa"] = "获得一层4~8点的【反击】",
    ["$LoR_kali_houfa"] = "尽早帮上忙要紧。",
    [":LoR_kali_houfa"] = "出牌阶段限一次，你获得一层4~8点的【反击】。" .. Fk:translate("Fanji_jieshao"),
}


-- 殷红迷雾    最强之人    99999

-- 殷红迷雾：锁定技：你使用【杀】伤害+2，使用【杀】次数+1。每回合开始时，你随机令一种你受到的伤害-1：【杀】造成的伤害;锦囊造成的伤害;非卡牌造成的伤害,直到你的下个回合开始时。你击杀一名角色时获得一层【血雾】。

-- #血雾：【杀】伤害+x（x为【血雾】层数）

-- 最强之人：锁定技，当你判定时，你的判定牌点数视为K。你的回合开始时，获得一层【反击↑】。你造成伤害时，若本次造成伤害的不小于4，你获得一层【强壮】

-- #反击↑:锁定技:当你成为【杀】的目标时，你进行一次判定:若此【杀】点数小于你的判定点数时，你视为对其使用一张【杀】；否则你失去一层【反击】。
-- #强壮：卡牌伤害+x（x为【强壮】层数），你的回合结束时，失去所有【强壮】

-- 后发制敌：锁定技：你的回合结束时，获得一层【反击↑】。当你受到伤害时，你令伤害来源获得一层【流血】

-- #流血：每次受到伤害时，额外受到x点无来源伤害，然后x减至2/3（向上取整）（x为【流血】层数）
-- #反击↑:锁定技:当你成为【杀】的目标时，你进行一次判定:若此【杀】点数小于你的判定点数时，你视为对其使用一张【杀】；否则你失去一层【反击】。


-- RedMist卡组：锁定技：每轮开始时，若你的手牌区没有【殷红迷雾E.G.O】，你随机获得一张【殷红迷雾E.G.O】。准备阶段开始时，若你的手牌区没有【殷红迷雾卡】，你随机获得一张【殷红迷雾卡】


-- 决意：出牌阶段限一次，当你使用【杀】造成伤害时，你回复一点体力，目标获得2层【流血】，你与目标获得一层【强壮】  —————— 守护他人的决意！

-- #流血：每次受到伤害时，额外受到x点无来源伤害，然后x减至2/3（向上取整）（x为【流血】层数）
-- #强壮：卡牌伤害+x（x为【强壮】层数），你的回合结束时，失去所有【强壮】


local LoR_kali_RedMist = General:new(extension, "LoR_kali_RedMist", "LoR_shu", 5, 5, 2)
LoR_kali_RedMist.total_hidden = true
local choice = { "basic", "trick", "notCardDamage" }
local RedMist_NormalCards =
{ "BingXi", "XianZhen__slash", "HengZhan__slash", "ZongPi__slash", "ZhiCi__slash" }

local RedMist_EGOCards = { "XueWuMiMan", "ShiHengBianYe__slash" }


local LoR_RedMist = fk.CreateTriggerSkill {
    name = "LoR_RedMist",
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.TurnStart, fk.CardUsing, fk.DamageInflicted, fk.Deathed },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if event == fk.Deathed and data.who ~= player and data.damage and data.damage.from == player then
                return true
            elseif event == fk.CardUsing and target == player and data.card.trueName == "slash" then
                return true
            elseif event == fk.TurnStart and target == player then
                return true
            elseif event == fk.DamageInflicted and target == player and player:getMark("@Mist") ~= nil then
                local damagetype = player:getMark("@Mist")
                if damagetype == "basic" then
                    damagetype = Card.TypeBasic
                elseif damagetype == "trick" then
                    damagetype = Card.TypeTrick
                end

                if data.by_user and data.card and data.card.type == damagetype then
                    return true
                elseif data.card == nil and damagetype == "notCardDamage" then
                    return true
                end
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.CardUsing then
            room:notifySkillInvoked(player, self.name, "offensive")
            data.additionalDamage = (data.additionalDamage or 0) + 2
        elseif event == fk.TurnStart then
            room:notifySkillInvoked(player, self.name, "special")
            local choiceOne = choice[math.random(3)]
            room:setPlayerMark(player, "@Mist", choiceOne)
        elseif event == fk.DamageInflicted then
            room:notifySkillInvoked(player, self.name, "defensive")
            data.damage = data.damage - 1
        elseif event == fk.Deathed then
            room:notifySkillInvoked(player, self.name, "support")
            room:setPlayerMark(player, "@RedMist", player:getMark("@RedMist") + 1)
        end
    end
}

local LoR_RedMist_slashNum = fk.CreateTargetModSkill {
    name = "#LoR_RedMist_slashNum",
    residue_func = function(self, player, skill, scope, card, to)
        if card.trueName == "slash" and player:hasSkill(LoR_RedMist) then
            return 1
        else
            return 0
        end
    end
}

local LoR_kali_RedMist_strongest = fk.CreateTriggerSkill {
    name = "LoR_kali_RedMist_strongest",
    anim_type = "special",
    frequency = Skill.Compulsory,
    events = { fk.AskForRetrial, fk.Damage, fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.Damage and data.from == player and data.damage >= 4 then
                return true
            elseif event == fk.AskForRetrial or (event == fk.TurnStart and player:getMark("@@Fanji2") == 0) then
                return true
            end
        end
        return false
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.AskForRetrial then
            local card_old = data.card
            local card_new = room:printCard(card_old.name, card_old.suit, 13)
            room:retrial(card_new, target, data, self.name, false)
        elseif event == fk.Damage then
            room:setPlayerMark(player, "@qiangzhuang", player:getMark("@qiangzhuang") + 1)
        else
            room:setPlayerMark(player, "@@Fanji2", 1)
        end
    end
}


local LoR_kali_RedMist_houfa_viewas = fk.CreateViewAsSkill {
    name = "#LoR_kali_RedMist_houfa_viewas",
    pattern = ".|.|.|.|.|basic,trick",
    interaction = function(self)
        local names = LoR_Utility.getViewAsCardNames(Self, self.name, RedMist_NormalCards)
        if #names > 0 then
            return UI.ComboBox { choices = names }
        end
    end,
    card_filter = Util.FalseFunc,
    view_as = function(self)
        if not self.interaction.data then return nil end
        local c = Fk:cloneCard(self.interaction.data)
        c.skillName = self.name
        return c
    end,
}
Fk:addSkill(LoR_kali_RedMist_houfa_viewas)

local LoR_kali_RedMist_houfa = fk.CreateTriggerSkill {
    name = "LoR_kali_RedMist_houfa",
    events = { fk.TurnEnd, fk.Damaged },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.Damaged and data.from and data.from ~= player then
                return true
            elseif event == fk.TurnEnd then
                return true
            end
        end
        return
    end,
    on_cost = function(self, event, target, player, data)
        if event == fk.Damaged then
            return true
        elseif event == fk.TurnEnd then
            return player.room:askForSkillInvoke(player, self.name)
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TurnEnd then
            room:notifySkillInvoked(player, self.name, "special")
            local pa = ".|13"
            local judge = {
                who = player,
                pattern = pa,
                reason = self.name
            }
            room:judge(judge)
            if judge.card.number > 12 then
                local _, dat = room:askForUseViewAsSkill(player, "#LoR_kali_RedMist_houfa_viewas",
                    "#LoR_kali_RedMist_houfa_viewas—prompt", true, { bypass_times = true, bypass_distance = true })
                if dat then
                    local c = Fk:cloneCard(dat.interaction)
                    c.skillName = self.name
                    room:useCard {
                        from = player.id,
                        tos = table.map(dat.targets, function(p) return { p } end),
                        card = c
                    }
                end
            end
        else
            room:notifySkillInvoked(player, self.name, "masochism")
            room:setPlayerMark(data.from, "@LiuXue_LoR", data.from:getMark("@LiuXue_LoR") + 1)
        end
    end
}

local LoR_kali_RedMist_getCards = fk.CreateTriggerSkill {
    name = "LoR_kali_RedMist_getCards",
    anim_type = "drawcard",
    frequency = Skill.Compulsory,
    events = { fk.TurnStart, fk.RoundStart },
    can_trigger = function(self, event, target, player, data)
        if player:hasSkill(self) then
            if target == player and event == fk.TurnStart and table.find(player.player_cards[Player.Hand], function(
                    card_id)
                    return table.contains(RedMist_NormalCards, Fk:getCardById(card_id).name)
                end) == nil then
                return true
            elseif event == fk.RoundStart and table.find(player.player_cards[Player.Hand], function(card_id)
                    return table.contains(RedMist_EGOCards, Fk:getCardById(card_id).name)
                end) == nil then
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local card1
        if event == fk.TurnStart then
            card1 = room:printCard(table.random(RedMist_NormalCards, 1)[1])
            room:moveCards({
                ids = { card1.id },
                fromArea = Card.Void,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player.id,
                skillName = self.name,
                moveVisible = true,
            })
        else
            card1 = room:printCard(table.random(RedMist_EGOCards, 1)[1])
            room:moveCards({
                ids = { card1.id },
                fromArea = Card.Void,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player.id,
                skillName = self.name,
                moveVisible = true,
            })
        end
        if card1 ~= nil then
            room:setCardMark(card1, MarkEnum.DestructIntoDiscard, 1)
        end
    end
}

local LoR_kali_RedMist_jueyi = fk.CreateTriggerSkill {
    name = "LoR_kali_RedMist_jueyi",
    anim_type = "support",
    events = { fk.Damage },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Play and data.card and
            data.card.trueName == "slash" and data.to and data.to ~= player and
            player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
        })
        room:setPlayerMark(data.to, "@LiuXue_LoR", data.to:getMark("@LiuXue_LoR") + 2)
        room:setPlayerMark(data.to, "@qiangzhuang", data.to:getMark("@qiangzhuang") + 1)
        room:setPlayerMark(player, "@qiangzhuang", player:getMark("@qiangzhuang") + 1)
    end
}

LoR_RedMist:addRelatedSkill(LoR_RedMist_slashNum)

LoR_kali_RedMist:addSkill(LoR_RedMist)
LoR_kali_RedMist:addSkill(LoR_kali_RedMist_strongest)
LoR_kali_RedMist:addSkill(LoR_kali_RedMist_houfa)
LoR_kali_RedMist:addSkill(LoR_kali_RedMist_getCards)
LoR_kali_RedMist:addSkill(LoR_kali_RedMist_jueyi)

Fk:loadTranslationTable {
    ["LoR_kali_RedMist"] = "最强之人",
    ["#LoR_kali_RedMist"] = "殷红迷雾",
    ["~LoR_kali_RedMist"] = "眼前的金钱……我不在乎。",
    ["designer:LoR_kali_RedMist"] = "Rem",

    ["LoR_RedMist"] = "殷红迷雾",
    [":LoR_RedMist"] = "锁定技：你使用【杀】伤害+2，使用【杀】次数+1。每回合开始时，你随机令一种你受到的伤害-1：" ..
        "【杀】造成的伤害;锦囊造成的伤害;非卡牌造成的伤害,直到你的下个回合开始时。你击杀一名角色时获得一层【血雾】。" .. Fk:translate("RedMist_jieshao"),

    ["LoR_kali_RedMist_strongest"] = "最强之人",
    [":LoR_kali_RedMist_strongest"] = "锁定技，当你判定时，你的判定牌点数视为K。你的回合开始时，若你没有【反击↑】，获得【反击↑】。你造成伤害时，若本次造成伤害的不小于4，你获得一层【强壮】"
        .. Fk:translate("Fanji2_jieshao") .. Fk:translate("qiangzhuang_jieshao"),

    ["LoR_kali_RedMist_houfa"] = "后发制敌",
    [":LoR_kali_RedMist_houfa"] = "你的回合结束时，你可以进行一次判定，若判定结果大于Q，你可以视为使用一张【殷弘迷雾卡】。锁定技，当你受到伤害时，你令伤害来源获得一层【流血】"
        .. Fk:translate("Fanji2_jieshao") .. Fk:translate("LiuXue_jieshao"),
    ["#LoR_kali_RedMist_houfa_viewas—prompt"] = "后发制敌:你可以视为使用一张【殷弘迷雾卡】",
    ["#LoR_kali_RedMist_houfa_viewas"] = "后发制敌",


    ["LoR_kali_RedMist_getCards"] = "RedMist卡组",
    [":LoR_kali_RedMist_getCards"] = "锁定技：每轮开始时，若你的手牌区没有【殷红迷雾E.G.O】，你随机获得一张【殷红迷雾E.G.O】。准备阶段开始时，若你的手牌区没有【殷红迷雾卡】，你随机获得一张【殷红迷雾卡】",

    ["LoR_kali_RedMist_jueyi"] = "决意",
    [":LoR_kali_RedMist_jueyi"] = "出牌阶段限一次，当你使用【杀】造成伤害时，你回复一点体力，目标获得2层【流血】，你与目标获得一层【强壮】 <font color='red'> —————— 守护他人的决意！</font>"
        .. Fk:translate("qiangzhuang_jieshao") .. Fk:translate("LiuXue_jieshao"),

    ["@Mist"] = "迷雾",
    ["notCardDamage"] = "非牌伤"
}


-- 废墟图书馆馆长  安吉拉  书 3/3
-- 光之种:锁定技，回合开始时，随机令一名我方角色获得一层【光之种】;回合结束时，你获得一张【司书信念之页】。

-- 馆藏:锁定技，准备阶段开始时，你随机获得一张【安吉拉专属战斗书页】和【司书信念之页】。你每使用九张【司书信念之页】时，获得【真理之页】。
-- 【真理之页】:出牌阶段限一次，你从随机三个【书】或【脑叶公司】势力的武将中选择一个技能获得，然后失去本技能。

local LoR__angel_master = General:new(extension, "LoR__angel_master", "LoR_shu", 3, 3, 2)

local LoR__angel_light = fk.CreateTriggerSkill {
    name = "LoR__angel_light",
    frequency = Skill.Compulsory,
    anim_type = "support",
    events = { fk.TurnStart, fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.TurnStart then
            room:addPlayerMark(table.random(LoR_Utility.GetFriends(room, player, true), 1)[1], "@guangzhizhong")
        else
            local card = room:printCard(table.random(SiShu_EGO, 1)[1])
            room:moveCards({
                ids = { card.id },
                fromArea = Card.Void,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player.id,
                skillName = self.name,
                moveVisible = true,
            })
        end
    end
}

local LoR__angel_zhenli = fk.CreateActiveSkill {
    name = "LoR__angel_zhenli",
    anim_type = "support",
    prompt = "#LoR__angel_zhenli",
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local generals = {}
        for _, g1 in pairs(Fk.generals) do
            if (g1.kingdom == "LoR_shu" or g1.kingdom == "LoC") and g1.name ~= "LoR__angel_master" then
                table.insert(generals, g1.name)
            end
        end
        if #generals == 0 then return end
        local general_name = room:askForGeneral(player, table.random(generals, 3), 1, true)
        if type(general_name) == "table" then general_name = general_name[1] end
        local general = Fk.generals[general_name]
        local choices = {}
        for _, s in ipairs(general:getSkillNameList()) do
            local skill = Fk.skills[s]
            if not player:hasSkill(skill, true) then
                table.insertIfNeed(choices, skill.name)
            end
        end
        if #choices > 0 then
            local choice = room:askForChoice(player, choices, self.name, ".", true)
            room:handleAddLoseSkills(player, choice .. "|-LoR__angel_zhenli", nil, true, false)
        end
    end
}

local LoR__angel_guangcang = fk.CreateTriggerSkill {
    name = "LoR__angel_guangcang",
    anim_type = "support",
    frequency = Skill.Compulsory,
    events = { fk.EventPhaseStart, fk.CardUsing },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.EventPhaseStart and player.phase == Player.Start then
                return true
            elseif event == fk.CardUsing and data.card and table.contains(SiShu_EGO, data.card.name) then
                return true
            end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.EventPhaseStart then
            local card = room:printCard(table.random(SiShu_EGO, 1)[1])
            room:moveCards({
                ids = { card.id },
                fromArea = Card.Void,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player.id,
                skillName = self.name,
                moveVisible = true,
            })
            local card2 = room:printCard(table.random(Angela_Cards, 1)[1])
            room:moveCards({
                ids = { card2.id },
                fromArea = Card.Void,
                to = player.id,
                toArea = Card.PlayerHand,
                moveReason = fk.ReasonPrey,
                proposer = player.id,
                skillName = self.name,
                moveVisible = true,
            })
        else
            room:addPlayerMark(player, "@LoR__angel_guangcang")
            if player:getMark("@LoR__angel_guangcang") >= 9 then
                room:handleAddLoseSkills(player, "LoR__angel_zhenli", nil, true, false)
                room:setPlayerMark(player, "@LoR__angel_guangcang", 0)
            end
        end
    end,
}

LoR__angel_master:addRelatedSkill(LoR__angel_zhenli)
LoR__angel_master:addSkill(LoR__angel_light)
LoR__angel_master:addSkill(LoR__angel_guangcang)

Fk:loadTranslationTable {
    ["LoR__angel_master"] = "安吉拉",
    ["#LoR__angel_master"] = "废墟图书馆馆长",
    ["~LoR__angel_master"] = "果然，你来到图书馆并不只是什么偶然吧，罗兰。",
    ["designer:LoR__angel_master"] = "Rem",

    ["LoR__angel_light"] = "光之种",
    ["$LoR__angel_light"] = "在这里，未经我的许可，无人可以长眠。",
    [":LoR__angel_light"] = "锁定技，回合开始时，随机令一名我方角色获得一层【光之种】;回合结束时，你获得一张【司书信念之页】。" .. Fk:translate("Guangzhizhong_jieshao"),

    ["LoR__angel_guangcang"] = "馆藏",
    ["@LoR__angel_guangcang"] = "馆藏",
    ["$LoR__angel_guangcang"] = "你们理应比任何人都要清楚，于这图书馆中对抗我是毫无意义的",
    [":LoR__angel_guangcang"] = "锁定技，准备阶段开始时，你随机获得一张【安吉拉专属战斗书页】和【司书信念之页】。你每使用九张【司书信念之页】时，获得【真理之页】。",

    ["LoR__angel_zhenli"] = "至理之书",
    ["$LoR__angel_zhenli"] = "我终将得到那本完善我和这座图书馆的至理之书。",
    ["#LoR__angel_zhenli"] = "至理之书:你从随机三个【书】或【脑叶公司】势力的技能中选择一个获得，然后失去本技能。",
    [":LoR__angel_zhenli"] = "出牌阶段限一次，你从随机三个【书】或【脑叶公司】势力的技能中选择一个获得，然后失去本技能。",
}


-- 终末之光  安吉拉  4/4  书
-- 灰烬:每当你体力值减少时，你令一名其他角色获得等量的【烧伤】。当你造成伤害时，令伤害目标获得等量的【烧伤】。
-- 火光:出牌阶段限一次，你获得一张【昂首阔步的信念】并对一名角色造成一点火焰伤害并令其获得1层【烧伤】，若其为【烧伤】层数最多的角色，你摸其【烧伤】层数张牌。

local LoR__angel_fire = General:new(extension, "LoR__angel_fire", "LoR_shu", 4, 4, 2)

local LoR__angel_fire_huijin = fk.CreateTriggerSkill {
    name = "LoR__angel_fire_huijin",
    prompt = "#LoR__angel_fire_huijin",
    anim_type = "masochism",
    events = { fk.HpChanged, fk.Damage },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if event == fk.HpChanged and data.num < 0 then
                return true
            elseif event == fk.Damage and data.to and data.damage and data.damage > 0 then
                return true
            end
        end
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local prompt, num, targetplayer
        if event == fk.HpChanged and data.num < 0 then
            num = math.abs(data.num)
            prompt = "#LoR__angel_fire_huijin-choose:::" .. num
            player:chat("这就是我的复仇，将他渴望的一切尽数烧毁。")
            targetplayer = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1,
                prompt, self.name, true)
        elseif event == fk.Damage and data.to and data.damage and data.damage > 0 then
            targetplayer = { data.to.id }
            num = data.damage
            prompt = "#LoR__angel_fire_huijin-choose2:" .. targetplayer[1] .. "::" .. num
            player:chat("火柴的光芒熄灭后，我就什么也不剩了。")
        end
        if #targetplayer > 0 then
            room:addPlayerMark(room:getPlayerById(targetplayer[1]), "@LoR_Fire", num)
        end
    end,
}

local LoR__angel_fire_huoguang = fk.CreateActiveSkill {
    name = "LoR__angel_fire_huoguang",
    prompt = "#LoR__angel_fire_huoguang",
    target_num = 1,
    target_filter = Util.TrueFunc,
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and player.phase == Player.Play
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        player:chat("如果能看见一丝暖光，我又怎会充满怨恨。")
        local target = room:getPlayerById(effect.tos[1])
        local card = room:printCard("Malkuth_Angela_EGO", Card.Diamond, 4)
        room:obtainCard(player, card, true, fk.ReasonPrey, player.id, self.name)
        room:damage({
            from = player,
            to = target,
            damage = 1,
            damageType = fk.FireDamage
        })
        room:addPlayerMark(target, "@LoR_Fire")
        for _, p in ipairs(room.alive_players) do
            if p:getMark("@LoR_Fire") > target:getMark("@LoR_Fire") then
                return
            end
        end
        player:drawCards(target:getMark("@LoR_Fire"), self.name)
    end,
}

LoR__angel_fire:addSkill(LoR__angel_fire_huijin)
LoR__angel_fire:addSkill(LoR__angel_fire_huoguang)

Fk:loadTranslationTable {
    ["LoR"] = "废墟图书馆",
    ["LoR__angel_fire"] = "安吉拉",
    ["#LoR__angel_fire"] = "终末之光",
    --["~LoR__angel_fire"] = "眼前的金钱……我不在乎。",
    ["designer:LoR__angel_fire"] = "Rem",

    ["LoR__angel_fire_huijin"] = "灰烬",
    ["#LoR__angel_fire_huijin"] = "灰烬:令一名其他角色获得烧伤",
    [":LoR__angel_fire_huijin"] = "每当你体力值减少时，你令一名其他角色获得等量的【烧伤】。当你造成伤害时，令伤害目标获得等量的【烧伤】。" .. Fk:translate("LoR_Fire_jieshao"),
    ["#LoR__angel_fire_huijin-choose"] = "灰烬:你令一名其他角色获得%arg层【烧伤】",
    ["#LoR__angel_fire_huijin-choose2"] = "灰烬:你令%src获得%arg层【烧伤】",

    ["LoR__angel_fire_huoguang"] = "火光",
    ["#LoR__angel_fire_huoguang"] = "火光:对一名角色造成一点火焰伤害并令其获得1层【烧伤】",
    [":LoR__angel_fire_huoguang"] = "出牌阶段限一次，你获得一张【昂首阔步的信念】并对一名角色造成一点火焰伤害并令其获得1层【烧伤】，若其为【烧伤】层数最多的角色，你摸其【烧伤】层数张牌。"
        .. Fk:translate("LoR_Fire_jieshao"),
}

-- 原初的图书馆  安吉拉  4/4  书
-- 白夜:回合开始时，你可以令一名其他角色获得一层【光之种】并在其下个回合结束时失去。你的第三个回合开始时，你获得【黑昼】。

-- 协议:准备阶段开始时:若场上拥有【书】势力的角色，你令其选择是否助力你，若其选择助力:其下个摸牌阶段少摸一张牌并获得一层【光之种】。
-- 你的摸牌阶段额外摸场上【光之种】数量的牌；若场上没有【书】势力的角色，你选择一名角色更改其势力为【书】。

-- 黑昼:回合结束时，你可以夺取一名其他角色的【光之种】。你的第四个回合结束后，你修改【协议】。

-- 协议2:锁定技，准备阶段开始时，你随机获得一张【司书信念之页】。每当你使用【司书信念之页】时，若你拥有【光之种】，失去1层【光之种】，然后你进行一次判定:
-- 红色，你选择一名其他目标，其获得一层烧伤和一层流血。黑色，你获得一层强壮和一层守护。
-- 守护:下次受到的伤害-1。


local LoR__angel_yuanchu = General:new(extension, "LoR__angel_yuanchu", "LoR_shu", 4, 4, 2)

local LoR__angel_yuanchu_baiye = fk.CreateTriggerSkill {
    name = "LoR__angel_yuanchu_baiye",
    prompt = "#LoR__angel_yuanchu_baiye",
    anim_type = "special",
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_cost = function(self, event, target, player, data)
        if player:getMark("xieyi1") == 0 then
            player.room:addPlayerMark(player, "@yuanchu_baiye", 1)
        end
        if player:getMark("@yuanchu_baiye") == 3 then
            player.room:notifySkillInvoked(player, self.name, "special")
            player:broadcastSkillInvoke(self.name, 1)
            player.room:removePlayerMark(player, "@yuanchu_baiye", player:getMark("@yuanchu_baiye"))
            player.room:handleAddLoseSkills(player, "LoR__angel_yuanchu_heizhou", nil, true, false)
            player.room:addPlayerMark(player, "xieyi1")
        end
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local targetPlayer_ids = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper),
            1, 1,
            "#LoR__angel_yuanchu_baiye-choose_player", self.name, false)

        local t_p = room:getPlayerById(targetPlayer_ids[1])
        room:addPlayerMark(t_p, "@guangzhizhong")


        room:addPlayerMark(player, "@LoR_ShouHu")
    end,

}

local LoR__angel_yuanchu_xieyi = fk.CreateTriggerSkill {
    name = "LoR__angel_yuanchu_xieyi",
    prompt = "#LoR__angel_yuanchu_xieyi1",
    events = { fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Start
    end,
    on_cost = function(self, event, target, player, data)
        return player.room:askForSkillInvoke(player, self.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local targetPlayers = table.filter(room:getOtherPlayers(player), function(p, index, array)
            return p.kingdom == "LoR_shu"
        end)
        if #targetPlayers > 0 then
            local choice_p = room:askForChoosePlayers(player, table.map(targetPlayers, Util.IdMapper), 1, 1,
                "#LoR__angel_yuanchu_xieyi_choose_shu_p", self.name, false)
            local target_p = room:getPlayerById(choice_p[1])
            local choice = room:askForChoice(target_p, { "助力", "不助力" }, self.name, "#LoR__angel_yuanchu_xieyi_choose")
            if choice == "助力" then
                room:addPlayerMark(target_p, "@guangzhizhong")
                room:setPlayerMark(target_p, "@@yuanchu_xieyi", 1)
            end
        else
            local choice_p = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1,
                1,
                "#LoR__angel_yuanchu_xieyi_choose_p", self.name, false)
            local target_p = room:getPlayerById(choice_p[1])
            room:changeKingdom(target_p, "LoR_shu", true)
        end
    end,
}
local LoR__angel_yuanchu_xieyi_draw = fk.CreateTriggerSkill {
    name = "#LoR__angel_yuanchu_xieyi_draw",
    anim_type = "drawcard",
    main_skill = LoR__angel_yuanchu_xieyi,
    frequency = Skill.Compulsory,
    events = { fk.DrawNCards },
    can_trigger = function(self, event, target, player, data)
        return target == player and
            (player:hasSkill("LoR__angel_yuanchu_xieyi") or player:getMark("@@yuanchu_xieyi") > 0)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if player:hasSkill("LoR__angel_yuanchu_xieyi") then
            local num = 0
            for _, p in ipairs(room.alive_players) do
                if p:getMark("@guangzhizhong") > 0 then
                    num = num + p:getMark("@guangzhizhong")
                end
            end
            data.n = data.n + num
        elseif player:getMark("@@yuanchu_xieyi") > 0 then
            data.n = data.n - 1
            if data.n < 0 then
                data.n = 0
            end
            room:removePlayerMark(player, "@@yuanchu_xieyi")
        end
    end,
}


local LoR__angel_yuanchu_xieyi_2 = fk.CreateTriggerSkill {
    name = "LoR__angel_yuanchu_xieyi_2",
    anim_type = "drawcard",
    frequency = Skill.Compulsory,
    events = { fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Start
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local card1 = room:printCard(SiShu_EGO[math.random(#SiShu_EGO)])
        room:moveCards({
            ids = { card1.id },
            fromArea = Card.Void,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
            moveVisible = true,
        })
    end,
}
local LoR__angel_yuanchu_xieyi2_usecard = fk.CreateTriggerSkill {
    name = "#LoR__angel_yuanchu_xieyi2_usecard",
    anim_type = "offensive",
    main_skill = LoR__angel_yuanchu_xieyi_2,
    events = { fk.CardUsing },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill("LoR__angel_yuanchu_xieyi_2") and player:getMark("@guangzhizhong") >
            0
            and data.card and table.contains(SiShu_EGO, data.card.name)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local judge = {
            who = player,
            pattern = ".",
            reason = self.name
        }
        room:judge(judge)
        if judge.card.color == Card.Red then
            local targetPlayer_ids = room:askForChoosePlayers(player,
                table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#LoR__angel_yuanchu_xieyi2-choose_p",
                self.name, false)
            local target_p = room:getPlayerById(targetPlayer_ids[1])
            room:addPlayerMark(target_p, "@LoR_Fire")
            room:addPlayerMark(target_p, "@LiuXue_LoR")
        elseif judge.card.color == Card.Black then
            room:addPlayerMark(player, "@qiangzhuang")
            room:addPlayerMark(player, "@LoR_ShouHu")
        end
    end,
}


local LoR__angel_yuanchu_heizhou = fk.CreateTriggerSkill {
    name = "LoR__angel_yuanchu_heizhou",
    prompt = "#LoR__angel_yuanchu_heizhou",
    anim_type = "special",
    events = { fk.TurnEnd },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) then
            if player:getMark("@yuanchu_heizhou") == 0 and player:getMark("xieyi2") == 0 then
                player.room:setPlayerMark(player, "@yuanchu_heizhou", 3)
            elseif player:getMark("@yuanchu_heizhou") > 0 and player:getMark("xieyi2") == 0 then
                player.room:removePlayerMark(player, "@yuanchu_heizhou")
                if player:getMark("@yuanchu_heizhou") == 0 then
                    player.room:notifySkillInvoked(player, self.name, "special")
                    player:broadcastSkillInvoke(self.name, 1)
                    player.room:handleAddLoseSkills(player, "LoR__angel_yuanchu_xieyi_2|-LoR__angel_yuanchu_xieyi", nil,
                        true, false)
                    player.room:addPlayerMark(player, "xieyi2")
                end
            end
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

LoR__angel_yuanchu_xieyi:addRelatedSkill(LoR__angel_yuanchu_xieyi_draw)
LoR__angel_yuanchu_xieyi_2:addRelatedSkill(LoR__angel_yuanchu_xieyi2_usecard)
LoR__angel_yuanchu:addRelatedSkill(LoR__angel_yuanchu_xieyi_2)

LoR__angel_yuanchu:addSkill(LoR__angel_yuanchu_baiye)
LoR__angel_yuanchu:addSkill(LoR__angel_yuanchu_xieyi)
LoR__angel_yuanchu:addRelatedSkill(LoR__angel_yuanchu_heizhou)

Fk:loadTranslationTable {
    ["LoR__angel_yuanchu"] = "安吉拉",
    ["#LoR__angel_yuanchu"] = "原初的图书馆",
    ["~LoR__angel_yuanchu"] = "无名的孩子啊，谢谢你能够让我安眠。",
    ["designer:LoR__angel_yuanchu"] = "Rem",

    ["LoR__angel_yuanchu_baiye"] = "白夜",
    ["$LoR__angel_yuanchu_baiye"] = "你哭泣时的样子真令人觉得陌生。",
    ["#LoR__angel_yuanchu_baiye"] = "白夜:你可以令一名其他角色获得1层【光之种】",
    [":LoR__angel_yuanchu_baiye"] = "回合开始时，你可以令一名其他角色获得1层【光之种】。你的第三个回合开始时，你获得【黑昼】。" .. Fk:translate("Guangzhizhong_jieshao"),
    ["#LoR__angel_yuanchu_baiye-choose_player"] = "白夜:你可以令一名其他角色获得1层【光之种】",
    ["@yuanchu_baiye"] = "白夜",


    ["LoR__angel_yuanchu_xieyi"] = "协议",
    ["$LoR__angel_yuanchu_xieyi1"] = "你只是在妥善地利用我而已。",
    ["#LoR__angel_yuanchu_xieyi1"] = "协议:你令【书】势力的角色选择是否助力你;否则你选择一名角色更改其势力为【书】。",
    ["#LoR__angel_yuanchu_xieyi2"] = "协议:令一名其他角色获得烧伤",
    [":LoR__angel_yuanchu_xieyi"] = "准备阶段开始时:若场上拥有【书】势力的角色，你令其选择是否助力你，若其选择助力:其下个摸牌阶段少摸一张牌并获得一层【光之种】。你的摸牌阶段额外摸场上【光之种】数量的牌；若场上没有【书】势力的角色，你选择一名角色更改其势力为【书】。" .. Fk:translate("Guangzhizhong_jieshao"),
    ["#LoR__angel_yuanchu_xieyi_draw"] = "协议",
    ["@@yuanchu_xieyi"] = "协议",
    ["#LoR__angel_yuanchu_xieyi_choose_shu_p"] = "协议:选择一名【书】势力的其他角色",
    ["#LoR__angel_yuanchu_xieyi_choose_p"] = "协议:选择一名其他角色改变其势力为【书】",

    ["LoR__angel_yuanchu_xieyi_2"] = "协议2",
    ["$LoR__angel_yuanchu_xieyi_2"] = "真是白跟你们达成协议了....",
    [":LoR__angel_yuanchu_xieyi_2"] = "锁定技，准备阶段开始时，你随机获得一张【司书信念之页】。每当你使用【司书信念之页】时，若你拥有【光之种】，失去1层【光之种】，然后你进行一次判定:红色，你选择一名其他目标，其获得一层【烧伤】和一层【流血】。黑色，你获得一层【强壮】和一层【守护】。" .. Fk:translate("LoR_ShouHu_jieshao"),
    ["#LoR__angel_yuanchu_xieyi2_usecard"] = "协议2",
    ["#LoR__angel_yuanchu_xieyi2-choose_p"] = "协议2:你选择一名其他目标，其获得一层【烧伤】和一层【流血】",


    ["LoR__angel_yuanchu_heizhou"] = "黑昼",
    ["$LoR__angel_yuanchu_heizhou"] = "这便是你的终点了。罗兰。这也是我所需要克服的痛苦之一吧。",
    ["#LoR__angel_yuanchu_heizhou"] = "黑昼:你可以夺取一名其他角色的【光之种】",
    [":LoR__angel_yuanchu_heizhou"] = "回合结束时，你可以夺取一名其他角色的【光之种】。你的第四个回合结束后，你失去【协议】并获得【协议2】。" .. Fk:translate("Guangzhizhong_jieshao"),
    ["@yuanchu_heizhou"] = "黑昼",

}



-- 提菲勒斯   自然层指定司书  9999
-- 试炼：锁定技，游戏开始时或准备阶段开始时:若场上没有【提菲勒斯—恶】则令一名随机敌方角色失去所有技能并替换武将为【提菲勒斯-恶】；当【提菲勒斯-恶】阵亡后，你进入【E.G.O展现状态】。
-- #E.G.O展现状态:该角色失去本技能原武将牌上的所有技能，替换武将图像并获得对应的EGO展现武将的技能。
-- 憧憬：出牌阶段限一次，你可以进行一次判定，然后选择至多3名其他角色令其弃置共计判定点数的牌，若其无法弃置则你获得1层【强壮】和1层【守护】


-- local LoR__Tiphereth = General:new(extension, "LoR__Tiphereth", "LoR_shu", 4, 4, 2)

-- local LoR__Tiphereth_shilian = fk.CreateTriggerSkill {
--     name = "LoR__Tiphereth_shilian",
--     frequency = Skill.Compulsory,
--     anim_type = "masochism",
--     events = { fk.GameStart, fk.EventPhaseStart },
--     can_trigger = function(self, event, target, player, data)
--         for _, p in ipairs(player.room.alive_players) do
--             if p.general == "LoR__Tiphereth_E" then
--                 if event == fk.GameStart then
--                     return player:hasSkill(self)
--                 else
--                     return target == player and player.phase == Player.Start and player:hasSkill(self)
--                 end
--             end
--         end
--     end,
--     on_use = function(self, event, target, player, data)
--         local room = player.room
--         local targetplayer = table.random(LoR_Utility.GetEnemies(room, player), 1)[1]
--         room:handleAddLoseSkills(targetplayer, table.map(targetplayer.player_skills, function(s) return s.name end), nil,
--             true, false)
--         room:changeHero(targetplayer, "LoR__Tiphereth_E", true)
--     end,
-- }

-- local LoR__Tiphereth_shilian_trigger = fk.CreateTriggerSkill {
--     name = "#LoR__Tiphereth_shilian_trigger",
--     frequency = Skill.Compulsory,
--     events = { fk.Deathed },
--     can_trigger = function(self, event, target, player, data)
--         return player:hasSkill(LoR__Tiphereth_shilian) and target.general == "LoR__Tiphereth_E"
--     end,
--     on_use = function(self, event, target, player, data)
--         LoR_Utility.EGOChangeGeneral(player, "LoR__Tiphereth", "LoR__Tiphereth_EGO")
--     end,
-- }

-- local LoR__Tiphereth_chongjing = fk.CreateActiveSkill {
--     name = "LoR__Tiphereth_chongjing",
--     prompt = "#LoR__Tiphereth_chongjing",
--     anim_type = "control",
--     mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
--         return user ~= to_select
--     end,
--     target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
--         return #selected <= 3 and self:modTargetFilter(to_select, selected, Self)
--     end,
--     max_target_num = 3,
--     min_target_num = 1,
--     can_use = function(self, player, card, extra_data)
--         return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
--     end,
--     on_use = function(self, room, cardUseEvent)
--         local player = room:getPlayerById(cardUseEvent.from)
--         local targetPlayers = table.map(cardUseEvent.tos, function(e)
--             return room:getPlayerById(e)
--         end)
--         local judge = {
--             who = player,
--             pattern = ".",
--             reason = self.name
--         }
--         room:judge(judge)
--         local judge_num = judge.card.number
--         if #targetPlayers > 0 then
--             for _, p in ipairs(targetPlayers) do
--                 local poxi_num = #LoR_Utility.PoXiMethod(player, judge_num,
--                     "#LoR__Tiphereth_chongjing-choose:::" .. judge_num, p, "#LoR__Tiphereth_chongjing-poxi",
--                     { { p.general, p:getCardIds("he") } }, true)
--                 if poxi_num == 0 then
--                     room:addPlayerMark(player, "@qiangzhuang")
--                     room:addPlayerMark(player, "@LoR_ShouHu")
--                 end
--             end
--         end
--     end,
-- }

-- LoR__Tiphereth_shilian:addRelatedSkill(LoR__Tiphereth_shilian_trigger)
-- LoR__Tiphereth:addSkill(LoR__Tiphereth_shilian)
-- LoR__Tiphereth:addSkill(LoR__Tiphereth_chongjing)


-- Fk:loadTranslationTable {
--     ["LoR__Tiphereth"] = "提菲勒斯",
--     ["#LoR__Tiphereth"] = "自然层指定司书",
--     ["~LoR__Tiphereth"] = "无名的孩子啊，谢谢你能够让我安眠。",
--     ["designer:LoR__Tiphereth"] = "Rem",

--     ["LoR__Tiphereth_shilian"] = "试炼",
--     ["$LoR__Tiphereth_shilian"] = "你哭泣时的样子真令人觉得陌生。",
--     ["#LoR__Tiphereth_shilian_trigger"] = "试炼",
--     [":LoR__Tiphereth_shilian"] = "锁定技，游戏开始时或准备阶段开始时:若场上没有【提菲勒斯—恶】则令一名随机敌方角色失去所有技能并替换武将为【提菲勒斯-恶】；当【提菲勒斯-恶】阵亡后，你进入【E.G.O展现状态】。"
--         .. Fk:translate("EGOShow"),


--     ["LoR__Tiphereth_chongjing"] = "憧憬",
--     ["$LoR__Tiphereth_chongjing"] = "你只是在妥善地利用我而已。",
--     ["#LoR__Tiphereth_chongjing"] = "憧憬:你可以进行一次判定，然后选择至多3名其他角色令其弃置共计判定点数的牌，若其无法弃置则你获得1层【强壮】和1层【守护】",
--     [":LoR__Tiphereth_chongjing"] = "出牌阶段限一次，你可以进行一次判定，然后选择至多3名其他角色令其弃置共计判定点数的牌，若其无法弃置则你获得1层【强壮】和1层【守护】" .. Fk:translate("LoR_ShouHu_jieshao"),
--     ["#LoR__Tiphereth_chongjing-choose"] = "憧憬:选择至多3名其他角色令其弃置共计%arg点数的牌，若其无法弃置则你获得1层【强壮】和1层【守护】",
--     ["#LoR__Tiphereth_chongjing-poxi"] = "憧憬",
-- }

-- -- 提菲勒斯-恶  内心的倒影  99999
-- -- 孤独：锁定技，回合开始时，若场上友方角色仅剩你，你获得2层【强壮】。
-- -- 倒影：锁定技，你每造成2点伤害随机获得1个未获得的【提菲勒斯-恶】衍生技。
-- -- #倒影衍生技
-- -- 破灭：出牌阶段限三次，你可以对一名本回合未以此法选择过的角色造成1点伤害。
-- -- 谛观：每项每轮限一次：你即将受到伤害时，若本次伤害来自卡牌，你令本次伤害-2；当你造成伤害时，你令其获得1层【爱意】。
-- -- 拒绝：锁定技，当你进行判定时，你令随机一名敌方角色获得1层【麻痹】。
-- -- 躯壳重构：出牌阶段开始时，你进行一次判定：若为黑色，对自己造成1点伤害，令自己获得1层【正面状态】；否则你回复1点体力并令一名随机敌方角色获得2层【负面状态】。
-- -- #状态
-- -- 正面状态有：强壮，守护。
-- -- 负面状态有：流血-LoR，烧伤，混乱，虚弱，破绽，爱意，麻痹。
-- -- 循环：结束阶段开始时，你进行1次判定，若为黑，你令一名随机敌方角色获得1层【负面状态】，然后重复判定（至多3次）；若为红，则你令一名随机友方角色获得1层【正面状态】。

local LoR__Tiphereth_E = General:new(extension, "LoR__Tiphereth_E", "LoR_shu", 4, 4, 2)

local LoR__Tiphereth_E_gudu = fk.CreateTriggerSkill {
    name = "LoR__Tiphereth_E_gudu",
    frequency = Skill.Compulsory,
    anim_type = "support",
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and #LoR_Utility.GetFriends(player.room, player, true) == 1
    end,
    on_use = function(self, event, target, player, data)
        player.room:addPlayerMark(player, "@qiangzhuang", 2)
    end,
}
local LoR__Tiphereth_E_daoying_skills = {"LoR__Tiphereth_E_daoying_pomie","LoR__Tiphereth_E_daoying_diguan","LoR__Tiphereth_E_daoying_xunhuan","LoR__Tiphereth_E_daoying_jujue", "LoR__Tiphereth_E_daoying_quqiaochongzu"}
local LoR__Tiphereth_E_daoying = fk.CreateTriggerSkill {
    name = "LoR__Tiphereth_E_daoying",
    frequency = Skill.Compulsory,
    anim_type = "special",
    events = { fk.Damage },
    can_trigger = function(self, event, target, player, data)
        if target == player and player:hasSkill(self) and data.damage and data.damage>2 then
        local skills = table.simpleClone(LoR__Tiphereth_E_daoying_skills)
        for _, skill in ipairs(player.player_skills) do
            if table.contains(skills, skill.name) then
                table.removeOne(skills, skill.name)
            end
        end
        if #skills > 0 then
           return true
        end
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room  
        local skills = table.simpleClone(LoR__Tiphereth_E_daoying_skills)
        for _, skill in ipairs(player.player_skills) do
            if table.contains(skills, skill.name) then
                table.removeOne(skills, skill.name)
            end
        end
        if #skills > 0 then
            player.room:handleAddLoseSkills(player, table.random(skills, 1)[1], nil, true, false)
        end
    end,
}

local LoR__Tiphereth_E_daoying_pomie = fk.CreateActiveSkill {
    name = "LoR__Tiphereth_E_daoying_pomie",
    prompt = "#LoR__Tiphereth_E_daoying_pomie-prompt",
    anim_type = "offensive",
    target_num = 1,
    target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
        return #selected < 1 and
            Fk:currentRoom():getPlayerById(to_select):getMark("LoR__Tiphereth_E_daoying_pomie-turn") == 0
    end,
    can_use = function(self, player, card, extra_data)
        return player:usedSkillTimes(self.name, Player.HistoryTurn) < 3
    end,
    on_use = function(self, room, effect)
        local player = room:getPlayerById(effect.from)
        local target = room:getPlayerById(effect.tos[1])
        room:damage({
            from      = player,
            to        = target,
            damage    = 1,
            skillName = self.name,
        })
        room:addPlayerMark(target, "LoR__Tiphereth_E_daoying_pomie-turn")
    end,
}

local LoR__Tiphereth_E_daoying_diguan = fk.CreateTriggerSkill {
    name = "LoR__Tiphereth_E_daoying_diguan",
    anim_type = "defensive",
    events = { fk.DamageInflicted, fk.Damage },
    can_trigger = function(self, event, target, player, data)
        if event == fk.Damage then
            return target == player and player:hasSkill(self) and
                player:getMark("LoR__Tiphereth_E_daoying_diguan1-round") == 0 and data.to
        else
            return target == player and player:hasSkill(self) and
                player:getMark("LoR__Tiphereth_E_daoying_diguan2-round") == 0 and data.card
        end
    end,
    on_cost = function(self, event, target, player, data)
        local room = player.room
        if event == fk.Damage then
            return room:askForSkillInvoke(player, self.name, nil, "#LoR__Tiphereth_E_daoying_diguan1-prompt")
        else
            return room:askForSkillInvoke(player, self.name, nil, "#LoR__Tiphereth_E_daoying_diguan2-prompt")
        end
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if event == fk.Damage then
            room:addPlayerMark(data.to, "@LoR_aiyi")
            room:addPlayerMark(player, "LoR__Tiphereth_E_daoying_diguan1-round")
        else
            data.damage = (data.damage or 0) - 2
            if data.damage < 0 then
                data.damage = 0
            end
            room:addPlayerMark(player, "LoR__Tiphereth_E_daoying_diguan2-round")
        end
    end
}

local LoR__Tiphereth_E_daoying_jujue = fk.CreateTriggerSkill {
    name = "LoR__Tiphereth_E_daoying_jujue",
    frequency = Skill.Compulsory,
    anim_type = "offensive",
    events = { fk.StartJudge },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and data.who == player and
            #LoR_Utility.GetEnemies(player.room, player) > 0
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local targetPlayers = LoR_Utility.GetEnemies(room, player)
        room:addPlayerMark(table.random(targetPlayers, 1)[1], "@LoR_MaBi")
    end
}

local LoR__Tiphereth_E_daoying_quqiaochongzu = fk.CreateTriggerSkill {
    name = "LoR__Tiphereth_E_daoying_quqiaochongzu",
    frequency = Skill.Compulsory,
    anim_type = "special",
    events = { fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Play
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local judge = {
            who = player,
            pattern = ".",
            reason = self.name
        }
        room:judge(judge)
        if judge.card.color == Card.Black then
            room:damage({
                from = player,
                to = player,
                damage = 1,
                skillName = self.name,
            })
            room:addPlayerMark(player, table.random(LoR_Buff, 1)[1])
        else
            room:recover({
                who = player,
                num = 1,
                skillName = self.name,
                recoverBy = player,
            })
            local targetplayer = table.random(LoR_Utility.GetEnemies(room, player), 1)[1]
            room:addPlayerMark(targetplayer, table.random(LoR_Debuff, 1)[1])
            room:addPlayerMark(targetplayer, table.random(LoR_Debuff, 1)[1])
        end
    end
}

local LoR__Tiphereth_E_daoying_xunhuan = fk.CreateTriggerSkill {
    name = "LoR__Tiphereth_E_daoying_xunhuan",
    frequency = Skill.Compulsory,
    anim_type = "special",
    events = { fk.EventPhaseStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self) and player.phase == Player.Finish
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        
        for i = 1, 3, 1 do
           local judge = {
            who = player,
            pattern = ".",
            reason = self.name
           }
            room:judge(judge)
            if judge.card.color == Card.Red then
                room:addPlayerMark(table.random(LoR_Utility.GetFriends(room, player),1)[1], table.random(LoR_Buff, 1)[1])
                break
            else
                room:addPlayerMark(table.random(LoR_Utility.GetEnemies(room, player),1)[1], table.random(LoR_Debuff, 1)[1])
            end
        end
    end
}
LoR__Tiphereth_E:addSkill(LoR__Tiphereth_E_gudu)
LoR__Tiphereth_E:addSkill(LoR__Tiphereth_E_daoying)

LoR__Tiphereth_E:addRelatedSkill(LoR__Tiphereth_E_daoying_pomie)
LoR__Tiphereth_E:addRelatedSkill(LoR__Tiphereth_E_daoying_diguan)
LoR__Tiphereth_E:addRelatedSkill(LoR__Tiphereth_E_daoying_jujue)
LoR__Tiphereth_E:addRelatedSkill(LoR__Tiphereth_E_daoying_quqiaochongzu)
LoR__Tiphereth_E:addRelatedSkill(LoR__Tiphereth_E_daoying_xunhuan)

Fk:loadTranslationTable {
    ["LoR__Tiphereth_E"] = "提菲勒斯-恶",
    ["#LoR__Tiphereth_E"] = "内心的倒影",
    ["designer:LoR__Tiphereth_E"] = "Rem",

    ["LoR__Tiphereth_E_gudu"] = "孤独",
    [":LoR__Tiphereth_E_gudu"] = "锁定技，回合开始时，若场上友方角色仅剩你，你获得2层【强壮】。",

    ["LoR__Tiphereth_E_daoying"] = "倒影",
    [":LoR__Tiphereth_E_daoying"] = "锁定技，当你造成不小于2点的伤害时，随机获得1个未获得的【提菲勒斯-恶】衍生技。",

    ["LoR__Tiphereth_E_daoying_pomie"] = "破灭",
    ["#LoR__Tiphereth_E_daoying_pomie-prompt"]="破灭:请选择一名本回合未选择过的角色，你对其造成1点伤害。",
    [":LoR__Tiphereth_E_daoying_pomie"] = "出牌阶段限三次，你可以对一名本回合未以此法选择过的角色造成1点伤害。",

    ["LoR__Tiphereth_E_daoying_diguan"] = "谛观",
    [":LoR__Tiphereth_E_daoying_diguan"] = "每项每轮限一次：你即将受到伤害时，若本次伤害来自卡牌，你令本次伤害-2；当你造成伤害时，你令其获得1层【<a href='LoR_Aiyi_jieshao'><font color='red'>爱意</font></a>】。",
    ["#LoR__Tiphereth_E_daoying_diguan2-prompt"] = "谛观：每轮限一次，你可以令本次伤害-2",
    ["#LoR__Tiphereth_E_daoying_diguan1-prompt"] = "谛观：每轮限一次，你可以令其获得1层【爱意】。",

    ["LoR__Tiphereth_E_daoying_jujue"] = "拒绝",
    [":LoR__Tiphereth_E_daoying_jujue"] = "锁定技，当你进行判定时，你令随机一名敌方角色获得1层【<a href='LoR_MaBi_jieshao'><font color='red'>麻痹</font></a>】",

    ["LoR__Tiphereth_E_daoying_quqiaochongzu"] = "躯壳重构",
    [":LoR__Tiphereth_E_daoying_quqiaochongzu"] = "出牌阶段开始时，你进行一次判定：若为黑色，对自己造成1点伤害，令自己获得1层【<a href='LoR_State_jieshao'><font color='red'>正面状态</font></a>】；否则你回复1点体力并令一名随机敌方角色获得2层【<a href='LoR_State_jieshao'><font color='red'>负面状态</font></a>】。",

    ["LoR__Tiphereth_E_daoying_xunhuan"] = "循环",
    [":LoR__Tiphereth_E_daoying_xunhuan"] = "结束阶段开始时，你进行1次判定，若为黑，你令一名随机敌方角色获得1层【负面状态】，然后重复判定（至多3次）；若为红，则你令一名随机友方角色获得1层【<a href='LoR_State_jieshao'><font color='red'>正面状态</font></a>】。",

}


-- 提菲勒斯   存在意义的证明   99999
-- 期待:锁定技，手牌上限+1，摸牌阶段额外摸牌数+1，出杀次数+1。每回合限x次，你判定牌若小于9点，则视为9点。若你的判定牌点数不小于你当前的体力值，你获得1层【正面状态】(x为你当前体力值)。
-- 自我证明:锁定技，每局游戏限5次，回合开始时你从随机3张中选择1张【存在的证明】卡牌置入你的武将牌上。
-- #存在的证明
-- 基本牌，置入武将牌上时你获得卡牌效果的增益，重复应用相同卡牌会进行增益强化。
-- 自我觉醒:锁定技，共鸣技，你每使用5张牌，获得一张【直面自我】。
-- #直面自我
-- 基本牌，效果:你进行一次判定，若判定点数不小于8，则你重复进行一次判定（至多5次）。目标需弃置x张点数为8的牌，否则其受到x点伤害（x为你判定的次数）
-- 魔法少女:出牌阶段开始时，你可以弃置任意张手牌，然后获得对应标记。
-- #魔法少女标记
-- 幸福:弃置方片♦️牌获得。每当你不以此法摸牌时，你可以消耗一枚幸福标记，摸两张牌。
-- 博爱:弃置红桃♥️牌获得。每当你不以此法回复体力时，你可以消耗一枚博爱标记，回复一点体力。
-- 勇气:弃置黑桃♠️牌获得。每当回合开始时，你可以弃置5枚勇气标记，令当前回合角色跳过一个除出牌以外的阶段。
-- 正义:弃置梅花♣️牌获得。每当你受到伤害后，你可以弃置2枚正义标记，对伤害来源造成1点伤害。

-- local LoR__Tiphereth_new = General:new(extension, "LoR__Tiphereth_new", "LoR_shu", 5, 5, 2)

-- local LoR__Tiphereth_new_qidai = fk.CreateTriggerSkill {
--     name = "LoR__Tiphereth_new_qidai",
--     anim_type = "support",
--     frequency = Skill.Compulsory,
--     events = { fk.ReasonJudge },
--     can_trigger = function(self, event, target, player, data)
--         return target == player and player:hasSkill(self) and data.who == player and data.card and data.card.number < 9 and
--         player:usedSkillTimes(self.name, Player.HistoryTurn) < player.hp
--     end,
--     on_use = function(self, event, target, player, data)
--         data.card.number = 9
--     end
-- }

-- local LoR__Tiphereth_new_qidai_trigger = fk.CreateTriggerSkill {
--     name = "#LoR__Tiphereth_new_qidai_trigger",
--     anim_type = "support",
--     frequency = Skill.Compulsory,
--     events = { fk.ReasonJudge },
--     can_trigger = function(self, event, target, player, data)
--         return target == player and player:hasSkill(LoR__Tiphereth_new_qidai) and data.who == player and data.card and
--         data.card.number >= player.hp
--     end,
--     on_use = function(self, event, target, player, data)
--         player.room:addPlayerMark(player, table.random(LoR_Buff, 1)[1])
--     end
-- }

-- local LoR__Tiphereth_new_qidai_targetMod = fk.CreateTargetModSkill {
--     name = "#LoR__Tiphereth_new_qidai_targetMod",
--     residue_func = function(self, player, skill, scope, card, to)
--         if card.trueName == "slash" and player:hasSkill(LoR__Tiphereth_new_qidai) then
--             return 1
--         else
--             return 0
--         end
--     end
-- }

-- local LoR__Tiphereth_new_qidai_maxcards = fk.CreateMaxCardsSkill {
--     name = "#LoR__Tiphereth_new_qidai_maxcards",
--     correct_func = function(self, player)
--         if player:hasSkill(LoR__Tiphereth_new_qidai) then
--             return 1
--         end
--     end
-- }

-- local LoR__Tiphereth_new_qidai_drawNcards = fk.CreateTriggerSkill {
--     name = "#LoR__Tiphereth_new_qidai_drawNcards",
--     frequency = Skill.Compulsory,
--     events = { fk.DrawNCards },
--     can_trigger = function(self, event, target, player, data)
--         return target == player and player:hasSkill(LoR__Tiphereth_new_qidai)
--     end,
--     on_use = function(self, event, target, player, data)
--         data.n = data.n + 1
--     end
-- }


-- local LoR__Tiphereth_new_ziwozhengming=fk.CreateTriggerSkill{
--     name="LoR__Tiphereth_new_ziwozhengming",
--     anim_type="support",
--     frequency=Skill.Compulsory,
--     events={fk.TurnStart},
--     can_trigger=function (self, event, target, player, data)
--         return target==player and player:hasSkill(self) and player:usedSkillTimes(self.name,Player.HistoryGame)<5
--     end
-- }


-- local testNPC = General:new(extension, "testNPC", "LoR_shu", 99, 99, 1)

local getCard = fk.CreateTriggerSkill {
    name = "getCard",
    frequency = Skill.Compulsory,
    events = { fk.TurnStart },
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        -- local targetPlayer = player.room:askForChoosePlayers(player, table.map(room.alive_players, function(e)
        --     return e.id
        -- end), 1, 1)
        -- room:loseHp(room:getPlayerById(targetPlayer[1]), room:getPlayerById(targetPlayer[1]).hp)
        local card1 = room:printCard("ShiHengBianYe__slash")
        room:setCardMark(card1, MarkEnum.DestructIntoDiscard, 1)
        room:moveCards({
            ids = { card1.id },
            fromArea = Card.Void,
            to = player.id,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonPrey,
            proposer = player.id,
            skillName = self.name,
            moveVisible = true,
        })
    end,
}

local AddSlash = fk.CreateTargetModSkill {
    name = "#AddSlash",
    residue_func = function(self, player, skill, scope, card, to)
        if card.trueName == "slash" and player:hasSkill(getCard) then
            return 3
        else
            return 0
        end
    end
}
local ChangeSF = fk.CreateTriggerSkill {
    name = "ChangeSF",
    mute = true,
    events = { fk.GamePrepared },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return target == player and player:hasSkill(self)
    end,
    on_use = function(self, event, target, player, data)
        player.role = "lord"
    end,
}
local super_yingzi = fk.CreateTriggerSkill {
    name = "super_yingzi",
    anim_type = "drawcard",
    events = { fk.DrawNCards },
    on_use = function(self, event, target, player, data)
        data.n = data.n + 20
    end,
}
local ChangeGeneral = fk.CreateTriggerSkill {
    name = "ChangeGeneral",
    mute = true,
    global = true,
    frequency = Skill.Compulsory,
    events = { fk.GameStart },
    on_use = function(self, event, target, player, data)
        -- if player.role ~= "lord" then
        --     player.room:setPlayerProperty(player, "role", "lord")
        -- end
        for _, p in ipairs(player.room.alive_players) do
            if p.id < 0 then
                -- player.room:changeHero(p, "wuzixu", true)
                player.room:changeMaxHp(p, 99)
                player.room:changeHp(p, 99)
                -- p.room:handleAddLoseSkills(p, "super_yingzi")
            else
                player.room:changeHero(p, "mouxusheng", true)
                -- p.room:setPlayerMark(p, "@qiangzhuang", 1)
                -- p.room:handleAddLoseSkills(p, "joy__jiaozi", nil, true, false)
                -- p:gainAnExtraTurn()

                player.room:changeMaxHp(p, 99)
                player.room:changeHp(p, 99)
            end
        end
    end,
}


local ChangeAI = fk.CreateTriggerSkill {
    name = "ChangeAI",
    mute = true,
    global = true,
    frequency = Skill.Compulsory,
    events = { fk.GameStart },
    can_trigger = function(self, event, target, player, data)
        return player.id < 0
    end,
    on_use = function(self, event, target, player, data)
        player.room:changeMaxHp(player, 99)
        player.room:changeHp(player, 99)
    end
}
local DisCardAI = fk.CreateTriggerSkill {
    name = "DisCardAI",
    frequency = Skill.Compulsory,
    mute = true,
    global = true,
    events = { fk.BeforeDrawCard, fk.DrawInitialCards },
    can_trigger = function(self, event, target, player, data)
        return player.id < 0 and target == player
    end,
    on_use = function(self, event, target, player, data)
        data.num = 0
    end
}

-- Fk:addSkill(ChangeGeneral)
-- Fk:addSkill(ChangeAI)
-- Fk:addSkill(DisCardAI)
-- getCard:addRelatedSkill(AddSlash)
-- testNPC:addSkill(getCard)
-- testNPC:addSkill(ChangeSF)
-- testNPC:addSkill(super_yingzi)







return extension
