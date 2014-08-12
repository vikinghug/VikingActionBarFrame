-- require "Window"
-- require "Apollo"
-- require "GameLib"
-- require "Spell"
-- require "Unit"
-- require "Item"
-- require "PlayerPathLib"
-- require "AbilityBook"
-- require "ActionSetLib"
-- require "AttributeMilestonesLib"
-- require "Tooltip"
-- require "HousingLib"

require "Window"
require "Apollo"
require "GameLib"
require "GroupLib"
require "PlayerPathLib"

local VikingLib
local VikingActionBarFrame = {
  _VERSION = 'VikingActionBarFrame.lua 0.1.0',
  _URL     = 'https://github.com/vikinghug/VikingActionBarFrame',
  _DESCRIPTION = '',
  _LICENSE = [[
    MIT LICENSE

    Copyright (c) 2014 Kevin Altman

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}


function VikingActionBarFrame:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function VikingActionBarFrame:Init()
  Apollo.RegisterAddon(self, nil, nil, {"VikingLibrary"})
end

function VikingActionBarFrame:OnLoad()
  self.xmlDoc = XmlDoc.CreateFromFile("VikingActionBarFrame.xml")
  self.xmlDoc:RegisterCallback("OnDocumentReady", self)

  Apollo.RegisterEventHandler("WindowManagementReady"  , "OnWindowManagementReady"  , self)
  Apollo.RegisterEventHandler("WindowManagementUpdate" , "OnWindowManagementUpdate" , self)

  Apollo.LoadSprites("VikingClassResourcesSprites.xml")
end

function VikingActionBarFrame:OnDocumentReady()
  if self.xmlDoc == nil then return end

  self.bDocLoaded = true
  self:OnRequiredFlagsChanged()
end


function VikingActionBarFrame:OnWindowManagementReady()
  SendVarToRover("wnd", self.tSkillsBar)
  Event_FireGenericEvent("WindowManagementAdd", { wnd = self.tSkillsBar.wnd, strName = "Viking Skills Bar" })
end

function VikingActionBarFrame:OnWindowManagementUpdate(tWindow)
  if tWindow and tWindow.wnd and (tWindow.wnd == self.tSkillsBar.wnd) then
    local bMoveable = tWindow.wnd:IsStyleOn("Moveable")

    tWindow.wnd:SetStyle("Sizable", bMoveable)
    tWindow.wnd:SetStyle("RequireMetaKeyToMove", bMoveable)
    tWindow.wnd:SetStyle("IgnoreMouse", not bMoveable)
  end
end

function VikingActionBarFrame:OnRequiredFlagsChanged()
  if GameLib.GetPlayerUnit() then
    self:OnCharacterLoaded()
  else
    Apollo.RegisterEventHandler("CharacterCreated", "OnCharacterLoaded", self)
  end
end

function VikingActionBarFrame:GetDefaults()

  local tColors = VikingLib.Settings.GetColors()

  return {
    char = {}
  }

end

function VikingActionBarFrame:OnCharacterLoaded()
  local playerUnit = GameLib.GetPlayerUnit()
  if not playerUnit then return end

  if VikingLib == nil then
    VikingLib = Apollo.GetAddon("VikingLibrary")
  end

  if VikingLib ~= nil then
    self.db = VikingLib.Settings.RegisterSettings(self, "VikingActionBarFrame", self:GetDefaults(), "Action Bars")
    -- self.generalDb = self.db.parent
  end


  -- SkillsBar
  self.tSkillsBar = self:CreateBar('Skills')
  self:PositionItems(self.tSkillsBar)
end

function VikingActionBarFrame:CreateBar(name)

  local wnd = Apollo.LoadForm(self.xmlDoc, "SkillsBar", "FixedHudStratum", self)

  local tFrame = {
    name    = name,
    wnd     = wnd,
    Columns = 9,
    X       = 0,
    Y       = 0,
    Scale   = 1,
    total   = 9,
    width   = 48,
    height  = 60,
    btns    = {},
  }


  local nLeft, nTop, nRight, nBottom = wnd:GetAnchorOffsets()

  tFrame.X = nLeft
  tFrame.Y = nTop

  for i = 1, 9 do
    wndCurrentItem = Apollo.LoadForm(self.xmlDoc, "ActionBarItem", tFrame.wnd, self)
    wndCurrentButton = wndCurrentItem:FindChild('btn')

    wndCurrentButton:SetContentId(i - 1)
    table.insert(tFrame.btns, wndCurrentItem)
  end

  return tFrame

end


function VikingActionBarFrame:PositionItems(tBar)
  local wnd = tBar.wnd
  local Columns = tBar.Columns
  local width = tBar.width
  local height = tBar.height
  local xOffset = 0
  local yOffset = 0

  for i, item in ipairs(tBar.btns) do
    n = i - 1
    local col = n % Columns
    local row = math.floor(n / Columns)

    xOffset = width * col
    yOffset = height * row
    item:SetAnchorOffsets(tBar.X + xOffset, tBar.Y + yOffset, tBar.X + xOffset + width, tBar.Y + yOffset + height)
  end

end

function VikingActionBarFrame:InitSettings(wndSettingsForm)

  local tDisplaySize = Apollo.GetDisplaySize()
  local wndX = wndSettingsForm:FindChild("X")
  local wndY = wndSettingsForm:FindChild("Y")
  local wndScale = wndSettingsForm:FindChild("Scale")

  SendVarToRover("wndX", tDisplaySize)

  local tHalfScreen = {
    Width = tDisplaySize.nRawWidth/2,
    Height = tDisplaySize.nRawHeight/2,
  }
  wndX:FindChild('Slider'):SetMinMax(-tHalfScreen.Width, tHalfScreen.Width)
  wndY:FindChild('Slider'):SetMinMax(-tDisplaySize.nRawHeight, 0)


end

function VikingActionBarFrame:OnSliderChange( wndHandler, wndControl, fNewValue, fOldValue, bOkToChange )
  local wndSection = wndHandler:GetParent():GetParent():GetParent()
  local SectionName = wndSection:GetName()
  local ElementName = wndHandler:GetParent():GetName()

  Print(SectionName .. " : " .. ElementName)

  self['t' .. SectionName][ElementName] = fNewValue
  self:PositionItems(self['t' .. SectionName])
  wndHandler:FindChild('Value'):SetText(fNewValue)

  return fNewValue
end


local VikingActionBarFrameInst = VikingActionBarFrame:new()
VikingActionBarFrameInst:Init()
