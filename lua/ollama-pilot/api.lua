M = {}
os = require('os')

M.git_url = function()
    local buf = io.popen('git remote show origin', 'r')
    local cmd_output = buf:read('*a')
    local fetch_url = get_fetch_url(cmd_output)
    assert(fetch_url)
    local https_fetch_url = format_url_to_https(fetch_url)
    os.execute(string.format('open %s', https_fetch_url))
end

function get_fetch_url(s)
    local lines = split(s, '\n')
    for i = 1, #lines do
        if string.match(lines[i], 'Fetch URL') then
            -- return lines[i]
            return string.sub(lines[i], 14)
        end
    end
    return nil
end

function split(s, delim)
    if delim == nil then
        delim = "%s"
    end
    local t = {}
    for str in string.gmatch(s, "([^" .. delim .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function format_url_to_https(s)
    if string.match(s, "git@github.com") then
        return 'https://github.com/' .. string.sub(s, 16)
    end
    return s
end

return M
