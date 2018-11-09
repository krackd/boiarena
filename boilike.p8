pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- boilike
-- by florent montesano

-- global params
-- --------------------
-- dec means decrement
-- inc means increment
-- min/max are thresold values to stop inc/dec each wave
player_speed = 2
player_speed_inc = 2
player_speed_max = 16
tear_speed = player_speed+.5
tear_lifetime = 30
tear_div = .2        -- tear divergence ratio (mult to the player speed)
fire_delay = 10
fire_delay_dec = .25 -- increase fire rate each wave
fire_delay_min = 4   -- cannot shoot faster than that
spawn_delay = 200
spawn_delay_dec = 5   -- reduce spawn delay each wave
spawn_delay_min = 100 -- cannot faster than that
enemy_firedelay = 60
enemy_firedelay_dec = 4
enemy_firedelay_min = 20
enemy_hp = 2
enemy_hp_inc = .25 -- .25
enemy_hp_max = 6
heart_drop_chance = 16
max_enemies = 5
-- global variables
can_fire = true
score=0
next_spawn=0
debug = false
-- scene state:
--  "title screen"
--  "game"
scene = "title screen"

function _init()
	palt(0,false) -- draw black
	palt(11,true) -- blend green
	poke(0x5f2d,1) -- use mouse

 -- the map limit
 -- (workaround before procedural
 -- generation implementaiton)
 make_collider(0,16,127,15)  -- top
 make_collider(0,96,127,15)  -- bottom
 make_collider(0,31,15,65)   -- left
 make_collider(112,31,15,65) -- right
 -- some interactive objects
 make_rock(2*8+1,4*8)
 make_rock(12*8-1,10*8-1)
 
 plr = make_plr(7*8,7*8)
 
 -- spanw waves
 local canspawn = true
 co(interval(function() return spawn_delay end,function()
  spawn_wave()
  if (spawn_delay>spawn_delay_min) spawn_delay-=spawn_delay_dec
  if (fire_delay>fire_delay_min) fire_delay-=fire_delay_dec
  if (player_speed<player_speed_max) player_speed+=player_speed_inc
  if (enemy_firedelay<enemy_firedelay_min) enemy_firedelay-=enemy_firedelay_dec
  if (enemy_hp<enemy_hp_max) enemy_hp+=enemy_hp_inc
 end))
 spawn_wave() -- first wave
end

