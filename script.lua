local canvas = js.global.document:getElementById("myCanvas")
local ctx = canvas:getContext("2d")
local DEBUG = true

-- constants
local START_TIME = js.global.document.start_time

-- panel and settings constants
local DEFAULT_DIFFICULTY = "hard" -- options: easy, medium, hard, very-hard, impossible
local DEFAULT_GRID_SIZE = 12 -- default grid dimension if size not provided
local SPEEDS = {
	easy = 5,
	medium = 7,
	hard = 10,
	["very-hard"] = 15,
	impossible = 20,
}
local GRID_SIZES = { 10, 12, 15, 20 }
local SHOW_PANEL = true

-- dials to adjust (will be overridden based on URL parameters)
local CELL_PER_SECOND = 10
local CELL_DIMENTION = 12

-- current selected settings (populated in initializeGameSettings)

local currentDifficulty = DEFAULT_DIFFICULTY
local currentGridSize = DEFAULT_GRID_SIZE

local state = {
	last_frame_time = START_TIME,
	snake_cells = { { 5, 4 }, { 4, 4 }, { 3, 4 }, { 2, 4 } },
	new_cell_entry_time = START_TIME,
	direction = "left",
	next_direction = nil,
	food = nil, -- Will store [x, y] position of food
	score = 0,
	game_over = false,
}
local latest_event = nil -- nil | "up" | "down" | "right" | "left"

-- Utility: Get URL parameters
local function getUrlParams()
	local search = js.global.window.location.search
	local params = {}

	if search:sub(1, 1) == "?" then
		search = search:sub(2)
	end

	for param in search:gmatch("([^&]+)") do
		local key, value = param:match("([^=]+)=?(.*)")
		params[key] = value
	end

	return params
end

-- Initialize game settings based on URL parameters
local function initializeGameSettings()
	local params = getUrlParams()

	-- Set panel visibility (if silent=1 then hide panel)
	SHOW_PANEL = params.silent ~= "1"

	-- Set difficulty (affects snake speed)
	currentDifficulty = params.difficulty or DEFAULT_DIFFICULTY
	CELL_PER_SECOND = SPEEDS[currentDifficulty] or SPEEDS[DEFAULT_DIFFICULTY]

	-- Set grid size
	currentGridSize = tonumber(params.size) or DEFAULT_GRID_SIZE

	CELL_DIMENTION = currentGridSize
end

-- Generate food at a random position that's not occupied by the snake

function generateFood()
	local valid = false
	local x, y

	while not valid do
		valid = true
		x = math.floor(math.random(0, CELL_DIMENTION - 1))
		y = math.floor(math.random(0, CELL_DIMENTION - 1))

		-- Check if position conflicts with any snake cell
		for _, cell in ipairs(state.snake_cells) do
			if cell[1] == x and cell[2] == y then
				valid = false

				break
			end
		end
	end

	state.food = { x, y }
end

-- Check if snake collides with itself

