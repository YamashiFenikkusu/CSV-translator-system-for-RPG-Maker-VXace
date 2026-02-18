#==============================================================================
# ** Multilingual System
#------------------------------------------------------------------------------
# ★ Yamashi Fenikkusu - v1.1
# https://github.com/YamashiFenikkusu/CSV-translator-system-for-RPG-Maker-VXace
#------------------------------------------------------------------------------
# This script able your game to be multilingual by using csv file.
# A good comprehension of programmation and csv system are required.
#------------------------------------------------------------------------------
# TERMS OF USE:
# -Credit ★Yamashi Fenikkusu.
# -You need a valid RPG Maker VXace licence.
# -Free for non commercial and commercial use.
# -You can modify the script for your own usage, but don't redistribute it.
# -Redistribution on other websites without authorization are forbidden.
# -It's not obligatory, but a DM is appreciated if you use this script. 
#------------------------------------------------------------------------------
# How to use:
# -You need to have a "CSV" named folder in the project root.
# -A CSV folder is offered on the GitHub page, it's containing a csv file for
#  Vocab module. Files csv for actors, weapons will come later. The csv files
#  offered on the Github page contain translation in English and French.
# -For messages event comand and choice, use this format for display a message
#  contained in a csv file: (tableName, keyName)
# -For linebreak in the csv files for messages and database, use the \L balise.
# -For use the system in database, use <key: keyNameInCorrespondingCSV> in the
#  Notes part.
# -You can parameter this script at the line 75 and read instruction at line 38.
#==============================================================================
# /!\ DISCLAIMER /!\
# This script doesn't integrate AI translator, you've the charge of yours translations.
#==============================================================================

#==============================================================================
# * Multilingual System
#==============================================================================
class MultilingualSystem
  #--------------------------------------------------------------------------
  # * Useful script commands
  #  -MultilingualSystem.read_key("tableName", "keyName"):
  #     Read a key in a csv file.
  #  -MultilingualSystem.set_language("desiredLanguage")
  #			Set a new language. The desiredLanguage parameter must be same as the
  #			one in @@languages array and csv files.
  #  -MultilingualSystem.current_language
  #     Return the current language.
  #--------------------------------------------------------------------------
  # * Using in database
  #  	-In the note part of an item, weapon or armor, you can add <key: something>
  #    remplace "something" by a key present in your correspondant csv file (items
  #    in /CSV/Items.csv, weapons in /CSV/Weapons.csv, etc). You have to
  #    have multiple versions of the key in the csv file: object, object_d, object_m.
  #    object is the name of the object and object_d (or other prefix) the
  #    description or displayed message.
  #--------------------------------------------------------------------------
  # * Variables
  #  -ROOT_FOLDER:
  #     The folder where csv files are located. By delfaut in the project root.
  #  -@@languages:
  #     The languages of the game. The headers keys must be the same as the keys
  #     in the array.
  #  -@default_lang:
  #     The default language of game.
  #  -$current_language:
  #     The current language of the game. By default, this variable is equal to
  #     @default_lang.
  #  -@set_local_pictures_folder:
  #			Set if the game loads pictures in an another language. You must have a
  #			"PictureLANGINITIAL" folder in the Graphics folder.
  #  -@set_local_title_folders:
  #			Same utility as @set_local_pictures_folder for Titles1 and Title2.
  #  -@set_local_movies_folder:
  #			Same utility as @set_local_movies_folder for Movies.
  #--------------------------------------------------------------------------
  ROOT_FOLDER = "CSV/"
  @@languages = ["EN", "FR"]
  @default_lang = @@languages[0]
  $current_language = @default_lang
  @set_local_pictures_folder = true
  @set_local_title_folders = false
  @set_local_movies_folder = true
  
  #--------------------------------------------------------------------------
  # * Read a key from CSV file
  #--------------------------------------------------------------------------
  def self.read_key(table, key)
    file_path = ROOT_FOLDER + table + ".csv"
    csv_reader = CSVReader.new(file_path)
    value = csv_reader.get_value(key, $current_language)
    #Linebreak gestion
    value = value.gsub(/\\[lL]/, "\n") if value.is_a?(String)
    value
  end
  
  #--------------------------------------------------------------------------
  # * Set language
  #--------------------------------------------------------------------------
  def self.set_language(lang)
    #Set language parameter
    $current_language = @@languages.include?(lang) ? lang : $current_language
    apply_translation
    Vocab.override_skill_type
    #Write in Game.ini
    return unless @@languages.include?(lang)
    lines = []
    language_written = false
    File.open("Game.ini", "r") do |file|
      file.each_line do |line|
        if line =~ /^Language=/
          lines << "Language=#{lang}\n"
          language_written = true
        else
          lines << line
        end
      end
    end
    lines << "Language=#{lang}\n" unless language_written
    File.open("Game.ini", "w") do |file|
      lines.each { |line| file.write(line) }
    end
    @@current_language = lang
  end
  
  #--------------------------------------------------------------------------
  # * Read language in Game.ini
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
    end
    lang
  end
  
  #--------------------------------------------------------------------------
  # * Current language
  #--------------------------------------------------------------------------
  def self.current_language; return $current_language end
  
  #--------------------------------------------------------------------------
  # * Return default language
  #--------------------------------------------------------------------------
  def self.default_language; return @default_lang end
  
  #--------------------------------------------------------------------------
  # * Return language array
  #--------------------------------------------------------------------------
  def self.return_language_array; return @@languages end
  
  #--------------------------------------------------------------------------
  # * Return local folders
  #--------------------------------------------------------------------------
  def self.return_set_local_pictures_folder; return @set_local_pictures_folder end
  def self.return_set_local_title_folders; return @set_local_title_folders end
  def self.return_set_local_movies_folder; return @set_local_movies_folder end
  
  #--------------------------------------------------------------------------
  # * Apply translation
  #--------------------------------------------------------------------------
  def self.apply_translation
    #Vocab
    (0..7).each  { |i| Vocab.basic(i) }
    (0..10).each { |i| Vocab.command(i) }
    (12..22).each { |i| Vocab.command(i) }
    Vocab.override_constants
    #Folder locations
    Cache.set_local_folders
    Game_Interpreter.set_local_folder
  end
  
  #--------------------------------------------------------------------------
  # * First initialize
  #--------------------------------------------------------------------------
  def self.first_initialize
    $current_language = read_ini_language
    apply_translation
  end
