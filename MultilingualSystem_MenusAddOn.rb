#==============================================================================
# ** Multilingual System - Simple Add on for menus
#------------------------------------------------------------------------------
# ★ Yamashi Fenikkusu - v1.0
# https://github.com/YamashiFenikkusu/CSV-translator-system-for-RPG-Maker-VX Ace/tree/main
#------------------------------------------------------------------------------
# This add on set an option on title screen and pause menu to changing the
# language game during a game session. It's needing the Multilingual System v1.1
# (available on the main Github page). Put this script under the Multilingual System.
#------------------------------------------------------------------------------
# TERMS OF USE:
# -Same as the main MultilingualSystem script.
#------------------------------------------------------------------------------
# How to use:
# -Set if you want language option in pause menu and title screen at line 24.
# -You can call the language option menu in your own script by the call method
#  SceneManager.call(Scene_Language)
#==============================================================================
 
#==============================================================================
# * Multilingual System - Menus add on
#==============================================================================
class MultilingualSystem
  @SHOW_OPTION_TITLE_SCREEN = true
  @SHOW_OPTION_PAUSE_MENU = true
  @SHOW_OPTION_IF_LANGUAGE_NO_FOUND = true
  @@no_present_language_in_game_ini = false #Don't touch
  
  #--------------------------------------------------------------------------
  # * Return show option
  #--------------------------------------------------------------------------
  def self.return_show_option_title_screen; return @SHOW_OPTION_TITLE_SCREEN end
  def self.return_show_option_pause_menu; return @SHOW_OPTION_PAUSE_MENU end
  def self.return_show_option_if_language_no_found; return @SHOW_OPTION_IF_LANGUAGE_NO_FOUND end
  def self.return_show_option_if_language_no_founded; return @@no_present_language_in_game_ini end
  
  #--------------------------------------------------------------------------
  # * Turn off no language present
  #--------------------------------------------------------------------------
  def self.turn_off_no_language_present; @@no_present_language_in_game_ini = false end
          
  #--------------------------------------------------------------------------
  # * Override read language in Game.ini
  #--------------------------------------------------------------------------
  def self.read_ini_language
    lang = nil
    lines = []
    found = false
    File.readlines("Game.ini").each do |line|
    if line =~ /^Language=(.+)$/i
      lang = $1.strip
      if @@languages.include?($1.strip) == false
        lang = @default_lang
      end
      found = true
    end
    lines << line
    end
    #Add Language=XX if this line doesn't exist
    unless found
      lines << "Language=#{@default_lang}\n"
      File.open("Game.ini", "w") { |f| f.puts lines }
      lang = @default_lang
      if @SHOW_OPTION_IF_LANGUAGE_NO_FOUND == true; @@no_present_language_in_game_ini = true end
    end
    lang
  end
end
 
#==============================================================================
# * Vocab - Menus add on
#==============================================================================
module Vocab
  @VOCAB_MENU_LANG = "menu_lang"
  @VOCAB_MENU_HEADER = "menu_lang_header"
  
  #--------------------------------------------------------------------------
  # * Menu lang translated key
  #--------------------------------------------------------------------------
  def self.menu_lang; return MultilingualSystem.read_key("Database_Vocab", @VOCAB_MENU_LANG) end
  def self.menu_lang_header; return MultilingualSystem.read_key("Database_Vocab", @VOCAB_MENU_HEADER) end
end
 
#==============================================================================
# * Window_MenuCommand modifier
#==============================================================================
class Window_MenuCommand < Window_Command
  #--------------------------------------------------------------------------
  # * Override create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_main_commands
    add_formation_command
    add_original_commands
    add_save_command
    if MultilingualSystem.return_show_option_pause_menu == true; add_set_lang_command end
    add_game_end_command
  end
        
  #--------------------------------------------------------------------------
  # * Add set lang command
  #--------------------------------------------------------------------------
  def add_set_lang_command; add_command(Vocab::menu_lang, :menu_lang) end
end
 
