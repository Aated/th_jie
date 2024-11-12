local extension = Package:new("ren")
extension.extensionName = "th_jie"
local U = require "packages/utility/utility"
local LoR_Utility = require "packages/th_jie/LoR_Utility"

Fk:loadTranslationTable {
  ["ren"] = "东方界包",
  ["tho"] = "东方"
}
Fk:appendKingdomMap("god", { "tho" })

local th_jie_zoufangzi = General:new(extension, "th_jie_zoufangzi", "tho", 3, 3, 2)

local th_jie_zoufangzi_tingfeng = fk.CreateTriggerSkill {
  name = "th_jie_zoufangzi_tingfeng",
  anim_type = "drawcard",
  events = { fk.EventPhaseStart },
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish and #player.room.alive_players > 1 then
      local room = player.room
      local n = 0
      local phase_ids = {}
      room.logic:getEventsOfScope(GameEvent.Phase, 1, function(e)
        if e.data[2] == Player.Discard then
          table.insert(phase_ids, { e.id, e.end_id })
        end
        return false
      end, Player.HistoryTurn)
      room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        local in_discard = false
        for _, ids in ipairs(phase_ids) do
          if #ids == 2 and e.id > ids[1] and e.id < ids[2] then
            in_discard = true
            break
          end
        end
        if in_discard then
          for _, move in ipairs(e.data) do
            if move.from == player.id and move.moveReason == fk.ReasonDiscard then
              for _, info in ipairs(move.moveInfo) do
                if info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip then
                  n = n + 1
                end
              end
            end
          end
        end
        return false
      end, Player.HistoryTurn)
      self.cost_data = n
      return true
    end
  end,
  on_cost = function(self, event, target, player, data)
    local choose = player.room:askForSkillInvoke(player, self.name, nil, "th_jie_zoufangzi_tingfeng-active")
    return choose
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local discardCards = player.room:askForCardsChosen(player, player, 0, player:getHandcardNum(), "h", self.name,
      "#th_jie_zoufangzi_tingfeng-chooseCards")
    player.room:throwCard(discardCards, self.name, player)
    local choosePlayer = player.room:askForChoosePlayers(player, table.map(room.alive_players, Util.IdMapper), 1,
      math.min(#discardCards + self.cost_data, #player.room.alive_players),
      "#th_jie_zoufangzi_tingfeng-choosePlayers", self.name, false)
    if #discardCards + self.cost_data >= 3 then
      player:drawCards(1, self.name)
    end
    for _, value in ipairs(choosePlayer) do
      player.room:getPlayerById(value):drawCards(1, self.name)
    end
  end
}

local th_jie_zoufangzi_qiyu = fk.CreateTriggerSkill {
  name = "th_jie_zoufangzi_qiyu",
  anim_type = "control",
  prompt = "#th_jie_zoufangzi_qiyu",
  events = { fk.AfterCardsMove },
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player.phase ~= Player.NotActive and player:usedSkillTimes(self.name, Player.HistoryTurn) <= 4 then
      for _, move in ipairs(data) do
        if fk.ReasonDraw == move.moveReason and move.to and move.to ~= player.id and move.toArea and move.toArea == Card.PlayerHand then
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
    for _, move in ipairs(data) do
      local movePlayer
      if move.to then
        movePlayer = player.room:getPlayerById(move.to)
      else
        break
      end
      if movePlayer:isNude() then
        break
      end
      local choice = room:askForChoice(movePlayer, { "交给诹坊子一张牌", "弃置一张牌，然后诹坊子摸一张牌" },
        self.name)
      if choice == "交给诹坊子一张牌" then
        local card = room:askForCardChosen(movePlayer,
          movePlayer, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      else
        room:askForDiscard(movePlayer, 1, 1, true, self.name, false, ".", "#th_jie_zoufangzi_qiyu_discard")
        player:drawCards(1, self.name)
      end
    end
  end
}

th_jie_zoufangzi:addSkill(th_jie_zoufangzi_tingfeng)
th_jie_zoufangzi:addSkill(th_jie_zoufangzi_qiyu)

Fk:loadTranslationTable {
  ["th_jie_zoufangzi"] = "诹坊子",
  ["#th_jie_zoufangzi"] = "小小青蛙，不输风雨",
  ["designer:th_jie_zoufangzi"] = "东方幽幽梦",
  ["tho"] = "东方",

  ["th_jie_zoufangzi_tingfeng"] = "听风",
  [":th_jie_zoufangzi_tingfeng"] = "结束阶段开始时，你可以弃置任意张（记作x）手牌，若如此做，结束阶段时，你可以令至多y名角色各摸一张牌。若y大于等于3，则你摸一张牌。（y为你弃牌阶段弃置的手牌数+x）",
  ["#th_jie_zoufangzi_tingfeng-chooseCards"] = "请选择弃置任意张牌",
  ["#th_jie_zoufangzi_tingfeng-choosePlayers"] = "请选择角色摸一张牌",
  ["th_jie_zoufangzi_tingfeng-active"] = "你是否发动【听风】",

  ["th_jie_zoufangzi_qiyu"] = "祈雨",
  ["#th_jie_zoufangzi_qiyu"] = "祈雨:你的回合内其他角色摸牌时，你可以令其选择一项：1.交给你一张牌2.弃置一张牌，然后你摸一张牌。",
  [":th_jie_zoufangzi_qiyu"] = "每回合限5次，你的回合内其他角色摸牌时，你可以令其选择一项：1.交给你一张牌2.弃置一张牌，然后你摸一张牌。",
  ["#th_jie_zoufangzi_qiyu_discard"] = "祈雨：弃置一张牌",
}

local th_jie_yinfandi = General:new(extension, "th_jie_yinfandi", "tho", 4, 4, 2)

local th_jie_yinfandi_xingyun = fk.CreateTriggerSkill {
  name = "th_jie_yinfandi_xingyun",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = { fk.AfterCardsMove },
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    if not player:isKongcheng() then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand then
            return true
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}

local th_jie_yinfandi_kaiyun = fk.CreateActiveSkill {
  name = "th_jie_yinfandi_kaiyun",
  anim_type = "drawcard",
  card_num = 2,
  prompt = "#th_jie_yinfandi_kaiyun-active",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) == 0 and #player:getCardIds("he") > 1 and
        player.phase == Player.Play
  end,
  target_num = 0,
  card_filter = function(self, to_select)
    return not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local from = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, from, from)
    if from:isAlive() then
      from:drawCards(2, self.name)
    end
  end,
}

th_jie_yinfandi:addSkill(th_jie_yinfandi_xingyun)
th_jie_yinfandi:addSkill(th_jie_yinfandi_kaiyun)

Fk:loadTranslationTable {
  ["th_jie_yinfandi"] = "界因幡帝",
  ["~th_jie_yinfandi"] = "我的好运都跑到哪里去了~",
  ["#th_jie_yinfandi"] = "幸运的腹黑兔子",
  ["designer:th_jie_yinfandi"] = "Yuyuko",
  ["cv:th_jie_yinfandi"] = "北斗夜",



  ["th_jie_yinfandi_kaiyun"] = "开运",
  ["$th_jie_yinfandi_kaiyun"] = "Lucky~又捡到两张牌",
  ["#th_jie_yinfandi_kaiyun-active"] = "请弃置两张牌",
  [":th_jie_yinfandi_kaiyun"] = "<font color=\"green\">出牌阶段限一次，</font>你可以弃置两张牌然后摸两张牌",

  ["th_jie_yinfandi_xingyun"] = "幸运",
  ["$th_jie_yinfandi_xingyun"] = "Lucky~又捡到两张牌",
  [":th_jie_yinfandi_xingyun"] = "锁定技，当你失去最后的手牌时，你摸两张牌。",

}


local th_jie_hongmeiling = General:new(extension, "th_jie_hongmeiling", "tho", 4, 4, 2)

