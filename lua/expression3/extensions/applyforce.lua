local extension = EXPR_LIB.RegisterExtension("applyforce");

extension:SetSharedState();

--[[
	Fast Math access
]]

local abs = math.abs

--[[
	Apply Force methods
]]

local function applyangForce(ph, a)
	if a.p != 0 or a.y != 0 or a.r != 0 then

		local pos = ph:GetPos();

		local up = ph:LocalToWorld(Vector(0,0,1)) - pos;
		local left = ph:LocalToWorld(Vector(0,1,0)) - pos;
		local forward = ph:LocalToWorld(Vector(1,0,0)) - pos;

		if a.p ~= 0 then
			local pitch = up * (Angle.p * 0.5);
			ph:ApplyForceOffset( forward, pitch );
			ph:ApplyForceOffset( forward * -1, pitch * -1 );
		end

		if a.y ~= 0  then
			local yaw = forward * (Angle.y * 0.5);
			ph:ApplyForceOffset( left, yaw );
			ph:ApplyForceOffset( left * -1, yaw * -1 );
		end

		if a.r ~= 0 then
			local roll = left * (Angle.r * 0.5);
			ph:ApplyForceOffset( up, roll );
			ph:ApplyForceOffset( up * -1, roll * -1 );
		end
	end
end

local function applyTorque(ph, tq)
	if tq.x != 0 or tq.y != 0 or tq.z != 0 then
		
		local pos = ph:GetPos()
		local tqamount = tq:Length()

		tq = ph:LocalToWorld(tq) - pos

		local off
		if abs(tq.x) > tqamount * 0.1 or abs(tq.z) > tqamount * 0.1 then
			off = Vector(-tq.z, 0, tq.x)
		else
			off = Vector(-tq.y, tq.x, 0)
		end

		off = off:GetNormal() * tqamount * 0.5

		local dir = (tq:Cross(off)):GetNormal()

		ph:ApplyForceOffset(dir, off)
		ph:ApplyForceOffset(dir * -1, off * -1)
	end
end

extension:SetServerState();

extension:RegisterMethod("e", "applyForce", "v", "", 0, function(context, e, v)
	if context:CanUseEntity(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			ph:ApplyForceCenter(v);
		end
	end
end, false);

extension:RegisterMethod("e", "applyOffsetForce", "v", "", 0, function(context, e, v)
	if context:CanUseEntity(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			ph:ApplyForceOffset(v);
		end
	end
end, false);

extension:RegisterMethod("e", "applyAngForce", "a", "", 0, function(context, e, a)
	if context:CanUseEntity(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			applyangForce(ph, a);
		end
	end
end, false);

extension:RegisterMethod("ph", "applyForce", "v", "", 0, function(context, ph, v)
	if IsValid(ph) then
		local e = ph:GetEntity();

		if context:CanUseEntity(e) then
			ph:ApplyForceCenter(v);
		end
	end
end, false);

extension:RegisterMethod("ph", "applyOffsetForce", "v", "", 0, function(context, ph, v)
	if IsValid(ph) then
		local e = ph:GetEntity();

		if context:CanUseEntity(e) then
			ph:ApplyForceOffset(v);
		end
	end
end, false);

extension:RegisterMethod("ph", "applyAngForce", "a", "", 0, function(context, ph, a)
	if IsValid(ph) then
		local e = ph:GetEntity();

		if context:CanUseEntity(e) then
			applyangForce(ph, a);
		end
	end
end, false);

extension:RegisterMethod("e", "applyTorque", "v", "", 0, function(context, e, v) 
	if context:CanUseEntity(e) then
		local ph = e:GetPhysicsObject();

		if IsValid(ph) then
			applyTorque(ph, v);
		end
	end
end, false)


--[[
	End of extention.
]]


extension:EnableExtension();