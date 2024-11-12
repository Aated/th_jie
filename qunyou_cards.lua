local extension = Package:new("qunyou_cards", Package.CardPack)
extension.extensionName = "th_jie"


Fk:loadTranslationTable {
    ["qunyou_cards"] = "Rem群友包卡组"
}
local slash = Fk:cloneCard("slash")


local liuxingchui_skill = fk.CreateTriggerSkill {
    name = "#liuxingchui_skill",
    attached_equip = "liuxingchui",
    events = { fk.TargetSpecifying },
    frequency = Skill.Compulsory,
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self) and data.from == player.id and data.card.trueName == "slash" and
            player:distanceTo(player.room:getPlayerById(data.to)) > 1
    end,
    on_use = function(self, event, target, player, data)
        data.additionalDamage = (data.additionalDamage or 0) + 1
        return true
    end,
}
Fk:addSkill(liuxingchui_skill)
local liuxingchui = fk.CreateWeapon {
    name = "liuxingchui",
    suit = Card.Spade,
    number = 7,
    attack_range = 3,
    equip_skill = liuxingchui_skill,
}

Fk:loadTranslationTable {
    ["liuxingchui"] = "流星锤",
    [":liuxingchui"] = "<b>牌名：</b>流星锤<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，你使用【杀】对距离大于1的角色造成伤害+1",
    ["#liuxingchui_skill"] = "流星锤",
}


local shanshuozhiguang_skill = fk.CreateTriggerSkill {
    name = "#shanshuozhiguang_skill",
    attached_equip = "shanshuozhiguang",
    frequency = Skill.Compulsory,
    events = { fk.PindianCardsDisplayed },
    can_trigger = function(self, event, target, player, data)
        return player:hasSkill(self)
    end,
    on_cost = function(self, event, target, player, data)
        return true
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        if player == data.from then
            if data.fromCard.number + 6 > 13 then
                data.fromCard.number = 13
            else
                data.fromCard.number = data.fromCard.number + 6
            end
            local card2 = room:printCard(data.fromCard.name, data.fromCard.suit, data.fromCard.number)
            room:sendLog {
                type = "#ShowPindianCardNum",
                from = player.id,
                card = { card2.id },
                arg = card2.number,
            }
        elseif data.results[player.id] then
            if data.results[player.id].toCard.number + 6 > 13 then
                data.results[player.id].toCard.number = 13
            else
                data.results[player.id].toCard.number = data.results[player.id].toCard.number + 6
            end
            local card2 = room:printCard(data.results[player.id].toCard.name, data.results[player.id].toCard.suit,
                data.results[player.id].toCard.number)
            room:sendLog {
                type = "#ShowPindianCardNum",
                from = player.id,
                card = { card2.id },
                arg = card2.number,
            }
        end
    end,
}


Fk:addSkill(shanshuozhiguang_skill)
local shanshuozhiguang = fk.CreateWeapon {
    name = "shanshuozhiguang",
    suit = Card.Diamond,
    number = 9,
    attack_range = 3,
    equip_skill = shanshuozhiguang_skill,
}

Fk:loadTranslationTable {
    ["shanshuozhiguang"] = "闪烁之光",
    [":shanshuozhiguang"] = "<b>牌名：</b>闪烁之光<br/><b>类型：</b>装备牌·武器<br /><b>攻击范围</b>：３<br /><b>武器技能</b>：锁定技，你的拼点牌点数+6",
    ["#shanshuozhiguang_skill"] = "闪烁之光",
    ["#ShowPindianCardNum"] = "%from展示了%card，点数为%arg"
}

extension:addCards({
    liuxingchui,
    shanshuozhiguang,
})

return extension