#==============================================================================
# * Scene_Menu modifier
#==============================================================================
class Scene_Menu < Scene_MenuBase
  #--------------------------------------------------------------------------
  # * Override create Command Window
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_MenuCommand.new
    @command_window.set_handler(:item,      method(:command_item))
    @command_window.set_handler(:skill,     method(:command_personal))
    @command_window.set_handler(:equip,     method(:command_personal))
    @command_window.set_handler(:status,    method(:command_personal))
    @command_window.set_handler(:formation, method(:command_formation))
    @command_window.set_handler(:save,      method(:command_save))
    if MultilingualSystem.return_show_option_pause_menu == true
      @command_window.set_handler(:menu_lang,      method(:command_lang))
    end
    @command_window.set_handler(:game_end,  method(:command_game_end))
    @command_window.set_handler(:cancel,    method(:return_scene))
  end
        
  #--------------------------------------------------------------------------
  # * Command lang
  #--------------------------------------------------------------------------
  def command_lang; SceneManager.call(Scene_Language) end
end
 
#==============================================================================
# * Window_MenuCommand modifier
#==============================================================================
class Window_TitleCommand < Window_Command
  #--------------------------------------------------------------------------
  # * Override create Command List
  #--------------------------------------------------------------------------
  def make_command_list
    add_command(Vocab::new_game, :new_game)
    add_command(Vocab::continue, :continue, continue_enabled)
    if MultilingualSystem.return_show_option_title_screen == true; add_set_lang_command end
    add_command(Vocab::shutdown, :shutdown)
  end
        
  #--------------------------------------------------------------------------
  # * Add set lang command
  #--------------------------------------------------------------------------
  def add_set_lang_command; add_command(Vocab::menu_lang, :menu_lang) end
end
 
#==============================================================================
# * Scene_Title modifier
#==============================================================================
class Scene_Title < Scene_Base
  #--------------------------------------------------------------------------
  # * Override start
  #--------------------------------------------------------------------------
  def start
    super
    SceneManager.clear
    Graphics.freeze
    create_background
    create_foreground
    play_title_music
    if (MultilingualSystem.return_show_option_if_language_no_founded == true) and (MultilingualSystem.return_show_option_if_language_no_found == true)
      SceneManager.call(Scene_Language)
    else
      create_command_window
    end
  end
        
  #--------------------------------------------------------------------------
  # * Override create Command Window
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_TitleCommand.new
    @command_window.set_handler(:new_game, method(:command_new_game))
    @command_window.set_handler(:continue, method(:command_continue))
    if MultilingualSystem.return_show_option_title_screen == true
            @command_window.set_handler(:menu_lang, method(:command_lang))
    end
    @command_window.set_handler(:shutdown, method(:command_shutdown))
  end
        
  #--------------------------------------------------------------------------
  # * Command lang
  #--------------------------------------------------------------------------
  def command_lang; SceneManager.call(Scene_Language) end
end
 
#==============================================================================
# * Window_LanguageMenu
#==============================================================================
class Window_LanguageMenu < Window_Command
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize
    super(0, 0)
    update_placement
    self.openness = 0
    open
  end
        
  #--------------------------------------------------------------------------
  # * Window width
  #--------------------------------------------------------------------------
  def window_width; return 200 end
        
  #--------------------------------------------------------------------------
  # * Update placement
  #--------------------------------------------------------------------------
  def update_placement
    self.x = (Graphics.width - width) / 2
    self.y = (Graphics.height - height) / 2
  end
        
  #--------------------------------------------------------------------------
  # * Make command list
  #--------------------------------------------------------------------------
  def make_command_list
    MultilingualSystem.return_language_array.size.times do |i|
      lang = MultilingualSystem.return_language_array[i]
      ranslated_key = MultilingualSystem.read_key("Database_Vocab", "menu_lang"<<lang)
      add_command(translated_key, :"switch_to_#{lang}")
    end
    add_command(Vocab::cancel, :cancel)
  end
        
  #--------------------------------------------------------------------------
  # * Make first command list
  #--------------------------------------------------------------------------
  def make_first_command_list
    MultilingualSystem.return_language_array.size.times do |i|
      lang = MultilingualSystem.return_language_array[i]
      translated_key = MultilingualSystem.read_key("Database_Vocab", "menu_lang"<<lang)
      add_command(translated_key, :"switch_to_#{lang}")
    end
  end
