#! /usr/bin/env ruby

=begin

    gsWax
    v 0.12.01
    
     an audio player for folks who miss their vinyl

    Copyright (C)  2012 Justin Kaiden

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


require 'green_shoes'
require 'observer'
require 'cgi'
brainsdir = File.join(File.dirname(File.expand_path(__FILE__)), "brains")
require File.join(brainsdir, "shared.rb")
require File.join(brainsdir, "Wax")
require File.join(brainsdir, "turntable")
require File.join(brainsdir, "playlist")
require File.join(brainsdir,  "browser")
require File.join(brainsdir, "scrollbox")
require File.join(brainsdir, "settings_manager")

Settings.read
scl = Settings.scale


Shoes.app(width: (727 * scl), height: (675 * scl), title: "gsWax") do
	
	Shoes::App.class_eval{include Wax}
	init_wax
	wax_pipeline.volume = Settings.volume
	
	Gtk::Drag.dest_set(
		self.win,
		Gtk::Drag::DEST_DEFAULT_ALL,
		[["text/plain", 0, 0]],
		Gdk::DragContext::ACTION_COPY
	)
	self.win.signal_connect("drag_data_received"){|w, context, x, y, data, i, t|
		data_drop(data.data, context)
	}
	
	
	def on_signals(message)
		if message.class == Array
			cmd = message[0].split(":")[-1]
			msg = message[1..-1]
		else
			cmd, msg = nil, nil
		end
		
		case message
			when "wax_info"; on_wax_info
			when "eos"; @table.update(Settings.at_bat)
			when "PLAYLIST"; playlist(wax_lineup)
			when "CLEAR_LIST"; clear_list
			when "BROWSER"; browser
			when "SETTINGS"; settings_manager
			when "UPDATE_SETTINGS"; update_settings
			when "TRACK_PROGRESS"; track_progress
			when "PLAY_PAUSE_TRACK"; play_pause_track
			when "PREVIOUS_TRACK"; previous_track
			when "NEXT_TRACK"; next_track
			when "SHUFFLE_TOGGLE"; toggle_wax_shuffle
			when "PLAYLIST_CLOSED"; @playlist = nil
			when "BROWSER_CLOSED"; @browser = nil
			when "SETTINGS_CLOSED"; @settings_man = nil
		end
		
		case cmd
			when "PLAY_NOW"; play_now(message[-1])
			when "APPEND"; add_to_list(message[1..-1])
			when "PREPEND"; add_to_list(message[1..-1], "prepend")
			when "SAVE_LIST"; Settings.playlist_file = message[1]
			when "LOAD_LIST"; load_playlist(message)
			when "VOLUME"; set_volume(message[-1])
			when "SEEK"; seek(message[-1])
		end
		
	end
	
	def on_wax_info
		@info_area.set_text(wax_info) if @info_area
	end
	
	def add_to_list(tracks, pos = "append")
		flag = true if wax_lineup.empty?
		
		if pos == "prepend"
			tracks.reverse.each{|e| wax_lineup.insert(0, e)}
			tracks.shuffle.each{|e| wax_lupine.insert(0, e)}
		else
			tracks.each{|e| wax_lineup << e}
			tracks.shuffle.each{|e| wax_lupine << e}
		end
		
		if flag
			batter_up_wax
			@info_area.set_text("gsWax - ready to rock")
			@table.update(Settings.at_bat)
		end
	end
	
	def data_drop(data, context)
		raw = CGI.unescape(data)
		arr = raw.chomp.split("file:#{File::Separator}#{File::Separator}")
		okfiles = [/.mp3/, /.flac/, /.ogg/, /.wav/]
		selected = []
		
		arr.each{|path|
			path.chomp!
			if File.directory?(path)
				Find.find(path){|item|
					okfiles.each{|ok| selected << item if File.extname(item.downcase) =~ ok}
				}
			elsif File.file?(path)
				ext  = File.extname(path.downcase)
				okfiles.each{|ok| selected << path if ext =~ ok}
				if ext == ".pls" or ext == ".m3u"
					File.open(path){|file|
						file.each_line{|line|
							if line.include?("http:")
								selected << /http.+/.match(line).to_s
							end
						}
					}
				end
			end
		}

		add_to_list(selected)
		@playlist.add(selected) if @playlist

		Gtk::Drag.finish(context, true, false, 0)
	end
	
	def browser
		if @browser
			@browser.close_window; @browser = nil
		else
			if Settings.music_dir
				if File.exists?(Settings.music_dir)
					dir = Settings.music_dir
				end
			else
				dir = File.dirname(File.expand_path(__FILE__))
			end
			@browser = DirBrowser.new(dir)
			@browser.add_observer(self, :on_signals)
			@browser.add_observer(@playlist, :on_browser_signals) if @playlist
		end
	end
	
	def playlist(list)
		if @playlist
			@playlist.close_window; @playlist = nil
		else
			@playlist = PlayList.new; @playlist.add(list)
			@playlist.add_observer(self, :on_signals)
			@browser.add_observer(@playlist, :on_browser_signals) if @browser
		end
	end
	
	def load_playlist(message)
		stop_wax if wax_state != "stopped"
		f_name = message[1]
		Settings.playlist_file = f_name
		Settings.line_up.clear
		tracks = message[2..-1]
		tracks.each{|track| Settings.line_up << track}
		read_wax_lineup
		@table.update(Settings.at_bat)
		@info_area.set_text("gsWax - ready to rock")
	end
	
	def clear_list
		stop_wax if wax_state != "stopped"
		wax_lineup.clear
		wax_lupine.clear
		self.wax_batter = 0
		batter_up_wax
		@table.update(Settings.at_bat)
		@table.set_state("stopped")
		@info_area.set_text("gsWax")
	end
	
	def settings_manager
		if @settings_man
			@settings_man.close_window; @settings_man = nil
		else
			@settings_man = SettingsManager.new
			@settings_man.add_observer(self, :on_signals)
		end
	end
	
	def track_progress
		unless @tracking
			timeout = GLib::Timeout.add(100){
				if wax_state == "playing"
					if wax_tracking
						pos_query = Gst::QueryPosition.new(3)
						wax_pipeline.query(pos_query)
						track_pos = pos_query.parse[1] / 10000.0
						arm_pos =(((track_pos * 1.0) / wax_duration) / 1000.0).round(1)
						@table.set_arm_pos(arm_pos)
						@tracking = true
					end
				else
					@tracking = false
					false
				end
			}
		end
	end
	
	def play_now(track)
		if wax_lineup.include?(track)
			self.wax_batter = wax_lineup.index(track) unless Settings.shuffle
			self.wax_batter = wax_lupine.index(track) if Settings.shuffle
			batter_up_wax
			stop_wax; play_pause_track
		else
			if wax_lineup.empty?
				wax_lineup << track
				batter_up_wax
				play_pause_track
			else
				wax_lineup.insert(wax_batter + 1, track) unless Settings.shuffle
				wax_lupine.insert(wax_batter + 1, track) if Settings.shuffle
				next_track
			end
			end
			@table.update(Settings.at_bat)
	end
	
	def play_pause_track
		play_pause_wax
		@table.set_state(wax_state)
		track_progress
	end
	
	def previous_track
		prev_wax
		@table.update(Settings.at_bat)
		@table.set_state(wax_state)
	end
	
	def next_track
		next_wax
		@table.update(Settings.at_bat)
		@table.set_state(wax_state)
	end
	
	def set_volume(vol)
		unless vol == Settings.volume
			wax_pipeline.volume = vol
			Settings.volume = vol
		end
	end
	
	def seek(percent)
		if wax_duration
			sought = wax_duration * percent
      			seek_to_wax((sought * 1000.0).round)
			@table.set_arm_pos(percent)
		end
	end
	
	def update_settings
		canvas.children.each{|child| canvas.remove(child)}
		self.win.resize(727 * Settings.scale, 675 * Settings.scale)
		@info_area.resize
		@table.resize
		@table.set_state(wax_state)
		set_table
		@info_area.show_text(wax_info)
	end
	
	def set_table
		canvas.put(@info_area.main, 0, 0)
		canvas.put(@table.main, 0, 77.0 * Settings.scale)
	end
	
	bga = Settings.bg_color
	bga.each{|v| v = v / 257}
	background(bga)
	
	@info_area = ScrollBox.new(wax_info)
	@table = Turntable.new
	@table.add_observer(self, :on_signals)
	@table.update(Settings.at_bat)
	@table.main.signal_connect("destroy"){
		stop_wax
		Settings.line_up = wax_lineup
		Settings.save
	}
	
	set_table
	
	add_observer(self, :on_signals) # (add self as an observer to Wax)
	
end	#Shoes.app
