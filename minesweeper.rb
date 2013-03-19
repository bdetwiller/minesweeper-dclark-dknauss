require 'debugger'
require 'yaml'
class Board
  attr_reader :board_dimension

  def initialize(board_size)
    @board_dimension = (board_size == :small ? 9 : 16)
    @board = []
    @game_over = false
    @num_bombs = (@board_dimension == 9 ? 10 : 40)
    make
  end

  def make
    @board_dimension.times do |i|
      line = []
      @board_dimension.times do |j|
        line << Tile.new
      end
      @board << line
    end
    add_bombs
  end

  def add_bombs
    bombs = 0
    until bombs == @num_bombs
      current_tile = @board.sample.sample
      unless current_tile.bomb?
        current_tile.make_bomb
        bombs += 1
      end
    end
  end

  def display
    display_small if @board_dimension == 9
    display_large if @board_dimension == 16
  end

  def display_small #REV, Really nice display! Seems like you could make one display method that handles both small and large cases
    puts
    print '      '
    "A".upto("I") { |num| print "#{num}  " }
    puts
    puts "    #{"###" * 9}##"
    @board.each_with_index do |row, i|
      print "#{i}  #  "
      row.each { |tile| print "#{tile.display}  " }
      print "#"
      puts
    end
    puts "    #{"###" * 9}##"
    puts
  end

  def display_large
    puts
    print '       '
    "A".upto("P") { |num| print "#{num}  " }
    puts
    puts "     #{"###" * @board_dimension}##"
    @board.each_with_index do |row, i|
      if i > 9
        print "#{i}  #  "
      else
        print "#{i}   #  "
      end
      row.each { |tile| print "#{tile.display}  " }
      print "#"
      puts
    end
    puts "     #{"###" * @board_dimension}##"
    puts
  end

  def select_tile(coordinates)
    x, y = coordinates
    @board[y][x]
  end

  def flag(coordinates)
    tile = select_tile(coordinates)
    tile.display_state = 'F'
  end

  def reveal(coordinates)
    tile = select_tile(coordinates)
    if tile.bomb?
      lost
    else
      bombs = count_surrounding_bombs(coordinates)
      if bombs == 0
        tile.display_state = '_'
        tile_neighbors(coordinates).each { |coords| reveal(coords) }
      else
        tile.display_state = "#{bombs}"
      end
    end
  end

  def valid_tile?(coordinates)
    x,y = coordinates
    (0..(@board_dimension - 1)).include?(x) &&
    (0..(@board_dimension - 1)).include?(y) &&
    ['*','F'].include?(@board[y][x].display)
  end

  def tile_neighbors(coordinates)
    neighbors_coords = []
    deltas = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]
    deltas.each do |delta|
      neighbor_coords = [delta, coordinates].transpose.map {|x| x.reduce(:+)}
      neighbors_coords << neighbor_coords if valid_tile?(neighbor_coords)
    end
    neighbors_coords
  end

  def count_surrounding_bombs(coordinates)
    bombs = 0
    tile_neighbors(coordinates).each do |neighbor_coords|
      neighbor_tile = select_tile(neighbor_coords)
      bombs += 1 if neighbor_tile.bomb?
    end
    bombs
  end

  def lost
    @game_over = true
  end

  def game_over?
    @game_over
  end

  def won?
    flags = 0
    @board.each do |line|
      line.each do |tile|
        case tile.display
        when '*' then return false
        when 'F' then flags += 1
        end
      end
    end
    return true if flags == @num_bombs
    false
  end

end

class Tile
  def initialize
    @bomb = false
    @display_state = '*'
  end

  def display_state=(state)
    @display_state = state
  end

  def display
    @display_state
  end

  def make_bomb
    @bomb = true
  end

  def bomb?
    @bomb
  end
end

class Game #REV this class is super clean. Good the use of cases!
  attr_accessor :board

  def print_welcome_shit
    puts "Welcome to Minesweeper"
    puts
  end

  def get_load_or_new_game
    puts "Would you like to load or start a new game?"
    puts "Press 'l' to load, 'n' for new game."
    answer = gets.chomp.upcase[0]
    case answer
    when 'L' then load_game
    when 'N' then new_game
    end
  end

  def load_game
    puts "Enter the filename of the game you'd like to load."
    puts "(e.g. my_save_game.yaml)"
    filename = gets.chomp
    save_game = YAML::load(File.read(filename))
    @board = save_game.board
    puts "Welcome Back!"
  end

  def new_game
    puts "Would you like a small (9x9) or large (16x16) board?"
    puts "enter 's' or 'l'"
    size = case gets.chomp.upcase[0]
    when 'S' then :small
    when 'L' then :large
    else :small
    end
    @board = Board.new(size)
  end

  def quit
    puts "Are you sure you want to quit (y/n)?"
    @board.lost if gets.chomp.upcase[0] == 'Y'
  end

  def help
    puts 'Enter coordinates prefixed by "r" or "f" to reveal/flag (e.g. "rA1")'
    puts 'or "q" to quit, "s" to save, or "h" to show this message.'
    puts 'Hit the <AnyKey>-key to dismiss.'
    gets
  end

  def parse_coordinates(user_input)
    # user_input = "R#{user_input}" if user_input.length == 2
    mode = case user_input[0]
    when 'R' then :reveal
    when 'F' then :flag
    when 'Q' then :quit
    when 'S' then :save
    when 'H' then :help
    end
    if [:reveal, :flag].include?(mode)
      x_range = (@board.board_dimension == 9 ? "ABCDEFGHI" : "ABCDEFGHIJKLMNOP")
      x = x_range.index(user_input[1])
      y = user_input[2..-1].to_i
      return [[x, y], mode]
    else
      [[0,0], mode]
    end
  end

  def get_coordinates_and_mode #REV, I couldn't get it to accept any input I gave it, 2B, B2, 2B R, 22, 2,2 etc. 
    print "Enter coordinates: "
    coordinates, mode = parse_coordinates(gets.chomp.upcase)
    until valid_input?(coordinates, mode)
      print "Please enter valid coordinates of an unchecked tile: "
      coordinates, mode = parse_coordinates(gets.chomp.upcase)
    end
    [coordinates, mode]
  end

  def valid_input?(coordinates, mode)
    return true if [:quit, :save, :help].include?(mode)
    @board.valid_tile?(coordinates) && [:reveal, :flag].include?(mode)
  end

  def take_action(coords_and_mode)
    coords, mode = coords_and_mode
    case mode
    when :reveal then @board.reveal(coords)
    when :flag then @board.flag(coords)
    when :quit then quit
    when :save then save
    when :help then help
    end
  end

  def play
    print_welcome_shit #REV haha
    get_load_or_new_game
    until @board.game_over? || @board.won?
      @board.display
      take_action(get_coordinates_and_mode)
    end
    if @board.won?
      puts "Congratulations, you've won!"
    else
      puts "Game Over"
    end
  end

  def clean_filename(user_input)
    return "my_saved_game" if user_input.length < 1
    user_input = user_input[0,140] if user_input.length > 140
    user_input.gsub!(' ','_')
    user_input.gsub(/\W/,'')
  end

  def save
    puts "What do you want to call your save game?"
    file_name = clean_filename(gets.chomp)
    File.open("#{file_name}.yaml", 'w') do |f|
      f.puts self.to_yaml
    end
  end

end

game = Game.new
game.play
