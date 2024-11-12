local extension = Package:new("LoR_normal_cards", Package.CardPack)
extension.extensionName = "th_jie"

local LoR_Utility = require "packages/th_jie/LoR_Utility"

Fk:loadTranslationTable {
  ["LoR_normal_cards"] = "图书馆普通卡组"
}
local slash = Fk:cloneCard("slash")

local XianZhen__slash_skill = fk.CreateActiveSkill {
  name = "XianZhen__slash_skill",
  target_num = 1,
  can_use = function(self, player, card, extra_data)
    return player.phase ~= Player.Play or
        table.find(Fk:currentRoom().alive_players, function(p1)
          if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 2) then
            return p1
          end
        end)
  end,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    local from = Fk:currentRoom():getPlayerById(user)
    if from and player then
      return from ~= player
    end
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
    room:broadcastPlaySound("./packages/th_jie/audio/card/male/XianZhen__slash")
    room:getPlayerById(cardUseEvent.from):addCardUseHistory(slash.name, 1)
    local targets = TargetGroup:getRealTargets(cardUseEvent.tos)
    local to = room:getPlayerById(targets[1])
    cardUseEvent.disresponsiveList = cardUseEvent.disresponsiveList or {}
    table.insert(cardUseEvent.disresponsiveList, to.id)
  end,
  on_effect = function(self, room, effect)
    room:damage({
      from = room:getPlayerById(effect.from),
      to = room:getPlayerById(effect.to),
      card = effect.card,
      damage = 3,
      skillName = self.name
    })
  end
}
local XianZhen__slash = fk.CreateBasicCard {
  name = "XianZhen__slash",
  number = 3,
  suit = Card.Spade,
  skill = XianZhen__slash_skill,
  is_damage_card = true,
}
local XianZhenSkill_Dying = fk.CreateTriggerSkill {
  name = "XianZhenSkill_Dying",
  frequency = Skill.Compulsory,
  global = true,
  mute = true,
  priority = 0.4,
  events = { fk.EnterDying, fk.AfterDying, fk.Deathed },
  can_trigger = function(self, event, target, player, data)
    return ((event == fk.AfterDying and player.room:getPlayerById(data.who).hp > 0) or event ~= fk.AfterDying) and
        data.damage and data.damage.card and data.damage.card.name == "XianZhen__slash" and
        data.damage.from == player
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EnterDying then
      data.damage.to:addMark("xianzhen-turn", 1)
    elseif event == fk.AfterDying or event == fk.Deathed then
      local targetPlayers = {}
      for _, p in ipairs(player.room:getOtherPlayers(player)) do
        if p:getMark("xianzhen-turn") < 1 and not player:isProhibited(p, Fk:cloneCard("slash")) then
          table.insertIfNeed(targetPlayers, p.id)
        end
      end
      if #targetPlayers > 0 then
        local choicePlayer = player.room:askForChoosePlayers(player, targetPlayers, 1, 1,
          "#xianzhen-choose", self.name, true, false)
        if choicePlayer and #choicePlayer > 0 then
          player.room:doIndicate(player.id, choicePlayer)
          player.room:useCard({
            from = player.id,
            tos = { { choicePlayer[1] } },
            card = XianZhen__slash
          })
        end
      end
    end
  end,
}
Fk:addSkill(XianZhenSkill_Dying)


Fk:loadTranslationTable {
  ["XianZhen__slash"] = "陷阵之志",
  ["XianZhenSkill_Use"] = "陷阵之志",
  ["XianZhenSkill_Dying"] = "陷阵之志",
  [":XianZhen__slash"] = "<b>牌名：</b>陷阵之志<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名角色<br /><b>效果</b>：消耗两次出【杀】次数。视为使用一张【杀】。" ..
      "此【杀】无法被响应且伤害+2。若此【杀】令一名角色陷入濒死，其濒死结算后你可以对一名除其以外的其他角色使用此【杀】。（无法选择本回合已因此牌进入过濒死的目标）",
  ["#xianzhen-choose"] = "你可以一名角色使用【陷阵之志】",
}

