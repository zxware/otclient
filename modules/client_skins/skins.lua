Skins = { }

-- private variables
local defaultSkinName = 'Default'
local installedSkins
local currentSkin
local skinComboBox

-- private functions
local function onSkinComboBoxOptionChange(self, optionText, optionData)
  if Skins.setSkin(optionText) then
    Settings.set('skin', optionText)
    reloadModules()
  end
end

local function getSkinPath(name)
  return g_modules.getModulesPath() .. g_lua.getCurrentSourcePath(0) .. '/skins/' .. string.lower(name) .. '/'
end

-- public functions
function Skins.init()
  installedSkins = {}

  Skins.installSkins('skins')

  if installedSkins[defaultSkinName] then
    g_resources.addToSearchPath(getSkinPath(defaultSkinName), 0)
  end

  local userSkinName = Settings.get('skin')
  if userSkinName and Skins.setSkin(userSkinName) then
    info('Using configured skin: ' .. userSkinName)
  else
    info('Using default skin: ' .. defaultSkinName)
    Skins.setSkin(defaultSkinName)
    Settings.set('skin', defaultSkinName)
  end

  addEvent( function()
              skinComboBox = createWidget('ComboBox', rootWidget:recursiveGetChildById('rightButtonsPanel'))
              for key,value in pairs(installedSkins) do
                skinComboBox:addOption(value.name)
              end
              skinComboBox:setCurrentOption(currentSkin.name)
              skinComboBox.onOptionChange = onSkinComboBoxOptionChange
            end, false)
end

function Skins.terminate()
  g_resources.removeFromSearchPath(getSkinPath(defaultSkinName))
  if currentSkin then
    g_resources.removeFromSearchPath(getSkinPath(currentSkin.name))
  end

  installedSkins = nil
  currentSkin = nil
  skinComboBox = nil
end

function Skins.installSkin(skin)
  if not skin or not skin.name or not skin.styles then
    error('Unable to install skin.')
    return false
  end

  if installedSkins[skin.name] then
    warning(skin.name .. ' has been replaced.')
  end

  installedSkins[skin.name] = skin
  return true
end

function Skins.installSkins(directory)
  dofiles(directory)
end

function Skins.setSkin(name)
  local skin = installedSkins[name]
  if not skin then
    warning("Skin " .. name .. ' does not exist.')
    return false
  end

  g_fonts.clearFonts()
  g_ui.clearStyles() 

  if name ~= defaultSkinName then
    local defaultSkin = installedSkins[defaultSkinName]
    if not defaultSkin then
      error("Default skin is not installed.")
      return false
    end

    Skins.loadSkin(defaultSkin)
  end

  if currentSkin then
    g_resources.removeFromSearchPath(getSkinPath(currentSkin.name))
  end
  g_resources.addToSearchPath(getSkinPath(skin.name), true)

  Skins.loadSkin(skin)
  currentSkin = skin
  return true
end

function Skins.loadSkin(skin)
  local lowerName = string.lower(skin.name)

  for i=1,#skin.fonts do
    g_fonts.importFont('skins/' .. lowerName .. '/fonts/' .. skin.fonts[i])

    if i == 1 then
      g_fonts.setDefaultFont(skin.fonts[i])
    end
  end

  for i=1,#skin.styles do
    g_ui.importStyle('skins/' .. lowerName .. '/styles/' .. skin.styles[i])
  end
end