end

#==============================================================================
# * CSV reader
#==============================================================================
class CSVReader
  attr_reader :data, :headers
  
  #--------------------------------------------------------------------------
  # * Initialize key
  #--------------------------------------------------------------------------
  def initialize(file_path, delimiter = ",")
    @data = []
    return unless File.exist?(file_path)
    File.open(file_path, "r:BOM|UTF-8") do |file|
      file.each_with_index do |line, index|
        next if line.strip.empty?
        row = line.strip.split(delimiter)
        if index == 0
          @headers = row
        else
          @data << row
        end
      end
    end
  end
  
  #--------------------------------------------------------------------------
  # * Search key
  #--------------------------------------------------------------------------
  def get_value(key, language)
    lang_index = @headers.index(language)
    return "[ERROR: Translation failed]" unless lang_index
    @data.each do |row|
      return row[lang_index] if row[0] == key
    end
    "[ERROR: Translation failed]"
  end
end

#==============================================================================
# * Vocab modifier
#==============================================================================
module Vocab
  #--------------------------------------------------------------------------
  # * Constants
  #--------------------------------------------------------------------------	
  VOCAB_KEY_BASIC =
  {
    0 => "level",   1 => "level_a",   2 => "hp",   3 => "hp_a",   4 => "mp",
    5 => "mp_a",   6 => "tp",   7 => "tp_a"
  }
  
  VOCAB_KEY_PARAM =
  {
    0 => "maxHitPoints",   1 => "maxMagicPoints",   2 => "attackPower",
    3 => "defensePower",   4 => "magicAttackPower",   5 => "magicDefensePower",
    6 => "agility",   7=> "luck"
  }
  
  VOCAB_KEY_ETYPE =
  {
    0 => "weapon2",   1 => "shield",   2 => "helmet",   3 => "armor",
    4 => "accessory"
  }
  
  VOCAB_KEY_COMMAND =
  {
    0 => "fight",   1 => "escape",   2 => "attack",   3 => "guard",   4 => "item",
    5 => "skill",   6 => "equip",    7 => "status",   8 => "formation",   9 => "save",
    10 => "game_end",   12 => "weapon",   13 => "armor",   14 => "key_item",   15 => "equip2",
    16 => "optimize",   17 => "clear",   18 => "new_game",   19 => "continue",   20 => "shutdown",
    21 => "to_title",   22 => "cancel"
  }
  
  VOCAB_DYNAMIC_CONSTANTS =
  {
    ShopBuy: "shop_buy",
    ShopSell: "shop_sell",
    ShopCancel: "shop_cancel",
    Possession: "shop_possesion",
    ExpTotal: "exp_total",
    ExpNext: "exp_next",
    SaveMessage: "save_message",
    LoadMessage: "load_message",
    File: "file",
    PartyName: "party_name",
    Emerge: "emerge",
    Preemptive: "preepmtive",
    Surprise: "suprise",
    EscapeStart: "escape_start",
    EscapeFailure: "escape_failure",
    Victory: "victory",
    Defeat: "defeat",
    ObtainExp: "obtain_exp",
    ObtainGold: "obtain_gold",
    ObtainItem: "obtain_item",
    LevelUp: "level_up",
    ObtainSkill: "obtain_skill",
    UseItem: "use_item",
    CriticalToEnemy: "critical_to_enemy",
    CriticalToActor: "critical_to_actor",
    ActorDamage: "actor_damage",
    ActorRecovery: "actor_recovery",
    ActorGain: "actor_gain",
    ActorLoss: "actor_loss",
    ActorDrain: "actor_drain",
    ActorNoDamage: "actor_no_damage",
    ActorNoHit: "actor_no_hit",
    EnemyDamage: "enemy_damage",
    EnemyRecovery: "enemy_recovery",
    EnemyGain: "enemy_gain",
    EnemyLoss: "enemy_loss",
    EnemyDrain: "enemy_drain",
    EnemyNoDamage: "enemy_no_damage",
    EnemyNoHit: "enemy_no_hit",
    Evasion: "evasion",
    MagicEvasion: "magic_evasion",
    MagicReflection: "magic_reflection",
    CounterAttack: "counter_attack",
    Substitute: "substitute",
    BuffAdd: "buff_add",
    DebuffAdd: "debuf_add",
    BuffRemove: "buff_remove",
    ActionFailure: "action_failure",
    PlayerPosError: "player_pos_error",
    Eradicator: "eradicator",
    EventOverflow: "event_overflow"
  }
  
  $vocab_skill_types_keys = []
  
  #--------------------------------------------------------------------------
  # * Vocab reference
  #--------------------------------------------------------------------------
  class << self
    alias_method :original_basic, :basic
    alias_method :original_etype, :etype
    alias_method :original_command, :command
    alias_method :original_param, :param
  end
  
  #--------------------------------------------------------------------------
  # * Override basic
  #--------------------------------------------------------------------------
  def self.basic(basic_id)
    key = VOCAB_KEY_BASIC[basic_id]
    return original_basic(basic_id) unless key
    translation = MultilingualSystem.read_key("Database_Vocab", key)
    translation.nil? ? original_basic(basic_id) : translation
  end
  
  #--------------------------------------------------------------------------
  # * Override etype
  #--------------------------------------------------------------------------
  def self.etype(etype_id)
    key = VOCAB_KEY_ETYPE[etype_id]
    return original_command(etype_id) unless key
    translation = MultilingualSystem.read_key("Database_Vocab", key)
    translation.nil? ? original_command(etype_id) : translation
  end
  
  #--------------------------------------------------------------------------
  # * Override command
  #--------------------------------------------------------------------------
  def self.command(command_id)
    key = VOCAB_KEY_COMMAND[command_id]
    return original_command(command_id) unless key
    translation = MultilingualSystem.read_key("Database_Vocab", key)
    translation.nil? ? original_command(command_id) : translation
  end
  
  #--------------------------------------------------------------------------
  # * Override param
  #--------------------------------------------------------------------------
  def self.param(param_id)
    key = VOCAB_KEY_PARAM[param_id]
    return original_command(param_id) unless key
    translation = MultilingualSystem.read_key("Database_Vocab", key)
    translation.nil? ? original_command(param_id) : translation
  end
  
  #--------------------------------------------------------------------------
  # * Override constants
  #--------------------------------------------------------------------------
  def self.override_constants
    VOCAB_DYNAMIC_CONSTANTS.each do |const_name, key_name|
      remove_const(const_name) if const_defined?(const_name)
      translation = MultilingualSystem.read_key("Database_Vocab", key_name) || "Default_#{const_name}"
      const_set(const_name, translation)
    end
  end
  
  #--------------------------------------------------------------------------
  # * Override skill type
  #--------------------------------------------------------------------------
  def self.override_skill_type
    keys = []
    for n in 0..$vocab_skill_types_keys.size
      translation = MultilingualSystem.read_key("Database_Vocab", $vocab_skill_types_keys[n])
      keys << translation
    end
    $data_system.skill_types = keys
  end