--屏息凝神：锦囊，使用时，获得2点护甲，下一次使用【杀】若造成伤害，自身获得3层【强壮】

local BingXi_skill = fk.CreateActiveSkill {
  name = "BingXi_skill",
  prompt = "#BingXi_skill",
  mute = true,
  can_use = function(self, player, card, extra_data)
    return not player:isProhibited(player, card)
  end,
  mod_target_filter = Util.TrueFunc,
  on_use = function(self, room, cardUseEvent)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
    room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
  end,
  on_effect = function(self, room, effect)
    local target = room:getPlayerById(effect.to)
    if target.dead then return end
    room:changeShield(target, 1)
    room:setPlayerMark(target, "@BingXimingshen", target:getMark("@BingXimingshen") + 1)
  end
}

local BingXi_slashskill = fk.CreateTriggerSkill {
  name = "BingXi_slashskill",
  mute = true,
  frequency = Skill.Compulsory,
  global = true,
  priority = 0.5,
  events = { fk.Damage, fk.CardEffectCancelledOut },
  can_trigger = function(self, event, target, player, data)
    if data.card and data.card.trueName == "slash" and player:getMark("@BingXimingshen") > 0 then
      if event == fk.Damage then
        return data.from == player
      else
        return data.from == player.id
      end
    end
    return false
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.Damage then
      player.room:addPlayerMark(player, "@qiangzhuang", 3)
    end
    player.room:removePlayerMark(player, "@BingXimingshen", 1)
  end
}
Fk:addSkill(BingXi_slashskill)

local BingXi = fk.CreateTrickCard {
  name = "BingXi",
  number = 3,
  suit = Card.Spade,
  skill = BingXi_skill,
  is_damage_card = false,
}

Fk:loadTranslationTable {
  ["BingXi"] = "屏息凝神",
  ["BingXi_skill"] = "屏息凝神",
  ["BingXi_slashskill"] = "屏息凝神",
  ["#BingXi_skill"] = "屏息凝神:使用时，获得1点护甲，下一次使用【杀】造成伤害时，自身获得3层【强壮】",
  [":BingXi"] = "<b>牌名：</b>屏息凝神<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：自己<br /><b>效果</b>：使用时，获得1点护甲，下一次使用【杀】造成伤害时，自身获得3层【<a href='qiangzhuang_jieshao'>强壮</a>】",
  ["@BingXimingshen"] = "屏息",
}



--大刀横斩：基本，使用时，消耗2次出杀次数，视为对目标使用2张杀。
--若此牌造成的伤害不小于4，你本回合出杀次数+1，令此牌目标获得2层【流血】，本局游戏同名牌消耗出杀次数-1（至少为0）

local HengZhan__slash_skill = fk.CreateActiveSkill {
  name = "HengZhan__slash_skill",
  prompt = "#HengZhan__slash_skill",
  target_num = 1,
  can_use = function(self, player, card, extra_data)
    return player.phase ~= Player.Play or
        table.find(Fk:currentRoom().alive_players, function(p1)
          if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 1) then
            return p1
          end
        end)
  end,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    local from = Fk:currentRoom():getPlayerById(user)
    if from and player then
      return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, true, card, player))
    end
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
    local targetplayer = room:getPlayerById(effect.to)
    local player = room:getPlayerById(effect.from)
    room:damage({
      from = player,
      to = targetplayer,
      card = effect.card,
      damage = 1,
      skillName = self.name
    })
    player.room:addPlayerMark(player, "@qiangzhuang", 1)
  end
}
local HengZhan__slash = fk.CreateBasicCard {
  name = "HengZhan__slash",
  number = 3,
  suit = Card.Spade,
  skill = HengZhan__slash_skill,
  is_damage_card = true,
}

