-- Copied to Mechanic sandbox by `just bootstrap` (upstream generate omits this file).
local suite = { name = "root", tests = {}, suites = {} }
local stack = { suite }
local results = { passed = 0, failed = 0, failures = {} }

local function current()
	return stack[#stack]
end

function describe(name, fn)
	local block = { name = name, tests = {}, suites = {} }
	table.insert(current().suites, block)
	table.insert(stack, block)
	fn()
	table.remove(stack)
end

function it(name, fn)
	table.insert(current().tests, { name = name, fn = fn })
end

local assert = {}

function assert.equals(expected, actual)
	if expected ~= actual then
		error(string.format("expected %s, got %s", tostring(expected), tostring(actual)), 2)
	end
end

function assert.same(expected, actual)
	if type(expected) ~= "table" or type(actual) ~= "table" then
		return assert.equals(expected, actual)
	end
	for k, v in pairs(expected) do
		if actual[k] ~= v then
			error("tables differ at key " .. tostring(k), 2)
		end
	end
	for k in pairs(actual) do
		if expected[k] == nil then
			error("unexpected key " .. tostring(k), 2)
		end
	end
end

function assert.is_true(value)
	if value ~= true then
		error("expected true, got " .. tostring(value), 2)
	end
end

function assert.is_false(value)
	if value ~= false then
		error("expected false, got " .. tostring(value), 2)
	end
end

function assert.is_nil(value)
	if value ~= nil then
		error("expected nil, got " .. tostring(value), 2)
	end
end

function assert.is_not_nil(value)
	if value == nil then
		error("expected non-nil value", 2)
	end
end

_G.assert = assert

local function run_block(block, prefix)
	local name = prefix .. block.name
	for i = 1, #block.tests do
		local test = block.tests[i]
		local full = name .. " > " .. test.name
		local ok, err = pcall(test.fn)
		if ok then
			results.passed = results.passed + 1
			print("PASS: " .. full)
		else
			results.failed = results.failed + 1
			table.insert(results.failures, { name = full, err = err })
			print("FAIL: " .. full .. " | " .. tostring(err))
		end
	end
	for i = 1, #block.suites do
		run_block(block.suites[i], name .. " > ")
	end
end

function _SANDBOX_AUTO_RUN()
	run_block(suite, "")
	local total = results.passed + results.failed
	print(string.format("SANDBOX_TESTS:%d:%d:%d", results.passed, results.failed, total))
	if results.failed > 0 then
		os.exit(1)
	end
end
