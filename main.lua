local sqlite3 = require("sqlite3")
local colors = require("ansicolors")
local db = require("db")

local params = {}

for i, v in ipairs(arg) do
    local key, value = v:match("([^=]+)=(.+)")
    if key and value then
        params[key] = value
    end
end

db.init()

local function list()
    local all_todos = db.fetch_all()
    for _, todo in ipairs(all_todos) do
        print(string.format("[%s] %s", todo.id, todo.title))
    end
end

local function add()
    local tmpfile = io.popen("mktemp"):read("*l")  -- Generate a temporary filename

    local success, reason, exitcode = os.execute("vim " .. tmpfile)

    local content = ""
    local file = io.open(tmpfile, "r")
    if file then
        content = file:read("*a")  -- Read all text
        file:close()
        os.remove(tmpfile)  -- Clean up the temp file
        db.save(content)
        print(colors("%{green}To-Do has been added."))
    else
        print(colors("%{red}Failed to adding new To-Do."))
    end
end

local function update(id)
    local todo = db.fetch_by_id(id)
    if not todo then
        print("Error: Todo not found.")
        return
    end

    -- Create a temporary file and write existing content to it
    local tmpfile = os.tmpname() .. ".txt"  -- Simple temp file (not secure)
    local file = io.open(tmpfile, "w")
    if not file then
        return false, "Failed to create temp file."
    end
    file:write(todo.title, todo.content)
    file:close()

    local success, reason, exitcode = os.execute("vim " .. tmpfile)

    -- Read the updated content (or original if user didn't save)
    local new_content = ""
    local file = io.open(tmpfile, "r")
    if file then
        new_content = file:read("*a")
        file:close()
        os.remove(tmpfile)  -- Clean up
        db.update(todo.id, new_content)

        print(colors("%{green}To-Do has been Updated"))
    else
        print(colors("%{red}To-Do has not been Updated"))
        return content
    end
end

local function delete(id)
    local success, err = db.delete(id)
    if success then
        print("Todo deleted successfully!")
    else
        print("Error deleting todo: " .. err)
    end
end

local function parse_input(input)
    local command, arg = input:match("^(%w+)%s*(%d*)$")
    return command, tonumber(arg)
end

local function main()
    io.write("Enter a command: ")
    local input = io.read("*l")
    local command, id = parse_input(input)

    if command == "list" then
        list()
    elseif command == "add" or command == "vim" and not id then
        add()
    elseif command == "update" or command == "edit" or command == "vim"  and id then
        update(id)
    elseif command == "delete" and id then
        delete(id)
    else
        print("Invalid command.")
    end
end

local commands =
colors("%{magenta}Welcome to the To-Do App!\n\n") ..
colors("%{white}Available commands:\n") ..
colors("%{cyan}- list       : List all To-Dos\n") ..
colors("%{yellow}- add        : Add a new To-Do\n") ..
colors("%{green}- update <id>  : Edit a specific To-Do (by ID)\n") ..
colors("%{red}- delete <id>: Delete a To-Do (by ID)\n")

print(commands)
while true do
    local success, err = pcall(main)
    if not success then
        print("\nTo-Do app has been shut down")

        if params["debug"] == "true" then
            print(err)
        end
        break
    end
end