end
 
#==============================================================================
# * Window_First_LanguageMenu
#==============================================================================
class Window_First_LanguageMenu < Window_Command
  #--------------------------------------------------------------------------
  # * Initialize
  #--------------------------------------------------------------------------
  def initialize
    @commands_to_add = []
    super(0, 0)
    update_placement
    self.openness = 0
    open
  end
        
  #--------------------------------------------------------------------------
  # * Window width
  #--------------------------------------------------------------------------
  def window_width; return 200 end
        
  #--------------------------------------------------------------------------
  # * Update placement
  #--------------------------------------------------------------------------
  def update_placement
    self.x = (Graphics.width - width) / 2
    self.y = (Graphics.height - height) / 2
  end
        
  #--------------------------------------------------------------------------
  # * Make command list
  #--------------------------------------------------------------------------
  def make_command_list
    MultilingualSystem.return_language_array.size.times do |i|
      lang = MultilingualSystem.return_language_array[i]
        translated_key = MultilingualSystem.read_key("Database_Vocab", "menu_lang"<<lang)
        add_command(translated_key, :"switch_to_#{lang}")
      end
  end
end
 
#==============================================================================
# * Scene_Language
#==============================================================================
class Scene_Language < Scene_Base
  #--------------------------------------------------------------------------
  # * Start
  #--------------------------------------------------------------------------
  def start
    super
    create_background
    if (MultilingualSystem.return_show_option_if_language_no_founded == true) and (MultilingualSystem.return_show_option_if_language_no_found == true)
      create_first_command_window
    else; create_command_window end
    create_header
  end
        
  #--------------------------------------------------------------------------
  # * Create background
  #--------------------------------------------------------------------------
  def create_background
    @background_sprite = Sprite.new
    @background_sprite.bitmap = SceneManager.background_bitmap
    @background_sprite.color.set(16, 16, 16, 128)
  end
        
  #--------------------------------------------------------------------------
  # * Create header
  #--------------------------------------------------------------------------
  def create_header
    @help_window = Window_Help.new(1)
    @help_window.set_text(Vocab.menu_lang_header)
  end
        
  #--------------------------------------------------------------------------
  # * Create command window
  #--------------------------------------------------------------------------
  def create_command_window
    @command_window = Window_LanguageMenu.new
    MultilingualSystem.return_language_array.size.times do |i|
      lang = MultilingualSystem.return_language_array[i]
      @command_window.set_handler(:"switch_to_#{lang}", method(:command_lang))
    end
    @command_window.set_handler(:cancel, method(:return_scene))
  end
        
  #--------------------------------------------------------------------------
  # * Create first command window
  #--------------------------------------------------------------------------
  def create_first_command_window
    @command_window = Window_First_LanguageMenu.new
    MultilingualSystem.return_language_array.size.times do |i|
      lang = MultilingualSystem.return_language_array[i]
      @command_window.set_handler(:"switch_to_#{lang}", method(:first_command_lang))
    end
  end
        
  #--------------------------------------------------------------------------
  # * Command lang
  #--------------------------------------------------------------------------
  def command_lang
    lang = @command_window.current_symbol.to_s.sub("switch_to_", "")
    MultilingualSystem.set_language(lang)
    return_scene
  end
        
  #--------------------------------------------------------------------------
  # * First command lang
  #--------------------------------------------------------------------------
  def first_command_lang
    lang = @command_window.current_symbol.to_s.sub("switch_to_", "")
    MultilingualSystem.set_language(lang)
    MultilingualSystem.turn_off_no_language_present
    SceneManager.call(Scene_Title)
  end
end
