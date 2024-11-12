local LoR_Utility = require "packages/th_jie/LoR_Utility"


LoR_Buff={"@qiangzhuang","@LoR_ShouHu"}
LoR_Debuff={"@LiuXue_LoR","@LoR_Fire","@LoR_Hunluan","@LoR_XuRuo","@LoR_PoZhan","@LoR_Aiyi","@LoR_MaBi"}

--状态技能：强壮
local QiangZhuang = fk.CreateTriggerSkill {
    name = "qiangzhuang",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.CardUsing },
    can_trigger = function(self, event, target, player, data)
        return data.from == player.id and player:getMark("@qiangzhuang") > 0 and
            data.card and data.card.is_damage_card == true
    end,
    on_use = function(self, event, target, player, data)
        if data.additionalDamage == nil then data.additionalDamage = 0 end
        data.additionalDamage = data.additionalDamage + player:getMark("@qiangzhuang")
    end,


    refresh_events = { fk.TurnEnd },
    can_refresh = function(self, event, target, player, data)
        return target == player and player:getMark("@qiangzhuang") > 0
    end,
    on_refresh = function(self, event, target, player, data)
        player.room:removePlayerMark(player, "@qiangzhuang", player:getMark("@qiangzhuang"))
    end
}
Fk:addSkill(QiangZhuang)
Fk:loadTranslationTable {
    ["qiangzhuang"] = "强壮",
    ["qiangzhuang_jieshao"] = "<br><font color='grey'><b>#强壮</b><br>你造成的卡牌伤害+X(X为强壮层数),你的回合结束时失去所有【强壮】",
    ["@qiangzhuang"] = "强壮",
}
--状态技能：流血-LoR
local LiuXue = fk.CreateTriggerSkill {
    name = "LiuXue",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.CardUsing },
    can_trigger = function(self, event, target, player, data)
        return data.from == player.id and player:getMark("@LiuXue_LoR") > 0 and data.card and data.card.is_damage_card
    end,
    on_use = function(self, event, target, player, data)
        player.room:damage({
            from = nil,
            to = player,
            damage = 1,
            skillName = self.name
        })
        player.room:removePlayerMark(player, "@LiuXue_LoR")
    end,

    refresh_events={fk.TurnEnd},
    can_refresh=function (self, event, target, player, data)
        return target==player and player:getMark("@LiuXue_LoR") > 0
    end,
    on_refresh=function (self, event, target, player, data)
        player.room:removePlayerMark(player, "@LiuXue_LoR")
    end,
}
Fk:addSkill(LiuXue)
Fk:loadTranslationTable {
    ["LiuXue"] = "流血-LoR",
    ["LiuXue_jieshao"] = "<br><font color='grey'><b>#流血-LoR</b><br>你每使用一张伤害牌，受到一点无来源伤害，然后失去一层【流血-LoR】；你的回合结束时失去一层【流血-LoR】",
    ["@LiuXue_LoR"] = "流血-LoR",
}

--状态技能：反击
local Fanji = fk.CreateTriggerSkill {
    name = "Fanji",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.TargetConfirmed },
    can_trigger = function(self, event, target, player, data)
        return #player.getTableMark(player, "Fanji_All") > 0 and data.card and
            data.card.is_damage_card and data.to == player.id
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local fanji_num = player.getTableMark(player, "@Fanji_LoR")[2]
        if fanji_num <= 1 then fanji_num = 1 end
        local pa = ".|1~" .. fanji_num
        local judge = {
            who = player,
            pattern = pa,
            reason = self.name
        }
        room:judge(judge)
        if judge.card.number <= fanji_num then
            local card = Fk:cloneCard("slash")
            room:useCard({
                from = player.id,
                tos = { { data.from } },
                card = card,
            })
        else
            local fanji_all = player.getTableMark(player, "Fanji_All")
            table.remove(fanji_all, #fanji_all)
            if #fanji_all > 0 then
                local mark = fanji_all[#fanji_all]
                room:setPlayerMark(player, "Fanji_All", fanji_all)
                room:setPlayerMark(player, "@Fanji_LoR", mark)
            else
                room:setPlayerMark(player, "@Fanji_LoR", 0)
                room:removePlayerMark(player, "@Fanji_LoR")
                room:setPlayerMark(player, "Fanji_All", 0)
                room:removePlayerMark(player, "Fanji_All")
            end
        end
    end,
}
Fk:addSkill(Fanji)
Fk:loadTranslationTable {
    ["Fanji"] = "反击",
    ["Fanji_jieshao"] = "<br><font color='grey'><b>#反击</b><br>当你成为伤害牌的目标时，你进行一次判定:若判定点数不大于【反击】点数，则你视为对其使用一张【杀】；否则你失去一层【反击】。",
    ["@Fanji_LoR"] = "反击",
}

--状态技能：血雾
local RedMist = fk.CreateTriggerSkill {
    name = "RedMist",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.TargetSpecifying },
    can_trigger = function(self, event, target, player, data)
        return data.from == player.id and player:getMark("@RedMist") > 0 and data.card and data.card.trueName == "slash"
    end,
    on_use = function(self, event, target, player, data)
        data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@RedMist")
    end,
}
Fk:addSkill(RedMist)
Fk:loadTranslationTable {
    ["RedMist"] = "血雾",
    ["RedMist_jieshao"] = "<br><font color='grey'><b>#血雾</b><br>你的【杀】伤害+X（x为【血雾】层数）。",
    ["@RedMist"] = "血雾",
}

