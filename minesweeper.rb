require 'debugger'
class Board
  def initialize
    @board = []
    @game_over = false
    @num_bombs = 1
    make
  end

  def make
    9.times do |i|
      line = []
      9.times do |j|
        line << Tile.new
      end
      @board << line
    end
    add_bombs
    print_bombs
  end

  def display
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

  def print_bombs
    @board.each_with_index do |row, i|
      row.each_with_index do |tile, j|
        print "#{[j,i]} " if @board[i][j].bomb?
      end
    end
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
      bombs = 0
      tile_neighbors(coordinates).each do |neighbor_coords|
        x, y = neighbor_coords
        neighbor_tile = @board[y][x]
        bombs += 1 if neighbor_tile.bomb?
      end
      if bombs == 0
        tile.display_state = '_'
        tile_neighbors(coordinates).each { |coords| reveal(coords) }
      else
        tile.display_state = "#{bombs}"
      end
    end
  end

  def lost
    @game_over = true
  end

  def game_over?
    @game_over
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

  def valid_tile?(coordinates)
    x,y = coordinates
    (0..8).include?(x) && (0..8).include?(y) &&
    ['*','F'].include?(@board[y][x].display)
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

class Game
  def initialize
    @board = Board.new
  end

  def print_welcome_shit
    puts "Welcome to Minesweeper"
    puts "Let's play."
    puts
    puts "Start by choosing the coordinate you want to reveal."
    puts "Choose the coordinate prefixed by r/f (reveal/flag) (e.g. 'rA1')"
  end

  def parse_coordinates(user_input)
    mode = case user_input[0]
    when 'R' then :reveal
    when 'F' then :flag
    end
    x = "ABCDEFGHI".index(user_input[1])
    y = user_input[2].to_i
    [[x, y], mode]
  end

  def get_coordinates_and_mode
    print "Enter coordinates (e.g. 'rA1', 'fB7'): "
    coordinates, mode = parse_coordinates(gets.chomp.upcase)
    until valid_input?(coordinates, mode)
      print "Please enter valid coordinates of an unchecked tile: "
      coordinates, mode = parse_coordinates(gets.chomp.upcase)
    end
    [coordinates, mode]
  end

  def valid_input?(coordinates, mode)
    @board.valid_tile?(coordinates) && [:reveal, :flag].include?(mode)
  end

  def play
    print_welcome_shit
    until @board.game_over? || @board.won?
      @board.display
      coords, mode = get_coordinates_and_mode
      @board.reveal(coords) if mode == :reveal
      @board.flag(coords) if mode == :flag
      @board.print_bombs
    end
    if @board.won?
      puts "Congratulations, you've won!"
    else
      puts "BOOOOOOOOOOOOOOOM"
    end
  end
end

game = Game.new
game.play
