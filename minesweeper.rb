class Board
  def make_board
    @board = [[Tile.new]*9]*9
  end

  def add_bombs
    until bombs == 10
      current_tile = @board.sample.sample
      unless current_tile.bomb?
        current_tile.make_bomb
        bombs += 1
      end
    end
  end
end

class Tile
  def initialize
    @bomb = false
  end

  def make_bomb
    @bomb = true
  end

  def bomb?
    @bomb
  end
end

p Board.new.make_board