local HengZhan__slash_Damage = fk.CreateTriggerSkill {
  name = "#HengZhan__slash_Damage",
  mute = true,
  frequency = Skill.Compulsory,
  events = { fk.Damage },
  global = true,
  can_trigger = function(self, event, target, player, data)
    return data.card and data.card.name == "HengZhan__slash" and data.damage and data.damage >= 4
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(data.to, "@LiuXue_LoR", 2)
  end,
}
Fk:addSkill(HengZhan__slash_Damage)

Fk:loadTranslationTable {
  ["HengZhan__slash"] = "大刀横斩",
  ["HengZhan__slash_skill"] = "大刀横斩",
  ["#HengZhan__slash_skill"] = "大刀横斩:视为普通【杀】，此牌造成伤害时,你获得1层【强壮】。若因此牌造成的伤害不小于4，你令目标获得两层【流血】",
  [":HengZhan__slash"] = "<b>牌名：</b>大刀横斩<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名攻击范围内的其他角色<br /><b>效果</b>：" ..
      "视为对其使用一张【杀】,此牌造成伤害时,你获得一层【<a href='qiangzhuang_jieshao'>强壮</a>】。若因此牌造成的伤害不小于4，你令目标获得2层【<a href='LiuXue_jieshao'>流血</a>】<br>"
}


--大刀纵劈:基本，使用时，本回合【杀】伤害+1。若此牌的【杀】总计造成的伤害不小于4，你摸两张牌，本局游戏【杀】伤害+1
local ZongPi__slash_skill = fk.CreateActiveSkill {
  name = "ZongPi__slash_skill",
  prompt = "#ZongPi__slash_skill",
  target_num = 1,
  can_use = function(self, player, card, extra_data)
    return player.phase ~= Player.Play or
        table.find(Fk:currentRoom().alive_players, function(p1)
          if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 1) then
            return p1
          end
        end)
  end,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    local from = Fk:currentRoom():getPlayerById(user)
    if from and player then
      return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, true, card, player))
    end
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
    local player = room:getPlayerById(cardUseEvent.from)
    if player:getMark("@ZongPi_slash-turn") == 0 then
      player.room:setPlayerMark(player, "@ZongPi_slash-turn", 1)
    end
    cardUseEvent.additionalDamage = (cardUseEvent.additionalDamage or 0) + player:getMark("@ZongPi_slash_damage")
  end,
  on_effect = function(self, room, effect)
    room:damage({
      from = room:getPlayerById(effect.from),
      to = room:getPlayerById(effect.to),
      card = effect.card,
      damage = 1,
      skillName = self.name
    })
  end
}
local ZongPi__slash = fk.CreateBasicCard {
  name = "ZongPi__slash",
  number = 3,
  suit = Card.Spade,
  skill = ZongPi__slash_skill,
  is_damage_card = true,
}
local ZongPi_slash_damage = fk.CreateTriggerSkill {
  name = "ZongPi_slash_damage",
  mute = true,
  global = true,
  frequency = Skill.Compulsory,
  events = { fk.CardUsing },
  priority = 0.5,
  can_trigger = function(self, event, target, player, data)
    if data.from == player.id and data.card and data.card.trueName == "slash" then
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@ZongPi_slash-turn")
  end,
}
local ZongPi_slash_Damage = fk.CreateTriggerSkill {
  name = "ZongPi_slash_Damage",
  mute = true,
  global = true,
  events = { fk.DamageCaused },
  priority = 3,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card.name == "ZongPi__slash" and data.damage >= 5
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("@ZongPi_slash_damage")<20 then
      player.room:addPlayerMark(player,"@ZongPi_slash_damage")
    else
      player:drawCards(2,"ZongPi__slash_skill")
    end
  end,
}
Fk:addSkill(ZongPi_slash_damage)
Fk:addSkill(ZongPi_slash_Damage)

