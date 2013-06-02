--[[

Copyright (c)2013  DrWhat

This program is part of a collection of works currently lacking a
decent title.  However, the idea is storage.  Storage that is
highly customizable, easily deployed, and modular.

This program is free software: you can redistribute it and/or modify
it any way you like.  However, please let me know if you do modify it
as I would appreciate ideas and feedback.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. In short,
don't blame me if your server blows up.

--]]

local itemTable = {}
local storageClusters = {}
local screens = {}
local myItems = {}

-- Config
screenw,screenh = term.getSize()
-- Config
local program = "Storage Sorter"
local version = "v1.1"
local author = "DrWhat"
local systemFrequency = "Default"
local systemSubfrequency = "A"

local systemConfig = { [0] = { systemFrequency = systemFrequency, systemSubfrequency = systemSubfrequency }  }

-- Functions
function saveTableToFile(table,name)
	local file = fs.open(name,"w")
	file.write(textutils.serialize(table))
	file.close()
end

function loadTableFromFile(name)
	if ( fs.exists(name) ~= true ) then
		return nil
	end
	local file = fs.open(name,"r")
	local data = file.readAll()
	file.close()
	return textutils.unserialize(data)
end

function printReverse(str, xpos, ypos)
	term.setCursorPos(xpos - (#str-1), ypos)
	term.write (str)
end

function printForward(str, xpos, ypos)
	term.setCursorPos(xpos, ypos)
	term.write (str)
end

function printCentered(str, ypos)
	term.setCursorPos(screenw/2 - #str/2, ypos)
	term.write(str)
end

function printRight(str, ypos)
	term.setCursorPos(screenw - #str, ypos)
	term.write(str)
end

function printLeft(str, ypos)
	term.setCursorPos(1, ypos)
	term.write(str)
end
-- Functions
-- function serlTable(table,name)
  -- --local file = fs.open(name,"w")
  -- --file.write(textutils.serialize(table))
	-- --file.close()
-- end

-- function loadTable(name)
	-- local file = fs.open(name,"r")
	-- local data = file.readAll()
	-- file.close()
	-- return textutils.unserialize(data)
-- end

 function makemsg(idfrom, idto, msgType, msg)
	local final = ""
	final = "HORACEV1A|" .. systemConfig[0].systemFrequency .. "::" .. systemConfig[0].systemSubfrequency .. "|" .. idfrom .. "|" .. idto .. "|" .. msgType .."|" .. msg
	return final
end



function explode(div,str)
    if (div=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
end

function processRestartCmd(idFrom)
	os.reboot()
end

function sendCmd( toid, cmd )
	--print( "Sending [ " .. #cmd .. "], to ID " .. toid )
	if (toid == 0) then
		rednet.broadcast(cmd)
		else
			rednet.send( toid, cmd )
	end
	
end

function processQueryCmd(idFrom)

	local b, s = locateSorter()
	
	if ( b == true ) then
		--print( "Querying storage" )
		local st = queryStorage( s )
		local sts = textutils.serialize(st)
		--print(st) 
		local msg = makemsg( os.getComputerID(), idFrom, "queryStorageResponse", sts )
		--rednet.broadcast(msg)
		sendCmd(tonumber(idFrom), msg)
		--print(s)
	end

end

function processQueryClusterListCmd(idFrom)
		-- local found
		-- local nestedStacks = {}
		--print("Received a processQueryClusterListCmd")
		-- --local st = queryStorage( s )
		for id,value in pairs(storageClusters) do
			if( os.clock() - value.lasttick > 300 ) then
				value.online = false
				else
					value.online = true
			end
		end
		local sts = textutils.serialize(storageClusters)
		-- --print(st) 
		local msg = makemsg( os.getComputerID(), idFrom, "queryClusterListResponse", sts )
		-- --rednet.broadcast(msg)
		sendCmd(tonumber(idFrom), msg)
		--print(msg)
		
		-- --for k,v in pairs(storageClusters) do
		-- --	local stacks = {}
			-- --table.insert(stacks, getStack(k, v.count, os.getComputerID()))
			-- --table.insert(nestedStacks, stacks)
		-- --end
		-- return nestedStacks 
end


function processQueryClustersResponse(idFrom, msg)
	--
	pushCluster(idFrom, msg)
	--print(msg)
end

function processDumpResponse(idFrom, msg)
	if( msg ~= nil ) then
		local cmdt = textutils.unserialize(msg)
		if( cmdt.result == true ) then
			clearItemsByComputerID(idFrom)
		end
	end
end
function clearItemsByComputerID(idFrom)
		
	for k,v in pairs(storageClusters) do
		if (v.computerID == idFrom) then
			--print(to_string(v.resources))
			for id, value in pairs(v.resources) do
				for x, y in pairs(value ) do
					popItem( y.uuid, 0, true ) 
				end
				
			end
			--found = true
			--storageClusters[computerid].lasttick = os.clock()
			--storageClusters[computerid].resources = resources
			--storageClusters[computerid].computerID = computerid
			--storageClusters[computerid].computerLabel = computerLabel
			--print("Found the entry for computer id " .. computerid .. ", computerLabel" .. computerLabel )--. ", adding ".. amt .. "total is now ".. myItems[itemuuid].count)
			
			return true
		end
	end
end
function dump()
		local found
		local dirs = { 0, 1, 2, 3, 4, 5 }
		local b, sort = locateSorter()
		local nestedStacks = {}
	
		for i, dir in ipairs(dirs) do
			local stacks = {}
			local t = nill
			local cont = true
			
			while ( cont == true ) do
				local b = peripheral.call(sort, "list", dir)
				p = peripheral.wrap(sort)
				if ( b ~= nill ) then
					if #to_string(b) == 0 then
						cont = false
					end
					redstone.setOutput("top", false)
					for uuid,count in pairs(b) do
						if ( count ~= 0 ) then
							local keep = pushItem(uuid, count)
								if ( keep == true ) then
									for i=1, count do
									   p.extract(dir,uuid,1,1)
									   if i%10 == 0 then
									--	 print("Processed " .. i .. " items.")
										 sleep(.1)
									   end
									end
								else
									for i=1, count do
									   p.extract(dir,uuid,0,1)
									   if i%10 == 0 then
									--	 print("Discarded " .. i .. " items.")
										 sleep(.1)
									   end
									end
								end
							else
								cont = false
						end
					end
					redstone.setOutput("top", true)
					else
						cont = false
				end
			end
		end
end

function processGetCmd(idFrom, ct, cmd)
	local b, s = locateSorter()
	local cmdt = textutils.unserialize(cmd)
	if ( b == false ) then
	 	local tb = {}
		tb.msg = "Error, no sorter found"
		tb.result = false
		local msg = makemsg( os.getComputerID(), idFrom, "response", to_string(tb) )
		sendCmd(idFrom, msg)	
		return false
	end	
		local tmp = queryStorage( s )
	if( #tmp == 0 or type(tmp) ~= "table" ) then
		local tb = {}
		tb.msg = "Error, no sorter found"
		tb.result = false
		local msg = makemsg( os.getComputerID(), idFrom, "response", to_string(tb) )
		sendCmd(idFrom, msg)	
		return false
	end

	for item = 1, #tmp do
		for key, value in pairs (tmp[item]) do
			if ( cmdt.uuid == value.uuid ) then
				local rb, rs = pushUIDOut(value.uuid, cmdt.amount, s)
				if ( rb == true ) then
					local tb = {}
					tb.msg = rs
					tb.result = true
					
					local msg = makemsg( os.getComputerID(), idFrom, "response", to_string(tb) )
					sendCmd(idFrom, msg)
					return true
					else
						local tb = {}
						tb.msg = rs
						tb.result = false
						local msg = makemsg( os.getComputerID(), idFrom, "response", to_string(tb) )
						sendCmd(idFrom, msg)
						return false
				end
			end -- if same uuid
		end -- for each item
	end -- for loop

	local tb = {}
	tb.msg = "Unable to service request, no item found matching UID " .. cmdt.uuid
	tb.result = false
	local msg = makemsg( os.getComputerID(), idFrom, "response", to_string(tb) )
	sendCmd(idFrom, msg)	
	return false
end
function processGetResponse(cmd)
	--print("command = " .. cmd)
	local tmp = textutils.unserialize(cmd )
	--print(to_string(tmp))
	if( tmp ~= nil ) then
		--print("popping " .. tmp.amount )
		if( tmp.amount == 0 ) then
			popItem( tmp.uuid, 0, true )
			else
				
				popItem( tmp.uuid, tmp.amount, false )
		end
		
	end
	
	--print(to_string(tmp))
	--currentResult = {}
	--currentResult.result = tmp.result
	--currentResult.msg = tmp.msg
	
end

function processCmd(idFrom, ct, cmd)
--for i,v in pairs(explode("|", ct)) do
--print (ct)
		if( ct:lower() == "querystorage" ) then
			--print( "Query received" )
			processQueryCmd(idFrom)
		end
		if( ct:lower() == "dumpresponse" ) then
			--print( "dumpresponse received" )
			processDumpResponse(idFrom, cmd)
		end
		if( ct:lower() == "querystorageclustersresponse" ) then
			--print( "Query received" )
			processQueryClustersResponse(idFrom, cmd)
		end
		if( ct:lower() == "queryclusterlist" ) then
			--print( "Query received" )
			processQueryClusterListCmd(idFrom)
		end
		if( ct:lower() == "restart" ) then
			--print("Restart received")
			sleep(5)
			processRestartCmd(idFrom);
		end
		if( ct:lower() == "getresponse" ) then
			--print("GetResponse received!")
			processGetResponse(cmd)
			--
			--sleep(5)
			--processRestartCmd(idFrom);
		end
	--end
end

function validateWeeblerMsg( msg )
	 --print("Validating message... ")
	 local m = 0
	 local ret = false
	 local cmd = nill
	 local cmdType = nill
	 local directedTo = 0
	 for i,v in pairs(explode("|", message)) do
		 if ( m == 0 ) then
			 if( v == "HORACEV1A" ) then
				-- print("WeeblerV1 message: TRUE")
				 else
					 return ret
			 end
		 end
		 if ( m == 1 ) then -- this is our frequency/subfrequency area
			local curFreq = systemConfig[0].systemFrequency .. "::" .. systemConfig[0].systemSubfrequency
			if( v:lower() == curFreq:lower() ) then
				else
					return ret -- fail
			end
		 end
		 if ( m == 2 ) then
			 --print( "Msg From: " .. v )
		 end
		 if ( m == 3 ) then
			if( tonumber(v) == os.getComputerID() ) then
				--print("Received a message to us! " .. msg)
				directedTo = tonumber(v)

			end
			 if ( v ~= "0" and tonumber(v) ~= os.getComputerID() ) then
				 --print( "Msg To: " .. v .. " which is not us, validation falied.")
				 --directedTo = tonumber(v)
				 return false
				 else
					 ret = true
					
			 end
		 end
		 if ( m == 4 ) then
			 --print( "CmdType: " .. v )
			 ctype = v
			 --cmd = v
			 --return ret, cmd
		 end
		 if ( m == 5 ) then
			 --print( "Command: " .. v )
			 cmd = v
			 return ret, ctype, cmd, directedTo
		 end
		 --print("[" .. i .. "] = " .. v)
		 m = m+1
	 end
	 return ret
 end
 
 function loadTable(str)
	--local file = fs.open(name,"r")
	--local data = file.readAll()
	--file.close()
	return textutils.unserialize(str)
end

function sendCmd( toid, cmd )
	if (toid == 0) then
		rednet.broadcast(cmd)
		else
			rednet.send( toid, cmd )
	end
	
end


function table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    local sb = {}
    for key, value in pairs (tt) do
      table.insert(sb, string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        table.insert(sb, "{\n");
        table.insert(sb, table_print (value, indent + 2, done))
        table.insert(sb, string.rep (" ", indent)) -- indent it
        table.insert(sb, "}\n");
      elseif "number" == type(key) then
        table.insert(sb, string.format("\"%s\"\n", tostring(value)))
      else
        table.insert(sb, string.format(
            "%s = \"%s\"\n", tostring (key), tostring(value)))
       end
    end
    return table.concat(sb)
  else
    return tt .. "\n"
  end
end

function to_string( tbl )
    if  "nil"       == type( tbl ) then
        return tostring(nil)
    elseif  "table" == type( tbl ) then
        return table_print(tbl)
    elseif  "string" == type( tbl ) then
        return tbl
    else
        return tostring(tbl)
    end
end


 -- Gets the Unique ID based on the ID and Meta
function getID(id, meta)
  if meta == nil then
    meta = 27268
  else
    meta = bit.bxor(meta, 0x6E6C)
  end
  local uuid = bit.bxor(id, 0x4F89) * 0x8000 + bit.bxor(meta, 0x3A69)
  return uuid
end

-- Get a stack table from a single uuid and amount
-- This does all the math to reverse the unique ID algorithm that RG wrote.
-- Valid for version 2.3
function getStack(uuid, c, pos)
        -- Reverse RG's fancy math
        local subt = bit.band(uuid, 0x7fff)
        local dexorm = bit.bxor(subt, 0x3a69)
        local metadata = nil
        if dexorm ~= 28262 then -- item takes dmg
                metadata = bit.bxor(dexorm, 0x6e6c)
        end
        local id = bit.bxor((uuid-subt)/0x8000, 0x4f89)
        -- put it in to a nice table
        local stack = {}
        stack.amount = c
        stack.id = id
        stack.meta = metadata
        stack.uuid = uuid
        stack.pos = pos

        return stack
end
 
-- Get stacks from an Interactive Sorter
-- direction   : the direction of the Interactive Sorter Peripheral
-- invDirection: the direction of the inventory from the peripheral
-- valid options for invDirection are 0,1,2,3,4,5 ( original values),
-- north, south, east, west, up, down, and the +/-X,Y,Z strings.
-- (see directions variable)
function getStacks(direction, invDirection)
		--print("getStacks, direction = " .. direction .. "invDirection = " .. invDirection )
        if not peripheral.isPresent(direction) then
				--print("No Peripheral")
                return false, "No Peripheral"
        end
		--print ("Type " .. peripheral.getType(direction))
        if peripheral.getType(direction) ~= "interactiveSorter" then
                return false, "Not a sorter"
        end
        local stacks = {}
       
        for uuid,count in pairs(peripheral.call(direction, "list", invDirection)) do-- directions[invDirection])) do
                table.insert(stacks, getStack(uuid, count, invDirection))
        end
        return true, stacks    
end

function transferContents(  dirSource, dirTarget )
		--local found
		--local dirs = { 0, 1, 2, 3, 4, 5 }
			local b, sort = locateSorter()
		--local nestedStacks = {}
		--for i, dir in ipairs(dirs) do
			local stacks = {}
			while true do
				local b = peripheral.call(sort, "list", dirSource)
				p = peripheral.wrap(sort)
				local t = nill
				if ( b ~= nill ) then
					for uuid,count in pairs(b) do
					--	curUUID = uuid
					--	totalItemCount = totalItemCount + count
						--print( "UID " .. uuid .. " Count = " .. count )
						p.extract(dirSource,uuid,dirTarget,count)
					end
				
				end
				sleep(5)
			end
			--
		--p = peripheral.wrap(sort)

		--end

end
function pushUIDOut( uid, amt, s )
		local found
		local dirs = { 0, 1, 2, 3, 4, 5 }
		local b, sort = locateSorter()
		local nestedStacks = {}
		for i, dir in ipairs(dirs) do
			local stacks = {}
			local t = nill
			
			local b = peripheral.call(sort, "list", dir)
			p = peripheral.wrap(sort)
			if ( b ~= nill ) then
				--print(to_string(peripheral.getMethods(sort)))
				local totalItemCount = 0
				local curUUID = nil
				
				for uuid,count in pairs(b) do
					curUUID = uuid
					totalItemCount = totalItemCount + count
					--print( "UID " .. uuid .. " Count = " .. count )
				end
				if ( uid == curUUID ) then
					if ( totalItemCount >= amt ) then
						p.extract(dir,uid,0,amt)
						return true, "Success. Extracting " .. amt .. " of " .. totalItemCount .. ", UUID=" .. uid
					end
					else
						return false, "Error. Unable to Extract " .. amt .. " of UUID " .. uid .. " failed because there is only " .. totalItemCount .. " remaining."
				end
				
			end
		end
		return false, "No quantity of UUID " .. uid .. " found."
end
function queryStorage(direction)

		local found
		local nestedStacks = {}
		for k,v in pairs(myItems) do
			local stacks = {}
			table.insert(stacks, getStack(k, v.count, os.getComputerID()))
			table.insert(nestedStacks, stacks)
		end
		return nestedStacks 
end


function locateSorter()

		local dirs = { "top", "bottom", "back", "front", "left", "right" }
		--local dirs = {0, 1, 2, 3, 4, 5}
		local found = {}
		for i, dir in ipairs(dirs) do
		  --print (name)
		  	if peripheral.isPresent(dir) and peripheral.getType(dir) == "interactiveSorter" then
				--print("Found a sorter peripheral. Location = " .. dir)
				--queryStorage(dir)
				return true, dir
			end
		end
		return false, "no sorter found"
end
function pushCluster( computerid, cmd )
	local tmp = textutils.unserialize(cmd)
	local resources = tmp.resources
	local computerLabel = tmp.computerLabel
	if( computerLabel == nil ) then 
		computerLabel = "Unknown"
	end
	if( storageClusters == nil ) then
		storageClusters = {}
	end
	local found = false
	for k,v in pairs(storageClusters) do
		if (k == computerid) then
			found = true
			storageClusters[computerid].lasttick = os.clock()
			storageClusters[computerid].resources = resources
			storageClusters[computerid].computerID = computerid
			storageClusters[computerid].computerLabel = computerLabel
			
			if( resources ~= nil and type(resources) == "table" ) then
				for item = 1, #resources do
					for key, value in pairs (resources[item]) do
					
						--print(value.uuid)
					--pushItem(value.uuid, value.amount)
						local found = false
						for i,x in pairs(myItems) do
							--print(key)
							if( value.uuid == x.uuid ) then found = true end
							if ( value.uuid == x.uuid and (x.count == 0 or x.count < value.amount)) then
								x.count = value.amount
								-- this is just a catchall that makes sure we include at least
								-- one stack from a barrel if it reports having it yet
								-- our sorter hasn't counted the items yet.
								break
							end
						end
						if ( found ~= true ) then
							pushItem(value.uuid, value.amount)
						end
					end
				end
			end
		
			--print("Found the entry for computer id " .. computerid .. ", computerLabel" .. computerLabel )--. ", adding ".. amt .. "total is now ".. myItems[itemuuid].count)
			
			return true
		end
	end
	if (found ~= true) then
		local newitem = {}
		newitem.computerID = computerid
		newitem.computerLabel = computerLabel
		newitem.resources = resources
		newitem.lasttick = os.clock()
		if( resources ~= nil and type(resources) == "table" ) then
			for item = 1, #resources do
				for key, value in pairs (resources[item]) do
					pushItem(value.uuid, value.amount)
				end
			end
		end
		
		table.insert(storageClusters, computerid, newitem) 
		--print("New index added for computer id " .. computerid)
		return true
	end
end

function pushItem( itemuuid, amt )
	local found = false
	for k,v in pairs(myItems) do
		if (k == itemuuid) then
			found = true
			if( myItems[itemuuid].count ~= nil and myItems[itemuuid].count >= myItems[itemuuid].maxcount ) then
				--print("Found the item type for " .. itemuuid .. ", but we have too many already, max = " .. myItems[itemuuid].maxcount .. " current count = " .. myItems[itemuuid].count)
				return false
			end
			myItems[itemuuid].count = myItems[itemuuid].count + amt
			--print("Found the item type for " .. itemuuid .. ", adding ".. amt .. " total is now ".. myItems[itemuuid].count)
			return true
		end
	end
	if (found ~= true) then
		local newitem = {}
		newitem.uuid = itemuuid;
		newitem.count = amt;
		newitem.maxcount = 65535
		table.insert(myItems, itemuuid, newitem) 
		--print("New index added for item type for " .. itemuuid .. ", adding ".. amt)
		return true
	end
end
function popItem( itemuuid, amt, override ) --I shouldn't call it pop, as it just decrements the count, but whatever.
	--local found = false
	for k,v in pairs(myItems) do
		if (k == itemuuid) then
			found = true
			--if( myItems[itemuuid].count ~= nil and myItems[itemuuid].count >= myItems[itemuuid].maxcount ) then
			--	print("Found the item type for " .. itemuuid .. ", but we have too many already, max = " .. myItems[itemuuid].maxcount .. " current count = " .. myItems[itemuuid].count)
			--	return false
			--end
			if ( override == true ) then
			-- this is a condition where we somehow got unsynced with the barell and nows its time to adjust the count
				myItems[itemuuid].count = amt
				else
				myItems[itemuuid].count = myItems[itemuuid].count - amt
				if ( myItems[itemuuid].count < 0 ) then
					myItems[itemuuid].count = 0 -- just to be safe!
				end
			end
			
			--print("Found the item type for " .. itemuuid .. ", adding ".. amt .. "total is now ".. myItems[itemuuid].count)
			return true
		end
	end
	-- if (found ~= true) then
		-- local newitem = {}
		-- newitem.uuid = itemuuid;
		-- newitem.count = amt;
		-- newitem.maxcount = 65535
		-- table.insert(myItems, itemuuid, newitem) 
		-- print("New index added for item type for " .. itemuuid .. ", adding ".. amt)
		-- return true
	-- end
end
-- Functions
function serlTable(table,name)
  local file = fs.open(name,"w")
	file.write(textutils.serialize(table))
	file.close()
end

function loadTable(name)
	if (fs.exists(name) ~= true) then
		return nil
	end
	local file = fs.open(name,"r")
	local data = file.readAll()
	file.close()
	return textutils.unserialize(data)
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

doSave = function()
	while (true) do
		if (myItems ~= nil ) then
			local tcount = tablelength(myItems)
			--print(tcount)
			if ( tcount > 0 ) then
				--print( "Saving " .. tcount .. " items." )
				serlTable(myItems, "stuff")
			end

		end
		if( storageClusters ~= nil ) then
						--
			tcount = tablelength(storageClusters)
			--print(tcount)
			if ( tcount > 0 ) then
				--print( "Saving " .. tcount .. " clusters." )
				serlTable(storageClusters, "storageClusters")
			end
		end
		
		sleep(5)
	end
end

doSorter = function()
		local b, sort = locateSorter()
		p = peripheral.wrap(sort)
		local count = 0
	while true do
		local sEvent, param, param2 = os.pullEvent("isort_item")
--		print("param "..param)
	--	print ("sevent ".. sEvent)
	--	print ("param2 " .. param2)
		count = count + param2
		local keep = pushItem(param, param2)
		--print(count)
		if ( keep == true ) then
			p.sort(1)
		else
			p.sort(0)
		end
		--data = m.list(1)
		--for j, k in pairs(data) do
		--  print(j.."  "..k)
		--  if j == param then
		    --print("Nalezena shoda")
		    --m.sort(1)
		--  end
	--	end
		--sleep(1)
	end

end


--rednet.open("right")
dumpLoop = function()
	while(true) do
		dump()
		sleep(1)
	end
end
mainLoop = function()
	print ("Storage Sorter process started")
	local _config = loadTableFromFile("systemConfig")
	if( _config == nil ) then
		saveTableToFile( systemConfig, "systemConfig" )
		else
		systemConfig = _config
	end
	local msg = makemsg( os.getComputerID(), 0, "queryStorageClusters", "" )
	sendCmd( 0, msg)
	while true do
		id, message  = rednet.receive(10)
		if id ~= nill then
			local b, c
			--print(message)
			b, ct, c = validateWeeblerMsg(message)
			if  (b == true ) then
				--print("Received a valid message, processing command: " .. message )
				--print("Received a message from " .. id)
			--	transferContents( 2, 1)
				redstone.setOutput("top", false)
				processCmd( id, ct, c)
				redstone.setOutput("top", true)
				else
					--print("Received an invalid message")
			end
		end
		
		--sleep(1)
	end
end



print("Starting...")
function initModem()
		local dirs = { "top", "bottom", "back", "front", "left", "right" }
		for i, dir in ipairs(dirs) do
		  	if peripheral.isPresent(dir) and peripheral.getType(dir) == "modem" then
				rednet.open(dir)
				--print("Found a modem on the " .. dir .. " side.")
				return true
			end
		end
		print("A modem must be attached for the storage interface application to function correctly.")
		return false
end
local modemInit = initModem()
if( modemInit ~= true ) then return end
myItems = loadTable("stuff")
storageClusters = loadTable("storageClusters")
if (myItems == nil ) then
	myItems = {}
end
if ( os.getComputerLabel() == nil or os.getComputerLabel == "" ) then
	os.setComputerLabel(tostring(os.getComputerID()))
end
redstone.setOutput("top", true)
parallel.waitForAll (doSave, mainLoop, dumpLoop)