local th_jie_hongmeiling_longquan = fk.CreateTriggerSkill {
  name = "th_jie_hongmeiling_longquan",
  anim_type = "offensive",
  events = { fk.CardUsing, fk.CardResponding },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.name == "jink")
  end,
  target_filter = function()

  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#th_jie_hongmeiling_longquan-choose")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targetFilter = {}
    for _, value in ipairs(room.alive_players) do
      if not value:isNude() then
        table.insertIfNeed(targetFilter, value.id)
      end
    end
    local to = player.room:askForChoosePlayers(player, targetFilter, 1, 1,
      "#th_jie_hongmeiling_longquan-throw:::" .. data.card:toLogString(),
      self.name, false)

    local cid = room:askForCardChosen(player, player.room:getPlayerById(to[1]), "he", self.name)
    room:throwCard({ cid }, self.name, player.room:getPlayerById(to[1]), player)
  end
}
local th_jie_hongmeiling_beishui = fk.CreateTriggerSkill {
  name = "th_jie_hongmeiling_beishui",
  frequency = Skill.Wake,
  events = { fk.EventPhaseStart },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
        player:usedSkillTimes(self.name, Player.HistoryGame) == 0 and
        player.phase == Player.Start
  end,
  can_wake = function(self, event, target, player, data)
    for _, value in ipairs(player.room.alive_players) do
      if value.hp < player.hp then
        return false
      end
      if player.hp > 2 then
        return false
      end
    end
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local num = player.maxHp > 3 and room:changeMaxHp(player, 3 - player.maxHp) or
        room:changeMaxHp(player, player.maxHp - 3)
    room:changeHp(player, 3)
    room:handleAddLoseSkills(player, "th_jie_hongmeiling_taiji", nil, true, false)
  end,
}
local th_jie_hongmeiling_taiji = fk.CreateViewAsSkill {
  name = "th_jie_hongmeiling_taiji",
  anim_type = "defensive",
  pattern = "jink,peach,slash,nullification",
  switch_skill_name = "th_jie_hongmeiling_taiji",
  card_filter = function(self, to_select, select)
    if Self:getSwitchSkillState("th_jie_hongmeiling_taiji") == fk.SwitchYang then
      return Fk:getCardById(to_select).color == Card.Red
    end
    if Self:getSwitchSkillState("th_jie_hongmeiling_taiji") == fk.SwitchYin then
      return Fk:getCardById(to_select).color == Card.Black
    end
  end,
  interaction = function()
    local names = {}
    local isYang = Self:getSwitchSkillState("th_jie_hongmeiling_taiji") == fk.SwitchYang
    local isYin = Self:getSwitchSkillState("th_jie_hongmeiling_taiji") == fk.SwitchYin
    if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("slash")) and isYang then
      table.insertIfNeed(names, "slash")
    else
      if Fk.currentResponsePattern == nil and Self:canUse(Fk:cloneCard("peach")) and isYin then
        table.insertIfNeed(names, "peach")
      else
        if isYang then
          for _, name in ipairs({ "slash", "nullification" }) do
            if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
              table.insertIfNeed(names, name)
            end
          end
        end
        if isYin then
          for _, name in ipairs({ "jink", "peach" }) do
            if Fk.currentResponsePattern and Exppattern:Parse(Fk.currentResponsePattern):match(Fk:cloneCard(name)) then
              table.insertIfNeed(names, name)
            end
          end
        end
      end
    end
    if #names == 0 then return end
    return UI.ComboBox { choices = names }
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then
      return nil
    end
    if not self.interaction.data then return end
    local c = Fk:cloneCard(self.interaction.data)
    c.skillName = "th_jie_hongmeiling_taiji"
    c:addSubcard(cards[1])
    return c
  end

}
local th_jie_hongmeiling_taiji_trigger = fk.CreateTriggerSkill {
  name = "#th_jie_hongmeiling_taiji_trigger",
  main_skill = th_jie_hongmeiling_taiji,
  events = { fk.CardUsing, fk.CardResponding },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
        data.card.skillName == "th_jie_hongmeiling_taiji"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local state = player:getSwitchSkillState("th_jie_hongmeiling_taiji")
    if state == fk.SwitchYin then
      room:notifySkillInvoked(player, "th_jie_hongmeiling_taiji", "drawcard")
      local ids = room:getCardsFromPileByRule(".|.|spade,club", 1, "allPiles")
      if #ids > 0 then
        room:obtainCard(player, ids[1], false, fk.ReasonPrey)
      end
    end
    if state == fk.SwitchYang then
      room:notifySkillInvoked(player, "th_jie_hongmeiling_taiji", "drawcard")
      local ids = room:getCardsFromPileByRule(".|.|heart,diamond", 1, "allPiles")
      if #ids > 0 then
        room:obtainCard(player, ids[1], false, fk.ReasonPrey)
      end
    end
  end
}

th_jie_hongmeiling:addSkill(th_jie_hongmeiling_longquan)
th_jie_hongmeiling:addSkill(th_jie_hongmeiling_beishui)
th_jie_hongmeiling_taiji:addRelatedSkill(th_jie_hongmeiling_taiji_trigger)
th_jie_hongmeiling:addRelatedSkill(th_jie_hongmeiling_taiji)

Fk:loadTranslationTable {
  ["th_jie_hongmeiling"] = "界红美铃",
  ["~th_jie_hongmeiling"] = "我要，带薪休假",
  ["#th_jie_hongmeiling"] = "我只打盹我不翘班",
  ["designer:th_jie_hongmeiling"] = "御射军神",
  ["cv:th_jie_hongmeiling"] = "小羽",

  ["#th_jie_hongmeiling_longquan-throw"] = "请弃置其一张牌",

  ["th_jie_hongmeiling_longquan"] = "龙拳",
  ["$th_jie_hongmeiling_longquan"] = "四两拨千斤！",
  ["#th_jie_hongmeiling_longquan-choose"] = "你是否发动龙拳",
  [":th_jie_hongmeiling_longquan"] = "当你使用或打出闪或杀时，你可以弃置任意一名角色1张牌。",

  ["th_jie_hongmeiling_beishui"] = "背水",
  ["$th_jie_hongmeiling_beishui"] = "可恶，背水一战！",
  [":th_jie_hongmeiling_beishui"] = "<font color=\"red\"><b>觉醒技，</b></font>准备阶段开始时，若你体力值为全场最低或之一且不大于2时，你将体力上限和体力值调整至3点并获得技能【太极】。",

  ["th_jie_hongmeiling_taiji"] = "太极",
  ["#th_jie_hongmeiling_taiji_trigger"] = "太极",
  ["$th_jie_hongmeiling_taiji"] = "呵！",
  [":th_jie_hongmeiling_taiji"] = "<font color=\"#2874A6\"><b>转换技，</b></font><font color=\"#229954\"><b>阳：</b></font>你可以将一张红色牌当【杀】或【无懈可击】使用或打出并摸一张黑色牌；<font color=\"#229954\"><b>阴：</b></font>:你可以将一张黑色牌当【闪】或【桃】使用或打出并摸一张红色牌",

}


local th_jie_sp_leimi = General(extension, "th_jie_sp_leimi", "tho", 4, 4, 2)

local th_jie_sp_leimi_mingyun = fk.CreateTriggerSkill {
  name = "th_jie_sp_leimi_mingyun",
  anim_type = "offensive",
  events = { fk.DrawNCards },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(4)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id
    })
    local get = {}
    get = room:askForArrangeCards(player, self.name, cards, "#th_jie_sp_leimi_mingyun-choose", false, 0, { 4, 2 },
      { 2, 2 })[2]
    if #get > 0 then
      room:obtainCard(player, get, true, fk.ReasonPrey)
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, self.name)
    end
    local num = 0
    for _, value in ipairs(get) do
      num = num + Fk:getCardById(value).number
    end
    player.room:addPlayerMark(player, "@th_jie_sp_leimi_mingyun-turn", num)
    data.n = data.n - 2
  end
}

local th_jie_sp_leimi_mingyun_slashtrigger = fk.CreateTriggerSkill {
  name = "#th_jie_sp_leimi_mingyun_slashtrigger",
  anim_type = "offensive",
  events = { fk.DamageCaused },
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and not data.chain and data.card and (data.card.trueName == "slash") and
        player:hasSkill(th_jie_sp_leimi_mingyun)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("th_jie_sp_leimi_mingyun")
    room:notifySkillInvoked(player, "th_jie_sp_leimi_mingyun")
    if data.card.number > player:getMark("@th_jie_sp_leimi_mingyun-turn") and player:getMark("@th_jie_sp_leimi_mingyun-turn") > 0 then
      data.damage = data.damage + 1
    end
  end
}


--神枪：你可以将两张手牌当做一张【杀】使用或打出，该【杀】点数视为两张牌的点数之和。
local th_jie_sp_leimi_shenqiang = fk.CreateViewAsSkill {
  name = "th_jie_sp_leimi_shenqiang",
  prompt = "#th_jie_sp_leimi_shenqiang",
  pattern = "slash",
  card_filter = function(self, to_select, selected)
    if #selected == 2 then return false end
    return table.contains(Self:getHandlyIds(true), to_select)
  end,
  view_as = function(self, cards)
    if #cards ~= 2 then
      return nil
    end
    local c = Fk:cloneCard("slash")
    local num = 0
    for _, value in ipairs(cards) do
      num = num + Fk:getCardById(value).number
    end
    c.skillName = "th_jie_sp_leimi_shenqiang"
    c:addSubcards(cards)
    c.number = num
    return c
  end
}