--状态技能：反击↑
local Fanji2 = fk.CreateTriggerSkill {
    name = "Fanji2",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.TargetConfirmed },
    can_trigger = function(self, event, target, player, data)
        return player:getMark("@@Fanji2") > 0 and data.card and
            data.card.trueName == "slash" and data.to == player.id
    end,
    on_use = function(self, event, target, player, data)
        local room = player.room
        local slash_num = data.card.number
        local pa = ".|1~" .. slash_num - 1
        local judge = {
            who = player,
            pattern = pa,
            reason = self.name
        }
        room:judge(judge)
        if judge.card.number > slash_num then
            local card = Fk:cloneCard("slash")
            room:useCard({
                from = player.id,
                tos = { { data.from } },
                card = card,
            })
        else
            room:removePlayerMark(player, "@@Fanji2")
        end
    end,
}
Fk:addSkill(Fanji2)
Fk:loadTranslationTable {
    ["Fanji2"] = "反击↑",
    ["Fanji2_jieshao"] = "<br><font color='grey'><b>#反击↑</b><br>锁定技:当你成为【杀】的目标时，你进行一次判定:若此【杀】点数小于你的判定点数时，你视为对其使用一张【杀】；否则你失去一层【反击↑】。",
    ["@@Fanji2"] = "反击↑",
}

--状态技能：光之种
--拥有【光之种】的角色，摸牌阶段额外抽x张牌，（x为【光之种】层数）；受到致命伤害时失去至多y层【光之种】令本次伤害-y(y为令你保留一点体力所需的回复值)。
local Guangzhizhong=fk.CreateTriggerSkill{
    name="Guangzhizhong",
    mute=true,
    global=true,
    frequency=Skill.Compulsory,
    priority=2,
    events={fk.DrawNCards,fk.DamageInflicted},
    can_trigger=function (self, event, target, player, data)
        if target==player and player:getMark("@guangzhizhong")>0 then
            if event==fk.DrawNCards then
                return true
            elseif event==fk.DamageInflicted then
                return data.damage>=player.hp+player.shield and data.to==player
            end
        end
    end,
    on_use=function (self, event, target, player, data)
        if event==fk.DrawNCards then
            data.n = data.n+ player:getMark("@guangzhizhong")
        else
            if data.damage>=player.hp+player.shield then
                local num=math.min(data.damage-(player.hp+player.shield)+1,player:getMark("@guangzhizhong"))
                data.damage=data.damage-num
                if data.damage<0 then
                    data.damage=0
                end
                player.room:removePlayerMark(player,"@guangzhizhong",num)
            end
        end
    end
}

Fk:addSkill(Guangzhizhong)
Fk:loadTranslationTable {
    ["Guangzhizhong"] = "光之种",
    ["Guangzhizhong_jieshao"] = "<br><font color='grey'><b>#光之种</b><br>锁定技:摸牌阶段额外抽x张牌，（x为【光之种】层数）；受到致命伤害时失去至多y层【光之种】令本次伤害-y(y为令你保留一点体力所需的回复值)。",
    ["@guangzhizhong"] = "光之种",
}

