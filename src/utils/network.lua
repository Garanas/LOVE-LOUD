local ftp = require'socket.ftp' --https://lunarmodules.github.io/luasocket/ftp.html
local ltn12 = require'ltn12'
local feedback = love.thread.getChannel'log'
local writePath = love.filesystem.isFused() and 'SCFA/LOUD/' or ''

local network = {}

function network.ftpGet(path)
    local sink = {}
    local good, err = ftp.get{
        host    = 'ftp.theloudproject.org',
        path    = '/LOUD/'..(path:gsub('\\', '/')),
        sink    = ltn12.sink.table(sink),
        user    = 'ftploud',
        password= 'ftploud123',
        port    = 21,
    }
    if not good then return feedback:push((path or 'no path')..': '..(err or 'no error')) end
    return table.concat(sink)
end

local fileHanders = {
    ['LoudDataPath.lua'] = require'utils.files.LoudDataPath',
}

function network.ftpGetWrite(path)
    local folder = path:match'^([^/]*)':gsub('\\', '/')
    path = path:gsub('\\', '/')
    feedback:push{path, 'downloading'}
    local fileData = network.ftpGet(path)
    if fileData then
        love.filesystem.createDirectory(writePath..folder)
        feedback:push{path, 'writing'}
        local handler = fileHanders[path:match'([^/\\]*)$']
        love.filesystem.write(writePath..path, handler and handler(fileData) or fileData)
        feedback:push{path, 'done'}
    end
end

return network