--绯红：锁定技，你的红色【杀】无视距离，造成伤害后回复一点体力。若该【杀】为非转化非虚拟，则此【杀】无法被响应。

local th_jie_sp_leimi_feihong = fk.CreateTriggerSkill {
  name = "th_jie_sp_leimi_feihong",
  anim_type = "offensive",
  events = { fk.TargetSpecified },
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.trueName == "slash" and not data.card:isVirtual() and
        data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    data.disresponsive = true
  end
}
local th_jie_sp_leimi_feihong_trigger = fk.CreateTriggerSkill {
  name = "#th_jie_sp_leimi_feihong_trigger",
  main_skill = th_jie_sp_leimi_feihong,
  events = { fk.Damage },
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card and data.card.trueName == "slash" and not data.chain and
        player.room.logic:damageByCardEffect(false) and
        data.card.color == Card.Red
  end,
  on_use = function(self, event, target, player, data)
    if player:isWounded() then
      player.room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
  end
}

local th_jie_sp_leimi_feihong_distance = fk.CreateTargetModSkill {
  name = "#th_jie_sp_leimi_feihong_distance",
  anim_type = "offensive",
  mute = true,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(th_jie_sp_leimi_feihong) and card.color == Card.Red and card.trueName == "slash"
  end
}




th_jie_sp_leimi_mingyun:addRelatedSkill(th_jie_sp_leimi_mingyun_slashtrigger)
th_jie_sp_leimi:addSkill(th_jie_sp_leimi_mingyun)
th_jie_sp_leimi:addSkill(th_jie_sp_leimi_shenqiang)
th_jie_sp_leimi_feihong:addRelatedSkill(th_jie_sp_leimi_feihong_distance)
th_jie_sp_leimi_feihong:addRelatedSkill(th_jie_sp_leimi_feihong_trigger)
th_jie_sp_leimi:addSkill(th_jie_sp_leimi_feihong)

Fk:loadTranslationTable {
  ["th_jie_sp_leimi"] = "SP蕾米莉亚",
  ["#th_jie_sp_leimi"] = "操纵命运的赤之恶魔",
  ["designer:th_jie_sp_leimi"] = "东方幽幽梦",
  ["cv:th_jie_sp_leimi"] = "VV",

  ["th_jie_sp_leimi_mingyun"] = "命运",
  [":th_jie_sp_leimi_mingyun"] = "摸牌阶段开始时，你可以放弃摸牌，改为你展示牌堆顶的四张牌并获得其中两张，然后记录其点数之和。本回合你使用的【杀】点数若大于该点数，则伤害+1。",
  ["#th_jie_sp_leimi_mingyun-choose"] = "你选择两张牌获得",
  ["#th_jie_sp_leimi_mingyun_slashtrigger"] = "命运",

  ["th_jie_sp_leimi_shenqiang"] = "神枪",
  [":th_jie_sp_leimi_shenqiang"] = "你可以将两张手牌当做一张【杀】使用或打出，该【杀】点数视为两张牌的点数之和",
  ["#th_jie_sp_leimi_shenqiang"] = "你可以将两张手牌当做一张【杀】使用或打出，该【杀】点数视为两张牌的点数之和。",

  ["th_jie_sp_leimi_feihong"] = "绯红",
  [":th_jie_sp_leimi_feihong"] = "锁定技，你的红色【杀】无视距离，造成伤害后回复一点体力。若该【杀】为非转化非虚拟，则此【杀】无法被响应。",
  ["#th_jie_sp_leimi_feihong_trigger"] = "绯红",
  ["#th_jie_sp_leimi_feihong"] = "绯红",

  ["$th_jie_sp_leimi_mingyun1"] = "亮一亮，吸血鬼的威严吧！",
  ["$th_jie_sp_leimi_mingyun2"] = "亮一亮，吸血鬼的威严吧！",
  ["$th_jie_sp_leimi_shenqiang"] = "中！一发入魂",
  ["$th_jie_sp_leimi_feihong"] = "B型血，赞👍！",

  ["@th_jie_sp_leimi_mingyun-turn"] = "命运",
  ["~th_jie_sp_leimi"] = "自古枪兵，幸运e啊",
}
local th_jie_tianzi = General:new(extension, "th_jie_tianzi", "tho", 3, 3, 2)

local th_jie_tianzi_doum = fk.CreateTriggerSkill {
  name = "th_jie_tianzi_doum",
  anim_type = "masochism",
  events = { fk.Damaged },
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, _, "#th_jie_tianzi_doum-active") and data.damage > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    room:notifySkillInvoked(player, self.name)
    local cards = room:getNCards(4 * data.damage)
    room:moveCards({
      ids = cards,
      toArea = Card.Processing,
      moveReason = fk.ReasonPut,
      skillName = self.name,
      proposer = player.id
    })
    local get = {}
    get = room:askForArrangeCards(player, self.name, cards, "#th_jie_tianzi_doum_get", false, 0, { 4 * data.damage, 2 *
    data.damage }, { 2 * data.damage, 2 * data.damage })[2]
    if #get > 0 then
      room:obtainCard(player, get, true, fk.ReasonPrey)
    end
    cards = table.filter(cards, function(id) return room:getCardArea(id) == Card.Processing end)
    if #cards > 0 then
      room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonJustMove, self.name)
    end
    LoR_Utility.askForDistribution(player, get, room.alive_players, self.name, 0, #get, "#th_jie_tianzi_doum_shareCards")
  end
}

local th_jie_tianzi_feitian = fk.CreateTriggerSkill {
  name = "th_jie_tianzi_feitian",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = { fk.FinishJudge },
  can_trigger = function(self, event, target, player, data)
    return data.card.color == Card.Red and player:hasSkill(self) and
        player.room:getCardArea(data.card) == Card.Processing
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
  end
}

local th_jie_tianzi_feitian_filter = fk.CreateFilterSkill {
  name = "#th_jie_tianzi_feitian_filter",
  mute = true,
  card_filter = function(self, to_select, player, isJudgeEvent)
    return player:hasSkill(self) and isJudgeEvent
  end,
  view_as = function(self, to_select)
    return Fk:cloneCard(to_select.name, Card.Heart, to_select.number)
  end,
}

th_jie_tianzi:addSkill(th_jie_tianzi_doum)
th_jie_tianzi_feitian:addRelatedSkill(th_jie_tianzi_feitian_filter)
th_jie_tianzi:addSkill(th_jie_tianzi_feitian)

Fk:loadTranslationTable {
  ["th_jie_tianzi"] = "界天子",
  ["#th_jie_tianzi"] = "有顶天的抖M",
  ["designer:th_jie_tianzi"] = "御射军神",
  ["~th_jie_tianzi"] = "啊~~~呜————T^T",
  ["cv:th_jie_tianzi"] = "VV",


  ["th_jie_tianzi_doum"] = "抖M",
  ["$th_jie_tianzi_doum"] = "kimoji<font color='red'>♥</font>~",
  [":th_jie_tianzi_doum"] = "每当你受到伤害后，你可以观看牌堆顶4乘X张牌，然后选择其中一半的牌交给至少一名角色并弃置剩余牌。X为你受到的伤害数。",

  ["#th_jie_tianzi_doum-active"] = "你是否发动【抖M】",
  ["#th_jie_tianzi_doum_shareCards"] = "抖M：你可以将这些牌分配给其他角色，或点“取消”自己保留",
  ["#th_jie_tianzi_doum_get"] = "将需要获取的牌拖入牌堆底并获得",

  ["th_jie_tianzi_feitian"] = "绯天",
  ["#th_jie_tianzi_feitian_filter"] = "绯天",
  ["$th_jie_tianzi_feitian"] = "拿过来吧！",
  [":th_jie_tianzi_feitian"] = "锁定技，当有角色的红色判定牌进入弃牌堆时，你获得之，你的判定牌视为<font color='red'>♥</font>。",
}

