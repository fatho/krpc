local Client = {}
Client.__index = Client

local schema = require "krpc.schema.KRPC"
local encoder = require "krpc.encoder"
local decoder = require "krpc.decoder"

function Client:new(rpc_connection, stream_connection)
  return setmetatable({rpc_connection = rpc_connection, stream_connection = stream_connection}, Client)
end

function Client._send_request(self, request)
  local data = request:SerializeToString()
  local header = encoder.varint(data:len())
  self.rpc_connection:send(header .. data)
end

function Client._receive_response(self)
  local size = 0
  local data = ""
  while true do
    data = data .. self.rpc_connection:receive(1)
    local success, result = pcall(decoder.varint, data)
    if success then
      size = result
      break
    end
  end

  local data = ""
  while data:len() < size do
    data = data .. self.rpc_connection:receive(size - data:len())
  end

  local response = schema.Response()
  response:ParseFromString(data)
  return response
end

return Client