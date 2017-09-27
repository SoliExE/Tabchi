redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('botBOT-IDadminset') then
		return true
	else
   		
    		print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    		print("\n\27[36m                     << \n >> Imput the Admin ID :\n\27[31m                 ")
    		admin=io.read()
		redis:del("botBOT-IDadmin")
    		redis:sadd("botBOT-IDadmin", admin)
		redis:set('botBOT-IDadminset',true)
  	end
  	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| Admin ID")
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("botBOT-IDid",naji.id_)
		if naji.first_name_ then
			redis:set("botBOT-IDfname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("botBOT-IDlanme",naji.last_name_)
		end
		redis:set("botBOT-IDnum",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-BOT-ID.lua")()
	send(chat_id, msg_id, "<i>SuccessfulLy Done.</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'botBOT-IDadmin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+')
		redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
	else
		redis:srem("botBOT-IDgoodlinks", i.link)
		redis:sadd("botBOT-IDsavedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		redis:srem("botBOT-IDwaitelinks", i.link)
		redis:sadd("botBOT-IDgoodlinks", i.link)
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+')
		redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
	else
		redis:srem("botBOT-IDwaitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botBOT-IDalllinks", link) then
				redis:sadd("botBOT-IDwaitelinks", link)
				redis:sadd("botBOT-IDalllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("botBOT-IDusers", id)
			redis:sadd("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:sadd("botBOT-IDsupergroups", id)
			redis:sadd("botBOT-IDall", id)
		else
			redis:sadd("botBOT-IDgroups", id)
			redis:sadd("botBOT-IDall", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("botBOT-IDall", id) then
		if Id:match("^(%d+)$") then
			redis:srem("botBOT-IDusers", id)
			redis:srem("botBOT-IDall", id)
		elseif Id:match("^-100") then
			redis:srem("botBOT-IDsupergroups", id)
			redis:srem("botBOT-IDall", id)
		else
			redis:srem("botBOT-IDgroups", id)
			redis:srem("botBOT-IDall", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("botBOT-IDmaxlink") then
			if redis:scard("botBOT-IDwaitelinks") ~= 0 then
				local links = redis:smembers("botBOT-IDwaitelinks")
				for x,y in pairs(links) do
					if x == 11 then redis:setex("botBOT-IDmaxlink", 60, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("botBOT-IDmaxjoin") then
			if redis:scard("botBOT-IDgoodlinks") ~= 0 then 
				local links = redis:smembers("botBOT-IDgoodlinks")
				for x,y in pairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 5 then redis:setex("botBOT-IDmaxjoin", 60, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("botBOT-IDid") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 123654789) then
			for k,v in pairs(redis:smembers('botBOT-IDadmin')) do
				tdcli_function({
					ID = "ForwardMessages",
					chat_id_ = v,
					from_chat_id_ = msg.chat_id_,
					message_ids_ = {[0] = msg.id_},
					disable_notification_ = 0,
					from_background_ = 1
				}, dl_cb, nil)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("botBOT-IDall", msg.chat_id_) then
				redis:sadd("botBOT-IDusers", msg.chat_id_)
				redis:sadd("botBOT-IDall", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			find_link(text)
			if is_naji(msg) then
				if text:match("^(!Admin) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDadmin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>User Is Curently Admin.</i>")
					elseif redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "You don`t have access.")
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "<i>User upgraded to Admin</i>")
					end
				elseif text:match("^(!Administrator) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "You don`t have access.")
					end
					if redis:sismember('botBOT-IDmod', matches) then
						redis:srem("botBOT-IDmod",matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "User upgraded to Administrator.")
					elseif redis:sismember('botBOT-IDadmin',matches) then
						return send(msg.chat_id_, msg.id_, 'User is Admin now.')
					else
						redis:sadd('botBOT-IDadmin', matches)
						redis:sadd('botBOT-IDadmin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "User promoted to Administrator.")
					end
				elseif text:match("^(!Del admin) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('botBOT-IDadmin', msg.sender_user_id_)
								redis:srem('botBOT-IDmod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "You aren`t Admin.")
						end
						return send(msg.chat_id_, msg.id_, "You don`t have access.")
					end
					if redis:sismember('botBOT-IDadmin', matches) then
						if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "You can not dismiss the administrator who has given you the position.")
						end
						redis:srem('botBOT-IDadmin', matches)
						redis:srem('botBOT-IDmod', matches)
						return send(msg.chat_id_, msg.id_, "User was dismissed from management.")
					end
					return send(msg.chat_id_, msg.id_, "The User not Admin.")
				elseif text:match("^(!RefreshBot)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>Bot`s info reloaded.</i>")
				elseif text:match("!Report") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 123654789,
						chat_id_ = 123654789,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^!Update$") then
					io.popen("git fetch --all && git reset --hard origin/persian && git pull origin persian && chmod +x bot"):read("*all")
					local text,ok = io.open("bot.lua",'r'):read('*a'):gsub("BOT%-ID",BOT-ID)
					io.open("bot-BOT-ID.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^!Shuffle sync$") then
					local botid = BOT-ID - 1
					redis:sunionstore("botBOT-IDall","tabchi:"..tostring(botid)..":all")
					redis:sunionstore("botBOT-IDusers","tabchi:"..tostring(botid)..":pvis")
					redis:sunionstore("botBOT-IDgroups","tabchi:"..tostring(botid)..":groups")
					redis:sunionstore("botBOT-IDsupergroups","tabchi:"..tostring(botid)..":channels")
					redis:sunionstore("botBOT-IDsavedlinks","tabchi:"..tostring(botid)..":savedlinks")
					return send(msg.chat_id_, msg.id_, "<b>Shuffle Sync bot  with number</b><code> "..tostring(botid).." </code><b>done.</b>")
				elseif text:match("^(!List) (.*)$") then
					local matches = text:match("^!List (.*)$")
					local naji
					if matches == "!Contact" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "Contact : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("botBOT-ID_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "botBOT-ID_contacts.txt"},
								caption_ = "Advertiser contact number BOT-ID"}
							}, dl_cb, nil)
							return io.popen("rm -rf botBOT-ID_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "!Auto reply" then
						local text = "<i>Auto reply list:</i>\n\n"
						local answers = redis:smembers("botBOT-IDanswerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("botBOT-IDanswers", v)) .. "\n"
						end
						if redis:scard('botBOT-IDanswerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "Block" then
						naji = "botBOT-IDblockedusers"
					elseif matches == "Private" then
						naji = "botBOT-IDusers"
					elseif matches == "Group" then
						naji = "botBOT-IDgroups"
					elseif matches == "Super GP" then
						naji = "botBOT-IDsupergroups"
					elseif matches == "Link" then
						naji = "botBOT-IDsavedlinks"
					elseif matches == "Admin" then
						naji = "botBOT-IDadmin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "List "..tostring(matches).." Advertiser number BOT-ID"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(!View state) (.*)$") then
					local matches = text:match("^!View state (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDmarkread", true)
						return send(msg.chat_id_, msg.id_, "<i>PM States >> Readed ✔️✔️\n</i><code>(Second tick active)</code>")
					elseif matches == "off" then
						redis:del("botBOT-IDmarkread")
						return send(msg.chat_id_, msg.id_, "<i>PM States >> Not Readed ✔️\n</i><code>(With no second tick)</code>")
					end 
				elseif text:match("^(!Add PM) (.*)$") then
					local matches = text:match("^Add With Number (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>Add contact message active</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddmsg")
						return send(msg.chat_id_, msg.id_, "<i>Add contact message deactive</i>")
					end
				elseif text:match("^(!Add number) (.*)$") then
					local matches = text:match("!Add number (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDaddcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>Send number when contact add is enabled</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDaddcontact")
						return send(msg.chat_id_, msg.id_, "<i>Send number when contact add is disabled</i>")
					end
				elseif text:match("^(!Set add contact PM) (.*)") then
					local matches = text:match("^!Set add contact PM (.*)")
					redis:set("botBOT-IDaddmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>Message Adding Registered Contact </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(!Set answer) "(.*)" (.*)') then
					local txt, answer = text:match('^Set answer "(.*)" (.*)')
					redis:hset("botBOT-IDanswers", txt, answer)
					redis:sadd("botBOT-IDanswerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>Answer for | </i>" .. tostring(txt) .. "<i> | set to :</i>\n" .. tostring(answer))
				elseif text:match("^(!Del answer) (.*)") then
					local matches = text:match("^Delete Answer (.*)")
					redis:hdel("botBOT-IDanswers", matches)
					redis:srem("botBOT-IDanswerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>Answer for | </i>" .. tostring(matches) .. "<i> | has been deleted from list.</i>")
				elseif text:match("^(!Auto reply) (.*)$") then
					local matches = text:match("^Auto reply (.*)$")
					if matches == "on" then
						redis:set("botBOT-IDautoanswer", true)
						return send(msg.chat_id_, 0, "<i>Advertiser auto reply enabled</i>")
					elseif matches == "off" then
						redis:del("botBOT-IDautoanswer")
						return send(msg.chat_id_, 0, "<i>Advertiser auto reply disabled.</i>")
					end
				elseif text:match("^(!Refresh)$")then
					local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					for i, v in pairs(list) do
							for a, b in pairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>Bot Reloadind </i><code> BOT-ID </code> SuccessfulLy Done!")
				elseif text:match("^(!Status)$") then
					local s = redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
					local ss = redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
					local msgadd = redis:get("botBOT-IDaddmsg") and "☑️" or "❎"
					local numadd = redis:get("botBOT-IDaddcontact") and "✅" or "❎"
					local txtadd = redis:get("botBOT-IDaddmsgtext") or  "Added! Start Private Chat"
					local autoanswer = redis:get("botBOT-IDautoanswer") and "✅" or "❎"
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local links = redis:scard("botBOT-IDsavedlinks")
					local txt = "<i>⚙️ Advertiser Runing States</i><code> BOT-ID </code>⛓\n\n" .. tostring(autoanswer) .."<code> Auto Reply Mode 🗣 </code>\n" .. tostring(numadd) .. "<code> Add Contact With Number 📞 </code>\n" .. tostring(msgadd) .. "<code> Add Contact With PM 🗞</code>\n〰〰〰ا〰〰〰\n<code>📄 Add Contact Message :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n<code>📁 Saved Link : </code><b>" .. tostring(links) .. "</b>\n<code>⏲	Link Waiting To Join: </code><b>" .. tostring(glinks) .. "</b>\n🕖   <b>" .. tostring(s) .. " </b><code>Second To Re_Join</code>\n<code>❄️ Links Waiting To Be Confirmed : </code><b>" .. tostring(wlinks) .. "</b>\n🕑️   <b>" .. tostring(ss) .. " </b><code>Second To Re_Confirm Link</code>"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(!Statistic)$") or text:match("^(!Statistic)$") then
					local gps = redis:scard("botBOT-IDgroups")
					local sgps = redis:scard("botBOT-IDsupergroups")
					local usrs = redis:scard("botBOT-IDusers")
					local links = redis:scard("botBOT-IDsavedlinks")
					local glinks = redis:scard("botBOT-IDgoodlinks")
					local wlinks = redis:scard("botBOT-IDwaitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("botBOT-IDcontacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("botBOT-IDcontacts")
					local text = [[
<i>📈 Status & Statistic 📊</i>
          
<code>👤 Private Chat: </code>
<b>]] .. tostring(usrs) .. [[</b>
<code>👥 Groups : </code>
<b>]] .. tostring(gps) .. [[</b>
<code>🌐 Super Groups : </code>
<b>]] .. tostring(sgps) .. [[</b>
<code>📖 Saved Contacts : </code>
<b>]] .. tostring(contacts)..[[</b>
<code>📂 Saved Links : </code>
<b>]] .. tostring(links)..[[</b>
]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(!Send to) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^!Send to (.*)$")
					local naji
					if matches:match("^(all)$") then
						naji = "botBOT-IDall"
					elseif matches:match("^(private)") then
						naji = "botBOT-IDusers"
					elseif matches:match("^(group)$") then
						naji = "botBOT-IDgroups"
					elseif matches:match("^(super gp)$") then
						naji = "botBOT-IDsupergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "<i>SuccessfulLy Sent!</i>")
				elseif text:match("^(!Send to sgp) (.*)") then
					local matches = text:match("^!Send to sgp (.*)")
					local dir = redis:smembers("botBOT-IDsupergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    			return send(msg.chat_id_, msg.id_, "<i>SuccessfulLy Sent!</i>")
				elseif text:match("^(!Block) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>User blocked.</i>")
				elseif text:match("^(!Unblock) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("botBOT-IDblockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>User Un_Blocked.</i>")	
				elseif text:match('^(!Set name) "(.*)" (.*)') then
					local fname, lname = text:match('^!Set name "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>New Name SuccessfulLy Set.</i>")
				elseif text:match("^(!Set username) (.*)") then
					local matches = text:match("^!Set username (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>Trying To Set UserName...</i>')
				elseif text:match("^(!Del username)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>SuccessfulLy Deleted.</i>')
				elseif text:match('^(!Send) "(.*)" (.*)') then
					local id, txt = text:match('^!Send "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>Sent.</i>")
				elseif text:match("^(!Say) (.*)") then
					local matches = text:match("^!Say (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(!My id)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(!Leave) (.*)$") then
					local matches = text:match("^!Leave (.*)$") 	
					send(msg.chat_id_, msg.id_, 'Advertiser Left The GP')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(!Add to all) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>User Added To All Of My Gp</i>")
				elseif (text:match("^(!Online)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(!Guide)$") then
					local txt = '📍Advertiser Guide📍\n\n!Online\n<i>!Status✔️</i>\n<code>❤️You Must Respond To This Message Even If Your Advertiser Has a Message Limitation❤️</code>\n/reload\n<i>l🔄Reload Bot🔄l</i>\n<code>I⛔️⛔️I</code>\n!Update\n<i> Update The Bot To The Latest Version And Reload🆕</i>\n\n!Admin\n<i>Add a New Admin With a Given ID 🛂</i>\n\n!Administrator\n<i>Add a New Administrator With a Given ID 🛂</i>\n\n<code>(⚠️The Difference Between The Admin & Administrator Is The Granting Of Access To Or Obtaining Of a Managerial Position⚠️)</code>\n\n!Del admin\n<i>Remove Admin Or Administrator Bu ID ✖️</i>\n\n!Leave\n<i>Leave From GP & Delete Info 🏃</i>\n\n!Add contact\n<i>Add Max Contacts & People In Your Private Chat To The Group ➕</i>\n\n!My id\n<i>Get Your ID 🆔</i>\n\n!Say\n<i>Get Text🗣</i>\n\n!Send\n<i>Send The Text To The Given Group Or User ID📤</i>\n\n!Set name\n<i>Set Bot`s Name✏️</i>\n\n!RefreshBot\n<i>Refresh Bot`s Info🎈</i>\n<code>(Used In Cases Such As Setting The Name To Update The Name Of The Advertiser`s Contact)</code>\n\n!Set username\n<i>Replacing The Name With The Current User Name (Limited In a Short Time) 🔄</i>\n\n!Del username\n<i>Delete UserName ❎</i>\n\n!Add number on|off\n<i>Change The Status Of The Subscription Number Of The Advertiser In The Answer To The Shared Number 🔖</i>\n\n!Add PM on|off\n<i>Change The Status Of The Message Sent In The Answer To The Shared Numberℹ️</i>\n\n!Set add contact PM\n<i>Set The Given Text As The Shared Number Answer📨</i>\n\n!Auto reply Block|Private|Group|Super GP|Link|Admin\n<i>Get a List Of Items In The Text File Or Message Format📄</i>\n\n!Block\n<i>Block User With ID From Private Chat 🚫</i>\n\n!Unblock\n<i>Unblock User With Given ID💢</i>\n\n!View state on|off 👁\n<i>Change The Status Of Viewing Messages By The Advertiser (Enable Or Disable The Second Tick)</i>\n\n!Statistic\n<i>Get Bot Statistic📊</i>\n\n!Status\n<i>Get Advertiser Status⚙️</i>\n\n!Refresh\n<i>Refresh States🚀</i>\n<code>🎃Used Max Once a Day🎃</code>\n\n!Send to all|private|group|super gp\n<i>Send The Message To The Requested Items 📩</i>\n<code>(😄We Advise Not To Use All & Private😄)</code>\n\n!Send to sgp\n<i>Send To Super GP ✉️</i>\n<code>(We Recommend You Use & Integrate Commands & Send Them To The Dupport Team)</code>\n\n!Set answer\n<i>Responding To The Answer As An Auto Reply To The Message Entered In Accordance With The Text 📝</i>\n\nحذف جواب متن\n<i>حذف جواب مربوط به متن ✖️</i>\n\nAuto reply on|off\n<i>Change the auto-responder`s response status to the set text 📯</i>\n\n!Add to all\n<i>Add To Super Groups & Groups With ID ➕➕</i>\n\n!Leave ID\n<i>Leave With GP ID 🏃</i>\n\n!Guide\n<i>Get This Message 🆘</i>\n〰〰〰ا〰〰〰\n!Shuffle sync\n<code>Synchronize advertiser information with pre-installed shadow information 🔃</code>'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(!Leave ID)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(!Add contact)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("botBOT-IDusers"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "<i>Adding Contact To Gp ...</i>")
					end
				end
			end
			if redis:sismember("botBOT-IDanswerslist", text) then
				if redis:get("botBOT-IDautoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("botBOT-IDanswers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif msg.content_.ID == "MessageContact" then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("botBOT-IDaddedcontacts",id) then
				redis:sadd("botBOT-IDaddedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("botBOT-IDaddcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("botBOT-IDfname")
					local lnasme = redis:get("botBOT-IDlname") or ""
					local num = redis:get("botBOT-IDnum")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("botBOT-IDaddmsg") then
				local answer = redis:get("botBOT-IDaddmsgtext") or "Added! Start Private Chat."
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif msg.content_.ID == "MessageChatJoinByLink" and msg.sender_user_id_ == bot_id then
			return add(msg.chat_id_)
		elseif msg.content_.ID == "MessageChatAddMembers" then
			for i = 0, #msg.content_.members_ do
				if msg.content_.members_[i].id_ == bot_id then
					add(msg.chat_id_)
				end
			end
		elseif msg.content_.caption_ then
			return find_link(msg.content_.caption_)
		end
		if redis:get("botBOT-IDmarkread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
		tdcli_function ({
			ID = "GetChats",
			offset_order_ = 9223372036854775807,
			offset_chat_id_ = 0,
			limit_ = 20
		}, dl_cb, nil)
	end
end
