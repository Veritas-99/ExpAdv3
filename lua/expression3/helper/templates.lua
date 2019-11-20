if SERVER then return; end

/*********************************************************************************
	Make our signatures look pretty
*********************************************************************************/

function EXPR_DOCS.PrettyPerams(perams)
	local r = {};

	for k, v in pairs(string.Explode(",", perams)) do
		if v[1] == "_" then v = v:sub(2); end
		r[k] = v:upper();
	end

	return table.concat(r,",");
end

local prettyPerams = EXPR_DOCS.PrettyPerams;

local prettyReturns = function(op)
	local rt = op["result type"] or "";

	--if rt then rt = prettyPerams(rt); end

	local rc = tonumber(op["result count"]) or 0;

	if rc == 0 or rt == "" or rt == "NIL" then return "" end

	local typ = EXPR_LIB.GetClass(rt);

	if typ then rt = typ.name; end

	if rc == 1 then return rt end

	return string.format("%s *%i", rt, rc);
end

function EXPR_DOCS.PrettyFunction(op)
	return string.format("%s.%s(%s)", op.library, op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyConstructor(op)
	return string.format("new %s(%s)", op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyMethod(op)
	local id = op.id:upper();

	if id[1] == "_" then id = id:sub(2); end

	return string.format("%s.%s(%s)", id, op.name, prettyPerams(op.parameter));
end

function EXPR_DOCS.PrettyReturn(op)
	local t = op["result type"];
	local c = tonumber(op["result count"]) or 0;
	
	if (not t) or (t == "") or (t == "_nil") or (c == 0) then return ""; end

	if t[1] == "_" then t = t:sub(2); end

	if c == 1 then return t:upper(); end

	return string.format("(%s x %d)", t:upper(), c);
end

/*********************************************************************************
	HTML Template Sheet
*********************************************************************************/
local pre_html = [[
	<html>
		<body>

			<style>
				body {background-color: #000; color: #FFF}
				table {width: 100%}
			</style>

			<table>		
]];

local post_html = [[
			</table>
		<body>
	</html>
]];

EXPR_DOCS.toHTML = function(tbl)

	local lines = {pre_html};

	for k, v in pairs(tbl) do
		
		if istable(v) then
			local str = string.format("<td>%s</td>\n<td>%s</td>", tostring(v[1] or ""), tostring(v[2] or ""));
			lines[#lines + 1] = string.format("<tr>%s</tr>", str);
		else
			local str = string.format("<td colspan=\"2\">%s</td>", tostring(v or ""));
			lines[#lines + 1] = string.format("<tr>%s</tr>", str);
		end

	end

	lines[#lines + 1] = post_html;

	return table.concat(lines, "\n"), #tbl;

end

/*********************************************************************************
	Add library nodes to the helper
*********************************************************************************/
local function describe(str)
	if str and str ~= "" then return str; end
	return "No helper data avalible.";
end

local function state(n)
	if n == EXPR_SERVER then return "[SERVER]"; end
	if n == EXPR_CLIENT then return "[CLIENT]"; end
	return "[SERVER] [CLIENT]";
end

local function stateIcon(node, n)
	if n == EXPR_SERVER then node:SetIcon("fugue/state-server.png") end
	if n == EXPR_CLIENT then node:SetIcon("fugue/state-client.png") end
	return node:SetIcon("fugue/state-shared.png");
end

hook.Add("Expression3.LoadHelperNodes", "Expression3.LibraryHelpers", function(pnl)
	
	local libdocs = EXPR_DOCS.GetLibraryDocs();

	libdocs:ForEach( function(i, keyvalues)

		local node = pnl:AddNode("Libraries", keyvalues.name);

		pnl:AddHTMLCallback(node, function()
			local keyvalues = libdocs:ToKV(libdocs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Library", keyvalues.name},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, libdocs;
		end);

	end );


	local fundocs = EXPR_DOCS.GetFunctionDocs();

	fundocs:ForEach( function(i, keyvalues)
		local signature = EXPR_DOCS.PrettyFunction(keyvalues);
		local result = EXPR_DOCS.PrettyReturn(keyvalues);
		
		local node = pnl:AddNode("Libraries", keyvalues.library, signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = fundocs:ToKV(fundocs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Function:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, fundocs;
		end);

	end );

end);

/*********************************************************************************
	Add class nodes to the helper
*********************************************************************************/
hook.Add("Expression3.LoadHelperNodes", "Expression3.ClassHelpers", function(pnl)
	local lk = {};

	local type_docs = EXPR_DOCS.GetTypeDocs();

	type_docs:ForEach( function(i, keyvalues)

		if not lk[keyvalues.id] then
			
			lk[keyvalues.id] = keyvalues.name;

			local node = pnl:AddNode("Classes", keyvalues.name);

			pnl:AddHTMLCallback(node, function()
				local keyvalues = type_docs:ToKV(type_docs.data[i]);

				return EXPR_DOCS.toHTML({
					{"Class:", string.format("%s (%s)", keyvalues.name, EXPR_DOCS.PrettyPerams(keyvalues.id))},
					{"Extends:", string.format("%s", lk[keyvalues.extends] or "")},
					keyvalues.example,
					describe(keyvalues.desc),
				});
			end);

			pnl:AddOptionsMenu(node, function()
				return keyvalues, type_docs;
			end);

		end

	end );

	local const_docs = EXPR_DOCS.GetConstructorDocs();

	const_docs:ForEach( function(i, keyvalues)

		local signature = EXPR_DOCS.PrettyConstructor(keyvalues);

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Constructors", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function()
			local keyvalues = const_docs:ToKV(const_docs.data[i]);

			keyvalues["result type"] = keyvalues.id;
			keyvalues["result count"] = 1;

			return EXPR_DOCS.toHTML({
				{"Constructor:", string.format("new %s(%s)", keyvalues.name, prettyPerams(keyvalues.parameter))},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, const_docs;
		end);

	end );

	local attr_docs = EXPR_DOCS.GetAttributeDocs();

	attr_docs:ForEach( function(i, keyvalues)

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Attributes", keyvalues.name);

		pnl:AddHTMLCallback(node, function()
			local keyvalues = attr_docs:ToKV(attr_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Atribute:", string.format("%s.%s", lk[keyvalues.id], keyvalues.name)},
				{"Type:", lk[keyvalues.type]},
				keyvalues.example,
				describe(keyvalues.desc),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, attr_docs;
		end);

	end );

	local method_docs = EXPR_DOCS.GetMethodDocs();

	method_docs:ForEach( function(i, keyvalues)

		local signature = EXPR_DOCS.PrettyMethod(keyvalues);

		local node = pnl:AddNode("Classes", lk[keyvalues.id], "Methods", signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = method_docs:ToKV(method_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Method:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, method_docs;
		end);
	end );

end);

/*********************************************************************************
	Operators are a lot of work
*********************************************************************************/

local function prettyOp(op)
	local signature = op.signature;

	signature = signature:upper():Replace("_", "");

	local match1, match2 = string.match(signature, "^([A-Za-z]+)%(([A-Za-z0-9_,]+)%)$");

	if match1 then
		local args = string.Explode(",", match2);

		local c = #args;

		local token;

		    if match1 == "EQ"  then token = "==";
		elseif match1 == "NEQ" then token = "!=";
		elseif match1 == "LEG" then token = "<=";
		elseif match1 == "GEQ" then token = ">=";
		elseif match1 == "LTH" then token = "<";
		elseif match1 == "GTH" then token = ">";
		elseif match1 == "DIV" then token = "/";
		elseif match1 == "MUL" then token = "*"; 
		elseif match1 == "SUB" then token = "-"; 
		elseif match1 == "ADD" then token = "+"; 
		elseif match1 == "EXP" then token = "^";
		elseif match1 == "MOD" then token = "%";
		elseif match1 == "AND" then token = "&&";
		elseif match1 == "OR" then token = "||";
		elseif match1 == "BAND" then token = "&";
		elseif match1 == "BOR" then token = "|";
		elseif match1 == "BXOR" then token = "^^";
		elseif match1 == "BSHL" then token = "<<";
		elseif match1 == "BSHR" then token = ">>";
		end

		if token then
			if c == 2 then return string.format("%s %s %s", args[1], token, args[2]), token; end
		end



		if match1 == "SET" then
			local cls = args[3] or "CLS";
			if cls and cls == "CLS" then cls = "type"; end

			if c >= 3 then return string.format("%s[%s,%s] = %s", args[1], args[2], cls, args[4] or cls), "[]="; end
		end

		if match1 == "GET" then
			local cls = args[3] or "CLS";
			if cls and cls == "CLS" then cls = "type"; end

			if c >= 2 then return string.format("%s[%s,%s]", args[1], args[2], cls), "[]"; end
		end



		    if match1 == "IS" then token = "";
		elseif match1 == "NOT" then token = "!";
		elseif match1 == "LEN" then token = "#";
		elseif match1 == "NEG" then token = "-";
		end

		if token then
			if c == 1 then return string.format("%s%s", token, args[2]), token; end
		end



		if match1 == "TEN" then
			if c == 3 then return string.format("%s ? %s : %s", args[1], args[2], args[3]), "?"; end
		end



		if match1 == "ITOR" then
			if c == 1 then return string.format("foreach(type k; type v in %s) {}", args[1]), "foreach"; end
		end

	end



	match1, match2 = string.match(op.signature, "^%(([A-Za-z0-9_]+)%)([A-Za-z0-9_]+)$");

	if match1 and match2 then
		match2 = match2:upper():Replace("_", "");

		local class = EXPR_LIB.GetClass(match1);
		if class then match1 = class.name; end;

		return string.format("(%s) %s", match1, match2), "casting";
	end

	return signature, "misc";
end

/*********************************************************************************
	Add class nodes to the helper
*********************************************************************************/
hook.Add("Expression3.LoadHelperNodes", "Expression3.OperatorHelpers", function(pnl)
	local op_docs = EXPR_DOCS.GetOperatorDocs();

	op_docs:ForEach( function(i, keyvalues)

		local signature, class = prettyOp(keyvalues);

		local node = pnl:AddNode("Operators", class, signature);

		stateIcon(node, keyvalues.state);

		pnl:AddHTMLCallback(node, function() 
			local keyvalues = op_docs:ToKV(op_docs.data[i]);

			return EXPR_DOCS.toHTML({
				{"Operator:", signature},
				{"Returns:", prettyReturns(keyvalues)},
				keyvalues.example,
				describe(keyvalues.desc),
				state(keyvalues.state),
			});
		end);

		pnl:AddOptionsMenu(node, function()
			return keyvalues, op_docs;
		end);

	end);
end);

/*********************************************************************************
	Add example nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.Examples", function(pnl)

	local path = "lua/expression3/helper/examples/";

	local editor = Golem.GetInstance( );

	local files = file.Find(path .. "*.txt", "GAME");

	for i, filename in pairs( files ) do
		local node = pnl:AddNode("Examples", filename);
		
		node.DoClick = function()
			local sCode = file.Read(path .. filename, "GAME");
			return editor:NewTab("editor", sCode, path, filename);
		end;

		node:SetIcon("fugue/script-text.png");
	end

end);

/*********************************************************************************
	Add url nodes to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.Links", function(pnl)

	local function addLink(sName, sUrl, sIcon)
		local node = pnl:AddNode("Links", sName);

		node:SetIcon(sIcon or sIcon);

		node.DoClick = function()
			gui.OpenURL(sUrl);
		end;
	end

	addLink("Git Hub", "https://github.com/Rusketh/ExpAdv3", "e3_github.png");

	hook.Run("Expression3.LoadHelperLinks", addLink);

end);

/*********************************************************************************
	Add exported data files to the helper
*********************************************************************************/

hook.Add("Expression3.LoadHelperNodes", "Expression3.SavedHelpers", function(pnl)

	local path = "e3docs/saved/";

	local editor = Golem.GetInstance( );

	local files = file.Find(path .. "*.txt", "DATA");

	for i, filename in pairs( files ) do

		local node = pnl:AddNode("Custom Helpers", filename)

		node:SetIcon("fugue/xfn.png");

		node.DoClick = function()
			local ok, err = EXPR_DOCS.LoadCustomDocFile(path .. filename, "DATA");

			if ok then
				pnl:WriteLine(Color(255, 255, 255), "Loaded Custom Helpers ", Color(0, 255, 0), filename);
			else
				pnl:WriteLine(Color(255, 255, 255), "Error Loading Custom Helpers ", Color(0, 255, 0), filename);
				pnl:WriteLine(Color(255, 255, 255), "Error ", Color(0, 255, 0), err);
			end
		end;
	end

end);

/*********************************************************************************
	Add menu to golem
*********************************************************************************/
hook.Add( "Expression3.AddGolemTabTypes", "HelperTab", function(editor)
	editor:AddCustomTab(false, "helper", function( self )
		if self.Helper then
			self.pnlSideTabHolder:SetActiveTab( self.Helper.Tab )
			self.Helper.Panel:RequestFocus( )
			return self.Helper
		end

		local Panel = vgui.Create( "GOLEM_E3Helper" )
		local Sheet = self.pnlSideTabHolder:AddSheet( "", Panel, "fugue/question.png", function(pnl) self:CloseMenuTab( pnl:GetParent( ), true ) end )
		self.pnlSideTabHolder:SetActiveTab( Sheet.Tab )
		self.Helper = Sheet
		Sheet.Panel:RequestFocus( )

		return Sheet
	end, function( self )
		self.Helper = nil
	end );

	editor.tbRight:SetupButton( "Helper", "fugue/question.png", TOP, function( ) editor:NewMenuTab( "helper" ); end )
end );