--状态技能：烧伤
local LoR_Fire=fk.CreateTriggerSkill{
    name = "LoR_Fire",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.TurnEnd},
    can_trigger = function(self, event, target, player, data)
        return player:getMark("@LoR_Fire")>0 and not player.dead
    end,
    on_use = function(self, event, target, player, data)
        local num=player:getMark("@LoR_Fire")
        player.room:removePlayerMark(player,"@LoR_Fire",player:getMark("@LoR_Fire"))
        player.room:damage({
            to=player,
            damage=num,
            damageType=fk.FireDamage
        })
    end,
}
Fk:addSkill(LoR_Fire)
Fk:loadTranslationTable {
    ["LoR_Fire"] = "烧伤",
    ["LoR_Fire_jieshao"] = "<br><font color='grey'><b>#烧伤</b><br>目标在当前回合结束时失去全部【烧伤】并受到等同于【烧伤】数量的无来源火焰伤害",
    ["@LoR_Fire"] = "烧伤",
}

--状态技能：混乱
local LoR_Hunluan=fk.CreateTriggerSkill{
    name = "LoR_Hunluan",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.TurnStart},
    can_trigger = function(self, event, target, player, data)
        return target==player and player:getMark("@LoR_Hunluan")>=15 and not player.dead 
    end,
    on_use = function(self, event, target, player, data)
        local room=player.room
        if player.faceup then
            player:turnOver()
        end
        room:removePlayerMark(player,"@LoR_Hunluan",player:getMark("@LoR_Hunluan"))
        room:addPlayerMark(player,"@@LoR_Zhiming-round")
    end,
}

local LoR_Zhiming=fk.CreateTriggerSkill{
    name="#LoR_Zhiming",
    mute=true,
    global=true,
    priority=0.5,
    frequency=Skill.Compulsory,
    events={fk.DamageInflicted},
    can_trigger=function (self, event, target, player, data)
        return target==player and player:getMark("@@LoR_Zhiming-round")>0
    end,
    on_use=function (self, event, target, player, data)
        data.damage=(data.damage or 0)*2
    end,
}
Fk:addSkill(LoR_Hunluan)
Fk:addSkill(LoR_Zhiming)
Fk:loadTranslationTable {
    ["LoR_Hunluan"] = "混乱",
    ["LoR_Hunluan_jieshao"] = "<br><font color='grey'><b>#混乱</b><br>你的回合开始时，若【混乱】层数不小于15时，失去所有【混乱】，获得[致命]:若你正面向上，则翻面;本轮受到的伤害翻倍。",
    ["@LoR_Hunluan"] = "混乱",
    ["@@LoR_Zhiming-round"] = "致命",
}

--状态技能：虚弱
local LoR_XuRuo=fk.CreateTriggerSkill{
    name = "LoR_XuRuo",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.DamageCaused},
    can_trigger = function(self, event, target, player, data)
        return target==player and player:getMark("@LoR_XuRuo")>0 and not player.dead
    end,
    on_use = function(self, event, target, player, data)
        local room=player.room
        if data.damage>=player:getMark("@LoR_XuRuo") then
            data.damage=data.damage-player:getMark("@LoR_XuRuo")
        else
            data.damage=0
        end
    end,

    refresh_events={fk.TurnEnd},
    can_refresh=function (self, event, target, player, data)
        return target==player and player:getMark("@LoR_XuRuo")>0
    end,
    on_refresh=function (self, event, target, player, data)
        player.room:removePlayerMark(player,"@LoR_XuRuo",player:getMark("@LoR_XuRuo"))
    end,
}
Fk:addSkill(LoR_XuRuo)
Fk:loadTranslationTable {
    ["LoR_XuRuo"] = "虚弱",
    ["LoR_XuRuo_jieshao"] = "<br><font color='grey'><b>#虚弱</b><br>目标造成伤害时，减少【虚弱】层数的伤害，目标回合结束时移除所有【虚弱】",
    ["@LoR_XuRuo"] = "虚弱",
}