Fk:loadTranslationTable {
  ["ZongPi__slash"] = "大刀纵劈",
  ["ZongPi__slash_skill"] = "大刀纵劈",
  ["#ZongPi__slash_skill"] = "大刀纵劈:视为普通【杀】，使用时本回合【杀】伤害+1，此【杀】造成的伤害不小于5时，若你拥有【纵劈】小于20层，本局游戏【大刀纵劈】伤害+1；否则你摸两张牌",
  ["ZongPi_Damage"] = "大刀纵劈",
  [":ZongPi__slash"] = "<b>牌名：</b>大刀纵劈<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名攻击范围内的其他角色<br /><b>效果</b>：视为对目标使用1张【杀】，本回合【杀】伤害+1。若此【杀】总计造成的伤害不小于5，本局游戏【大刀纵劈】伤害+1",
  ["ZongPi_slash_damage"] = "大刀纵劈",
  ["ZongPi_slash_Damage"] = "大刀纵劈",
  ["@ZongPi_slash_damage"] = "纵劈+",
  ["@ZongPi_slash-turn"] = "杀+",
}

--大刀直刺:基本，
local ZhiCi__slash_skill = fk.CreateActiveSkill {
  name = "ZhiCi__slash_skill",
  prompt = "#ZhiCi__slash_skill",
  target_num = 1,
  can_use = function(self, player, card, extra_data)
    return player.phase ~= Player.Play or
        table.find(Fk:currentRoom().alive_players, function(p1)
          if LoR_Utility.withinTimesLimit(player, Player.HistoryPhase, slash, "slash", p1, slash.skill, 1) then
            return p1
          end
        end)
  end,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    local from = Fk:currentRoom():getPlayerById(user)
    if from and player then
      return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, true, card, player))
    end
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
    for _, to in ipairs(TargetGroup:getRealTargets(cardUseEvent.tos)) do
      room:addPlayerMark(room:getPlayerById(to), "@LiuXue_LoR")
    end
  end,
  on_effect = function(self, room, effect)
    local to = effect.to
    room:damage({
      from = room:getPlayerById(effect.from),
      to = room:getPlayerById(to),
      card = effect.card,
      damage = 1,
      skillName = self.name
    })
  end
}
local ZhiCi__slash = fk.CreateBasicCard {
  name = "ZhiCi__slash",
  number = 3,
  suit = Card.Spade,
  skill = ZhiCi__slash_skill,
  is_damage_card = true,
}
local ZhiCi_Damage = fk.CreateTriggerSkill {
  name = "ZhiCi_Damage",
  mute = true,
  global = true,
  events = { fk.DamageCaused },
  priority = 3,
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card and data.card.name == "ZhiCi__slash"
  end,
  on_use = function(self, event, target, player, data)
    if data.damage >= 4 then
      if player.maxHp<20 then
        player.room:changeMaxHp(player, 1)
      else
        player.room:addPlayerMark(data.to,"@LiuXue_LoR",2)
      end
    end
  end,
}

Fk:addSkill(ZhiCi_Damage)

Fk:loadTranslationTable {
  ["ZhiCi__slash"] = "大刀直刺",
  ["ZhiCi__slash_skill"] = "大刀直刺",
  ["#ZhiCi__slash_skill"] = "大刀直刺：视为普通【杀】，此牌指定目标时，目标获得一层【流血】。若此【杀】造成伤害不小于4时，若你的体力上限小于20，你增加一点体力上限；否则你令目标获得2层【流血】。",
  ["ZhiCi_Damage"] = "大刀直刺",
  [":ZhiCi__slash"] = "<b>牌名：</b>大刀直刺<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名攻击范围内的其他角色<br /><b>效果</b>：使用时，视为对目标使用1张杀。此牌指定目标时，目标获得一层【流血】。若此【杀】造成伤害不小于4，你增加一点体力上限。"
      .. Fk:translate("LiuXue_jieshao"),

}



