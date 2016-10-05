--[[
Clock Rings by Linux Mint (2011) reEdited by despot77

This script draws percentage meters as rings, and also draws clock hands if you want! It is fully customisable; all options are described in the script. This script is based off a combination of my clock.lua script and my rings.lua script.

IMPORTANT: if you are using the 'cpu' function, it will cause a segmentation fault if it tries to draw a ring straight away. The if statement on line 145 uses a delay to make sure that this doesn't happen. It calculates the length of the delay by the number of updates since Conky started. Generally, a value of 5s is long enough, so if you update Conky every 1s, use update_num>5 in that if statement (the default). If you only update Conky every 2s, you should change it to update_num>3; conversely if you update Conky every 0.5s, you should use update_num>10. ALSO, if you change your Conky, is it best to use "killall conky; conky" to update it, otherwise the update_num will not be reset and you will get an error.

To call this script in Conky, use the following (assuming that you save this script to ~/scripts/rings.lua):
    lua_load ~/scripts/clock_rings.lua
    lua_draw_hook_pre clock_rings
    
Changelog:
+ v1.0 -- Original release (30.09.2009)
   v1.1p -- Jpope edit londonali1010 (05.10.2009)
*v 2011mint -- reEdit despot77 (18.02.2011)
]]


require 'cairo'

function rgb_to_r_g_b(colour,alpha)
    return ((colour / 0x10000) % 0x100) / 255., ((colour / 0x100) % 0x100) / 255., (colour % 0x100) / 255., alpha
end

function draw_ring(cr,t,pt)
    local w,h=conky_window.width,conky_window.height
    
    local xc,yc,ring_r,ring_w,sa,ea=pt['x'],pt['y'],pt['radius'],pt['thickness'],pt['start_angle'],pt['end_angle']
    local bgc, bga, fgc, fga=pt['bg_colour'], pt['bg_alpha'], pt['fg_colour'], pt['fg_alpha']

    local angle_0=sa*(2*math.pi/360)-math.pi/2
    local angle_f=ea*(2*math.pi/360)-math.pi/2
    local t_arc=t*(angle_f-angle_0)

    local radius_c = pt["radius"]*0.7


    if pt["clusterNode"]["state"]==1 then
        -- Draw background ring

        cairo_set_source_rgba(cr,rgb_to_r_g_b(bgc,bga))
        cairo_arc(cr,xc,yc,ring_r,angle_0,angle_f)
        cairo_set_line_width(cr,ring_w)
        cairo_stroke(cr)
        
        -- Draw indicator ring
        local isOffline = tonumber(pt["clusterNode"]["offline"])

        cairo_arc(cr,xc,yc,ring_r,angle_0,angle_0+t_arc)
        if  isOffline== 1 then
            cairo_set_source_rgba(cr,rgb_to_r_g_b(0xFF0000,0.5))
        else
            cairo_set_source_rgba(cr,rgb_to_r_g_b(fgc,fga))
        end
        cairo_stroke(cr)        

    -- Draw small rings
        local maxCpu = pt["clusterNode"]["ncpus"]
        --local radius_c = pt["radius"]*0.7
        local phi,xr,yr
        local threads = tonumber(pt["clusterNode"]["threads"])
        print(threads)
        for i = 1, maxCpu do
            phi = angle_0 + (i-1+0.5)/maxCpu * 2*math.pi 
            xr = radius_c * math.cos(phi)
            yr = radius_c * math.sin(phi)
            cairo_arc(cr,xc+xr,yc+yr,2,0,2*math.pi)
            if i <= threads then
                cairo_set_source_rgba(cr,rgb_to_r_g_b(0xff0000,1))
            else
                if  isOffline== 1 then
                    cairo_set_source_rgba(cr,rgb_to_r_g_b(0x000000,0.5))
                else
                    cairo_set_source_rgba(cr,rgb_to_r_g_b(0xff0000,0.3))
                end
            end
            cairo_fill(cr)
            cairo_stroke(cr)
        end
    elseif pt["clusterNode"]["state"]==2 then
        local user = tonumber(pt["clusterNode"]["numUser"])
        local maxUser = 2
        cairo_set_source_rgba(cr,rgb_to_r_g_b(fgc,0.3))
        if user > maxUser then
            fgc = 0xFF0000
            fga = 0.8
        end
        if user > 1 then
            cairo_set_source_rgba(cr,rgb_to_r_g_b(fgc,fga))
        end
        cairo_arc(cr,xc+1,yc,ring_r,-1/2*math.pi,1/2*math.pi)
        cairo_fill(cr)
        cairo_stroke(cr)
        if user > 0 then
            cairo_set_source_rgba(cr,rgb_to_r_g_b(fgc,fga))
        end
        cairo_arc(cr,xc-1,yc,ring_r,-3/2*math.pi,-1/2*math.pi)
        cairo_fill(cr)
        cairo_stroke(cr)

    else
        cairo_set_source_rgba(cr,rgb_to_r_g_b(0xff0000,0.3))
        cairo_arc(cr,xc,yc,ring_r,angle_0,angle_f)
        --cairo_set_line_width(cr,ring_w)
        cairo_stroke(cr)
    end
