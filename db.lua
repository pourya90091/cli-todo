local sqlite3 = require("lsqlite3")

local M = {}  -- Module table

local function get_db()
    local db, err = sqlite3.open("sqlite3.db")
    if not db then
        print("Database error:", err)
        return nil
    end
    return db
end

function M.init()
    local db = get_db()
    db:exec[[
      CREATE TABLE IF NOT EXISTS todos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ]]
    db:close()
end

function M.save(full_text)
    local db = get_db()

    -- Extract the first line as the title, and the rest as content
    local title, content = full_text:match("([^\n]*)\n?(.*)")
    if title == "" then
        return false, "Title cannot be empty"
    end

    -- Insert into the database
    local stmt = db:prepare("INSERT INTO todos (title, content) VALUES (?, ?)")
    if not stmt then
      db:close()
      return false, "Statement error"
    end
  
    stmt:bind_values(title, content)
    local result = stmt:step()
    stmt:finalize()
    db:close()
    
    return result == sqlite3.DONE
end

function M.fetch_by_id(id)
    local db = get_db()
    
    local stmt = db:prepare("SELECT * FROM todos WHERE id = ?")
    if not stmt then
        db:close()
        return false, "Statement preparation failed"
    end
    
    stmt:bind_values(id)
    local result = stmt:step()
    
    if result == sqlite3.ROW then
        local todo = {
            id = stmt:get_value(0),
            title = stmt:get_value(1),
            content = stmt:get_value(2),
            created_at = stmt:get_value(3)
        }

        stmt:finalize()
        db:close()
        return todo
    else
        stmt:finalize()
        db:close()
        return false, "Todo not found"
    end 

end

function M.update(id, full_text)
    local db = get_db()

    -- Extract the first line as the title, and the rest as content
    local title, content = full_text:match("([^\n]*)\n?(.*)")
    if title == "" then
        return false, "Title cannot be empty"
    end

    -- Prepare the SQL statement for updating
    local stmt = db:prepare("UPDATE todos SET title = ?, content = ? WHERE id = ?")
    if not stmt then
        db:close()
        return false, "Statement error"
    end

    stmt:bind_values(title, content, id)
    local result = stmt:step()

    -- Check if any rows were affected
    if db:changes() > 0 then
        stmt:finalize()
        db:close()
        return true
    else
        stmt:finalize()
        db:close()
        return false, "Todo not found or no changes made"
    end
end

function M.fetch_all()
    local db = get_db()

    local todos = {}
    for row in db:nrows("SELECT * FROM todos") do
        table.insert(todos, {
            id = row.id,
            title = row.title,
            content = row.content,
            created_at = row.created_at
        })
    end
    db:close()
    return todos
end

function M.delete(id)
    local db = get_db()

    local stmt = db:prepare("DELETE FROM todos WHERE id = ?")
    if not stmt then
        db:close()
        return false, "Statement preparation failed"
    end

    stmt:bind_values(id)
    local result = stmt:step()

    stmt:finalize()
    if result == sqlite3.DONE and db:changes() > 0 then
        return true

    else
        return false, "Todo not found"
    end 

    db:close()
end

return M
