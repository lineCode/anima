
local plugin = require"anima.plugins.plugin"

local vert_shad = [[
in vec3 Position;
in vec2 texcoords;
void main()
{
	gl_TexCoord[0] = vec4(texcoords,0,1);
	gl_Position = vec4(Position,1);
}

]]
local frag_shad = [[

uniform sampler2D tex0;
uniform vec2 ini;
uniform float len;
uniform float param;
uniform bool bypass;
uniform bool oval;
uniform bool invert;
uniform bool AA;
void main()
{
	
	vec2 texsize = textureSize(tex0,0);
	//vec2 pos = vec2(gl_FragCoord.x/w,gl_FragCoord.y/h);
	vec2 pos = gl_FragCoord.xy/texsize;
	vec4 color = texture2D(tex0,pos);
	float alpha = 1.0;
	if(!bypass){
		if(oval){
			vec2 itopos = pos - ini;
			float radio = param;
			float dst = length(itopos);
			if(!AA){
				alpha = 1.0 - smoothstep(radio, radio + len, dst);
			}else{
				//float delta = fwidth(dst);
				float delta = length(vec2(dFdx(dst),dFdy(dst)));
				alpha = 1.0 - smoothstep(radio - delta, radio + delta + len, dst);
			}
		}else{
			vec2 itopos = pos - ini;
			float ang = param;
			vec2 itoend = vec2(cos(ang),sin(ang))*len;
			float proj = dot(itopos,itoend)/dot(itoend,itoend);
			alpha = clamp(proj,0.0,1.0);
		}
		if(invert)
			alpha = 1.0 - alpha;
	}
	
	gl_FragColor = vec4(color.xyz,color.a*alpha); 
}
]]


local M = {}

function M.make(GL,name)
	name = name or "gradient"

	local LM = plugin.new{res={GL.W,GL.H}}
	local fB --= plugin.serializer(LM)
	local presets = plugin.presets(LM)
	
	local NM = GL:Dialog(name or "gradient",
{
{"iniX",0,guitypes.dial},
{"iniY",0.2,guitypes.dial},
{"len",0.001,guitypes.drag,{min=0,max=1}},
{"param",0.5,guitypes.dial},
{"oval",false,guitypes.toggle},
{"invert",false,guitypes.toggle},
{"bypass",false,guitypes.toggle},
{"AA",false,guitypes.toggle},
},function() 		
		fB.draw()
		presets.draw()
	end)
	
	LM.NM = NM
	LM.load = function(self,pars) return LM.NM:SetValues(pars) end
	LM.save = function() return LM.NM:GetValues() end
	fB = plugin.serializer(LM)
	local programfx

	function LM.init()
		programfx = GLSL:new():compile(vert_shad,frag_shad)
		local m = mesh.quad(-1,-1,1,1)
		LM.vao = VAO({Position=m.points,texcoords = m.texcoords},programfx,m.indexes)
		LM.inited = true
	end
	
	function LM:process(srctex,w,h)

		srctex:Bind()
		
		programfx:use()
		programfx.unif.tex0:set{0}
		programfx.unif.ini:set{NM.iniX,NM.iniY}
		programfx.unif.len:set{NM.len}
		programfx.unif.param:set{NM.param}
		programfx.unif.bypass:set{NM.bypass}
		programfx.unif.oval:set{NM.oval}
		programfx.unif.invert:set{NM.invert}
		programfx.unif.AA:set{NM.AA}
		
		gl.glViewport(0,0,w or self.res[1], h or self.res[2])
		self.vao:draw_elm()

	end
	
	function LM:draw(t,w,h,args)
		if not self.fbo then self.fbo = GL:initFBO() end
		
		local clip = args.clip
		self.fbo:Bind()
		clip[1]:draw(t,w,h,clip)
		self.fbo:UnBind()
		local srctex = self.fbo:GetTexture()	
		local w,h = srctex.width,srctex.height
		
		srctex:Bind()
		
		programfx:use()
		programfx.unif.tex0:set{0}
		programfx.unif.ini:set{NM.iniX,NM.iniY}
		programfx.unif.len:set{NM.len}
		programfx.unif.param:set{NM.param}
		programfx.unif.bypass:set{NM.bypass}
		programfx.unif.oval:set{NM.oval}
		programfx.unif.invert:set{NM.invert}
		programfx.unif.AA:set{NM.AA}
		
		gl.glViewport(0,0,w,h)
		self.vao:draw_elm()
		--slab.pong:UnBind()
		--slab:swapt()
	end
	
	GL:add_plugin(LM,name)
	return LM
end

--[=[
require"anima"
GL = GLcanvas{H=700,aspect = 1.5}
mask = M.make(GL)
function GL:init()
	textura = Texture():Load[[C:\luaGL\media\juncos.tif]]
end
function GL.draw(t,w,h)
	gl.glClearColor(0,0,0,1)
	ut.Clear()
	gl.glEnable(glc.GL_BLEND)
	gl.glBlendFunc(glc.GL_SRC_ALPHA, glc.GL_ONE_MINUS_SRC_ALPHA)
	mask:draw(t,w,h,{clip={textura}})
	--textura:draw(t,w,h)
	gl.glDisable(glc.GL_BLEND)
end
GL:start()
--]=]

return M