--状态技能：破绽
local LoR_PoZhan=fk.CreateTriggerSkill{
    name = "LoR_PoZhan",
    mute = true,
    global = true,
    priority = 2,
    frequency = Skill.Compulsory,
    events = { fk.Damaged},
    can_trigger = function(self, event, target, player, data)
        return target==player and player:getMark("@LoR_PoZhan")>0 and not player.dead and not player:isNude()
    end,
    on_use = function(self, event, target, player, data)
        local room=player.room
        if #player:getCardIds("he")>=player:getMark("@LoR_PoZhan") then
            room:throwCard(table.random(player:getCardIds("he"),player:getMark("@LoR_PoZhan")),self.name,player)
        else
            player:throwAllCards("he")
        end
    end,

    refresh_events={fk.TurnStart},
    can_refresh=function (self, event, target, player, data)
        return target==player and player:getMark("@LoR_PoZhan")>0
    end,
    on_refresh=function (self, event, target, player, data)
        player.room:removePlayerMark(player,"@LoR_PoZhan",player:getMark("@LoR_PoZhan"))
    end,
}
Fk:addSkill(LoR_PoZhan)
Fk:loadTranslationTable {
    ["LoR_PoZhan"] = "破绽",
    ["LoR_PoZhan_jieshao"] = "<br><font color='grey'><b>#破绽</b><br>当你受到伤害时，失去【破绽】层数数量的牌。你的回合开始时失去所有【破绽】",
    ["@LoR_PoZhan"] = "破绽",
}

--状态技能：爱意
local LoR_Aiyi = fk.CreateTriggerSkill {
    name = "LoR_Aiyi",
    global = true,
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.TargetSpecifying },
    can_trigger = function(self, event, target, player, data)
      return target == player and player:getMark("@LoR_aiyi") > 0 and data.card
    end,
    on_use = function(self, event, target, player, data)
      table.insertIfNeed(data.nullifiedTargets, data.to)
      player.room:removePlayerMark(player, "@LoR_aiyi")
      return true
    end,
  }
  Fk:addSkill(LoR_Aiyi)
  Fk:loadTranslationTable {
    ["LoR_Aiyi"] = "爱意",
    ["LoR_Aiyi_jieshao"] = "<br><font color='grey'><b>#爱意</b><br>你使用的下一张牌无效，然后失去一层【爱意】",
    ["@LoR_Aiyi"] = "爱意",
}

--状态技能：守护
local LoR_ShouHu=fk.CreateTriggerSkill{
    name="LoR_ShouHu",
    global = true,
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.DamageInflicted},
    can_trigger=function (self, event, target, player, data)
       return target==player and player:getMark("@LoR_ShouHu")>0 and data.damage>0
    end,
    on_use=function (self, event, target, player, data)
        local room=player.room
        room:removePlayerMark(player,"@LoR_ShouHu")
        data.damage=data.damage-1
    end,
}
Fk:addSkill(LoR_ShouHu)
Fk:loadTranslationTable {
  ["LoR_ShouHu"] = "守护",
  ["LoR_ShouHu_jieshao"] = "<br><font color='grey'><b>#守护</b><br>你受到的下一次伤害-1，然后失去一层【守护】",
  ["@LoR_ShouHu"] = "守护",
}


--状态技能：麻痹
local LoR_MaBi=fk.CreateTriggerSkill{
    name="LoR_MaBi",
    global = true,
    mute = true,
    frequency = Skill.Compulsory,
    events = { fk.DamageCaused},
    can_trigger=function (self, event, target, player, data)
       return target==player and player:getMark("@LoR_MaBi")>0 and data.card and data.damage>0
    end,
    on_use=function (self, event, target, player, data)
        local room=player.room
        room:removePlayerMark(player,"@LoR_MaBi")
        data.damage=data.damage-1
    end,
}
Fk:addSkill(LoR_MaBi)
Fk:loadTranslationTable {
  ["LoR_MaBi"] = "麻痹",
  ["LoR_MaBi_jieshao"] = "<br><font color='grey'><b>#麻痹</b><br>你造成的下一次卡牌伤害-1，然后失去一层【麻痹】",
  ["@LoR_MaBi"] = "麻痹",
}

local function LoR_State_jieshao()
    local string1="<br><font color='grey'><b>#状态</b></font><br><font color='white'>正面状态："
    local stringBuff=""
    for _, value in ipairs(LoR_Buff) do
        stringBuff=stringBuff..Fk:translate(value)..","
    end
    string1=string1..stringBuff.."<br>负面状态："
    local stringDebuff=""
    for _, value in ipairs(LoR_Debuff) do
        stringDebuff=stringDebuff..Fk:translate(value)..","
    end
    string1=string1..stringDebuff.."</font>"
    return string1
end
Fk:loadTranslationTable{
    ["LoR_State_jieshao"]=LoR_State_jieshao(),
    ["EGOShow"]="<br><font color='grey'><b>#E.G.O展现状态</b><br>该角色失去本技能原武将牌上的所有技能，替换武将图像并获得对应的EGO展现武将的技能。",
}