end

#==============================================================================
# * Game Message modifier
#==============================================================================
class Game_Message
  alias multilingual_add add
  
  #--------------------------------------------------------------------------
  # * Override add
  #--------------------------------------------------------------------------
  def add(text)
    #Reading
    result = text
    if text.is_a?(String) && text.strip.start_with?("(") && text.strip.end_with?(")")
      begin
        inner = text.strip[1..-2].strip
        parts = inner.split(",").map { |s| s.strip.gsub(/^["']|["']$/, "") }
        if parts.size == 2
          table, key = parts
          translated = MultilingualSystem.read_key(table, key)
          result = translated || "#{table}.#{key}"
        end
      rescue => e
        result = "[ERROR: Translation failed]"
      end
    end
    #Linebreak
    result = result.gsub(/\\L/i, "\n") if result.is_a?(String)
    multilingual_add(result)
  end
end

#==============================================================================
# * Window ChoiceList modifier
#==============================================================================
class Window_ChoiceList < Window_Command
  alias multilingual_make_command_list make_command_list
  
  #--------------------------------------------------------------------------
  # * Override make command list
  #--------------------------------------------------------------------------
  def make_command_list
    $game_message.choices.each do |choice|
      if choice.is_a?(String) && choice.strip.start_with?("(") && choice.strip.end_with?(")")
        begin
          inner = choice.strip[1..-2].strip
          parts = inner.split(",").map { |s| s.strip.gsub(/^["']|["']$/, "") }
          if parts.size == 2
            table, key = parts
            translated = MultilingualSystem.read_key(table, key)
            result = translated || "#{table}.#{key}"
          end
        rescue => e
          result = "[ERROR: Translation failed]"
        end
      end
      add_command(result, :choice)
    end
  end
end

#==============================================================================
# * Cache modifier
#==============================================================================
module Cache
  @pictures_folder = ""
  @title1_folder = ""
  @title2_folder = ""
  class << self
    alias_method :multilingual_picture, :picture
    alias_method :multilingual_title1, :title1
    alias_method :multilingual_title2, :title2
  end
  
  #--------------------------------------------------------------------------
  # * Set local folders
  #--------------------------------------------------------------------------
  def self.set_local_folders
    #Pictures folder
    if MultilingualSystem.return_set_local_pictures_folder == true and MultilingualSystem.current_language != MultilingualSystem.default_language
      @pictures_folder = "Graphics/Pictures"<<MultilingualSystem.current_language<<"/"
    else
      @pictures_folder = "Graphics/Pictures/"
    end
    #Title folders
    if MultilingualSystem.return_set_local_title_folders == true and MultilingualSystem.current_language != MultilingualSystem.default_language
      @title1_folder = "Graphics/Titles1"<<MultilingualSystem.current_language<<"/"
      @title2_folder = "Graphics/Titles2"<<MultilingualSystem.current_language<<"/"
    else
      @title1_folder = "Graphics/Titles1/"
      @title2_folder = "Graphics/Titles2/"
    end
  end
  
  #--------------------------------------------------------------------------
  # * Override picture
  #--------------------------------------------------------------------------
  def self.picture(filename); load_bitmap(@pictures_folder, filename) end
  
  #--------------------------------------------------------------------------
  # * Override title1
  #--------------------------------------------------------------------------
  def self.title1(filename); load_bitmap(@title1_folder, filename) end
  
  #--------------------------------------------------------------------------
  # * Override title2
  #--------------------------------------------------------------------------
  def self.title2(filename); load_bitmap(@title2_folder, filename) end
end

#==============================================================================
# * Game_Interpreter modifier
#==============================================================================
class Game_Interpreter
  @@movies_folder = ""
  alias multilingual_command_261 command_261
  
  #--------------------------------------------------------------------------
  # * Set local movies folder
  #--------------------------------------------------------------------------
  def self.set_local_folder
    if MultilingualSystem.return_set_local_movies_folder == true and MultilingualSystem.current_language != MultilingualSystem.default_language
      @@movies_folder = "Movies"<<MultilingualSystem.current_language<<"/"
    else
      @@movies_folder = "Movies/"
    end
  end
  
  #--------------------------------------------------------------------------
  # * Override command_261 ("Play movie" in the events commands)
  #--------------------------------------------------------------------------
  def command_261
    Fiber.yield while $game_message.visible
    Fiber.yield
    name = @params[0]
    Graphics.play_movie(@@movies_folder + name) unless name.empty?
  end
end

#==============================================================================
# * RPG::Actor modifier
#==============================================================================
class RPG::Actor
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Actors", translation_key) || @name
  end
  
  #--------------------------------------------------------------------------
  # * Override nickname
  #--------------------------------------------------------------------------
  def nickname
    MultilingualSystem.read_key("Database_Actors", "#{translation_key}_n") || @nickname
  end
  
  #--------------------------------------------------------------------------
  # * Override description
  #--------------------------------------------------------------------------
  def description
    MultilingualSystem.read_key("Database_Actors", "#{translation_key}_d") || @description
  end
end

#==============================================================================
# * RPG::Enemy modifier
#==============================================================================
class RPG::Enemy
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty, used for database
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Enemies", translation_key) || @name
  end
end

#==============================================================================
# * RPG::Item modifier
#==============================================================================
class RPG::Item
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Items", translation_key) || @name
  end
  
  #--------------------------------------------------------------------------
  # * Override description
  #--------------------------------------------------------------------------
  def description
    MultilingualSystem.read_key("Database_Items", "#{translation_key}_d") || @description
  end
end

#==============================================================================
# * RPG::Weapon modifier
#==============================================================================
class RPG::Weapon
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Weapons", translation_key) || @name
  end
  
  #--------------------------------------------------------------------------
  # * Override description
  #--------------------------------------------------------------------------
  def description
    MultilingualSystem.read_key("Database_Weapons", "#{translation_key}_d") || @description
  end
end

#==============================================================================
# * RPG::Armor modifier
#==============================================================================
class RPG::Armor
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Armors", translation_key) || @name
  end
  
  #--------------------------------------------------------------------------
  # * Override description
  #--------------------------------------------------------------------------
  def description
    MultilingualSystem.read_key("Database_Armors", "#{translation_key}_d") || @description
  end
end

#==============================================================================
# * RPG::Skill modifier
#==============================================================================
class RPG::Skill
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Skills", translation_key) || @name
  end
  
  #--------------------------------------------------------------------------
  # * Override description
  #--------------------------------------------------------------------------
  def description
    MultilingualSystem.read_key("Database_Skills", "#{translation_key}_d") || @description
  end
  
  #--------------------------------------------------------------------------
  # * Override message1
  #--------------------------------------------------------------------------
  def message1
    MultilingualSystem.read_key("Database_Skills", "#{translation_key}_m") || @message1
  end
  
  #--------------------------------------------------------------------------
  # * Override message2
  #--------------------------------------------------------------------------
  def message2
    MultilingualSystem.read_key("Database_Skills", "#{translation_key}_m2") || @message2
  end
end

#==============================================================================
# * RPG::State modifier
#==============================================================================
class RPG::State
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_States", translation_key) || @name
  end
  
  #--------------------------------------------------------------------------
  # * Override message1
  #--------------------------------------------------------------------------
  def message1
    MultilingualSystem.read_key("Database_States", "#{translation_key}_ally") || @message1
  end
  
  #--------------------------------------------------------------------------
  # * Override message2
  #--------------------------------------------------------------------------
  def message2
    MultilingualSystem.read_key("Database_States", "#{translation_key}_enemy") || @message2
  end
  
  #--------------------------------------------------------------------------
  # * Override message3
  #--------------------------------------------------------------------------
  def message3
    MultilingualSystem.read_key("Database_States", "#{translation_key}_stay") || @message3
  end
  
  #--------------------------------------------------------------------------
  # * Override message4
  #--------------------------------------------------------------------------
  def message4
    MultilingualSystem.read_key("Database_States", "#{translation_key}_debuff") || @message4
  end
end

#==============================================================================
# * RPG::Class modifier
#==============================================================================
class RPG::Class
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty, used for database
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override name
  #--------------------------------------------------------------------------
  def name
    MultilingualSystem.read_key("Database_Class", translation_key) || @name
  end
end

#==============================================================================
# * RPG::Map modifier
#==============================================================================
class RPG::Map
  #--------------------------------------------------------------------------
  # * Check if translation key isn't empty, used for database
  #--------------------------------------------------------------------------
  def translation_key
    if @translation_key.nil?
      note.match(/<key:\s*(\w+)>/i)
      @translation_key = $1 || "item_#{@id}"
    end
    @translation_key
  end
  
  #--------------------------------------------------------------------------
  # * Override display name
  #--------------------------------------------------------------------------
  def display_name
    MultilingualSystem.read_key("Database_Maps", translation_key) || @display_name
  end
end

#==============================================================================
# * Scene Manager modifier
#==============================================================================
module SceneManager
  class << self
    alias multilingual_run run
    
    #--------------------------------------------------------------------------
    # * Override run
    #--------------------------------------------------------------------------
    def run
      MultilingualSystem.first_initialize
      multilingual_run
    end
  end
end

#==============================================================================
# * Scene Title modifier
#==============================================================================
class Scene_Title
  alias multilingual_start start
  
  #--------------------------------------------------------------------------
  # * Override start
  #--------------------------------------------------------------------------
  def start
    multilingual_start
    $vocab_skill_types_keys = $data_system.skill_types
    Vocab.override_skill_type
  end
end
