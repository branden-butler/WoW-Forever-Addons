-- Exercise the actual minimap implementation with frame geometry mocks.
local f=assert(io.open("ProfessionBarsForever/ProfessionBarsForever.lua"))
local source=f:read("*a");f:close()
local start=assert(source:find("placeMinimapButton=function()",1,true))
local stop=assert(source:find("-- Diagnostic only: enumerate",start,true))
local frames={}
local function frame(parent)
 local t={parent=parent,scripts={},shown=true,scale=1}
 function t:SetSize(w,h) self.width=w;self.height=h end
 function t:SetScale(v) self.scale=v end
 function t:SetIgnoreParentScale(v) self.ignoreParent=v end
 function t:SetFrameStrata() end
 function t:SetFrameLevel() end
 function t:GetFrameLevel() return 1 end
 function t:RegisterForClicks() end
 function t:RegisterForDrag() end
 function t:SetScript(k,v) self.scripts[k]=v end
 function t:ClearAllPoints() self.point=nil end
 function t:SetPoint(...) self.point={...} end
 function t:SetTexture(v) self.texture=v end
 function t:CreateTexture() return frame(self) end
 function t:Hide() self.shown=false end
 function t:Show() self.shown=true end
 return t
end
local map=frame()
map.width=140;map.height=140;map.effectiveScale=1
function map:GetWidth() return self.width end
function map:GetHeight() return self.height end
function map:GetEffectiveScale() return self.effectiveScale end
function map:GetCenter() return 100,100 end
function map:HookScript(k,v) self.scripts[k]=v end
local cursorX,cursorY=0,0
local shape="ROUND"
local settingsClicks,finderClicks=0,0
local env=setmetatable({
 Minimap=map,PBFDB={minimapAngle=0,minimapHidden=false},
 GetMinimapShape=function() return shape end,
 GetCursorPosition=function() return cursorX,cursorY end,
 CreateFrame=function(_,_,parent) local t=frame(parent);frames[#frames+1]=t;return t end,
 toggleSettings=function() settingsClicks=settingsClicks+1 end,
 toggleRecipeFinder=function() finderClicks=finderClicks+1 end
},{__index=_G})
local chunk=assert(loadstring("local minimapButton\nlocal placeMinimapButton\n"..source:sub(start,stop-1).."\nreturn {create=createMinimapButton,place=placeMinimapButton,get=function() return minimapButton end}"))
setfenv(chunk,env)
local api=chunk();api.create()
local button=api.get()
local function near(a,b) assert(math.abs(a-b)<0.00001,tostring(a).." != "..tostring(b)) end
near(button.width,31);near(button.icon.width,19);near(button.border.width,53)
near(button.point[4],78);near(button.point[5],0)
assert(button.parent==map and button.scale==1 and button.ignoreParent==false)
-- Inherit map scale once, while keeping local geometry unchanged.
map.effectiveScale=2;api.place()
near(button.width,31)
near(button.width*map:GetEffectiveScale()*button.scale,62)
-- Resizing the frame resizes every visual element and the orbit.
map.width=280;map.height=280;map.scripts.OnSizeChanged()
near(button.width,62);near(button.icon.width,38);near(button.border.width,106)
near(button.point[4],156)
-- Rectangular maps use separate horizontal/vertical radii.
map.width=280;map.height=140;env.PBFDB.minimapAngle=90;api.place()
near(button.width,31);near(button.point[4],0);near(button.point[5],78)
-- The geometry watcher handles hidden buttons too.
env.PBFDB.minimapHidden=true;api.place();assert(not button.shown)
map.width=140;map.height=140
frames[2].scripts.OnUpdate(frames[2],0.5)
near(button.width,31)
env.PBFDB.minimapHidden=false;api.place();assert(button.shown)
-- Dragging uses the minimap's coordinate scale, not UIParent.
button.scripts.OnDragStart(button)
cursorX,cursorY=(100+78)*2,100*2
button.scripts.OnUpdate(button,0.01)
near(env.PBFDB.minimapAngle,0)
cursorX,cursorY=100*2,(100+78)*2
button.scripts.OnUpdate(button,0.01)
near(env.PBFDB.minimapAngle,90)
button.scripts.OnDragStop(button)
assert(not button.dragging)
button.scripts.OnClick(button,"LeftButton")
button.scripts.OnClick(button,"RightButton")
assert(settingsClicks==1 and finderClicks==1)
-- Square maps anchor at the square edge rather than the inscribed circle.
shape="SQUARE";env.PBFDB.minimapAngle=45;api.place()
near(button.point[4],78);near(button.point[5],78)
-- Persisted hidden state is respected when the UI is recreated after login.
env.PBFDB.minimapHidden=true;api.create();assert(not api.get().shown)
env.PBFDB.minimapHidden=false;api.place();assert(api.get().shown)
print("Minimap visibility, resizing, scale inheritance and drag-coordinate tests passed")
