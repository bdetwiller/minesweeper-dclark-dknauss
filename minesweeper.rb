require 'debugger'
class Board
  def initialize
    @board = []
    @game_over = false
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
    puts "Game Over!" if @game_over
  end

  def add_bombs
    bombs = 0
    until bombs == 10
      current_tile = @board.sample.sample
      unless current_tile.bomb?
        current_tile.make_bomb
        bombs += 1
      end
    end
  end

  def reveal(coordinates)
    x, y = coordinates
    tile = @board[y][x]
    if tile.bomb?
      game_over
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

  def game_over
    @game_over = true
  end

  def tile_neighbors(coordinates)
    neighbors_coords = []
    deltas = [[1,0],[1,1],[0,1],[-1,1],[-1,0],[-1,-1],[0,-1],[1,-1]]
    deltas.each do |delta|
      neighbor_coords = [delta, coordinates].transpose.map {|x| x.reduce(:+)}
      neighbors_coords << neighbor_coords if valid_tile(neighbor_coords)
    end
    neighbors_coords
  end

  def valid_tile(coordinates)
    x,y = coordinates
    (0..8).include?(x) && (0..8).include?(y) && @board[y][x].display == '*'
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
  end

  def play

  end

end