end

function explode(div,str)
    if (div=='') then return false end
    local pos,arr = 0,{}
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1))
        pos = sp + 1
    end
    table.insert(arr,string.sub(str,pos))
    return arr
end

-- see if the file exists
function file_exists(file)
  local f = io.open(file, "rb")
  if f then f:close() end
  return f ~= nil
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  if not file_exists(file) then return {} end
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  return lines
end

function conky_cluster_rings()
    local function setup_rings(cr,pt)
        local value = pt["value"]
        pct=value/pt["max"]
        draw_ring(cr,pct,pt)
    end

    local function setContains(set, key)
        return set[key] ~= nil
    end

    local str
    str=string.format('${%s %s}','exec','cat ~/.conky/cluster/data/clusterStatus')
    str=conky_parse(str)
    
    
    local dataString={}
    for line in str:gmatch("[^\r\n]+") do 
        table.insert(dataString,line)
    end

    --for key,value in pairs(dataString) do print(key,value) end

    local clusterNodes = {}
    for i, line in ipairs(dataString) do
        k = explode(" ",line)
        table.insert(clusterNodes,{})
        if k[1]=="Linux" then
            clusterNodes[i]["state"] = 1
            clusterNodes[i]["ncpus"] = k[3]
            clusterNodes[i]["threads"] = k[2]
            clusterNodes[i]["load"] = k[4]
            clusterNodes[i]["offline"] = k[5]
        elseif k[1]=="Windows" then
            clusterNodes[i]["state"] = 2
            clusterNodes[i]["numUser"] = k[2]
        else 
            clusterNodes[i]["state"] = 0
        end
    end

    local rings = {}
    for i, n in pairs(clusterNodes) do
        rings[i] = {}
        if n['state']==1 then
            rings[i]["value"] = n["load"]*100
            rings[i]["bg_colour"]=0xffffff
        else
            rings[i]["value"] = 0
            rings[i]["bg_colour"]=0xff0000
        end
        rings[i]["x"]=i*60
        rings[i]["y"]=30
        rings[i]["max"] = 100
        rings[i]["bg_alpha"]=0.2
        rings[i]["fg_colour"]=0x0066FF
        rings[i]["fg_alpha"]=0.8
        rings[i]["radius"]=25
        rings[i]["thickness"]=4
        rings[i]["start_angle"]=-90
        rings[i]["end_angle"]=270
        rings[i]["clusterNode"]=n
    end

    if conky_window==nil then return end
    local cs=cairo_xlib_surface_create(conky_window.display,conky_window.drawable,conky_window.visual, conky_window.width,conky_window.height)
    
    local cr=cairo_create(cs)    
    
    
    for i in pairs(rings) do
        setup_rings(cr,rings[i])
    end
    
end