-- 亡我:锁定技，你的手牌上限+2;若你体力值为全场最低，你不能成为其他角色基本牌的目标。
-- 返魂:当有角色进入濒死时，你摸一张牌，若为本局游戏其首次进入濒死你可以令濒死角色
--     体力回复至一点，然后直到其下个回合结束时，若其没有造成过伤害，其流失一点体力。此次结算后你可以弃置一张非基本牌，
--     令当前回合角色本回合使用牌不能指定其他角色为目标。
-- 誘死:你的回合结束时，若你的体力值不为全场最高，你可以至多选择X名角色各流失一点体力然后摸一张牌。(X为你已损失体力值)



local th_jie_uuz = General:new(extension, "th_jie_uuz", "tho", 2, 4, 2)


local th_jie_uuz_wangwo          = fk.CreateProhibitSkill {
  name = "th_jie_uuz_wangwo",
  frequency = Skill.Compulsory,
  is_prohibited = function(self, from, to, card)
    if to:hasSkill(self) and from ~= to then
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p.hp < to.hp then return false end -- 只要找到一个比我血还少的，就可以触发了
      end
      return card.type == Card.TypeBasic
    end
  end,
}

local th_jie_uuz_wangwo_maxcard  = fk.CreateMaxCardsSkill {
  name = "#th_jie_uuz_wangwo_maxcard",
  correct_func = function(self, player)
    if player:hasSkill(self.name) then
      return 2
    end
  end
}

local th_jie_uuz_fanhun          = fk.CreateTriggerSkill {
  name = "th_jie_uuz_fanhun",
  anim_type = "special",
  mute = true,
  events = { fk.EnterDying, fk.TurnEnd },
  can_trigger = function(self, event, target, player, data)
    return (player:hasSkill(self) and event == fk.EnterDying) or (target:getMark("fanhun") > 0 and event == fk.TurnEnd)
  end,
  on_cost = function(self, event, target, player, data)
    if target:getMark("fanhun") > 0 and event == fk.TurnEnd then
      return true
    elseif event == fk.EnterDying then
      return player.room:askForSkillInvoke(player, self.name)
    end
  end,
  on_use = function(self, event, target, player, data)
    if event == fk.EnterDying then
      player.room:broadcastPlaySound("./packages/th_jie/audio/skill/th_jie_uuz_fanhun1")
      player:drawCards(1, self.name)
      if target:getMark(self.name) == 0 then
        local recover = player.room:askForSkillInvoke(player, self.name, _, "#th_jie_uuz_fanhun-choose")
        if recover then
          player.room:doIndicate(player.id, { target.id })
          player.room:broadcastPlaySound("./packages/th_jie/audio/skill/th_jie_uuz_fanhun2")
          player.room:changeHp(target, 1 - target.hp)
          target:addMark("fanhun", 1)
          local discard = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".|.|.|hand,equip|.|^basic",
            "#fanhun_discard")
          if #discard > 0 then
            player.room:doIndicate(player.id, { player.room.current.id })
            player.room:broadcastPlaySound("./packages/th_jie/audio/skill/th_jie_uuz_fanhun3")
            player.room:setPlayerMark(player.room.current, "th_jie_uuz_fanhun_prohibit-turn", 1)
          end
        end
        target:addMark(self.name, 1)
      end
    elseif target:getMark("fanhun") > 0 and event == fk.TurnEnd then
      player.room:broadcastPlaySound("./packages/th_jie/audio/skill/th_jie_uuz_fanhun3")
      player.room:loseHp(target, 1, self.name)
    end
  end
}

local th_jie_uuz_fanhun_prohibit = fk.CreateProhibitSkill {
  name = "#th_jie_uuz_fanhun_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("th_jie_uuz_fanhun_prohibit-turn") > 0 and from ~= to
  end,
}
local th_jie_uuz_fanhun_damage   = fk.CreateTriggerSkill {
  name = "#th_jie_uuz_fanhun_damage",
  events = { fk.Damage },
  can_trigger = function(self, event, target, player, data)
    return player:getMark("fanhun") > 0 and data.from == player
  end,
  on_use = function(self, event, target, player, data)
    player:removeMark("fanhun", 1)
  end
}


local th_jie_uuz_yousi = fk.CreateTriggerSkill {
  name = "th_jie_uuz_yousi",
  anim_type = "offensive",
  events = { fk.TurnEnd },
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      for _, otherplayer in ipairs(player.room:getOtherPlayers(player)) do
        if player.hp < otherplayer.hp then
          return true
        end
      end
    end
    return false
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local losehp = player.maxHp - player.hp
    local ids = table.map(player.room.alive_players, function(e)
      return e.id
    end)
    local chooseplayers = player.room:askForChoosePlayers(player, ids, 0, losehp, "#yousi_tips", self.name, true)
    if chooseplayers ~= nil and #chooseplayers > 0 then
      player.room:doIndicate(player.id, chooseplayers)
      for _, c_player in ipairs(chooseplayers) do
        player.room:loseHp(player.room:getPlayerById(c_player), 1, self.name)
        player:drawCards(1, self.name)
      end
    end
  end
}

th_jie_uuz_wangwo:addRelatedSkill(th_jie_uuz_wangwo_maxcard)
th_jie_uuz:addSkill(th_jie_uuz_wangwo)


th_jie_uuz_fanhun:addRelatedSkill(th_jie_uuz_fanhun_prohibit)
th_jie_uuz_fanhun:addRelatedSkill(th_jie_uuz_fanhun_damage)
th_jie_uuz:addSkill(th_jie_uuz_fanhun)

th_jie_uuz:addSkill(th_jie_uuz_yousi)

Fk:loadTranslationTable {
  ["th_jie_uuz"] = "SP幽幽子",
  ["#th_jie_uuz"] = "幽冥公主",
  ["designer:th_jie_uuz"] = "Yuyuko",
  ["~th_jie_uuz"] = "果然不能饿着肚子打架呢~~妖梦？妖梦？",
  ["cv:th_jie_uuz"] = "VV",


  ["th_jie_uuz_wangwo"] = "亡我",
  [":th_jie_uuz_wangwo"] = "锁定技，你的手牌上限+2;若你体力值为全场最低，你不能成为其他角色基本牌的目标。",

  ["th_jie_uuz_fanhun"] = "返魂",
  ["$th_jie_uuz_fanhun1"] = "啊啦，你已经死了呢",
  ["$th_jie_uuz_fanhun2"] = "只差一点，西行妖就能够盛开了呢",
  ["$th_jie_uuz_fanhun3"] = "不如，就这样沉眠于花下好了",
  [":th_jie_uuz_fanhun"] = "当有角色进入濒死时，你摸一张牌，若为本局游戏其首次进入濒死你可以令濒死角色体力回复至一点，然后直到其下个回合结束时，若其没有造成过伤害，其流失一点体力。此次结算后你可以弃置一张非基本牌，令当前回合角色本回合使用牌不能指定其他角色为目标。",
  ["#th_jie_uuz_fanhun_damage"] = "返魂",
  ["#th_jie_uuz_fanhun-choose"] = "是否令濒死角色血量调整至1",

  ["th_jie_uuz_yousi"] = "诱死",
  ["$th_jie_uuz_yousi"] = "优雅的绽放吧，墨染的樱花",
  [":th_jie_uuz_yousi"] = "你的回合结束时，若你的体力值不为全场最高，你可以至多选择X名角色各流失一点体力然后摸一张牌。(X为你已损失体力值)",
  ["#yousi_tips"] = "请选择角色令其失去一点体力，然后你摸选择角色数的牌",
}


--朔命:每个阶段限一次，你的准备阶段、你成为牌的目标或你
--使用牌时，你可以观看牌堆顶x张牌并弃置其中任意张牌，与弃置牌相同花色的牌
--直到本回合结束不可以使用。(x为5-此技能本回合发动次数)

-- 血霧：每个回合结束时，若你本回合体力值变动，你可以失去
-- 1至4 点体力并视为使用一张【杀】，此【杀】对体力值不
-- 小于你的角色无距离限制且造成伤害后你回复一点体力。

-- 血裔：主公技，游戏开始时，非妖势力角色可以交给你一张牌
-- 并将势力改为妖;你的攻击范围加场上妖势力角色数。
-- 樂
local th_jie_yao_leimi = General:new(extension, "th_jie_yao_leimi", "yao", 4, 4, 2)