local LoR_angela_haixiu_skill = fk.CreateActiveSkill {
  name = "LoR_angela_haixiu_skill",
  prompt = "#LoR_angela_haixiu_skill",
  target_filter = Util.FalseFunc,
  can_use = function(self, player, card)
    return not player:isProhibited(player, card)
  end,
  on_use = function(self, room, cardUseEvent)
    room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.to)
    if player.dead then return end
    player:drawCards(1)
    room:changeShield(player, 1)
    room:addPlayerMark(player, "@LoR_slash-turn", 3)
  end,
}
local LoR_targetmod = fk.CreateTargetModSkill {
  name = "#LoR_targetmod",
  global = true,
  residue_func = function(self, player, skill, scope, card, to)
    if player:getMark("@LoR_slash-turn") > 0 and card.trueName == "slash" then
      return player:getMark("@LoR_slash-turn")
    end
  end
}

Fk:addSkill(LoR_targetmod)


local LoR_angela_haixiu = fk.CreateBasicCard {
  name = "LoR_angela_haixiu",
  number = 5,
  suit = Card.Diamond,
  skill = LoR_angela_haixiu_skill,
  is_damage_card = false,
}

Fk:loadTranslationTable {
  ["LoR_angela_haixiu"] = "害羞",
  ["LoR_angela_haixiu_skill"] = "害羞",
  [":LoR_angela_haixiu"] = "<b>牌名：</b>害羞<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：自己<br /><b>效果</b>：增加一点【护甲】，摸一张牌，本回合增加3次使用【杀】次数",
  ["@LoR_slash-turn"] = "杀次数+",
  ["#LoR_angela_haixiu_skill"] = "对自己使用，增加一点【护甲】，摸一张牌，本回合增加3次使用【杀】次数",
}


local LoR_angela_youyi_skill = fk.CreateActiveSkill {
  name = "LoR_angela_youyi_skill",
  prompt = "#LoR_angela_youyi_skill",
  target_filter = Util.FalseFunc,
  can_use = function(self, player, card)
    return not player:isProhibited(player, card)
  end,
  on_use = function(self, room, cardUseEvent)
    room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
    if not cardUseEvent.tos or #TargetGroup:getRealTargets(cardUseEvent.tos) == 0 then
      cardUseEvent.tos = { { cardUseEvent.from } }
    end
  end,
  on_effect = function(self, room, cardEffectEvent)
    local player = room:getPlayerById(cardEffectEvent.from)
    local buddy = table.filter(room.alive_players, function(p)
      return p.role == player.role
    end)
    local choosePlayer = player
    for index, p in ipairs(buddy) do
      if p.hp < player.hp then
        choosePlayer = p
      end
    end
    room:recover({
      who = choosePlayer,
      num = 2,
      recoverBy = player,
      card = cardEffectEvent.card
    })
  end,
}

local LoR_angela_youyi = fk.CreateTrickCard {
  name = "LoR_angela_youyi",
  number = 10,
  suit = Card.Heart,
  skill = LoR_angela_youyi_skill,
  is_damage_card = false,
}

Fk:loadTranslationTable {
  ["LoR_angela_youyi"] = "友谊之证",
  ["LoR_angela_youyi_skill"] = "友谊之证",
  [":LoR_angela_youyi"] = "<b>牌名：</b>友谊之证<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：体力最低的我方角色<br /><b>效果</b>：令其回复两点体力",
  ["#LoR_angela_youyi_skill"] = "令体力最低的我方角色回复两点体力",
}


