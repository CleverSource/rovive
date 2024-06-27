local RunService = game:GetService("RunService")
local shouldTraceback = RunService:IsStudio()

return function(...)
   if shouldTraceback then
      local callerName = debug.info(2, "s")
      local isServerOrClient = RunService:IsServer() and "server" or "client"
      warn(`[${callerName}][{isServerOrClient}]:`)
   end
   print(...)
end