local th_jie_yao_leimi_shuoming = fk.CreateTriggerSkill {
  name = "th_jie_yao_leimi_shuoming",
  anim_type = "control",
  events = { fk.EventPhaseStart, fk.TargetConfirmed, fk.CardUsing },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and
        (event ~= fk.EventPhaseStart or player.phase == Player.Start) and
        player:usedSkillTimes(self.name, Player.HistoryTurn) < 5
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local ids = room:getNCards(5 - player:usedSkillTimes(self.name, Player.HistoryTurn))
    room:moveCards({
      ids = ids,
      toArea = Card.Processing,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
    local discards, choice = LoR_Utility.askforChooseCardsAndChoice(player, ids, { "#shuoming_top", "#shuomingdiscards" },
      self.name, "#shuoming-choose", { "Cancel" }, 0, #ids)
    if choice == "Cancel" then return end
    if discards ~= nil and #discards > 0 then
      for _, value in ipairs(ids) do
        if table.contains(discards, value) then
          table.removeOne(ids, value)
        end
      end
      local mark = player:getMark("@shuoming-turn")
      if mark == 0 then mark = {} end
      for _, discard in ipairs(discards) do
        table.insertIfNeed(mark, Fk:getCardById(discard):getSuitString(true))
      end
      for _, p in ipairs(room.alive_players) do
        room:doIndicate(player.id, { p.id })
        room:setPlayerMark(p, "@shuoming-turn", mark)
      end
      room:moveCards({
        ids = discards,
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end

    room:moveCards({
      ids = ids,
      toArea = Card.DrawPile,
      moveReason = fk.ReasonJustMove,
      proposer = player.id,
      skillName = self.name,
    })
  end
}
local th_jie_yao_leimi_shuoming_prohibit = fk.CreateProhibitSkill {
  name = "#th_jie_yao_leimi_shuoming_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@shuoming-turn") ~= 0 and
        table.contains(player:getMark("@shuoming-turn"), card:getSuitString(true))
  end,
}

local th_jie_yao_leimi_xuewu = fk.CreateTriggerSkill {
  name = "th_jie_yao_leimi_xuewu",
  anim_type = "offensive",
  events = { fk.TurnStart, fk.TurnEnd },
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnStart then
        player.room:setPlayerMark(player, "xuewu_hp", player.hp)
        return false
      elseif event == fk.TurnEnd and player.hp ~= player:getMark("xuewu_hp") then
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choicesHp = {}
    for i = 1, math.min(4, player.hp) do
      table.insertIfNeed(choicesHp, tostring(i))
    end
    local losehp = room:askForChoice(player, choicesHp, self.name, "#xuewu-choose")
    local losehp_num = tonumber(losehp)
    if losehp_num == nil then
      losehp_num = 1
    end
    room:loseHp(player, losehp_num, self.name)
    local otherplayers = {}
    for _, other in ipairs(room:getOtherPlayers(player)) do
      if player:inMyAttackRange(other) then
        table.insertIfNeed(otherplayers, other.id)
      elseif other.hp >= player.hp then
        table.insertIfNeed(otherplayers, other.id)
      end
    end
    local targetplayer = room:askForChoosePlayers(player, otherplayers, 1, 1,
      "#xuewu_chooseplayer", self.name, true, false)
    local slashcard = Fk:cloneCard("slash")
    slashcard.skillName = self.name
    room:useCard({
      from = player.id,
      tos = { targetplayer },
      card = slashcard
    })
  end
}

local th_jie_yao_leimi_xuewu_slashdamage = fk.CreateTriggerSkill {
  name = "#th_jie_yao_leimi_xuewu_slashdamage",
  events = { fk.DamageCaused },
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(th_jie_yao_leimi_xuewu) and data.card.skillName ==
        "th_jie_yao_leimi_xuewu"
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player,
      num = 1,
      skillName = "th_jie_yao_leimi_xuewu"
    })
  end
}

local th_jie_yao_leimi_xueyi = fk.CreateTriggerSkill {
  name = "th_jie_yao_leimi_xueyi",
  anim_type = "drawcard",
  events = { fk.GameStart },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and player.role == "lorad"
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local choiceCards = {}
    local room = player.room
    for _, p in ipairs(player.room:getOtherPlayers(player)) do
      if p.kingdom ~= "yao" then
        local choiceCard = room:askForCard(p, 0, 1, true, self.name, true)
        if choiceCard ~= nil and #choiceCard > 0 then
          room:moveCardTo(choiceCard, player.Hand, player, fk.ReasonJustMove, self.name)
          table.insertIfNeed(choiceCards, choiceCard[1])
          room:changeKingdom(p, "yao", true)
        end
      end
    end
    for _, p in ipairs(player.room.alive_players) do
      if p.kingdom == "yao" then
        player:addMark("xueyi", 1)
      end
    end
  end
}

local th_jie_yao_leimi_xueyi_atkrange = fk.CreateAttackRangeSkill {
  name = "#th_jie_yao_leimi_xueyi_atkrange",
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill("th_jie_yao_leimi_xueyi") then
      return from:getMark("xueyi")
    end
  end
}

th_jie_yao_leimi_shuoming:addRelatedSkill(th_jie_yao_leimi_shuoming_prohibit)
th_jie_yao_leimi_xuewu:addRelatedSkill(th_jie_yao_leimi_xuewu_slashdamage)
th_jie_yao_leimi_xueyi:addRelatedSkill(th_jie_yao_leimi_xueyi_atkrange)

th_jie_yao_leimi:addSkill(th_jie_yao_leimi_shuoming)
th_jie_yao_leimi:addSkill(th_jie_yao_leimi_xuewu)
th_jie_yao_leimi:addSkill(th_jie_yao_leimi_xueyi)

Fk:loadTranslationTable {
  ["th_jie_yao_leimi"] = "界蕾米莉亚",
  ["yao"] = "妖",
  ["#th_jie_yao_leimi"] = "猩红之月",
  ["designer:th_jie_yao_leimi"] = "云里雾里沙",


  ["th_jie_yao_leimi_shuoming"] = "朔命",
  [":th_jie_yao_leimi_shuoming"] = "每个阶段限一次，你的准备阶段、你成为牌的目标或你使用牌时，你可以观看牌堆顶x张牌并弃置其中任意张牌，与弃置牌相同花色的牌直到本回合结束不可以使用。(x为5-此技能本回合发动次数)",
  ["@shuoming-turn"] = "朔命",
  ["#shuoming_top"] = "牌堆顶的牌",
  ["#shuomingdiscards"] = "弃置的牌",
  ["#shuoming-choose"] = "请选择弃置牌",

  ["th_jie_yao_leimi_xuewu"] = "血霧",
  [":th_jie_yao_leimi_xuewu"] = "每个回合结束时，若你本回合体力值变动，你可以失去1~4体力并视为使用一张【杀】，此【杀】对体力值不小于你的角色无距离限制且造成伤害后你回复一点体力。",
  ["#xuewu-choose"] = "请选择失去体力的数量",
  ["#xuewu_chooseplayer"] = "请选择使用【杀】的目标",
  ["#th_jie_yao_leimi_xuewu_slashdamage"] = "血雾",

  ["th_jie_yao_leimi_xueyi"] = "血裔",
  [":th_jie_yao_leimi_xueyi"] = "主公技，游戏开始时，非妖势力角色可以交给你一张牌并将势力改为【妖】;你的攻击范围加场上妖势力角色数。",
}

--界妖梦 4/4
--二刀：锁定技，游戏开始时，你获得一个额外武器栏；
--你对你距离不等于1的角色使用牌无次数限制。


--断迷：你不以此法使用伤害牌后，你可以获得其中一名目标的一张牌，
--若未对其造成过伤害，你视为对其使用同名牌。
local th_jie_yaomeng = General:new(extension, "th_jie_yaomeng", "tho", 4, 4, 2)

local th_jie_yaomeng_erdao = fk.CreateTriggerSkill {
  name = "th_jie_yaomeng_erdao",
  frequency = Skill.Compulsory,
  events = { fk.GameStart },
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerEquipSlots(player, { Player.WeaponSlot })
  end,
}

local th_jie_yaomeng_erdao_extra = fk.CreateTargetModSkill {
  name = "#th_jie_yaomeng_erdao_extra",
  frequency = Skill.Compulsory,
  bypass_times = function(self, player, skill, scope, card, to)
    if player:hasSkill(self) and player:compareDistance(to, 1, ">") and
        scope == Player.HistoryPhase then
      return true
    end
  end
}
local th_jie_yaomeng_erdao_Audio = fk.CreateTriggerSkill {
  name = "#th_jie_yaomeng_erdao_Audio",
  visible = false,
  refresh_events = { fk.CardUsing },
  can_refresh = function(self, event, target, player, data)
    local targets = TargetGroup:getRealTargets(data.tos)
    local to = player.room:getPlayerById(targets[1])
    return target == player and player:hasSkill(self) and
        data.card.trueName == "slash" and player:compareDistance(to, 1, ">") and
        player:usedCardTimes("slash") > 1
  end,
  on_refresh = function(self, event, target, player, data)
    player:broadcastSkillInvoke("th_jie_yaomeng_erdao")
    player.room:doAnimate("InvokeSkill", {
      name = "th_jie_yaomeng_erdao",
      player = player.id,
      skill_type = "offensive",
    })
  end,
}

local th_jie_yaomeng_duanmi = fk.CreateTriggerSkill {
  name = "th_jie_yaomeng_duanmi",
  events = { fk.CardUseFinished },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.card.is_damage_card and
        not table.contains(data.card.skillNames, self.name)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = table.filter(TargetGroup:getRealTargets(data.tos), function(id)
      return not room:getPlayerById(id):isNude()
    end)
    if #tos == 0 then return end
    local player = room:askForChoosePlayers(player, tos, 1, 1,
      "#th_jie_yaomeng_duanmi-invoke:::" .. data.card:toLogString() .. ":" .. data.card.name)
    if #player > 0 then
      self.cost_data = player[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = player.room:getPlayerById(self.cost_data)
    local choicecard = room:askForCardChosen(player, to, "he", self.name)
    room:obtainCard(player, choicecard, false, fk.ReasonPrey, player.id, self.name)
    if not (data.damageDealt or {})[to.id] then
      room:useVirtualCard(data.card.name, nil, player, to, self.name)
    end
  end,
}


th_jie_yaomeng_erdao:addRelatedSkill(th_jie_yaomeng_erdao_extra)
th_jie_yaomeng_erdao:addRelatedSkill(th_jie_yaomeng_erdao_Audio)

th_jie_yaomeng:addSkill(th_jie_yaomeng_erdao)
th_jie_yaomeng:addSkill(th_jie_yaomeng_duanmi)


Fk:loadTranslationTable {
  ["th_jie_yaomeng"] = "界妖梦",
  ["#th_jie_yaomeng"] = "虚幻2.5庭师",
  ["~th_jie_yaomeng"] = "啊啦，该给幽幽子大人做饭了————",
  ["designer:th_jie_yaomeng"] = "妖梦厨",
  ["cv:th_jie_yaomeng"] = "小羽",
  ["illustrator:th_jie_yaomeng"] = "レイ",

  ["th_jie_yaomeng_erdao"] = "二刀",
  ["$th_jie_yaomeng_erdao"] = "我还是有两把刷子的。",
  [":th_jie_yaomeng_erdao"] = "锁定技，游戏开始时，你获得一个额外武器栏；你对你距离大于1的角色使用牌无次数限制。",

  ["th_jie_yaomeng_duanmi"] = "断迷",
  ["$th_jie_yaomeng_duanmi"] = "先斩了再说！",
  [":th_jie_yaomeng_duanmi"] = "你不以此法使用伤害牌后，你可以获得其中一名目标的一张牌，若此牌未对其造成伤害，你视为对其使用同名牌。",
  ["#th_jie_yaomeng_duanmi-invoke"] = "断迷：你可以获得其中一名目标的一张牌，若 %arg 未对其造成伤害，你视为对其使用 %arg2",
  ["#th_jie_yaomeng_duanmi_damage"] = "断迷",
}



-- 尘世遗珠 辉夜 3/3

-- 　　变迁:出牌阶段各限一次。你可以1.将手牌调整至与体力值相同；2.将体力值与体力上限调整至与手牌相同。

local th_jie_huiye = General:new(extension, "th_jie_huiye", "tho", 3, 3, 2)

local th_jie_huiye_bianqian = fk.CreateActiveSkill {
  name = "th_jie_huiye_bianqian",
  anim_type = "drawcard",
  prompt = "#th_jie_huiye_bianqian",
  can_use = function(self, player, card, extra_data)
    return player:usedSkillTimes(self.name, Player.HistoryTurn) < 2
  end,
  on_use = function(self, room, cardUseEvent)
    local player = room:getPlayerById(cardUseEvent.from)
    local choosetable = {}
    local choose
    if player:getMark("bianqian1-turn") == 0 and player:getMark("bianqian2-turn") == 0 then
      choosetable = { "#bianqian1:::" .. #player:getCardIds(Player.Hand) .. ":" .. player.hp, "#bianqian2:::" ..
      player.maxHp .. ":" .. #player:getCardIds(Player.Hand) }
    elseif player:getMark("bianqian1-turn") == 0 and player:getMark("bianqian2-turn") ~= 0 then
      choosetable = { "#bianqian1:::" .. #player:getCardIds(Player.Hand) .. ":" .. player.hp }
    elseif player:getMark("bianqian1-turn") ~= 0 and player:getMark("bianqian2-turn") == 0 then
      choosetable = { "#bianqian2:::" .. player.maxHp .. ":" .. #player:getCardIds(Player.Hand) }
    end

    choose = room:askForChoice(player, choosetable, self.name, "#th_jie_huiye_bianqian-choose", false,
      { "#bianqian1:::" .. #player:getCardIds(Player.Hand) .. ":" .. player.hp, "#bianqian2:::" ..
      player.maxHp .. ":" .. #player:getCardIds(Player.Hand) })

    if choose == "#bianqian1:::" .. #player:getCardIds(Player.Hand) .. ":" .. player.hp then
      room:addPlayerMark(player, "bianqian1-turn")
      if #player:getCardIds(Player.Hand) < player.hp then
        player:drawCards(player.hp - #player:getCardIds(Player.Hand), self.name)
      elseif #player:getCardIds(Player.Hand) > player.hp then
        local num = #player:getCardIds(Player.Hand) - player.hp
        local targetcards = room:askForCardsChosen(player, player, num, num, "h", self.name,
          "#th_jie_huiye_bianqian_throwcards:::" .. num)
        room:throwCard(targetcards, self.name, player)
      end
    else
      room:addPlayerMark(player, "bianqian2-turn")
      room:changeMaxHp(player, #player:getCardIds(Player.Hand) - player.maxHp)
      room:changeHp(player, player.maxHp - player.hp, "recover", self.name)
    end
  end,
}

th_jie_huiye:addSkill(th_jie_huiye_bianqian)

Fk:loadTranslationTable {
  ["th_jie_huiye"] = "SP辉夜",
  ["~th_jie_huiye"] = "这游戏连存档都没有怎么玩!😡",
  ["#th_jie_huiye"] = "尘世遗珠",
  ["designer:th_jie_huiye"] = "澪汐",
  ["cv:th_jie_huiye"] = "shourei小N",

  ["th_jie_huiye_bianqian"] = "变迁",
  ["$th_jie_huiye_bianqian1"] = "这一题，是没有答案的😎",
  ["$th_jie_huiye_bianqian2"] = "豆腐脑是甜的，还是咸的？🤔",
  ["$th_jie_huiye_bianqian3"] = "陷入永夜吧！🌙",
  ["#th_jie_huiye_bianqian"] = "变迁：出牌阶段各限一次。你可以1.将手牌调整至与体力值相同；2.将体力值与体力上限调整至与手牌相同。",
  ["#th_jie_huiye_bianqian_throwcards"] = "请弃置%arg张牌。",
  [":th_jie_huiye_bianqian"] = "出牌阶段各限一次。你可以1.将手牌调整至与体力值相同；2.将体力值与体力上限调整至与手牌相同。",
  ["#th_jie_huiye_bianqian-choose"] = "变迁：请选择一项",
  ["#bianqian1"] = "将手牌数(%arg)调整至与体力值(%arg2)相同",
  ["#bianqian2"] = "将体力值与体力上限(%arg)调整至与手牌数(%arg2)相同。",
}

--图书管理员 界小恶魔 4/4
--寻找：出牌阶段限一次，你可以摸X张牌，然后将至少三张牌置于牌堆顶或场上。（X为存活角色数，至少为3）

local th_jie_xiaoemo = General:new(extension, "th_jie_xiaoemo", "tho", 4, 4, 2)

local th_jie_xiaoemo_xunzhao = fk.CreateActiveSkill {
  name = "th_jie_xiaoemo_xunzhao",
  anim_type = "drawcard",
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  can_use = function(self, player, card, extra_data)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local num = math.max(#room.alive_players, 3)
    player:drawCards(num, self.name)
    for i = 1, #player:getCardIds("he"), 1 do
      if player.dead or player:isNude() then return end
      local invoke, dat
      if i <= 3 then
        invoke, dat = room:askForUseActiveSkill(player, "th_jie_xiaoemo_xunzhao_active",
          "#th_jie_xiaoemo_xunzhao-card:::" .. tostring(i), false)
      else
        invoke, dat = room:askForUseActiveSkill(player, "th_jie_xiaoemo_xunzhao_active",
          "#th_jie_xiaoemo_xunzhao-card2", true)
        if invoke == false then
          break
        end
      end

      local card_id = dat and dat.cards[1] or player:getCardIds("he")[1]
      local choice = dat and dat.interaction or "Top"
      if choice == "Field" and dat then
        local to = room:getPlayerById(dat.targets[1])
        local card = Fk:getCardById(card_id)
        if card.type == Card.TypeEquip then
          room:moveCardTo(card, Card.PlayerEquip, to, fk.ReasonPut, "th_jie_xiaoemo_xunzhao", "", true, player.id)
        elseif card.sub_type == Card.SubtypeDelayedTrick then
          -- FIXME : deal with visual DelayedTrick
          room:moveCardTo(card, Card.PlayerJudge, to, fk.ReasonPut, "th_jie_xiaoemo_xunzhao", "", true, player.id)
        end
      else
        local drawPilePosition = 1
        room:moveCards({
          ids = { card_id },
          from = player.id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonPut,
          skillName = "th_jie_xiaoemo_xunzhao",
          drawPilePosition = drawPilePosition,
          moveVisible = true
        })
      end
    end
  end,
}
local th_jie_xiaoemo_xunzhao_active = fk.CreateActiveSkill {
  name = "th_jie_xiaoemo_xunzhao_active",
  mute = true,
  card_num = 1,
  max_target_num = 1,
  interaction = function()
    return UI.ComboBox { choices = { "Field", "Top" } }
  end,
  card_filter = function(self, to_select, selected, targets)
    if #selected == 0 then
      if self.interaction.data == "Field" then
        local card = Fk:getCardById(to_select)
        return card.type == Card.TypeEquip or card.sub_type == Card.SubtypeDelayedTrick
      end
      return true
    end
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected == 0 and self.interaction.data == "Field" and #selected_cards == 1 then
      local card = Fk:getCardById(selected_cards[1])
      local target = Fk:currentRoom():getPlayerById(to_select)
      if card.type == Card.TypeEquip and target then
        return target:hasEmptyEquipSlot(card.sub_type)
      elseif card.sub_type == Card.SubtypeDelayedTrick and target then
        return not target:isProhibited(target, card)
      end
    end
    return false
  end,
  feasible = function(self, selected, selected_cards)
    if #selected_cards == 1 then
      if self.interaction.data == "Field" then
        return #selected == 1
      else
        return true
      end
    end
  end,
}

Fk:addSkill(th_jie_xiaoemo_xunzhao_active)
th_jie_xiaoemo:addSkill(th_jie_xiaoemo_xunzhao)

Fk:loadTranslationTable {
  ["th_jie_xiaoemo"] = "界小恶魔",
  ["~th_jie_xiaoemo"] = "这边没有。。去那边找找好了————",
  ["#th_jie_xiaoemo"] = "图书管理员",
  ["designer:th_jie_xiaoemo"] = "妖梦厨",
  ["cv:th_jie_xiaoemo"] = "VV",

  ["th_jie_xiaoemo_xunzhao"] = "寻找",
  ["th_jie_xiaoemo_xunzhao_active"] = "寻找",
  ["$th_jie_xiaoemo_xunzhao"] = "诶？！本子都被姆Q扔掉了吗？😣",
  ["#th_jie_xiaoemo_xunzhao"] = "你可以摸%arg张牌，然后将至少三张牌置于牌堆顶或场上。",
  [":th_jie_xiaoemo_xunzhao"] = "出牌阶段限一次，你可以摸X张牌，然后将至少三张牌置于牌堆顶或场上。（X为存活角色数，至少为3）",

  ["#th_jie_xiaoemo_xunzhao-card"] = "寻找：将一张牌置于场上或牌堆顶(至少3张，目前第%arg张)",
  ["#th_jie_xiaoemo_xunzhao-card2"] = "寻找：将一张牌置于场上或牌堆顶（可取消）",

}

-- 铃仙（界）4/4
-- 狂气:当你使用杀或决斗对其他角色造成伤害后，你令其获得【丧心】直到其回合结束。出牌阶段限一次，你可以弃置一张非基本牌，视为对一名角色使用一张无次数距离限制的杀。
-- 生药:当你回复体力后，你可以摸一张牌；若因[桃]回复体力，本回合你造成的伤害+1。
-- 【丧心】:锁定技，出牌阶段，你不能使用[杀]以外的牌，你使用杀只能指定最近的目标。
local th_jie_lingxian = General:new(extension, "th_jie_lingxian", "tho", 4, 4, 2)

local th_jie_lingxian_kuangqi = fk.CreateActiveSkill {
  name = "th_jie_lingxian_kuangqi",
  prompt = "#th_jie_lingxian_kuangqi",
  anim_type = "offensive",
  card_num = 1,
  card_filter = function(self, to_select, selected, selected_targets)
    return #selected == 0 and not Self:prohibitDiscard(to_select) and Fk:getCardById(to_select).type ~= Card.TypeBasic
  end,
  target_num = 1,
  mod_target_filter = function(self, to_select, selected, user, card, distance_limited)
    return user ~= to_select
  end,
  target_filter = function(self, to_select, selected, selected_cards, card, extra_data)
    return self:modTargetFilter(to_select, selected, Self.id, card)
  end,
  can_use = function(self, player, card, extra_data)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, cardUseEvent)
    local player = room:getPlayerById(cardUseEvent.from)
    room:throwCard(cardUseEvent.cards, self.name, player, player)
    room:useCard({
      from = player.id,
      tos = { cardUseEvent.tos },
      card = Fk:cloneCard("slash"),
      extra_data = { bypass_distances = true, bypass_times = true }
    })
  end,
}
local th_jie_lingxian_sangxin = fk.CreateProhibitSkill {
  name = "th_jie_lingxian_sangxin",
  frequency = Skill.Compulsory,
  prohibit_use = function(self, player, card)
    return player.phase == Player.Play and player:getMark("@@th_jie_lingxian_sangxin") > 0 and card and
        card.trueName ~= "slash"
  end,
  is_prohibited = function(self, from, to, card)
    local room = Fk:currentRoom()
    if from:getMark("@@th_jie_lingxian_sangxin") > 0 and card and from.phase == Player.Play and card.trueName == "slash" then
      if to then
        local room = Fk:currentRoom()
        local player = from
        ---获取最近距离
        local n = 999
        for _, p in ipairs(room.alive_players) do
          if p ~= player and player:distanceTo(p) < n then
            n = player:distanceTo(p)
          end
        end
        ---

        ---找最近距离的角色
        local targets = table.map(table.filter(room.alive_players, function(p)
          return player:distanceTo(p) == n
        end), function(p) return p.id end)
        return not table.contains(targets, to.id)
      end
    end
  end,
}
local th_jie_lingxian_kuangqi_sangxin = fk.CreateTriggerSkill {
  name = "#th_jie_lingxian_kuangqi_sangxin",
  prompt = "#th_jie_lingxian_kuangqi_sangxin-prompt",
  anim_type = "control",
  events = { fk.Damage },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(th_jie_lingxian_kuangqi) and data.card and
        (data.card.trueName == "slash" or data.card.trueName == "duel")
        and data.to and data.to ~= player
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke("th_jie_lingxian_kuangqi")
    player.room:handleAddLoseSkills(data.to, "th_jie_lingxian_sangxin", nil, true, false)
    player.room:addPlayerMark(data.to, "@@th_jie_lingxian_sangxin")
  end,

  refresh_events = { fk.TurnEnd },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@th_jie_lingxian_sangxin") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@@th_jie_lingxian_sangxin")
    player.room:handleAddLoseSkills(player, "-th_jie_lingxian_sangxin", nil, true, false)
  end,
}

local th_jie_lingxian_shengyao = fk.CreateTriggerSkill {
  name = "th_jie_lingxian_shengyao",
  prompt = "#th_jie_lingxian_shengyao",
  anim_type = "drawcard",
  events = { fk.HpRecover },
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, self.name)
    if data.card and data.card.trueName == "peach" then
      player.room:addPlayerMark(player, "@@th_jie_lingxian_shengyao-turn")
    end
  end,

  refresh_events = { fk.DamageCaused },
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@th_jie_lingxian_shengyao-turn") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.damage = (data.damage or 0) + 1
  end
}

th_jie_lingxian_kuangqi:addRelatedSkill(th_jie_lingxian_kuangqi_sangxin)
th_jie_lingxian:addSkill(th_jie_lingxian_kuangqi)
th_jie_lingxian:addSkill(th_jie_lingxian_shengyao)
th_jie_lingxian:addRelatedSkill(th_jie_lingxian_sangxin)

Fk:loadTranslationTable {
  ["th_jie_lingxian"] = "界铃仙",
  ["~th_jie_lingxian"] = "师傅，这药————🐇",
  ["#th_jie_lingxian"] = "永琳的首席药品品尝官",
  ["designer:th_jie_lingxian"] = "Yuyuko",
  ["cv:th_jie_lingxian"] = "小羽",

  ["th_jie_lingxian_kuangqi"] = "狂气",
  ["$th_jie_lingxian_kuangqi1"] = "根本停不下来！！🏃‍",
  ["$th_jie_lingxian_kuangqi2"] = "给你们看看全部的！月的疯狂！🌙",
  ["#th_jie_lingxian_kuangqi"] = "你可以弃置一张非基本牌，视为对一名角色使用一张无次数距离限制的【杀】。",
  [":th_jie_lingxian_kuangqi"] = "当你使用杀或决斗对其他角色造成伤害后，你令其获得【丧心】直到其回合结束。出牌阶段限一次，你可以弃置一张非基本牌，视为对一名角色使用一张无次数距离限制的【杀】。",

  ["#th_jie_lingxian_kuangqi_sangxin"] = "狂气",
  ["#th_jie_lingxian_kuangqi_sangxin-prompt"] = "你可以令其获得【丧心】直到其回合结束。",

  ["th_jie_lingxian_sangxin"] = "丧心",
  [":th_jie_lingxian_sangxin"] = "锁定技，出牌阶段，你不能使用【杀】以外的牌，你使用【杀】只能指定最近的目标。",
  ["@@th_jie_lingxian_sangxin"] = "丧心",

  ["th_jie_lingxian_shengyao"] = "生药",
  ["$th_jie_lingxian_shengyao"] = "国士无双之药‍，认准蓝瓶的😊",
  ["#th_jie_lingxian_shengyao"] = "你可以摸一张牌；若因【桃】回复体力，本回合你造成的伤害+1。",
  [":th_jie_lingxian_shengyao"] = "当你回复体力后，你可以摸一张牌；若因【桃】回复体力，本回合你造成的伤害+1。",
  ["@@th_jie_lingxian_shengyao-turn"] = "生药",

}

-- 八云蓝 9999

-- 深虑:出牌阶段限一次，你可以弃置至多x张牌，然后执行前x项。
-- 1.获得制衡，2.回复1点体力,3.摸两张牌,4.失去制衡，该技能视为未发动，5.删除1选项，将该项并入邻项，然后本回合使用牌没有次数限制。（x为【深虑】剩余选项项数）

local th_jie_bayunlan = General:new(extension, "th_jie_bayunlan", "tho", 4, 4, 2)

local th_jie_bayunlan_shenlv = fk.CreateActiveSkill {
  name = "th_jie_bayunlan_shenlv",
  prompt = function()
    local num = 5
    local player
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("th_jie_bayunlan_shenlv") then
        player = p
      end
    end
    if player.getTableMark(player,"th_jie_bayunlan_shenlv")and #player.getTableMark(player,"th_jie_bayunlan_shenlv")>0  then
      return "#th_jie_bayunlan_shenlv:::" .. #player.getTableMark(player,"th_jie_bayunlan_shenlv")
    else
      return "#th_jie_bayunlan_shenlv:::" .. num
    end
  end,
  anim_type = "drawcard",
  max_card_num = function()
    local player
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("th_jie_bayunlan_shenlv") then
        player = p
      end
    end
    if player.getTableMark(player,"th_jie_bayunlan_shenlv") and #player.getTableMark(player,"th_jie_bayunlan_shenlv")>0 then
      return #player.getTableMark(player,"th_jie_bayunlan_shenlv")
    else
      return 5
    end
  end,
  min_card_num = 1,
  card_filter = function(self, to_select, selected, selected_targets)
    local player
    for _, p in ipairs(Fk:currentRoom().alive_players) do
      if p:hasSkill("th_jie_bayunlan_shenlv") then
        player = p
      end
    end
    if player.getTableMark(player,"th_jie_bayunlan_shenlv") and #player.getTableMark(player,"th_jie_bayunlan_shenlv")>0  then
      return #selected < #player.getTableMark(player,"th_jie_bayunlan_shenlv")
    else
      return #selected < 5
    end
  end,
  can_use = function(self, player, card, extra_data)
    if player.getTableMark(player,"th_jie_bayunlan_shenlv") and #player.getTableMark(player,"th_jie_bayunlan_shenlv")==0  then
      return player:usedSkillTimes(self.name, Player.HistoryPhase) ==0
    elseif #player.getTableMark(player,"th_jie_bayunlan_shenlv")~=0 then
      return player:usedSkillTimes(self.name, Player.HistoryPhase) ==0 and #player.getTableMark(player,"th_jie_bayunlan_shenlv")>1
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local discard_num = #effect.cards
    local mark = player.getTableMark(player,"th_jie_bayunlan_shenlv")
    if mark and #mark==0 then
      player.room:setPlayerMark(player,"th_jie_bayunlan_shenlv",{1,2,3,4,5})
      mark=player.getTableMark(player,"th_jie_bayunlan_shenlv")
    end
    if discard_num > 0 and #mark>1 then
      room:throwCard(effect.cards, self.name, player, player)
      for i=1,discard_num,1 do
        if mark[i]==1 then
          room:handleAddLoseSkills(player, "ex__zhiheng", nil, true, false)
        end
        if mark[i]==2 then
          room:recover({
            who = player,
            num = 1,
            recoverBy = player,
            skillName = self.name
          })
        end
        if mark[i]==3 then
          player:drawCards(2, self.name)
        end
        if mark[i]==4 then
          room:handleAddLoseSkills(player, "-ex__zhiheng", nil, true, false)
          local skill_name=self.name
          local ids = Fk.skills[skill_name]
          local scope_type = ids.scope_type
          if scope_type == nil then
              scope_type = Player.HistoryPhase
          end
          if scope_type and player:usedSkillTimes(skill_name, scope_type) > 0 then
              player:setSkillUseHistory(skill_name, 0, scope_type)
          end
        end
        if mark[i]==5 then
          table.remove(mark,#mark-1)
          p("______________")
          p(mark)
          room:setPlayerMark(player, "th_jie_bayunlan_shenlv", mark)
          room:setPlayerMark(player, "th_jie_bayunlan_shenlv_times-turn", 1)
        end
      end
      
    end
  end,
}

local th_jie_bayunlan_shenlv_times = fk.CreateTargetModSkill {
  name = "#th_jie_bayunlan_shenlv_times",
  bypass_times = function(self, player, skill, scope, card, to)
    return player:getMark("th_jie_bayunlan_shenlv_times-turn") > 0 and card ~= nil
  end
}

th_jie_bayunlan_shenlv:addRelatedSkill(th_jie_bayunlan_shenlv_times)
th_jie_bayunlan:addSkill(th_jie_bayunlan_shenlv)

Fk:loadTranslationTable {
  ["th_jie_bayunlan"] = "SP八云蓝",
  ["~th_jie_bayunlan"] = "没有油炸豆腐了吗？失算了——😔",
  ["#th_jie_bayunlan"] = "天河一号的核心",
  ["designer:th_jie_bayunlan"] = "澪汐",
  ["cv:th_jie_bayunlan"] = "shourei小N",

  ["th_jie_bayunlan_shenlv"] = "深虑",
  ["$th_jie_bayunlan_shenlv"] = "掐指一算，这次能摸到油炸豆腐的说~❤",
  ["#th_jie_bayunlan_shenlv"] = "你可以弃置至多%arg张牌，然后执行前%arg项",
  [":th_jie_bayunlan_shenlv"] = "出牌阶段限一次，你可以弃置至多x张牌，然后执行前x项。1.获得制衡，2.回复1点体力,3.摸两张牌,4.失去制衡，该技能视为未发动，5.删除除该项外的最后一项，然后本回合使用牌没有次数限制。（x为【深虑】剩余选项项数）",
  ["#th_jie_bayunlan_shenlv-damge"]="深虑:选择一名角色造成一点伤害。",
}


return extension