function spawn_wave()
 if plr.hp > 0 then
  local c = rnd(2)
  if (#enemies < max_enemies) make_fly(c>1 and 12*8-rnd(7*8) or 13*8,c>1 and 4*8 or 8*8-rnd(4*8),enemy_hp)
  if (#enemies < max_enemies) make_fly(c>1 and 3*8 or 3*8+rnd(7*8),c>1 and 10*8-rnd(4*8) or 11*8,enemy_hp)
 end
end

function _update()
	if scene == "title screen" then
		update_title_screen()
 elseif scene == "game" then
		update_game()
 end
end

function update_title_screen()
 if (btn(1,0) or btn(1,1) or btn(1,2) or btn(1,3)) scene = "game"
end

function update_game()
 foreach(sprites,updatesprite)
 foreach(actions,updateco)
 updatecollisions()
 next_spawn-=1
 if (next_spawn<0) next_spawn=spawn_delay
end

function updatesprite(s)
	if s.type == "player" then
		update_plr(s)
	elseif s.type == "bullet" then
	 s.x+=s.vx
 	s.y+=s.vy
 end
 -- update ai
	if s.ai and s.canai then
	 s:ai()
	 s.canai=false
		co(waitfor(4,function()
		 s.canai=true
	 end))
	end
	-- update anim
	if (s.anim) s:anim()
end

function update_plr(p)
 -- move
 dx=0
 dy=0
	if btn(0,1) then dx -= p.vx end
	if btn(1,1) then dx += p.vx end
	if btn(2,1) then dy -= p.vy end
	if btn(3,1) then dy += p.vy end
	p:move(dx,dy)
	-- fire
	update_fire(p)
end

function update_fire(p)
	if (not can_fire) return

	local m1 = mousebtn() == 1
	local mx = mousex()-plr.x-plr.h/2
	local my = mousey()-plr.y-plr.w/2

	local up =    mx<-my and mx>my
	local down =  mx>-my and mx<my
	local left =  mx<-my and mx<my
	local right = mx>-my and mx>my
	
	if btn(➡️) or (m1 and right) then
		make_tear(p.x+12,p.y+6,tear_speed,p.my*tear_div)
	elseif btn(⬅️) or (m1 and left) then 
		make_tear(p.x-4,p.y+6,-tear_speed,p.my*tear_div)
	elseif btn(⬆️) or (m1 and up) then
		make_tear(p.x+5,p.y-4,p.mx*tear_div,-tear_speed)
	elseif btn(⬇️) or (m1 and down) then
		make_tear(p.x+5,p.y+14,p.mx*tear_div,tear_speed)
	end

 local	fired = m1 or btn(⬆️) or btn(⬇️) or btn(⬅️) or btn(➡️)
	if fired then
		-- start cooldown
		can_fire = false
		co(waitfor(fire_delay,function()
	 	can_fire = true
		end))
	end
end

function _draw()
 cls()
 
 if scene == "title screen" then
		draw_game()
		draw_title_screen()
 elseif scene == "game" then
		draw_game()
 end
end

function draw_title_screen()
 print("move: e ,s ,d ,f",16,18,0)
 print("fire: ⬆️,⬇️,⬅️,➡️, mouse",16,24,0)
 print("move to start",38,75,0)
end

function draw_game()
 map(0,0,0,0,16,16) -- draw map
 draw_sprites()
 -- draw mouse cursor
 spr(0,mousex(),mousey())
 print("score: "..score,5,1,6)
 print("next wave: "..next_spawn,70,1,6)
 -- hearts
 hp:draw()
 
 if debug then
  foreach(sprites,draw_debug)
  print("actions: "..#actions,60,6,6)
  print("enemies: "..#enemies,60,12,6)
 end
 
 if plr.hp<=0 then
  print("game over",64-18,64-28,8)
  print("enter to restart",64-32,64-18,6)
 end
end

function draw_debug(s)
 if hascollider(s) then
 	rect(s.x+s.cx,s.y+s.cy,s.x+s.cx+s.cw,s.y+s.cy+s.ch,8)
 end
end

function draw_sprites()
	foreach(sprites, draw_sprite)
end

function draw_sprite(s)
	if (s.f!=0) spr(s.f,s.x,s.y,s.w/8,s.h/8)
end


-->8
-- procedural

-->8
-- factories

function make_sprite(t,x,y,f)
 local	s = {}
	s.x = x
	s.y = y
	s.w = 8 -- width
	s.h = 8 -- height
	s.f = f -- frame
	s.px = x -- previous position
	s.py = y -- previous position
	s.mx=0   -- latest movement x
	s.my=0   -- latest movement y
	s.ais = {}
	s.ondeads = {}
	s.type = t
	
	function s:move(dx,dy)
	 -- previous position
		self.px=self.x
		self.py=self.y
		-- movement
		self.mx=dx
		self.my=dy
		-- current position
		self.x+=dx
		self.y+=dy
	end
	
	function s:eject()
	 self.x=self.px
	 self.y=self.py
	end
	
	function s:ai()
		foreach(self.ais, function(f) f() end)
	end
	
	function s:ondead()
 	foreach(self.ondeads, function(f) f() end)
	end
	
	add(sprites,s)
	return s
end

function make_collider(x,y,w,h)
 local c = make_sprite("collider",x,y,0)
 c.w=w
 c.h=h
 add_collider(c,0,0,w,h)
end

function make_character(t,x,y,f,hpm,hp,bhp)
	local c = make_sprite(t,x,y,f)
	
	c.hpmax = hpm  -- total nb of red hearts
	c.hp = hp      -- full hearts
	c.bluehp = bhp -- nb of "blue" hearts
 c.canai=true
	
	function c:heal(a)
	 -- always heal red hearts
		self.hp += a
		-- normalize
		if self.hp>self.hpmax then self.hp=self.hpmax end
	end
	
	function c:hurt(a)
	 -- remove bluehp first
	 if self.bluehp > 0 then
	 	self.bluehp-=a
	 -- red one otherwise
		else
			self.hp-=a
		end
		-- normalize
		if (self.bluehp<0) self.bluehp=0
		if self.hp<=0 then
		 self.hp=0
		 if (self.ondead) self:ondead()
		end
	end
	
	return c
end

function make_plr(x,y)
	local plr = make_character("player",x,y,14,3,3,0)
	plr.w = 16  -- width
	plr.h = 16  -- height
	plr.vx = player_speed -- x speed
	plr.vy = player_speed -- y speed
	add_collider(plr,5,11,5,4)
	add_destroyondead(plr)
	
	return plr
end

function make_rock(x,y)
 local r = make_sprite("rock",x,y,64) -- 46
 r.w = 16
 r.h = 16
 add_collider(r,0,0,r.w,r.h)
 add(rocks,r)
	return r
end

function make_heart(x,y,destroy_delay)
	local h = make_sprite("heart",x,y,62)
	h.w=7
	h.h=7
	h.health = 1 -- give one health
 add_collider(h,0,0,h.w,h.h,true)
 
 function h:ontriggerenter(other)
	 if other.type == "player" and other.hp < other.hpmax then
	  other:heal(self.health)
	  destroy(self)
	 end
	end
	
	if (destroy_delay) destroyin(h,destroy_delay)
 
	add(hearts,h)
	return h
end

function make_enemy(x,y,f,hpm,hp,bhp)
 local e = make_character("enemy",x,y,f,hpm,hp,bhp)
 add(enemies,e)
 return e
end

function make_fly(x,y,hp)
	local f = make_enemy(x,y,64+flr(hp/2)*2,hp,hp,0)
	f.w=8
	f.h=8
	f.dmg = 1
 add_collider(f,0,0,f.w,f.h)
	add_destroyondead(f)
	add_addscoreondead(f)
	add_rndexecondead(f,1/heart_drop_chance,function() make_heart(f.x,f.y,spawn_delay) end)
 add_anim(f,0.3,f.f,f.f+1)
 add_movetoplrai(f)
 add_firetoplrai(f,enemy_firedelay)
	 
	add(enemies,h)
	return h
end

function make_tear(x,y,vx,vy)
 return make_bullet(x,y,6,6,vx,vy,47,"enemy",1)
end

function make_bdrop(x,y,vx,vy)
 return make_bullet(x,y,4,4,vx,vy,63,"player",1)
end

function make_bullet(x,y,w,h,vx,vy,f,enemy,dmg)
	local b = make_sprite("bullet",x,y,f)
	b.vx = vx
	b.vy = vy
	b.w = w
	b.h = h
	b.dmg = dmg -- damage dealt
	add_collider(b,0,0,b.w,b.h,true)
	
	function b:ontriggerenter(other)
	 if other.type == enemy then
	  other:hurt(self.dmg)
	 end
		if (not other.istrigger) destroy(self)
	end
	
	add(bullets,b)
 -- wait lifetime frames
 -- then destroy the tear
 destroyin(b,tear_lifetime)
	return b
end
-->8
-- events

function add_anim(s,speed,startf,endf)
 function s:anim()
	 self.f+=speed
	 if (self.f>endf+1) self.f=startf -- 67 - 66
	end
end

function add_movetoplrai(s)
 add(s.ais, function()
  local offset = { x=flr(rnd(4))-2, y=flr(rnd(4))-2 } -- -1..1 range
		local vplr = { x = plr.x, y = plr.y }
		local vself = { x = s.x, y = s.y }
		local v = v_addv(v_normalize(v_subv(vplr,vself)), offset)
		s:move(v.x,v.y)
	end)
end

function add_firetoplrai(s,delay)
 s.canfireai = false
 co(interval(delay,function()
  s.canfireai = true
 end,function()
  return s.hp > 0
 end))
 add(s.ais, function()
  if s.canfireai and plr.hp > 0 then
 		local vplr = { x = plr.x+plr.cx, y = plr.y+plr.cy }
 		local vself = { x = s.x, y = s.y }
 		local vdir = v_normalize(v_subv(vplr,vself))
 		local x = s.x+s.w/2+vdir.x*(s.w/2)
 		local y = s.y+s.h/2+vdir.y*(s.h/2)
   make_bdrop(x,y,vdir.x,vdir.y)
   s.canfireai = false
  end
	end)
end

function add_destroyondead(s)
 add(s.ondeads, function() destroy(s) end)
end

function add_addscoreondead(s)
 add(s.ondeads, function() score+=1 end)
end

function add_rndexecondead(s,rng,f)
 add(s.ondeads, function()
  if (rnd(rng)>rng/2) f()
 end)
end
-->8
-- physics

function add_collider(s,cx,cy,cw,ch,istrigger)
	s.cx=cx
	s.cy=cy
	s.cw=cw
	s.ch=ch
	s.istrigger = istrigger
end

function hascollider(s)
	return s.cx != nil
end

function updatecollisions()
	for a in all(sprites) do
		for b in all(sprites) do
		 local cancollide = hascollider(a) and hascollider(b)
			if a != b and cancollide then
				collide(a,b)
			end
		end
	end
end

function collide(a,b)
	local collide = iscolintersect(a,b) or iscolintersect(b,a)
	if collide then
	 if not a.istrigger and not b.istrigger then
		 -- back to previous pos
		 a:eject()
		 b:eject()
		end
	 -- call events
	 callphysicsevent(a,b)
	 callphysicsevent(b,a)
	end
end

function callphysicsevent(s,other)
 if s.istrigger then
 	if s.ontriggerenter then
			s:ontriggerenter(other)
		end
 elseif not other.istrigger then
		if s.oncollisionenter then
			s:oncollisionenter(other)
		end
	end
end

function iscolintersect(a,b)
 local cx=a.x+a.cx
 local cy=a.y+a.cy
	return    isincollider(cx					,cy					,b)
	       or isincollider(cx+a.cw,cy					,b)
        or isincollider(cx					,cy+a.ch,b)
        or isincollider(cx+a.cw,cy+a.ch,b)
end

function isincollider(px,py,s)
	local cx=s.x+s.cx
	local cy=s.y+s.cy
	return px>cx and px<cx+s.cw and py>cy and py<cy+s.ch
end
-->8
-- sets

-- game objects sets
plr = {}
sprites = {}
rocks = {}
hearts = {}
bullets = {}
enemies = {}

function destroy(s)
	del(sprites,s)
	if s.type == "bullet" then
		del(bullets,s)
	elseif s.type == "rock" then
 	del(rocks,s)
	elseif s.type == "heart" then
		del(hearts,s)
	elseif s.type == "enemy" then
		del(enemies,s)
	end
end
-->8
-- utils (inputs, co, vectors)

-- inputs
function mousex() return stat(32)-1 end
function mousey() return stat(33)-1 end
function mousebtn() return stat(34) end

-- coroutines
actions = {}
-- creates coroutines
-- and add it to actions
-- to perform
function co(f)
	local c = cocreate(f)
	add(actions,c)
end
-- update of coroutines
function updateco(c)
	-- perform action
	-- if coroutine is still alive
	if costatus(c) != "dead" then
		coresume(c)
	-- remove dead coroutines
	else
		del(actions,c)
	end
end

function waitfor(n,f)
	return function()
		for i=1,n do
			yield()
		end
		f()
	end
end

function interval(n,f,isalive)
	return function()
	 while not isalive or isalive() do
	  local m = type(n)=='function' and n() or n
 		for i=1,m do
 			yield()
 		end
 		f()
 	end
	end
end

function destroyin(s,delay)
 co(waitfor(delay,function()
	 destroy(s)
 end))
end


--methods for handling math between 2d vectors
-- vectors are tables with x,y variables inside

-- contributors: warrenm

-- add v1 to v2
function v_addv( v1, v2 )
  return { x = v1.x + v2.x, y = v1.y + v2.y }
end

-- subtract v2 from v1
function v_subv( v1, v2 )
  return { x = v1.x - v2.x, y = v1.y - v2.y }
end

-- multiply v by scalar n
function v_mults( v, n )
  return { x = v.x * n, y = v.y * n }
end

-- divide v by scalar n
function v_divs( v, n )
  return { x = v.x / n, y = v.y / n }
end

-- gets magnitude of v, squared (faster than v_mag)
function v_magsqr( v )
  return ( v.x * v.x ) + ( v.y * v.y )
end

-- compute magnitude of v
function v_mag( v )
  return sqrt( ( v.x * v.x ) + ( v.y * v.y ) )
end

-- normalizes v into a unit vector
function v_normalize( v )
  local len = v_mag( v )
  return { x = v.x / len, y = v.y / len }
end

-- computes dot product between v1 and v2
function v_dot( v1, v2 )
   return ( v1.x * v2.x ) + ( v1.y * v2.y )
end

-- computes the reflection vector between vector v and normal n
-- note : assumes v and n are normalized
function v_reflect( v, n )
  local dot = v_dot( v, n )
  local wdnv = v_mults( v_mults( n, dot ), 2.0 )
  local refv = v_subv( v, wdnv )
  return refv
end
-->8
-- ui

hp = {
 -- constants
	startx=4,
	starty=9,
	space=6,
	full_color=8,
	empty_color=5,
	blueh_color=13,
	-- state
	x=startx,
	y=starty
}

function hp:draw()
	--color(self.shadow_color)
	--self:reset(1,2)
	--self:draw_part(plr.hpmax)
	color(self.full_color)
	self:reset(0,0)
	self:draw_part(plr.hp)
	color(self.empty_color)
	self:draw_part(plr.hpmax-plr.hp)
	color(self.blueh_color)
	self:draw_part(plr.bluehp)
end

function hp:reset(x,y)
	self.x = self.startx+x
	self.y = self.starty+y
end
	
function hp:draw_part(length)
	for i=1,length do
  print("♥",self.x,self.y)
  self.x += self.space
 end
end

__gfx__
000bbbbb00000000000000000000000000000000000000000000000002222222222000000000000000000000000000000222222222222220bbbbbbbbbbbbbbbb
0bbbbbbb00dddddddddddddddddddddddddddd000dddddddddddddd00222220000022220dddddddddddddddddddddddd0222222222222220bbbbbbbbbbbbbbbb
0bbffbbb020dddddddddddddddddddddddddd0200d000000000000d00000002222220020dddddddddddddddddddddddd0220002220002220bbbbb000000bbbbb
bbf70fbb0220dddddddddddddddddddddddd02200d00dddddddd00d00222222000000020ddddddddddd000dd00000ddd0200000200000220bbbb0ffffff0bbbb
bbf00fbb02220dddddddddddddddddddddd022200dd0dddddddd0dd000000000ddddd020dddddddddd000000000000dd0000000000000220bbb0ffffffff0bbb
bbfccfbb022220dddddddddddddddddddd022220d0d0dddddddd0d0d0dddddddddddd020dddddddddd000000000000dd0000000000000220bb0ffffffffff0bb
bbfcfbbb0222220dddddddddddddddddd0222220d0d0dddddddd0d0d0dddddddddddd020dddddddddd0000000000000d0000000000002220bb0f70ffff70f0bb
bbbfbbbb02222220dddddddddddddddd02222220d0d0dddddddd0d0d0dddddddddddd020ddddddddddd000000000000d0000000000002220bb0f00ffff00f0bb
00000000555555550dddddddddddddd022222220d0d00dddddd00d0d0dddddddddddd020dddddddddddd0000000000dd0000000000000220bb0fcc0000ccf0bb
000000005555555520dddddddddddd0222222220d0dd0dddddd0dd0d0dddddddddddd020ddddddddddd0000000000ddd0000000000000220bbb0cf0000fc0bbb
0000000055555555220dddddddddd02222222220dd0d0dddddd0d0dd0dddddddddddd020dddddddddd000000000000dd0000000000000220bbbb0ffffff0bbbb
00000000555555552220dddddddd022222222220dd0d0dddddd0d0dd00000000ddddd020dddddddddd0000000000000d0000000000000220bbb0f000000f0bbb
000000005555555522220dddddd0222222222220dd0d0dddddd0d0dd0222222000000020dddddddddd0000000000000d0000000000000220bbb000ffff000bbb
0000000055555555222220dddd02222222222220dd0d0dddddd0d0dd0000002222220020ddddddddddd000000000000d0000002000002220bbbbb0ffff0bbbbb
00000000555555552222220dd022222222222220dd0d0dddddd0d0dd0222220000022220dddddddddddd0000000000dd0200022200222220bbbbb0f00f0bbbbb
0000000055555555222222200222222222222220000000000000000002222222222000000000000000000000000000000222222222222220bbbbb00bb00bbbbb
0000000002222222222222200222222222222220000000000000000000000222222222202222222000000000000000000222222222222220bbb000bbbb00bbbb
00000000022222222222220dd022222222222220dd0d0dddddd0d0dd022220000022222022222220dddd0000000000dd0222220022200020bb0ddd0bb0cc0bbb
0000000002222222222220dddd02222222222220dd0d0dddddd0d0dd020022222200000022222220ddd000000000000d0222000002000000bb0dd60b0c7cc0bb
000000000222222222220dddddd0222222222220dd0d0dddddd0d0dd020000000222222022222220dd0000000000000d0220000000000000b0ddddd00cccc0bb
00000000022222222220dddddddd022222222220dd0d0dddddd0d0dd020ddddd0000000022222220dd0000000000000d02200000000000000dd6ddd0b0cc0bbb
0000000002222222220dddddddddd02222222220dd0d0dddddd0d0dd020dddddddddddd022222220dd000000000000dd02200000000000000d66dd0bbb00bbbb
000000000222222220dddddddddddd0222222220d0dd0dddddd0dd0d020dddddddddddd022222220ddd0000000000ddd0220000000000000b0ddd0bbbbbbbbbb
00000000022222220dddddddddddddd022222220d0d00dddddd00d0d020dddddddddddd022222220dddd0000000000dd0220000000000000bb000bbbbbbbbbbb
000bbbbb02222220dddddddddddddddd02222220d0d0dddddddd0d0d020dddddddddddd002222222ddd000000000000d0222000000000000b00b00bbb00bbbbb
0bbbbbbb0222220dddddddddddddddddd0222220d0d0dddddddd0d0d020dddddddddddd002222222dd0000000000000d02220000000000000880880b0780bbbb
0bbffbbb022220dddddddddddddddddddd022220d0d0dddddddd0d0d020dddddddddddd002222222dd000000000000dd02200000000000000878880b0880bbbb
bbf70fbb02220dddddddddddddddddddddd022200dd0dddddddd0dd0020ddddd0000000002222222dd000000000000dd02200000000000000888880bb00bbbbb
bbf00fbb0220dddddddddddddddddddddddd02200d00dddddddd00d0020000000222222002222222ddd000dd00000ddd0220000020000020b08880bbbbbbbbbb
bbfccfbb020dddddddddddddddddddddddddd0200d000000000000d0020022222200000002222222dddddddddddddddd0222000222000220bb080bbbbbbbbbbb
bbfcfbbb00dddddddddddddddddddddddddddd000dddddddddddddd0022220000022222002222222dddddddddddddddd0222222222222220bbb0bbbbbbbbbbbb
bbbfbbbb0dddddddddddddddddddddddddddddd0000000000000000000000222222222200222222200000000000000000222222222222220bbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbb0bbbb0bbb0bb0bbb0bbbb0bbb0bb0bbb0bbbb0bbb0bb0bbb0bbbb0bbb0bb0bbb0b00b0bb008800bbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbb00000bbb0b0bb0b0b0b00b0b0b0bb0b0b0b00b0b0b0bb0b0b0b00b0b0b0bb0b0b0b00b0b0b0000b0b088880bbbbbbbbbbbbbbbbb0000000000000000
bbbbb000555550bb0b0bb0b0b0b00b0b0b0bb0b0b0b00b0b0b0000b0b0b88b0b0b0000b0b088880b00000000b888888bbbbbbbbbbbbbbbbb0000000000000000
bbbb0555ddddd50b0b0bb0b0bb0bb0bb0b0000b0bb0880bb0b0000b0bb8888bb00000000b888888b0007000088878888bbbbbbbbbbbbbbbb0000000000000000
bbbb05ddddddd550b007000bbbb78bbbb007000bbb8788bbb007000bb887888bb007000bb887888b0000000088888888bbbbbbbbbbbbbbbb0000000000000000
bbbb05ddddddd550bbb00bbbbbb88bbbbb0000bbbb8888bbb000000bb888888bb000000bb888888bb000000bb888888bbbbbbbbbbbbbbbbb0000000000000000
bbbb055ddd555550bbbbbbbbbbbbbbbbbbb00bbbbbb88bbbbb0000bbbb8888bbb000000bb888888bbb0000bbbb8888bbbbbbbbbbbbbbbbbb0000000000000000
bb00555555555550bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bbbbbb88bbbbb0000bbbb8888bbbbb00bbbbbb88bbbbbbbbbbbbbbbbbbb0000000000000000
b0555ddd55dd5550b0000bbbb0000bbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
055ddddd5dddd5500ffff0bb0ffff0bb0ffff0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0ffff0bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
05dddddd5dddd5500cffc0bb0cffc0bb0cffc0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0ffffff0bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
05ddddd55555550b0ffff0bb0ffff0bb0ffff0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0f0ff0f0bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
05ddddd55555550bb0000bbbb0000bbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0fcffcf0bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
055ddd55555550bb011110bb0111f0bb0f1110bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0ffffff0bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
b055555555500bbb0f11f0bb0f1110bb0111f0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0ffff0bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bb000000000bbbbbb0000bbbb0000bbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb011110bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb011110bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbf1111fbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb010010bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00bb00bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb55bb55bbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000
__label__
06600660066066606660000000006660000000000000000000000000000066006660606066600000606066606060666000000000660066606660000000000000
60006000606060606000060000006060000000000000000000000000000060606000606006000000606060606060600006000000060000600060000000000000
66606000606066006600000000006060000000000000000000000000000060606600060006000000606066606060660000000000060066600660000000000000
00606000606060606000060000006060000000000000000000000000000060606000606006000000666060606660600006000000060060000060000000000000
66000660660060606660000000006660000000000000000000000000000060606660606006000000666060600600666000000000666066606660000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000880880880880880880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888880888880888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000888880888880888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000088800088800088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000008000008000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd00
020dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd020
0220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0220
02220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd02220
022220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd022220
0222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0222220
02222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd02222220
022222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd022222220
0222222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0222222220
02222222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd02222222220
022222222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd022222222220
0222222222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd0222222222220
02222222222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd02222222222220
022222222222220dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd022222222222220
02222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555550000055555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555550005555505555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
0222222222222220555550555ddddd50555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555505ddddddd55055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555505ddddddd55055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
022222222222222055555055ddd55555055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205550055555555555055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
0222222222222220550555ddd55dd555055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205055ddddd5dddd55055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
0222222222222220505dddddd5dddd55055555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
0222222222222220505ddddd55555550555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
0222222222222220505ddddd55555550555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205055ddd555555505555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205505555555550055555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205550000000005555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555055550555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555550505505055555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555550505505055555555555555555555555550222222222222220
00000222222222205555555555555555555555555555555555555555555555555555555555555550500005055555555555555555555555550222222222200000
02222000002222205555555555555555555555555555555555555555555555555555555555555555007000555555555555555555555555550222220000022220
02002222220000005555555555555555555555555555555555555555555555555555555555555555500005555555555555555555555555550000002222220020
02000000022222205555555555555555555555555555555555555555555555555555555555555555550055555555555555555555555555550222222000000020
020ddddd0000000055555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555500000000ddddd020
020dddddddddddd05555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550dddddddddddd020
020dddddddddddd05555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550dddddddddddd020
020dddddddddddd05555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550dddddddddddd020
020dddddddddddd05555555555555555500000055555555555555555555555555555555555555555555555555555555555555555555555550dddddddddddd020
020dddddddddddd055555555555555550ffffff05555555555555555555555555555555555555555555555555555555555555555555555550dddddddddddd020
020dddddddddddd05555555555555550ffffffff0555555555555555555555555555555555555555555555555555555555555555555555550dddddddddddd020
020ddddd00000000555555555555550ffffffffff0555555555555555555555555555555555555555555555555555555555555555555555500000000ddddd020
0200000002222220555555555555550f70ffff70f055555555555555555555555555555555555555555555555555555555555555555555550222222000000020
0200222222000000555555555555550f00ffff00f055555555555555555555555555555555555555555555555555555555555555555555550000002222220020
0222200000222220555555555555550fcc0000ccf055555555555555555555555555555555555555555555555555555555555555555555550222220000022220
00000222222222205555555555555550cf0000fc0555555555555550555505555555555555555555555555555555555555555555555555550222222222200000
022222222222222055555555555555550ffffff05555555555555505055050555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555550f000000f0555555555555505055050555555555555555555555555555555555555555555555555550222222222222220
0222222222222220555555555555555000ffff000555555555555505000050555555555555555555555555555555555555555555555555550222222222222220
0222222222222220555555555555555550ffff055555555555555550070005555555555555555555555555555555555555555555555555550222222222222220
0222222222222220555555555555555550f00f055555555555555555000055555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555500550055555555555555555500555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555550000055550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555550005555505550222222222222220
0222222222222220555555555555555555555555555555555555555555555555555555555555555555555555555555555550555ddddd50550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555505ddddddd55050222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555505ddddddd55050222222222222220
022222222222222055555555555555555555555555555555555555555555555555555555555555555555555555555555555055ddd55555050222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555550055555555555050222222222222220
0222222222222220555555555555555555555555555555555555555555555555555555555555555555555555555555550555ddd55dd555050222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555055ddddd5dddd55050222222222222220
0222222222222220555555555555555555555555555555555555555555555555555555555555555555555555555555505dddddd5dddd55050222222222222220
0222222222222220555555555555555555555555555555555555555555555555555555555555555555555555555555505ddddd55555550550222222222222220
0222222222222220555555555555555555555555555555555555555555555555555555555555555555555555555555505ddddd55555550550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555055ddd555555505550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555505555555550055550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555550000000005555550222222222222220
02222222222222205555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555550222222222222220
02222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000222222222222220
022222222222220ddddddddddddddddddddddddddddddddddddddddddd0d0dddddd0d0ddddddddddddddddddddddddddddddddddddddddddd022222222222220
02222222222220dddddddddddddddddddddddddddddddddddddddddddd0d0dddddd0d0dddddddddddddddddddddddddddddddddddddddddddd02222222222220
0222222222220ddddddddddddddddddddddddddddddddddddddddddddd0d0dddddd0d0ddddddddddddddddddddddddddddddddddddddddddddd0222222222220
022222222220dddddddddddddddddddddddddddddddddddddddddddddd0d0dddddd0d0dddddddddddddddddddddddddddddddddddddddddddddd022222222220
02222222220ddddddddddddddddddddddddddddddddddddddddddddddd0d0dddddd0d0ddddddddddddddddddddddddddddddddddddddddddddddd02222222220
0222222220ddddddddddddddddddddddddddddddddddddddddddddddd0dd0dddddd0dd0ddddddddddddddddddddddddddddddddddddddddddddddd0222222220
022222220dddddddddddddddddddddddddddddddddddddddddddddddd0d00dddddd00d0dddddddddddddddddddddddddddddddddddddddddddddddd022222220
02222220ddddddddddddddddddddddddddddddddddddddddddddddddd0d0dddddddd0d0ddddddddddddddddddddddddddddddddddddddddddddddddd02222220
0222220dddddddddddddddddddddddddddddddddddddddddddddddddd0d0dddddddd0d0dddddddddddddddddddddddddddddddddddddddddddddddddd0222220
022220ddddddddddddddddddddddddddddddddddddddddddddddddddd0d0dddddddd0d0ddddddddddddddddddddddddddddddddddddddddddddddddddd022220
02220ddddddddddddddddddddddddddddddddddddddddddddddddddd0dd0dddddddd0dd0ddddddddddddddddddddddddddddddddddddddddddddddddddd02220
0220dddddddddddddddddddddddddddddddddddddddddddddddddddd0d00dddddddd00d0dddddddddddddddddddddddddddddddddddddddddddddddddddd0220
020ddddddddddddddddddddddddddddddddddddddddddddddddddddd0d000000000000d0ddddddddddddddddddddddddddddddddddddddddddddddddddddd020
00dddddddddddddddddddddddddddddddddddddddddddddddddddddd0dddddddddddddd0dddddddddddddddddddddddddddddddddddddddddddddddddddddd00
0ddddddddddddddddddddddddddddddddddddddddddddddddddddddd0000000000000000ddddddddddddddddddddddddddddddddddddddddddddddddddddddd0
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0102020202020202020203030202020400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3912191919191919191919191919131400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3929111111111111111111111111392900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3929111111111111111111111111392900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3929111111111111111111111111391400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2728111111111111111111111111070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3738111111111111111111111111171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3929111111111111111111111111391400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3929111111111111111111111111392900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3929111111111111111111111111392900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3922090909090925260909090909232400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3132323232323235363232323232333400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000f75006140211402113020130121201f120121201d120141200a2201a1201c1101b1101a11019110121101411017110161101515016150131601316011160111600f1200f1500f150211500f1200f160
