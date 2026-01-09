# encoding: UTF-8
# frozen_string_literal: true

require 'gosu'
require 'yaml'

module Pacman
  class WindowGame < Gosu::Window
    CELL_WALL = '#'
    CELL_EMPTY = ' '
    CELL_PELLET = '.'

    def initialize(map_path: nil)
      @width_cells = 31
      @height_cells = 21
      @cell = 24
      @hud_h = 48
      super(@width_cells * @cell, @height_cells * @cell + @hud_h)
      self.caption = 'Pacman Ruby Window'

      @tick_ms = 80
      @last_step_ms = Gosu.milliseconds

      @score = 0
      @lives = 3
      @pellet_count = 0
      @running = true
      @frame = 0
      @ghost_move_delay = 2
      @last_move = [0, 0]

      @font = Gosu::Font.new(24)

      if !build_map_from_yaml
        @map_path = map_path
        build_ok = build_map_from_yaml
        unless build_ok
          build_map
          place_entities
        end
      end

      if ENV['PACMAN_DEBUG']
        idx = ENV['PACMAN_DEBUG_GHOST'] ? ENV['PACMAN_DEBUG_GHOST'].to_i : 0
        puts "DEBUG: ghosts=#{@ghosts.size} logging ghost index=#{idx}"
        puts "DEBUG: map=#{@map_path || find_map_path || 'default'} size=#{@width_cells}x#{@height_cells}"
      end
    end

    def update
      handle_input
      return unless @running

      now = Gosu.milliseconds
      if now - @last_step_ms >= @tick_ms
        @last_step_ms = now
        step_world
      end
    end

    def draw
      draw_background
      draw_hud
      draw_map
      draw_entities
      draw_end_text unless @running
    end

    def button_down(id)
      case id
      when Gosu::KB_ESCAPE then close
      when Gosu::KB_Q then close
      end
      super
    end

    private

    def handle_input
      dx = dy = 0
      if Gosu.button_down?(Gosu::KB_W) || Gosu.button_down?(Gosu::KB_UP)
        dy = -1
      elsif Gosu.button_down?(Gosu::KB_S) || Gosu.button_down?(Gosu::KB_DOWN)
        dy = 1
      elsif Gosu.button_down?(Gosu::KB_A) || Gosu.button_down?(Gosu::KB_LEFT)
        dx = -1
      elsif Gosu.button_down?(Gosu::KB_D) || Gosu.button_down?(Gosu::KB_RIGHT)
        dx = 1
      end
      # 常に現在の押下状態を反映（未押下なら [0,0]）
      @last_move = [dx, dy]
    end

    def step_world
      @frame += 1
      # move player only while key is held
      if @last_move[0] != 0 || @last_move[1] != 0
        nx = @player[0] + @last_move[0]
        ny = @player[1] + @last_move[1]
        if can_move?(nx, ny)
          @player = [nx, ny]
          # consume pellet only when moved
          if @map[ny][nx] == CELL_PELLET
            @map[ny][nx] = CELL_EMPTY
            @score += 10
            @pellet_count -= 1
            win! if @pellet_count <= 0
          end
        end
      end

      # move ghosts slower
      if (@frame % @ghost_move_delay).zero?
        @ghosts = @ghosts.each_with_index.map { |g, i| ghost_step(i, g) }
      end

      # collision with ghosts
      @ghosts.each do |g|
        if g[0] == @player[0] && g[1] == @player[1]
          @lives -= 1
          if @lives <= 0
            game_over!
          else
            @player = @player_spawn.dup
          end
        end
      end
    end

    def build_map
      @map = Array.new(@height_cells) { Array.new(@width_cells, CELL_PELLET) }
      # border walls
      @height_cells.times do |y|
        @map[y][0] = CELL_WALL
        @map[y][@width_cells - 1] = CELL_WALL
      end
      @width_cells.times do |x|
        @map[0][x] = CELL_WALL
        @map[@height_cells - 1][x] = CELL_WALL
      end
      add_wall_rect(2, 2, 5, 3)
      add_wall_rect(@width_cells - 7, 2, 5, 3)
      add_wall_rect(2, @height_cells - 5, 6, 3)
      add_wall_rect(@width_cells - 8, @height_cells - 5, 6, 3)
      add_wall_rect(@width_cells / 2 - 2, 6, 5, 3)
      add_wall_rect(@width_cells / 2 - 10, 10, 7, 3)
      add_wall_rect(@width_cells / 2 + 4, 10, 7, 3)
      add_wall_rect(@width_cells / 2 - 2, 14, 5, 3)

      # tunnel
      tunnel_y = @height_cells / 2
      (((@width_cells / 2) - 12)..((@width_cells / 2) - 1)).each do |x|
        @map[tunnel_y][x] = CELL_EMPTY unless @map[tunnel_y][x] == CELL_WALL
      end
      (((@width_cells / 2) + 1)..((@width_cells / 2) + 12)).each do |x|
        @map[tunnel_y][x] = CELL_EMPTY unless @map[tunnel_y][x] == CELL_WALL
      end

      # count pellets
      @pellet_count = 0
      @height_cells.times do |y|
        @width_cells.times do |x|
          @pellet_count += 1 if @map[y][x] == CELL_PELLET
        end
      end
    end

    def build_map_from_yaml
      begin
        path = find_map_path
        return false unless path
        data = YAML.load_file(path)
        grid = data['grid']
        return false unless grid && grid.is_a?(Array) && !grid.empty?

        @height_cells = grid.size
        @width_cells = grid.first.size
        @map = Array.new(@height_cells) { Array.new(@width_cells, CELL_EMPTY) }
        @pellet_count = 0
        ghost_spawns = []
        @player_spawn = nil

        @height_cells.times do |y|
          row = grid[y]
          @width_cells.times do |x|
            ch = row[x]
            case ch
            when '#'
              @map[y][x] = CELL_WALL
            when '.'
              @map[y][x] = CELL_PELLET
              @pellet_count += 1
            when 'P'
              @map[y][x] = CELL_EMPTY
              @player_spawn = [x, y]
            when 'G'
              @map[y][x] = CELL_EMPTY
              ghost_spawns << [x, y]
            else
              @map[y][x] = CELL_EMPTY
            end
          end
        end

        @player = (@player_spawn || [@width_cells / 2, @height_cells - 3]).dup
        @ghosts = ghost_spawns.any? ? ghost_spawns : [[@width_cells / 2, @height_cells / 2]]
        @ghost_dirs = @ghosts.map { |g| initial_ghost_dir(g) }
        true
      rescue StandardError
        false
      end
    end

    def find_map_path
      return @map_path if @map_path && File.exist?(@map_path)
      env_map = ENV['PACMAN_MAP']
      return env_map if env_map && File.exist?(env_map)
      cwd_map = File.join(Dir.pwd, 'config', 'maps', 'default.yaml')
      return cwd_map if File.exist?(cwd_map)
      gem_map = File.expand_path('../../config/maps/default.yaml', __dir__)
      return gem_map if File.exist?(gem_map)
      nil
    end

    def add_wall_rect(x, y, w, h)
      h.times do |dy|
        w.times do |dx|
          xx = x + dx
          yy = y + dy
          next if xx <= 0 || yy <= 0 || xx >= @width_cells - 1 || yy >= @height_cells - 1
          @map[yy][xx] = CELL_WALL
        end
      end
    end

    def place_entities
      @player_spawn = [@width_cells / 2, @height_cells - 3]
      @player = @player_spawn.dup
      gh_spawn = [@width_cells / 2, @height_cells / 2]
      @ghosts = [
        gh_spawn.dup,
        [gh_spawn[0] - 4, gh_spawn[1]],
        [gh_spawn[0] + 4, gh_spawn[1]]
      ]
      @ghost_dirs = @ghosts.map { |g| initial_ghost_dir(g) }
    end

    def can_move?(x, y)
      return false if x < 0 || y < 0 || x >= @width_cells || y >= @height_cells
      @map[y][x] != CELL_WALL
    end

    # simplified AI: helpers for hand-rule are removed

    def debug_ghost?(i)
      return false unless ENV['PACMAN_DEBUG']
      idx = ENV['PACMAN_DEBUG_GHOST'] ? ENV['PACMAN_DEBUG_GHOST'].to_i : 0
      i == idx
    end

    def manhattan(a, b)
      (a[0] - b[0]).abs + (a[1] - b[1]).abs
    end

    def dist_to_player(x, y)
      manhattan([x, y], @player)
    end

    def ghost_step(i, g)
      dirs = [[1,0],[-1,0],[0,1],[0,-1]]
      available = dirs.select { |dx, dy| can_move?(g[0] + dx, g[1] + dy) }
      return g if available.empty?

      dir = @ghost_dirs[i] || initial_ghost_dir(g)
      @ghost_dirs[i] = dir
      reverse = [-dir[0], -dir[1]]
      forward_ok = available.include?(dir)
      intersection = available.length >= 3

      if intersection
        # 分岐では「前回通った道（逆方向）」のみ除外し、残りからランダム選択
        choices = available.reject { |d| d == reverse }
        if debug_ghost?(i)
          avail_info = available.map { |d| [[d[0], d[1]], dist_to_player(g[0] + d[0], g[1] + d[1])] }
          choice_info = choices.map { |d| [[d[0], d[1]], dist_to_player(g[0] + d[0], g[1] + d[1])] }
          puts "G#{i} INTERSECTION pos=#{g.inspect} player=#{@player.inspect} dir=#{dir.inspect} avail=#{avail_info.inspect} choices=#{choice_info.inspect}"
        end
        chosen = choices.sample
        if debug_ghost?(i)
          cur = dist_to_player(g[0], g[1])
          nxt = dist_to_player(g[0] + chosen[0], g[1] + chosen[1])
          puts "G#{i} chosen=#{chosen.inspect} dist_current=#{cur} dist_next=#{nxt} delta=#{nxt - cur}"
        end
        return g unless chosen
        @ghost_dirs[i] = chosen
        [g[0] + chosen[0], g[1] + chosen[1]]
      elsif forward_ok
        if debug_ghost?(i)
          cur = dist_to_player(g[0], g[1])
          nxt = dist_to_player(g[0] + dir[0], g[1] + dir[1])
          puts "G#{i} FORWARD pos=#{g.inspect} player=#{@player.inspect} dir=#{dir.inspect} dist_current=#{cur} dist_next=#{nxt} delta=#{nxt - cur}"
        end
        [g[0] + dir[0], g[1] + dir[1]]
      else
        choices = available.reject { |d| d == reverse }
        if debug_ghost?(i)
          avail_info = available.map { |d| [[d[0], d[1]], dist_to_player(g[0] + d[0], g[1] + d[1])] }
          choice_info = choices.map { |d| [[d[0], d[1]], dist_to_player(g[0] + d[0], g[1] + d[1])] }
          puts "G#{i} BLOCKED pos=#{g.inspect} player=#{@player.inspect} dir=#{dir.inspect} avail=#{avail_info.inspect} choices=#{choice_info.inspect}"
        end
        chosen = choices.sample
        if debug_ghost?(i)
          cur = dist_to_player(g[0], g[1])
          nxt = dist_to_player(g[0] + chosen[0], g[1] + chosen[1])
          puts "G#{i} chosen=#{chosen.inspect} dist_current=#{cur} dist_next=#{nxt} delta=#{nxt - cur}"
        end
        return g unless chosen
        @ghost_dirs[i] = chosen
        [g[0] + chosen[0], g[1] + chosen[1]]
      end
    end

    def initial_ghost_dir(g)
      dirs = [[1,0],[-1,0],[0,1],[0,-1]]
      choices = dirs.select { |dx, dy| can_move?(g[0] + dx, g[1] + dy) }
      choices.sample || [0,0]
    end

    def draw_background
      Gosu.draw_rect(0, 0, width, height, Gosu::Color::BLACK, 0)
    end

    def draw_hud
      @font.draw_text("Score: #{@score}   Lives: #{@lives}", 10, 10, 1, 1.0, 1.0, Gosu::Color::WHITE)
      @font.draw_text('Move: WASD/Arrows   Quit: Esc/Q', 10, 10 + 24, 1, 1.0, 1.0, Gosu::Color::GRAY)
    end

    def draw_map
      offset_y = @hud_h
      @height_cells.times do |y|
        @width_cells.times do |x|
          ch = @map[y][x]
          if ch == CELL_WALL
            Gosu.draw_rect(x * @cell, offset_y + y * @cell, @cell, @cell, Gosu::Color.argb(0xff_1d2b53), 1)
          elsif ch == CELL_PELLET
            # draw small dot in center
            size = @cell / 6
            px = x * @cell + (@cell - size) / 2
            py = offset_y + y * @cell + (@cell - size) / 2
            Gosu.draw_rect(px, py, size, size, Gosu::Color::WHITE, 1)
          end
        end
      end
    end

    def draw_entities
      offset_y = @hud_h
      # player
      Gosu.draw_rect(@player[0] * @cell, offset_y + @player[1] * @cell, @cell, @cell, Gosu::Color::YELLOW, 2)
      # ghosts
      @ghosts.each do |g|
        Gosu.draw_rect(g[0] * @cell, offset_y + g[1] * @cell, @cell, @cell, Gosu::Color::RED, 2)
      end
    end

    def draw_end_text
      msg = @lives <= 0 ? 'Game Over' : 'You Win!'
      @font.draw_text(msg, width / 2 - 80, height / 2 - 20, 3, 1.5, 1.5, Gosu::Color::WHITE)
      @font.draw_text('Press Esc/Q to exit', width / 2 - 140, height / 2 + 20, 3, 1.0, 1.0, Gosu::Color::GRAY)
    end

    def game_over!
      @running = false
    end

    def win!
      @running = false
    end
  end
end
