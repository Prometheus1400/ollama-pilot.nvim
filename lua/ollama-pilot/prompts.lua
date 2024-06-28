M = {}

M.explain = function(text)
    return "Explain the following as succinct as possible:\n" .. text
end

M.autocomplete = function(above, current, below)
    return string.format(
    "ONLY COMPLETE THE LINE OR EXPRESSION WITH CODE AS YOUR RESPONSE.FAVOR BREVITY.DO NOT GENERATE THE TEXT ALREADY PRESENT IN THE LINE OR EXPRESSION YOU ARE COMPLETING.\ngiven this code above:\n%s\nand this code below:\n%s\nautocomplete this line or expression:\n%s", above, below,
        current)
end

return M