local LoR_angela_xueyi_skill = fk.CreateActiveSkill {
  name = "LoR_angela_xueyi_skill",
  prompt = "#LoR_angela_xueyi_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    local from = Fk:currentRoom():getPlayerById(user)
    if from and player then
      return from ~= player and not (distance_limited and not self:withinDistanceLimit(from, true, card, player))
    end
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
    local player = room:getPlayerById(cardUseEvent.from)
    room:addPlayerMark(player, "@LoR_slash-turn")
    player:drawCards(1)
    room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
  end,
  on_effect = function(self, room, cardEffectEvent)
    room:damage({
      from = room:getPlayerById(cardEffectEvent.from),
      to = room:getPlayerById(cardEffectEvent.to),
      damage = 1,
      card = cardEffectEvent.card,
      damageType = fk.NormalDamage,
      skillName = self.name
    })
    room:addPlayerMark(room:getPlayerById(cardEffectEvent.to), "@LiuXue_LoR")
  end,
}
local LoR_angela_xueyi__slash = fk.CreateBasicCard {
  name = "LoR_angela_xueyi__slash",
  number = 10,
  suit = Card.Heart,
  skill = LoR_angela_xueyi_skill,
  is_damage_card = true,
}

Fk:loadTranslationTable {
  ["LoR_angela_xueyi__slash"] = "萎缩的血翼",
  ["LoR_angela_xueyi_skill"] = "萎缩的血翼",
  [":LoR_angela_xueyi__slash"] = "<b>牌名：</b>萎缩的血翼<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br /><b>效果</b>：视为普通【杀】，[使用时]增加1次【杀】次数并摸一张牌。[命中时]对其造成一点伤害并令其获得一层【流血】" .. Fk:translate("LiuXue_jieshao"),
  ["#LoR_angela_xueyi_skill"] = "视为普通【杀】，[使用时]增加1次【杀】次数并摸一张牌。[命中时]对其造成一点伤害并令其获得一层【流血】",
}

local LoR_angela_aiyi_skill = fk.CreateActiveSkill {
  name = "LoR_angela_aiyi_skill",
  prompt = "#LoR_angela_aiyi_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
    if #selected == 1 then
      return false
    end
    return self:modTargetFilter(to_select, selected, Self.id, card, true)
  end,
  on_use = function(self, room, cardUseEvent)
    room:setCardMark(cardUseEvent.card, MarkEnum.DestructIntoDiscard, 1)
  end,
  on_effect = function(self, room, cardEffectEvent)
    room:damage({
      from = room:getPlayerById(cardEffectEvent.from),
      to = room:getPlayerById(cardEffectEvent.to),
      damage = 1,
      card = cardEffectEvent.card,
      damageType = fk.FireDamage,
      skillName = self.name
    })
    room:addPlayerMark(room:getPlayerById(cardEffectEvent.to), "@LoR_aiyi")
  end,
}

local LoR_angela_aiyi = fk.CreateTrickCard {
  name = "LoR_angela_aiyi",
  number = 10,
  suit = Card.Heart,
  skill = LoR_angela_aiyi_skill,
  is_damage_card = true,
}

Fk:loadTranslationTable {
  ["LoR_angela_aiyi"] = "表达爱意",
  ["LoR_angela_aiyi_skill"] = "表达爱意",
  [":LoR_angela_aiyi"] = "<b>牌名：</b>表达爱意<br/><b>类型：</b>锦囊牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名其他角色<br /><b>效果</b>：对其造成一点火焰伤害，并令其获得一层【爱意】" .. Fk:translate("LoR_Aiyi_jieshao"),

  ["#LoR_angela_aiyi_skill"] = "表达爱意:对其造成一点火焰伤害，并令其获得一层【爱意】",
  ["@LoR_aiyi"] = "爱意"
}



