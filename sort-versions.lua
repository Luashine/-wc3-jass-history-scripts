#!/usr/bin/env lua

error("Unfinished, do it by hand")

local versions = {}

for line in io.stdin:lines() do
	local ver = line:gsub("\r*$", "")
	table.insert(versions, ver)
end


do
	--[[
	Beta-ROC
	ROC
	Beta-TFT
	TFT
	Reforged
	]]
	local VER_BETA_ROC = 1
	local VER_ROC = 2
	local VER_BETA_TFT = 3
	local VER_TFT = 4
	local VER_REFORGED = 5
	
	local compare = {}
	
	compare[VER_BETA_ROC] = function (a, b)
		local function ... ah i dont want to. its faster to do by hand.
	end
	
	local function gameReleaseToNumber(ver)
		local ver = ver:lower()
		
		if ver:find("beta-roc-", 1, true) then
			return VER_BETA_ROC
		elseif ver:find("roc-", 1, true) then
			return VER_ROC
		elseif ver:find("beta-tft-", 1, true) then
			return VER_BETA_TFT
		elseif ver:find("tft-", 1, true) then
			return VER_TFT
		elseif ver:find("reforged-", 1, true) then
			return VER_REFORGED
		end
	end
	
	local function compareGameRelease(a, b)
		local aRelease = gameReleaseToNumber(a)
		local bRelease = gameReleaseToNumber(b)
		
		if aRelease < bRelease then
			return -1
		elseif aRelease == bRelease then
			return 0
		else
			return 1
		end
	end
	
	function wc3VersionSort(a, b)
		local cmpRelease = compareGameRelease(a, b)
		if cmpRelease ~= 0 then
			if cmpRelease == -1 then
				return true -- < operator
			else
				return false
			end
		
		else
			-- compare individual versions
			
			local versionABCD = 
		end
	end
end