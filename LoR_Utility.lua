---@class LoR_Utility:Object
local LoR_Utility = {}

---根据卡牌类型返回对应的类型字符串
---@param typechose CardType
---@return string
LoR_Utility.getBugMarkValue = function(typechose)
    local choice=""
    if typechose == Card.TypeBasic then
        choice = "basic"
    elseif typechose == Card.TypeTrick then
        choice = "trick"
    elseif typechose == Card.TypeEquip then
        choice = "equip"
    end
    return choice
end

-- 判断技能次数是否在剩余次数内
---@param player Player @ 使用者
---@param scope integer @ 考察时机（默认为回合）
---@param card? Card @ 牌，若没有牌，则尝试制造一张虚拟牌
---@param card_name? string @ 牌名
---@param to any @ 目标
---@param card_skill UsableSkill @ 技能
---@param num? integer @ 技能剩余使用次数（最大使用牌量-当前阶段使用牌量>=此参数）
---@return bool
function LoR_Utility.withinTimesLimit(player, scope, card, card_name, to, card_skill, num)
    if to and to.dead then return false end
    scope = scope or Player.HistoryTurn
    local status_skills = Fk:currentRoom().status_skills[TargetModSkill] or Util.DummyTable
    if not card then
        if card_name then
            card = Fk:cloneCard(card_name)
        elseif card_skill.name:endsWith("_skill") then
            card = Fk:cloneCard(card_skill.name:sub(1, #card_skill.name - 6))
        end
    end
    if not card_name and card then
        card_name = card.trueName
    end
    for _, sk in ipairs(status_skills) do
        if sk:bypassTimesCheck(player, card_skill, scope, card, to) then return true end
    end

    local temp_suf = table.simpleClone(MarkEnum.TempMarkSuffix)
    local card_temp_suf = table.simpleClone(MarkEnum.CardTempMarkSuffix)

    ---@param object Card|Player
    ---@param markname string
    ---@param suffixes string[]
    ---@return boolean
    local function hasMark(object, markname, suffixes)
        if not object then return false end
        for mark, _ in pairs(object.mark) do
            if mark == markname then return true end
            if mark:startsWith(markname .. "-") then
                for _, suffix in ipairs(suffixes) do
                    if mark:find(suffix, 1, true) then return true end
                end
            end
        end
        return false
    end
    if not num then num = 0 end
    return (player:usedCardTimes(card_name, scope) < card_skill:getMaxUseTime(player, scope, card, to) and
            card_skill:getMaxUseTime(player, scope, card, to) - player:usedCardTimes(card_name, scope) >= num) or
        hasMark(card, MarkEnum.BypassTimesLimit, card_temp_suf) or
        hasMark(player, MarkEnum.BypassTimesLimit, temp_suf) or
        hasMark(to, MarkEnum.BypassTimesLimitTo, temp_suf)
    -- (card and table.find(card_temp_suf, function(s)
    --   return card:getMark(MarkEnum.BypassTimesLimit .. s) ~= 0
    -- end)) or
    -- (table.find(temp_suf, function(s)
    --   return player:getMark(MarkEnum.BypassTimesLimit .. s) ~= 0
    -- end)) or
    -- (to and (table.find(temp_suf, function(s)
    --   return to:getMark(MarkEnum.BypassTimesLimitTo .. s) ~= 0
    -- end)))
end

---改变武将图像
---@param player ServerPlayer 当前需要改变的角色
---@param old string   当前的武将名
---@param new string   需要改变的武将名
function LoR_Utility.ChangeGeneral(player, old, new)
    local room = player.room
    if player.deputyGeneral == old or player.general == old then
        if player.deputyGeneral == old then
            player.deputyGeneral = new
            room:broadcastProperty(player, "deputyGeneral")
        elseif player.general == old then
            player.general = new
            room:broadcastProperty(player, "general")
        end
    else
        player.general = new
        room:broadcastProperty(player, "general")
    end
end

---EGO展现状态：失去本技能原武将牌上的所有技能，替换武将图像并获得对应的EGO展现武将的技能。
---@param player ServerPlayer
---@param old string
---@param new string
function LoR_Utility.EGOChangeGeneral(player, old, new)
    local room = player.room
    LoR_Utility.ChangeGeneral(player, old, new)
    local oldSkills = {}
    for _, value in ipairs(Fk.generals[old]:getSkillNameList()) do
        table.insert(oldSkills, "-" .. value)
    end
    room:handleAddLoseSkills(player, Fk.generals[new]:getSkillNameList(), nil, true, false)
    room:handleAddLoseSkills(player, oldSkills, nil, true, false)
end

---根据点数选择牌poxi
---@param player ServerPlayer 当前的player
---@param n integer 要求的点数
---@param prompt string 提示信息
---@param targetplayer ServerPlayer 做选择的player
---@param poxi_type string 筛选函数的名称
---@param data any 填入所有卡的列表例：{ { player.general, player:getCardIds("h") } }
---@param extra_data any
---@param cancelable? boolean  能否取消选择
---@return integer[]
function LoR_Utility.PoXiMethod(player, n, prompt, targetplayer, poxi_type, data, extra_data, cancelable)
    local room = player.room
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
        name = poxi_type,
        card_filter = function(to_select, selected, data, extra_data)
            local card = Fk:getCardById(to_select)
            if card.number == nil then
                return false
            end
            return xianjiselect(selected, to_select, n)
        end,
        feasible = function(selected, data, extra_data)
            return xianjifeasible(selected, n)
        end,
        prompt = prompt,
    }

    local gain = room:askForPoxi(targetplayer, poxi_type, data, extra_data, cancelable)
    return gain
end

--- 获得队友（注意：在客户端不能对暗身份角色生效）（或许对ai有用？）
---@param room Room|AbstractRoom @ 房间
---@param player Player @ 自己
---@param include_self? boolean @ 是否包括自己。默认是
---@param include_dead? boolean @ 是否包括死亡角色。默认否
---@return ServerPlayer[] @ 玩家列表
LoR_Utility.GetFriends = function(room, player, include_self, include_dead)
    if include_self == nil then include_self = true end
    local players = include_dead and room.players or room.alive_players
    local friends = table.filter(players, function(p)
        return p.role == player.role or
            (table.contains({ "lord", "loyalist" }, p.role) and table.contains({ "lord", "loyalist" }, player.role))
    end)
    if not include_self then
        table.removeOne(friends, player)
    end
    return friends
end

--- 获得敌人（注意：在客户端不能对暗身份角色生效）（或许对ai有用？）
---@param room Room|AbstractRoom @ 房间
---@param player Player @根据player的身份判断敌我的角色
---@param include_dead? boolean @ 是否包括死亡角色。默认否
---@return ServerPlayer[] @ 玩家列表
LoR_Utility.GetEnemies = function(room, player, include_dead)
    local players = include_dead and room.players or room.alive_players
    return table.filter(players, function(p)
        return p.role ~= player.role and
            not (table.contains({ "lord", "loyalist" }, p.role) and table.contains({ "lord", "loyalist" }, player.role))
    end)
end



---调整角色手牌数量
---@param player ServerPlayer 需要调整的角色
---@param num integer   需要调整至的数值
---@param prompt string 调整数值不小于手牌时的弃牌提示
---@param skill Skill   本技能，一般填入self
function LoR_Utility.ChangeHandNum(player, num, prompt, skill)
    local room = player.room
    local difference = math.abs(player:getHandcardNum() - num)
    if player:getHandcardNum() >= num then
        room:askForDiscard(player, difference, difference, false, skill.name, false, ".|.|.|hand", prompt)
    else
        player:drawCards(difference, skill.name)
    end
end

-- 泛转化技能的牌名筛选，仅用于interaction里对泛转化牌名的合法性检测（按无对应实体牌的牌来校验）
--
-- 注：如果需要无距离和次数限制则需要外挂TargetModSkill（来点功能型card mark？）
--
---@param player Player @ 使用者Self
---@param skill_name string @ 泛转化技的技能名
---@param card_names string[] @ 待判定的牌名列表
---@param subcards? string[] @ 子卡（某些技能可以提前确定子卡，如奇策、妙弦）
---@param ban_cards? string[] @ 被排除的卡名
---@return string[] @ 返回牌名列表
LoR_Utility.getViewAsCardNames = function(player, skill_name, card_names, subcards, ban_cards)
    ban_cards = ban_cards or {}
    if Fk.currentResponsePattern == nil then
        return table.filter(card_names, function(name)
            local card = Fk:cloneCard(name)
            if table.contains(ban_cards, card.trueName) then return false end
            card.skillName = skill_name
            if subcards then
                card:addSubcards(subcards)
            end
            return player:canUse(card) and not player:prohibitUse(card)
        end)
    else
        return table.filter(card_names, function(name)
            local card = Fk:cloneCard(name)
            if table.contains(ban_cards, card.trueName) then return false end
            card.skillName = skill_name
            if subcards then
                card:addSubcards(subcards)
            end
            return Exppattern:Parse(Fk.currentResponsePattern):match(card)
        end)
    end
end

-- 获取加入游戏的卡的牌名（暂不考虑装备牌），常用于泛转化技能的interaction
---@param guhuo_type string @ 神杀智慧，用"btd"三个字母的组合表示卡牌的类别， b 基本牌, t - 普通锦囊牌, d - 延时锦囊牌
---@param true_name? boolean @ 是否使用真实卡名（即不区分【杀】、【无懈可击】等的具体种类）
---@return string[] @ 返回牌名列表
LoR_Utility.getAllCardNames = function(guhuo_type, true_name)
    local all_names = {}
    local basics = {}
    local normalTricks = {}
    local delayedTricks = {}
    for _, card in ipairs(Fk.cards) do
        if not table.contains(Fk:currentRoom().disabled_packs, card.package.name) and not card.is_derived then
            if card.type == Card.TypeBasic then
                table.insertIfNeed(basics, true_name and card.trueName or card.name)
            elseif card.type == Card.TypeTrick and card.sub_type ~= Card.SubtypeDelayedTrick then
                table.insertIfNeed(normalTricks, true_name and card.trueName or card.name)
            elseif card.type == Card.TypeTrick and card.sub_type == Card.SubtypeDelayedTrick then
                table.insertIfNeed(delayedTricks, true_name and card.trueName or card.name)
            end
        end
    end
    if guhuo_type:find("b") then
        table.insertTable(all_names, basics)
    end
    if guhuo_type:find("t") then
        table.insertTable(all_names, normalTricks)
    end
    if guhuo_type:find("d") then
        table.insertTable(all_names, delayedTricks)
    end
    return all_names
end
--- 获取实际的伤害事件
LoR_Utility.getActualDamageEvents = function(room, n, func, scope, end_id)
    if not end_id then
        scope = scope or Player.HistoryTurn
    end

    n = n or 1
    func = func or Util.TrueFunc

    local logic = room.logic
    local eventType = GameEvent.Damage
    local ret = {}
    local endIdRecorded
    local tempEvents = {}

    local addTempEvents = function(reverse)
        if #tempEvents > 0 and #ret < n then
            table.sort(tempEvents, function(a, b)
                if reverse then
                    return a.data[1].dealtRecorderId > b.data[1].dealtRecorderId
                else
                    return a.data[1].dealtRecorderId < b.data[1].dealtRecorderId
                end
            end)

            for _, e in ipairs(tempEvents) do
                table.insert(ret, e)
                if #ret >= n then return true end
            end
        end

        endIdRecorded = nil
        tempEvents = {}

        return false
    end

    if scope then
        local event = logic:getCurrentEvent()
        local start_event ---@type GameEvent
        if scope == Player.HistoryGame then
            start_event = logic.all_game_events[1]
        elseif scope == Player.HistoryRound then
            start_event = event:findParent(GameEvent.Round, true)
        elseif scope == Player.HistoryTurn then
            start_event = event:findParent(GameEvent.Turn, true)
        elseif scope == Player.HistoryPhase then
            start_event = event:findParent(GameEvent.Phase, true)
        end

        if not start_event then return {} end

        local events = logic.event_recorder[eventType] or Util.DummyTable
        local from = start_event.id
        local to = start_event.end_id
        if math.abs(to) == 1 then to = #logic.all_game_events end

        for _, v in ipairs(events) do
            local damageStruct = v.data[1]
            if damageStruct.dealtRecorderId then
                if endIdRecorded and v.id > endIdRecorded then
                    local result = addTempEvents()
                    if result then
                        return ret
                    end
                end

                if v.id >= from and v.id <= to then
                    if not endIdRecorded and v.end_id > -1 and v.end_id > v.id then
                        endIdRecorded = v.end_id
                    end

                    if func(v) then
                        if endIdRecorded then
                            table.insert(tempEvents, v)
                        else
                            table.insert(ret, v)
                        end
                    end
                end
                if #ret >= n then break end
            end
        end

        addTempEvents()
    else
        local events = logic.event_recorder[eventType] or Util.DummyTable

        for i = #events, 1, -1 do
            local e = events[i]
            if e.id <= end_id then break end

            local damageStruct = e.data[1]
            if damageStruct.dealtRecorderId then
                if e.end_id == -1 or (endIdRecorded and endIdRecorded > e.end_id) then
                    local result = addTempEvents(true)
                    if result then
                        return ret
                    end

                    if func(e) then
                        table.insert(ret, e)
                    end
                else
                    endIdRecorded = e.end_id
                    if func(e) then
                        table.insert(tempEvents, e)
                    end
                end

                if #ret >= n then break end
            end
        end

        addTempEvents(true)
    end

    return ret
end

--- 将一些卡牌同时分配给一些角色。
---@param room Room @ 房间
---@param list table<string, integer[]> @ 分配牌和角色的数据表，键为取整后字符串化的角色id，值为分配给其的牌
---@param proposer? integer @ 操作者的id。默认为空
---@param skillName? string @ 技能名。默认为“分配”
---@return integer[][] @ 返回成功分配的卡牌
LoR_Utility.doDistribution = function (room, list, proposer, skillName)
    fk.qWarning("Utility.doDistribution is deprecated! Use Room:doYiji instead")
    skillName = skillName or "distribution_skill"
    local moveInfos = {}
    local move_ids = {}
    for str, cards in pairs(list) do
      local to = tonumber(str)
      local toP = room:getPlayerById(to)
      local handcards = toP:getCardIds("h")
      cards = table.filter(cards, function (id) return not table.contains(handcards, id) end)
      if #cards > 0 then
        table.insertTable(move_ids, cards)
        local moveMap = {}
        local noFrom = {}
        for _, id in ipairs(cards) do
          local from = room.owner_map[id]
          if from then
            moveMap[from] = moveMap[from] or {}
            table.insert(moveMap[from], id)
          else
            table.insert(noFrom, id)
          end
        end
        for from, _cards in pairs(moveMap) do
          table.insert(moveInfos, {
            ids = _cards,
            moveInfo = table.map(_cards, function(id)
              return {cardId = id, fromArea = room:getCardArea(id), fromSpecialName = room:getPlayerById(from):getPileNameOfId(id)}
            end),
            from = from,
            to = to,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonGive,
            proposer = proposer,
            skillName = skillName,
            visiblePlayers = proposer,
          })
        end
        if #noFrom > 0 then
          table.insert(moveInfos, {
            ids = noFrom,
            to = to,
            toArea = Card.PlayerHand,
            moveReason = fk.ReasonGive,
            proposer = proposer,
            skillName = skillName,
            visiblePlayers = proposer,
          })
        end
      end
    end
    if #moveInfos > 0 then
      room:moveCards(table.unpack(moveInfos))
    end
    return move_ids
  end

--- 询问将卡牌分配给任意角色。
---@param player ServerPlayer @ 要询问的玩家
---@param cards? integer[] @ 要分配的卡牌。默认拥有的所有牌
---@param targets? ServerPlayer[] @ 可以获得卡牌的角色。默认所有存活角色
---@param skillName? string @ 技能名，影响焦点信息。默认为“分配”
---@param minNum? integer @ 最少交出的卡牌数，默认0
---@param maxNum? integer @ 最多交出的卡牌数，默认所有牌
---@param prompt? string @ 询问提示信息
---@param expand_pile? string|integer[] @ 可选私人牌堆名称，如要分配你武将牌上的牌请填写
---@param skipMove? boolean @ 是否跳过移动。默认不跳过
---@param single_max? integer|table @ 限制每人能获得的最大牌数。输入整数或(以角色id为键以整数为值)的表
---@return table<string, integer[]> @ 返回一个表，键为取整后字符串化的角色id，值为分配给其的牌
LoR_Utility.askForDistribution = function(player, cards, targets, skillName, minNum, maxNum, prompt, expand_pile,
                                          skipMove, single_max)
    local room = player.room
    targets = targets or room.alive_players
    cards = cards or player:getCardIds("he")
    local _cards = table.simpleClone(cards)
    targets = table.map(targets, Util.IdMapper)
    room:sortPlayersByAction(targets)
    skillName = skillName or "distribution_skill"
    minNum = minNum or 0
    maxNum = maxNum or #cards
    local getString = function(n) return string.format("%.0f", n) end
    local list = {}
    for _, pid in ipairs(targets) do
        list[getString(pid)] = {}
    end
    local data = { expand_pile = expand_pile, skillName = skillName }
    room:setPlayerMark(player, "distribution_targets", targets)
    local residueMap = {}
    if type(single_max) == "table" then
        for pid, v in pairs(single_max) do
            residueMap[getString(pid)] = v
        end
    end
    local residue_sum = 0
    local residue_num = type(single_max) == "number" and single_max or 9999
    for _, pid in ipairs(targets) do
        local num = residueMap[getString(pid)] or residue_num
        room:setPlayerMark(room:getPlayerById(pid), "distribution_residue", num)
        residue_sum = residue_sum + num
    end
    minNum = math.min(minNum, #_cards, residue_sum)

    while maxNum > 0 and #_cards > 0 do
        room:setPlayerMark(player, "distribution_cards", _cards)
        room:setPlayerMark(player, "distribution_maxnum", maxNum)
        local _prompt = prompt or ("#distribution_skill:::" .. minNum .. ":" .. maxNum)
        local success, dat = room:askForUseActiveSkill(player, "distribution_skill", _prompt, minNum == 0, data, true)
        if success and dat then
            local to = dat.targets[1]
            local give_cards = dat.cards
            for _, id in ipairs(give_cards) do
                table.insert(list[getString(to)], id)
                table.removeOne(_cards, id)
                room:setCardMark(Fk:getCardById(id), "@distribution_to", Fk:translate(room:getPlayerById(to).general))
            end
            minNum = math.max(0, minNum - #give_cards)
            maxNum = maxNum - #give_cards
            room:removePlayerMark(room:getPlayerById(to), "distribution_residue", #give_cards)
        else
            break
        end
    end

    for _, id in ipairs(cards) do
        room:setCardMark(Fk:getCardById(id), "@distribution_to", 0)
    end
    for _, pid in ipairs(targets) do
        if minNum == 0 or #_cards == 0 then break end
        local p = room:getPlayerById(pid)
        local num = math.min(p:getMark("distribution_residue"), minNum, #_cards)
        if num > 0 then
            for i = num, 1, -1 do
                local c = table.remove(_cards, i)
                table.insert(list[getString(pid)], c)
                minNum = minNum - 1
            end
        end
    end
    if not skipMove then
        LoR_Utility.doDistribution(room, list, player.id, skillName)
    end

    return list
end


--- 询问玩家选择牌和选项
---@param player ServerPlayer @ 要询问的玩家
---@param cards integer[] @ 待选卡牌
---@param choices string[] @ 可选选项列表（在min和max范围内选择cards里的牌才会被点亮的选项）
---@param skillname string @ 烧条技能名
---@param prompt string @ 操作提示
---@param cancel_choices? string[] @ 可选选项列表（不选择牌时的选项）
---@param min? integer  @ 最小选牌数（默认为1）
---@param max? integer  @ 最大选牌数（默认为1）
---@param all_cards? integer[]  @ 会显示的所有卡牌
---@return integer[], string
LoR_Utility.askforChooseCardsAndChoice = function(player, cards, choices, skillname, prompt, cancel_choices, min, max,
                                                  all_cards)
    cancel_choices = (cancel_choices == nil) and {} or cancel_choices
    min = min or 1
    max = max or 1
    assert(min <= max, "limits error: The upper limit should be less than the lower limit")
    assert(#cards >= min or #cancel_choices > 0, "limits Error: No enough cards")
    assert(#choices > 0 or #cancel_choices > 0, "should have choice to choose")
    local cardsToWatch = table.filter(all_cards or cards, function(id)
        return player.room:getCardArea(id) == Player.Hand and player.room:getCardOwner(id) ~= player
    end)
    if #cardsToWatch > 0 then
        local log = {
            type = "#WatchCard",
            from = player.id,
            card = cardsToWatch,
        }
        player:doNotify("GameLog", json.encode(log))
    end
    local result = player.room:askForCustomDialog(player, skillname,
        "packages/utility/qml/ChooseCardsAndChoiceBox.qml", {
            all_cards or cards,
            choices,
            prompt,
            cancel_choices,
            min,
            max,
            all_cards and table.filter(all_cards, function(id)
                return not table.contains(cards, id)
            end) or {}
        })
    if result ~= "" then
        local reply = json.decode(result)
        return reply.cards, reply.choice
    end
    if #cancel_choices > 0 then
        return {}, cancel_choices[1]
    end
    return table.random(cards, min), choices[1]
end

--- 询问玩家观看一些卡牌并选择一项
---@param player ServerPlayer @ 要询问的玩家
---@param cards integer[] @ 待选卡牌
---@param choices string[] @ 可选选项列表
---@param skillname string @ 烧条技能名
---@param prompt? string @ 操作提示
---@return string
LoR_Utility.askforViewCardsAndChoice = function(player, cards, choices, skillname, prompt)
    local _, result = LoR_Utility.askforChooseCardsAndChoice(player, cards, {}, skillname, prompt or "#AskForChoice",
        choices)
    return result
end


--- 类似于askForCardsChosen，适用于“选择每个区域各一张牌”
---@param chooser ServerPlayer @ 要被询问的人
---@param target ServerPlayer @ 被选牌的人
---@param flag any @ 用"hej"三个字母的组合表示能选择哪些区域, h - 手牌区, e - 装备区, j - 判定区
---@param skill_name? string @ 技能名（暂时没用的参数，poxi没提供接口）
---@param prompt? string @ 提示信息（暂时没用的参数，poxi没提供接口）
---@param disable_ids? integer[] @ 不允许选的牌
---@param cancelable? boolean @ 是否可以点取消，默认是
---@return integer[] @ 选择的id
LoR_Utility.askforCardsChosenFromAreas = function(chooser, target, flag, skill_name, prompt, disable_ids, cancelable)
    cancelable = (cancelable == nil) and true or cancelable
    disable_ids = disable_ids or {}
    local card_data = {}
    if type(flag) ~= "string" then
        flag = "hej"
    end
    if string.find(flag, "h") and target:getHandcardNum() > 0 then
        local handcards = {}
        if chooser:isBuddy(target) then
            handcards = target:getCardIds("h")
        else
            local n = #table.filter(target:getCardIds("h"), function(id)
                return not table.contains(disable_ids, id)
            end)
            if n > 0 then
                for i = 1, n, 1 do
                    table.insert(handcards, -1)
                end
            end
        end
        local cards = table.filter(handcards, function(id)
            return not table.contains(disable_ids, id)
        end)
        if #cards > 0 then
            table.insert(card_data, { "$Hand", cards })
        end
    end
    if string.find(flag, "e") and #target:getCardIds("e") > 0 then
        local cards = table.filter(target:getCardIds("e"), function(id)
            return not table.contains(disable_ids, id)
        end)
        if #cards > 0 then
            table.insert(card_data, { "$Equip", cards })
        end
    end
    if string.find(flag, "j") and #target:getCardIds("j") > 0 then
        local cards = table.filter(target:getCardIds("j"), function(id)
            return not table.contains(disable_ids, id)
        end)
        if #cards > 0 then
            table.insert(card_data, { "$Judge", cards })
        end
    end
    if #card_data == 0 then return {} end
    local ret = chooser.room:askForPoxi(chooser, "askforCardsChosenFromAreas", card_data, nil, cancelable)
    local result = table.filter(ret, function(id) return id ~= -1 end)
    local hand_num = #ret - #result
    if hand_num > 0 then
        table.insertTable(result, table.random(target:getCardIds("h"), hand_num))
    end
    return result
end



--- 判断一张牌能否移动至某角色的装备区
---@param target Player @ 接受牌的角色
---@param cardId integer @ 移动的牌
---@param convert? boolean @ 是否可以替换装备（默认可以）
---@return boolean
LoR_Utility.canMoveCardIntoEquip = function(target, cardId, convert)
    convert = (convert == nil) and true or convert
    local card = Fk:getCardById(cardId)
    if not (card.sub_type >= 3 and card.sub_type <= 7) then return false end
    if target==nil or target.dead or table.contains(target:getCardIds("e"), cardId) then return false end
    if target:hasEmptyEquipSlot(card.sub_type) or (#target:getEquipments(card.sub_type) > 0 and convert) then
        return true
    end
    return false
end

--- 将一张牌移动至某角色的装备区，若不合法则置入弃牌堆。目前没做相同副类别装备同时置入的适配(甘露神典韦)
---@param room Room @ 房间
---@param target ServerPlayer @ 接受牌的角色
---@param cards integer|integer[] @ 移动的牌
---@param skillName? string @ 技能名
---@param convert? boolean @ 是否可以替换装备（默认可以）
---@param proposer? ServerPlayer @ 操作者
LoR_Utility.moveCardIntoEquip = function(room, target, cards, skillName, convert, proposer)
    convert = (convert == nil) and true or convert
    skillName = skillName or ""
    cards = type(cards) == "table" and cards or { cards }
    local moves = {}
    for _, cardId in ipairs(cards) do
        local card = Fk:getCardById(cardId)
        local fromId = room.owner_map[cardId]
        local proposerId = proposer and proposer.id or nil
        if LoR_Utility.canMoveCardIntoEquip(target, cardId, convert) then
            if target:hasEmptyEquipSlot(card.sub_type) then
                table.insert(moves,
                    { ids = { cardId }, from = fromId, to = target.id, toArea = Card.PlayerEquip, moveReason = fk
                    .ReasonPut, skillName = skillName, proposer = proposerId })
            else
                local existingEquip = target:getEquipments(card.sub_type)
                local throw = #existingEquip == 1 and existingEquip[1] or
                    room:askForCardChosen(proposer or target, target, { card_data = { { "convertEquip", existingEquip } } },
                        "convertEquip", "#convertEquip")
                table.insert(moves,
                    { ids = { throw }, from = target.id, toArea = Card.DiscardPile, moveReason = fk
                    .ReasonPutIntoDiscardPile, skillName = skillName, proposer = proposerId })
                table.insert(moves,
                    { ids = { cardId }, from = fromId, to = target.id, toArea = Card.PlayerEquip, moveReason = fk
                    .ReasonPut, skillName = skillName, proposer = proposerId })
            end
        else
            table.insert(moves,
                { ids = { cardId }, from = fromId, toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile, skillName =
                skillName })
        end
    end
    room:moveCards(table.unpack(moves))
end

---从num数量的技能中选择1个获得（已开启的扩展全武将）
---@param player ServerPlayer 需要获得技能的角色
---@param skill Skill   引发本效果的技能（一般是self
---@param prompt string 提示信息
---@param num integer   可选择的数量
LoR_Utility.getSkill=function (player,skill,prompt,num)
    local room=player.room
    local skills = {}
    for _, general in ipairs(Fk:getAllGenerals()) do
      for _, skill in ipairs(general.skills) do
        if not player:hasSkill(skill) then
          table.insertIfNeed(skills, skill.name)
        end
      end
    end
    if #skills > 0 then
      local skill = room:askForChoice(player, table.random(skills, math.min(num, #skills)), skill.name, prompt, true)
      room:handleAddLoseSkills(player, skill, nil, true, false)
    end
end

return LoR_Utility
