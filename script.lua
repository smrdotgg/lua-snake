function draw()
	drawBox("red", 100, 100)
	-- print("Hello")
	-- js.global.console:log("draw called")
	local c = js.global.document:getElementById("myCanvas")
	local ctx = c:getContext("2d")
	ctx:moveTo(0, 0)
	ctx:lineTo(50, 100)
	ctx:stroke()
end

local BOX_WIDTH = 100
local BOX_HEIGHT = 100
function drawBox(color, startX, startY)
	local c = js.global.document:getElementById("myCanvas")
	local ctx = c:getContext("2d")
	ctx:fillStyle(color)
	ctx:fillRect(0, 0, 200, 100)
end

-- Function called by JavaScript
function handlePingFromJS(message)
	local outputDiv = js.global.document:getElementById("output")
	-- Append message to the output div

	outputDiv.innerHTML = outputDiv.innerHTML .. "<p>Lua received: " .. message .. "</p>"

	-- Also log to browser console via JS
	js.global.console:log("Lua received ping from YOYOYAJS:", message)
end

-- Function to send a ping to JavaScript

function sendPingToJS()
	local message = "Ping from Lua!"
	-- Call the global JavaScript function handlePingFromLua
	js.global:handlePingFromLua(message)
end

-- Optional: Initial message from Lua on load
js.global.console:log("Lua script loaded.")
--         <script>
-- var c = document.getElementById("myCanvas");
-- var ctx = c.getContext("2d");
-- ctx.moveTo(0, 0);
-- ctx.lineTo(200, 100);
-- ctx.stroke();
-- </script>