function checkSelfCollision()
	local head = state.snake_cells[#state.snake_cells]

	-- Check collision with any other body part
	for i = 1, #state.snake_cells - 1 do
		if head[1] == state.snake_cells[i][1] and head[2] == state.snake_cells[i][2] then
			return true
		end
	end

	return false
end

local function update_new_cell()
	local last_two_cells = {
		state.snake_cells[#state.snake_cells - 1],
		state.snake_cells[#state.snake_cells],
	}
	local diffX = last_two_cells[2][1] - last_two_cells[1][1]
	local diffY = last_two_cells[2][2] - last_two_cells[1][2]
	local direction = state.direction

	local new_cell = (function()
		if direction == "down" then
			local new_x = last_two_cells[2][1]
			local new_y = (function()
				if last_two_cells[2][2] == CELL_DIMENTION - 1 then
					return 0
				else
					return last_two_cells[2][2] + 1
				end
			end)()

			return { new_x, new_y }
		elseif direction == "up" then
			local new_x = last_two_cells[2][1]

			local new_y = (function()
				if last_two_cells[2][2] == 0 then
					return CELL_DIMENTION - 1
				else
					return last_two_cells[2][2] - 1
				end
			end)()
			return { new_x, new_y }
		elseif direction == "right" then
			local new_x = (function()
				if last_two_cells[2][1] == CELL_DIMENTION - 1 then
					return 0
				else
					return last_two_cells[2][1] + 1
				end
			end)()

			local new_y = last_two_cells[2][2]
			return { new_x, new_y }
		elseif direction == "left" then
			jsPrint(last_two_cells)
			local new_x = (function()
				if last_two_cells[2][1] == 0 then
					return CELL_DIMENTION - 1
				else
					return last_two_cells[2][1] - 1
				end
			end)()
			local new_y = last_two_cells[2][2]
			jsPrint(new_x)
			return { new_x, new_y }
		end
	end)()

	table.insert(state.snake_cells, new_cell)

	-- Check if snake eats food
	if state.food and new_cell[1] == state.food[1] and new_cell[2] == state.food[2] then
		state.score = state.score + 1
		generateFood()
	else
		-- Remove tail cell (snake only grows when eating food)
		table.remove(state.snake_cells, 1)
	end

	-- Check for self collision
	if checkSelfCollision() then
		state.game_over = true
	end

	state.new_cell_entry_time = js.global.document:get_time()
end

function gameLoopCore()
	-- Generate initial food if not exists

	if state.food == nil then
		generateFood()
	end

	local current_time = js.global.document:get_time()
	local transition_ended = (current_time - state.new_cell_entry_time) / 1000 >= (1 / CELL_PER_SECOND)

	if transition_ended and not state.game_over then
		if state.next_direction ~= nil then
			state.direction = state.next_direction

			state.next_direction = nil
		end
		update_new_cell()
	end

	renderGrid()
	renderFood()
	renderSnake()

	-- Render panel on top of game
	renderPanel()

	if state.game_over then
		renderGameOver()
	end
end

function renderFood()
	if state.food then
		-- Higher contrast gray for food
		ctx.fillStyle = "#BDBDBD"
		ctx:fillRect(gridStartX + (state.food[1] * boxSize), gridStartY + (state.food[2] * boxSize), boxSize, boxSize)

		-- Draw black X at the center

		ctx.strokeStyle = "#000000"
		ctx.lineWidth = 2

		local x = gridStartX + (state.food[1] * boxSize)

		local y = gridStartY + (state.food[2] * boxSize)
		local padding = boxSize * 0.2 -- 20% padding for X

		ctx:beginPath()
		ctx:moveTo(x + padding, y + padding)
		ctx:lineTo(x + boxSize - padding, y + boxSize - padding)

		ctx:stroke()

		ctx:beginPath()
		ctx:moveTo(x + boxSize - padding, y + padding)
		ctx:lineTo(x + padding, y + boxSize - padding)
		ctx:stroke()
	end
end

function renderGameOver()
	-- Dim overlay
	ctx.fillStyle = "rgba(0, 0, 0, 0.7)"
	ctx:fillRect(0, 0, canvas.width, canvas.height)

	-- Game over text
	ctx.fillStyle = "#FFFFFF"
	ctx.font = "30px monospace"

	ctx.textAlign = "center"

	local centerX = canvas.width / 2
	local centerY = canvas.height / 2

	ctx:fillText("GAME OVER", centerX, centerY - 20)

	ctx:fillText("SCORE " .. state.score, centerX, centerY + 20)

	ctx.font = "16px monospace"
	ctx:fillText("Press SPACE to restart", centerX, centerY + 60)
end

local function gameLoop()
	ctx:clearRect(0, 0, canvas.width, canvas.height)
	gameLoopCore()
	js.global:setInterval(gameLoopCore, 10) -- 10ms interval
end

function renderSnake()
	-- Render middle cells
	for cell_index = 2, #state.snake_cells - 1 do
		local startingX = state.snake_cells[cell_index][1]
		local startingY = state.snake_cells[cell_index][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(gridStartX + (startingX * boxSize), gridStartY + (startingY * boxSize), boxSize, boxSize)
	end

	-- Render animated cells
	local time_now = js.global.document:get_time()
	local time_gone = (time_now - state.new_cell_entry_time) / 1000

	fraction_gone = time_gone / (1 / CELL_PER_SECOND)

	renderAnimatedHead()
	renderAnimatedTail()
end

function renderAnimatedTail()
	local tail_direction = (function()
		local first_cell = state.snake_cells[1]
		local second_cell = state.snake_cells[2]
		local diffX = second_cell[1] - first_cell[1]
		local diffY = second_cell[2] - first_cell[2]

		if diffX == 1 then
			return "right"
		elseif diffX == -1 then
			return "left"
		elseif diffY == 1 then
			return "down"
		elseif diffY == -1 then
			return "up"
		end
	end)()

	if tail_direction == "right" then
		local startingX = state.snake_cells[1][1]
		local startingY = state.snake_cells[1][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(
			gridStartX + ((startingX + fraction_gone) * boxSize),
			gridStartY + (startingY * boxSize),
			boxSize * (1 - fraction_gone),
			boxSize
		)
	elseif tail_direction == "down" then
		local startingX = state.snake_cells[1][1]
		local startingY = state.snake_cells[1][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(
			gridStartX + (startingX * boxSize),
			gridStartY + ((startingY + fraction_gone) * boxSize),
			boxSize,
			boxSize * (1 - fraction_gone)
		)
	elseif tail_direction == "left" then
		local startingX = state.snake_cells[1][1]
		local startingY = state.snake_cells[1][2]
		ctx.fillStyle = "#E0E0E0"

		ctx:fillRect(
			gridStartX + (startingX * boxSize),
			gridStartY + (startingY * boxSize),
			boxSize * (1 - fraction_gone),
			boxSize
		)
	elseif tail_direction == "up" then
		local startingX = state.snake_cells[1][1]
		local startingY = state.snake_cells[1][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(
			gridStartX + (startingX * boxSize),
			gridStartY + (startingY * boxSize),
			boxSize,
			boxSize * (1 - fraction_gone)
		)
	end
end

function renderAnimatedHead()
	if state.direction == "right" then
		local startingX = state.snake_cells[#state.snake_cells][1]
		local startingY = state.snake_cells[#state.snake_cells][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(
			gridStartX + (startingX * boxSize),
			gridStartY + (startingY * boxSize),
			boxSize * fraction_gone,
			boxSize
		)
	elseif state.direction == "down" then
		local startingX = state.snake_cells[#state.snake_cells][1]
		local startingY = state.snake_cells[#state.snake_cells][2]
		ctx.fillStyle = "#E0E0E0"

		ctx:fillRect(
			gridStartX + (startingX * boxSize),
			gridStartY + (startingY * boxSize),
			boxSize,
			boxSize * fraction_gone
		)
	elseif state.direction == "left" then
		local startingX = state.snake_cells[#state.snake_cells][1]
		local startingY = state.snake_cells[#state.snake_cells][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(
			gridStartX + ((startingX + 1 - fraction_gone) * boxSize),
			gridStartY + (startingY * boxSize),
			boxSize * fraction_gone,
			boxSize
		)
	elseif state.direction == "up" then
		local startingX = state.snake_cells[#state.snake_cells][1]

		local startingY = state.snake_cells[#state.snake_cells][2]
		ctx.fillStyle = "#E0E0E0"
		ctx:fillRect(
			gridStartX + (startingX * boxSize),
			gridStartY + ((startingY + 1 - fraction_gone) * boxSize),
			boxSize,
			boxSize * fraction_gone
		)
	end
end

function resizeCanvas()
	local canvas = js.global.document:getElementById("myCanvas")
	canvas.width = js.global.window.innerWidth
	canvas.height = js.global.window.innerHeight
end

function drawBorder()
	ctx.strokeStyle = "#555555"
	ctx.lineWidth = 15
	ctx:strokeRect(0, 0, canvas.width, canvas.height)
end

-- Render the panel with score and buttons for difficulty and grid size.
-- The current options will be highlighted.
function renderPanel()
	if not SHOW_PANEL then
		return
	end

	-- Panel background
	ctx.fillStyle = "rgba(51, 51, 51, 0.9)"
	ctx:fillRect(10, 10, 200, 422.5)

	-- Score display
	ctx.fillStyle = "#FFFFFF"
	ctx.font = "20px monospace"

	ctx:fillText("Score: " .. state.score, 20, 40)

	-- Difficulty buttons
	local difficulties = { "easy", "medium", "hard", "very-hard", "impossible" }
	for i, diff in ipairs(difficulties) do
		local y = 70 + (i - 1) * 40
		-- If this difficulty is the current one, use a highlight color.
		local bgColor = (diff == currentDifficulty) and "#888888" or "#444444"
		ctx.fillStyle = bgColor
		ctx:fillRect(20, y, 180, 30)
		ctx.fillStyle = "#FFFFFF"
		ctx.font = "16px monospace"
		ctx:fillText(diff, 30, y + 20)
	end

	-- Grid size buttons
	for i, size in ipairs(GRID_SIZES) do
		local y = 270 + (i - 1) * 40
		local bgColor = (size == currentGridSize) and "#888888" or "#444444"
		ctx.fillStyle = bgColor
		ctx:fillRect(20, y, 180, 30)
		ctx.fillStyle = "#FFFFFF"
		ctx.font = "16px monospace"
		ctx:fillText(size .. "x" .. size, 30, y + 20)
	end
end

-- Handle clicks on the panel buttons
function handlePanelClick(x, y)
	if not SHOW_PANEL then
		return
	end

	if x < 10 or x > 210 or y < 10 or y > 410 then
		return
	end

	-- Get existing query parameters.
	local params = getUrlParams()

	local updated = false

	-- Check Difficulty buttons (starting at y = 70)
	local difficulties = { "easy", "medium", "hard", "very-hard", "impossible" }
	for i, diff in ipairs(difficulties) do
		local buttonY = 70 + (i - 1) * 40
		if y >= buttonY and y <= buttonY + 30 then
			params["difficulty"] = diff
			updated = true
			break
		end
	end

	-- Check Grid size buttons (starting at y = 270)
	if not updated then
		for i, size in ipairs(GRID_SIZES) do
			local buttonY = 270 + (i - 1) * 40
			if y >= buttonY and y <= buttonY + 30 then
				params["size"] = tostring(size)
				updated = true

				break
			end
		end
	end

	if updated then
		local queryParts = {}
		for k, v in pairs(params) do
			table.insert(queryParts, k .. "=" .. v)
		end

		local newQuery = table.concat(queryParts, "&")
		local newUrl = js.global.window.location.pathname
		if newQuery ~= "" then
			newUrl = newUrl .. "?" .. newQuery
		end
		js.global.window.location.href = newUrl
	end
end

function main()
	initializeGameSettings()

	js.global.window:addEventListener("resize", function()
		resizeCanvas()
		renderGrid()
	end)

	js.global.document:addEventListener("keydown", function(document, event)
		if state.game_over and event.key == " " then
			state = {
				last_frame_time = js.global.document:get_time(),
				snake_cells = { { 5, 4 }, { 4, 4 }, { 3, 4 }, { 2, 4 } },

				new_cell_entry_time = js.global.document:get_time(),
				direction = "left",
				next_direction = nil,
				food = nil,
				score = 0,

				game_over = false,
			}
			generateFood()
		end

		if not state.game_over and state.next_direction == nil then
			if event.key == "ArrowDown" or event.key == "s" then
				if state.direction ~= "up" then
					state.next_direction = "down"
				end
			elseif event.key == "ArrowRight" or event.key == "d" then
				if state.direction ~= "left" then
					state.next_direction = "right"
				end
			elseif event.key == "ArrowLeft" or event.key == "a" then
				if state.direction ~= "right" then
					state.next_direction = "left"
				end
			elseif event.key == "ArrowUp" or event.key == "w" then
				if state.direction ~= "down" then
					state.next_direction = "up"
				end
			end
		end
		jsPrint("[KEY_EVENT] got key" .. event.key)
	end)

	canvas:addEventListener("click", function(_, event)
		local rect = canvas:getBoundingClientRect()
		local x = event.clientX - rect.left
		local y = event.clientY - rect.top
		handlePanelClick(x, y)
	end)

	resizeCanvas()
	renderGrid()
	math.randomseed(os.time())
	generateFood()
	gameLoop()
end

function renderGrid()
	local constraint = math.min(js.global.window.innerWidth, js.global.window.innerHeight)

	gridStartX = (js.global.window.innerWidth / 2) - (constraint / 2)
	gridStartY = (js.global.window.innerHeight / 2) - (constraint / 2)

	local endingX = gridStartX + constraint

	local endingY = gridStartY + constraint

	boxSize = (endingY - gridStartY) / CELL_DIMENTION

	ctx.fillStyle = "black"
	ctx:fillRect(0, 0, js.global.window.innerWidth, js.global.window.innerHeight)
	ctx.fillStyle = "#333333"
	ctx:fillRect(gridStartX, gridStartY, constraint, constraint)

	ctx.lineWidth = 1
	for x = 0, CELL_DIMENTION - 1 do
		for y = 0, CELL_DIMENTION - 1 do
			local xIsOdd = (x % 2) == 1
			local yIsOdd = (y % 2) == 1
			local parityIsSimilar = (xIsOdd == yIsOdd)
			ctx.fillStyle = parityIsSimilar and "#2A2A2A" or "#333333"
			ctx:fillRect(gridStartX + (x * boxSize), gridStartY + (y * boxSize), boxSize, boxSize)
		end
	end
end

function drawBox(color, startX, startY)
	ctx.fillStyle = color
	ctx:fillRect(0, 0, startX + 300, 100)
end

function jsPrint(val)
	js.global.console:log(val)
end
function jsDebug(val)
	if DEBUG then
		js.global.console:log(val)
	end
end
function stringify(tbl, indent)
	indent = indent or ""
	local str = "{\n"
	local next_indent = indent .. "  "
	local first = true

	local is_array = true
	local max_index = 0

	for k, _ in pairs(tbl) do
		if type(k) ~= "number" or k < 1 or k % 1 ~= 0 then
			is_array = false
			break
		end
		if k > max_index then
			max_index = k
		end
	end
	if is_array then
		for i = 1, max_index do
			if tbl[i] == nil then
				is_array = false
				break
			end
		end
		if max_index == 0 and next(tbl) ~= nil then
			is_array = false
		end
	end

	if is_array then
		str = "[\n"
		for i = 1, #tbl do
			if not first then
				str = str .. ",\n"
			end

			str = str .. next_indent
			local value = tbl[i]
			local value_type = type(value)
			if value_type == "table" then
				str = str .. stringify(value, next_indent)
			elseif value_type == "string" then
				str = str .. '"' .. value .. '"'
			elseif value_type == "number" or value_type == "boolean" then
				str = str .. tostring(value)
			else
				str = str .. '"' .. tostring(value) .. '"'
			end
			first = false
		end

		str = str .. "\n" .. indent .. "]"
	else
		str = "{\n"
		for key, value in pairs(tbl) do
			if not first then
				str = str .. ",\n"
			end
			str = str .. next_indent
			if type(key) == "string" then
				str = str .. '"' .. key .. '": '
			else
				str = str .. "[" .. tostring(key) .. "]: "
			end

			local value_type = type(value)
			if value_type == "table" then
				str = str .. stringify(value, next_indent)
			elseif value_type == "string" then
				str = str .. '"' .. value .. '"'
			elseif value_type == "number" or value_type == "boolean" then
				str = str .. tostring(value)
			else
				str = str .. '"' .. tostring(value) .. '"'
			end
			first = false
		end
		str = str .. "\n" .. indent .. "}"
	end

	return str
end

js.global.console:log("Lua script loaded.")