local LoR_angela_guanjiu_skill = fk.CreateActiveSkill {
  name = "LoR_angela_guanjiu_skill",
  prompt = "#LoR_angela_guanjiu_skill",
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    local player = Fk:currentRoom():getPlayerById(to_select)
    if player then
      return user ~= to_select and player:getMark("@LoR_guanjiu") == 0
    end
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
  on_effect = function(self, room, cardEffectEvent)
    room:damage({
      to = room:getPlayerById(cardEffectEvent.to),
      damage = 1,
      card = cardEffectEvent.card,
      damageType = fk.NormalDamage,
      skillName = self.name
    })
    local mark = { "start_phase", "draw_phase", "play_phase" }
    local mark2 = { "start_phase", "draw_phase", "play_phase" }
    local player = room:getPlayerById(cardEffectEvent.to)

    if #player:getTableMark("@LoR_guanjiu") > 0 then
      for _, value in ipairs(mark) do
        if table.contains(player:getTableMark("@LoR_guanjiu"), value) then
          table.removeOne(mark2, value)
        end
      end
      if #mark2 > 0 then
        room:addTableMark(player, "@LoR_guanjiu", mark2[math.random(#mark2)])
      end
    else
      room:addTableMark(player, "@LoR_guanjiu", mark[math.random(3)])
    end
  end,
}
local LoR_angela_guanjiu_trigger = fk.CreateTriggerSkill {
  name = "#LoR_angela_guanjiu_trigger",
  global = true,
  mute = true,
  frequency = Skill.Compulsory,
  events = { fk.EventPhaseChanging },
  can_trigger = function(self, event, target, player, data)
    if target == player and player.getTableMark(player,"@LoR_guanjiu") and  #player.getTableMark(player,"@LoR_guanjiu") > 0 then
      local mark = player.getTableMark(player, "@LoR_guanjiu")
      local phase = {}
      if table.contains(mark, "start_phase") then
        table.insertIfNeed(phase, Player.Start)
      elseif table.contains(mark, "draw_phase") then
        table.insertIfNeed(phase, Player.Draw)
      elseif table.contains(mark, "play_phase") then
        table.insertIfNeed(phase, Player.Play)
      end
      if table.contains(phase, data.to) then
        local stringmark = function(num)
          if num == Player.Start then
            return "start_phase"
          elseif num == Player.Draw then
            return "draw_phase"
          elseif num == Player.Play then
            return "play_phase"
          end
        end
        player.room:removeTableMark(player, "@LoR_guanjiu",stringmark(data.to))
        return true
      end
    end
  end,
  on_use = Util.TrueFunc,
}
Fk:addSkill(LoR_angela_guanjiu_trigger)

local LoR_angela_guanjiu__slash = fk.CreateBasicCard {
  name = "LoR_angela_guanjiu__slash",
  number = 13,
  suit = Card.Club,
  skill = LoR_angela_guanjiu_skill,
  is_damage_card = true,
}

Fk:loadTranslationTable {
  ["LoR_angela_guanjiu__slash"] = "棺柩",
  ["LoR_angela_guanjiu_skill"] = "棺柩",
  [":LoR_angela_guanjiu__slash"] = "<b>牌名：</b>棺柩<br/><b>类型：</b>基本牌<br/><b>时机</b>：出牌阶段<br/><b>目标</b>：一名没有【棺柩】的其他角色<br /><b>效果</b>：视为普通【杀】，[命中后]对其造成一点无来源伤害并令其跳过随机阶段（准备、摸牌和出牌中随机选一）<br><font color='grey'><b>#棺柩</b><br>回合开始时，跳过对应阶段，然后失去一层【棺柩】",
  ["#LoR_angela_guanjiu_skill"] = "棺柩:[命中后]对其造成一点无来源伤害并令其跳过随机阶段（准备、摸牌和出牌中随机选一）",
  ["@LoR_guanjiu"] = "棺柩",
  ["start_phase"] = "准备",
  ["draw_phase"] = "摸牌",
  ["play_phase"] = "出牌",

}

extension:addCards {
  BingXi,
  XianZhen__slash,
  HengZhan__slash,
  ZongPi__slash,
  ZhiCi__slash,
  LoR_angela_haixiu, LoR_angela_haixiu,
  LoR_angela_youyi, LoR_angela_youyi,
  LoR_angela_xueyi__slash, LoR_angela_xueyi__slash,
  LoR_angela_aiyi, LoR_angela_aiyi,
  LoR_angela_guanjiu__slash, LoR_angela_guanjiu__slash,
}
return extension
