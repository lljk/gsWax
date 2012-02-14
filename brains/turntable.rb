=begin
	
	this file is part of: gsWax v. 0.12.01

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


class Turntable
	include Observable
	attr_accessor :main
	
	def initialize
		@imagedir = File.join(Settings.brains_dir, "images")
		@arm_pos = 0
		@vol_pos = ((Settings.volume * -1) +1) * (170 * Settings.scale)
		@main = Gtk::VBox.new(true, 2)
		@arm_file = File.join(Settings.brains_dir, "images", "arm.png")
		@cover_pix = Gdk::Pixbuf.new(File.join(@imagedir, "no_cover.png"), 485 * Settings.scale, 485 * Settings.scale)
		@first = true
		init_ui
	end
	
	def init_ui
		@main.set_size_request(727 * Settings.scale, 598 * Settings.scale)
		@arm_pix = Gdk::Pixbuf.new(@arm_file, 146 * Settings.scale, 512 * Settings.scale)

			layout = Gtk::Layout.new

				@cover_image = Gtk::Image.new(@cover_pix)

				@play_overlay = Gdk::Pixbuf.new(File.join(@imagedir, "stanton1.png"), 727 * Settings.scale, 598 * Settings.scale)
				@pause_overlay = Gdk::Pixbuf.new(File.join(@imagedir, "stanton.png"), 727 * Settings.scale, 598 * Settings.scale)
				@table_overlay = Gtk::Image.new(@pause_overlay)
				
				@arm_area = Gtk::EventBox.new
				@arm_area.set_size_request(450.0 * Settings.scale, 540.0 * Settings.scale)
				@arm_area.set_visible_window(false)
				@arm_area.signal_connect("expose_event"){|w, e| draw_arm(w)}
				@arm_area.signal_connect("button-press-event"){|w, e| send_seek_data(e)}####
				
				transport_btns = Gtk::HBox.new(false, 0)
				
					prev_btn = ImageButton.new{emit_signal("PREVIOUS_TRACK")}
					prev_btn.set_images(
						File.join(@imagedir, "prev.png"),
						File.join(@imagedir, "prevHOVER.png"),
						68 * Settings.scale
					)
					
					@play_btn = ImageButton.new{emit_signal("PLAY_PAUSE_TRACK")}
					@play_btn.set_images(
						File.join(@imagedir, "play.png"),
						File.join(@imagedir, "playHOVER.png"),
						68 * Settings.scale
					)
					
					next_btn = ImageButton.new{emit_signal("NEXT_TRACK")}
					next_btn.set_images(
						File.join(@imagedir, "next.png"),
						File.join(@imagedir, "nextHOVER.png"),
						68 * Settings.scale
					)
				
				transport_btns.pack_start(prev_btn, false, false, 2)
				transport_btns.pack_start(@play_btn, false, false, 2)
				transport_btns.pack_start(next_btn, false, false, 2)
				
				@shuf_btn = ImageButton.new{toggle_shuffle}
				toggle_shuffle
		
				playlist_browser_btns = Gtk::HBox.new(false, 0)
				
					list_btn = ImageButton.new{emit_signal("PLAYLIST")}
					list_btn.set_images(
						File.join(@imagedir, "playlist.png"),
						File.join(@imagedir, "playlistHOVER.png"),
						45 * Settings.scale
					)
					
					browser_btn = ImageButton.new{emit_signal("BROWSER")}
					browser_btn.set_images(
						File.join(@imagedir, "dugout.png"),
						File.join(@imagedir, "dugoutHOVER.png"),
						45 * Settings.scale
					)
				
				playlist_browser_btns.pack_start(list_btn, false, false, 2)
				playlist_browser_btns.pack_start(browser_btn, false, false, 2)
				
				settings_btn = ImageButton.new{emit_signal("SETTINGS")}
				settings_btn.set_images(
					File.join(@imagedir, "settings.png"),
					File.join(@imagedir, "settingsHOVER.png"),
					40 * Settings.scale
				)
				
				vbg_pix = Gdk::Pixbuf.new(
					File.join(@imagedir, "vol.png"), 60 * Settings.scale, 198 * Settings.scale
				)
				vol_bg = Gtk::Image.new(vbg_pix)
				
				@slider_area = Gtk::EventBox.new
				@slider_area.set_size_request(60.0 * Settings.scale, 238.0 * Settings.scale)
				@slider_area.set_visible_window(false)
				@slider_area.signal_connect("expose_event"){|w, e| draw_slider(w, e)}
				@slider_area.signal_connect('motion_notify_event'){ |w, e| move_vol_slider(w, e)}

				@slider_pix = Gdk::Pixbuf.new(
					File.join(@imagedir, "volslider.png"), 38 * Settings.scale, 35 * Settings.scale
				)
				

			layout.put(@cover_image, 49 * Settings.scale, 49 * Settings.scale)
			layout.put(@table_overlay, 0, 0)
			layout.put(@arm_area, 300.0 * Settings.scale, 0)
			layout.put(transport_btns, 486.0 * Settings.scale, 500.0 * Settings.scale)
			layout.put(@shuf_btn, 545.0 * Settings.scale, 460.0 * Settings.scale)
			layout.put(playlist_browser_btns, 14.0 * Settings.scale, 518.0 * Settings.scale)
			layout.put(settings_btn, 32.0 * Settings.scale, 26.0 * Settings.scale)
			layout.put(vol_bg, 630.0 * Settings.scale, 280.0 * Settings.scale)
			layout.put(@slider_area, 630.0 * Settings.scale, 260.0 * Settings.scale)
			
		@main.pack_start(layout, true, true, 2)
	end
	
	def draw_arm(w)
		@acc.destroy if @acc
		@acc = w.window.create_cairo_context
		@acc.translate(622.0 * Settings.scale, 149.0 * Settings.scale)
		@acc.rotate((@arm_pos + 18.25) * Math::PI / 180)
		@acc.set_source_pixbuf(@arm_pix, -109.0 * Settings.scale, -119.0 * Settings.scale)
		@acc.paint
	end
	
	def set_arm_pos(percent)
		@arm_pos=(((percent * 23) / 100))
		@arm_area.queue_draw
	end
	
	def draw_slider(w, e)
		@scc.destroy if @cc
		@scc = w.window.create_cairo_context
		@scc.translate(622.0 * Settings.scale, 149.0 * Settings.scale)
		@scc.set_source_pixbuf(@slider_pix, 16.0 * Settings.scale, ((127.0 * Settings.scale) + @vol_pos))
		@scc.paint
	end
	
	def move_vol_slider(w, e)
		y = e.y - (35.0 * Settings.scale)
		y = 0 if y < 0; y = 170 * Settings.scale if y > 170 * Settings.scale
		@vol_pos = y
		@slider_area.queue_draw
		vol = (((@vol_pos / (170 * Settings.scale)) - 1) * -1).round(1)
		vol = 0 if vol < 0; vol = 1.0 if vol > 1.0
		emit_signal(["VOLUME", vol])
	end
	
	def set_state(state)
		if state == "playing"
			@table_overlay.pixbuf = @play_overlay
			@play_btn.set_images(
				File.join(@imagedir, "pause.png"),
				File.join(@imagedir, "pauseHOVER.png"),
				68 * Settings.scale
			)
		else
			@table_overlay.pixbuf = @pause_overlay
			@play_btn.set_images(
				File.join(@imagedir, "play.png"),
				File.join(@imagedir, "playHOVER.png"),
				68 * Settings.scale
			)
		end
		@table_overlay.show_all
		@play_btn.show_all
	end
	
	def update(path)
		get_cover(path)
		@cover_image.pixbuf = @cover_pix
		@cover_image.show
		@armpos = 0
		set_arm_pos(@armpos)
	end
	
	def get_cover(path)
		cover_file = File.join(Settings.brains_dir, "images", "no_cover.png")
		cover_size = 485.0 * Settings.scale

		if path && File.exists?(path)
			dir = File.dirname(path)
			Dir.chdir(dir)
			files = Dir['*.{jpg,JPG,png,PNG,gif,GIF}']
			if files[0]
				cover_file = File.join(dir, files[0])
			end
		end
		@cover_pix = Gdk::Pixbuf.new(cover_file, cover_size, cover_size)
	end
	
	def toggle_shuffle
		emit_signal("SHUFFLE_TOGGLE") unless @first
		@first = false
		
		if Settings.shuffle
			@shuf_btn.set_images(
				File.join(@imagedir, "shuffle.png"),
				File.join(@imagedir, "shuffleHOVER.png"),
				45 * Settings.scale
			)
		else
			@shuf_btn.set_images(
				File.join(@imagedir, "default.png"),
				File.join(@imagedir, "defaultHOVER.png"),
				45 * Settings.scale
			)
		end
		
		@shuf_btn.show_all
	end
	
	def resize
		@main.children.each{|child| @main.remove(child)}
		@first = true
		@cover_pix = @cover_pix.scale(485 * Settings.scale, 485 * Settings.scale)
		init_ui
		@main.show_all
	end
	
	def send_seek_data(click_event)
		x = click_event.x / Settings.scale
		y = click_event.y / Settings.scale
		
		x_flag = true if x > 25 and x < 165
		y_flag = true if y > 360 and y < 490
		
		if x_flag and y_flag
			percent  = ((y - 490.0) / -130.0).round(2)
			percent = 0.01 if percent < 0.01; percent = 0.99 if percent > 0.99
			emit_signal(["SEEK", percent])
		end

	end

	def emit_signal(signal)
		changed; notify_observers(signal)
	end
	
end	#Turntable
