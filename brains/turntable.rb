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
		@scale = Settings.scale
		main_width = 727 * @scale
		main_height = 598 * @scale
		cover_size = 485 * @scale
		cover_x = cover_y = 49 * @scale
		arm_width = 146 * @scale
		arm_height = 512 * @scale
		@arm_x = 480.0 * @scale
		@arm_y = -305.0 * @scale
		arm_file = File.join(Settings.brains_dir, "images", "arm.png")
		@arm_pix = Gdk::Pixbuf.new(arm_file, arm_width, arm_height)
		@arm_pos = 0
		@vol_pos = ((Settings.volume * -1) +1) * (170 * @scale)
		
		@main = Gtk::VBox.new(true, 2)
		@main.set_size_request(main_width, main_height)
			layout = Gtk::Layout.new

				cover_pix = Gdk::Pixbuf.new(File.join(@imagedir, "no_cover.png"), cover_size, cover_size)
				@cover_image = Gtk::Image.new(cover_pix)
				@play_overlay = Gdk::Pixbuf.new(File.join(@imagedir, "stanton1.png"), main_width, main_height)
				@pause_overlay = Gdk::Pixbuf.new(File.join(@imagedir, "stanton.png"), main_width, main_height)
				@table_overlay = Gtk::Image.new(@pause_overlay)
				
				@arm_area = Gtk::EventBox.new
				@arm_area.set_size_request(450.0 * @scale, 540.0 * @scale)
				@arm_area.set_visible_window(false)
				@arm_area.signal_connect("expose_event"){|w, e| draw_arm(w)}
				
				transport_btns = Gtk::HBox.new(false, 0)
				
					prev_btn = ImageButton.new{emit_signal("PREVIOUS_TRACK")}
					prev_btn.set_images(
						File.join(@imagedir, "prev.png"),
						File.join(@imagedir, "prevHOVER.png"),
						68 * @scale
					)
					
					@play_btn = ImageButton.new{emit_signal("PLAY_PAUSE_TRACK")}
					@play_btn.set_images(
						File.join(@imagedir, "play.png"),
						File.join(@imagedir, "playHOVER.png"),
						68 * @scale
					)
					
					next_btn = ImageButton.new{emit_signal("NEXT_TRACK")}
					next_btn.set_images(
						File.join(@imagedir, "next.png"),
						File.join(@imagedir, "nextHOVER.png"),
						68 * @scale
					)
				
				transport_btns.pack_start(prev_btn, false, false, 2)
				transport_btns.pack_start(@play_btn, false, false, 2)
				transport_btns.pack_start(next_btn, false, false, 2)
				
				@shuf_btn = ImageButton.new{toggle_shuffle}
				@first = true
				toggle_shuffle
		
				playlist_browser_btns = Gtk::HBox.new(false, 0)
				
					list_btn = ImageButton.new{emit_signal("PLAYLIST")}
					list_btn.set_images(
						File.join(@imagedir, "playlist.png"),
						File.join(@imagedir, "playlistHOVER.png"),
						45 * @scale
					)
					
					browser_btn = ImageButton.new{emit_signal("BROWSER")}
					browser_btn.set_images(
						File.join(@imagedir, "dugout.png"),
						File.join(@imagedir, "dugoutHOVER.png"),
						45 * @scale
					)
				
				playlist_browser_btns.pack_start(list_btn, false, false, 2)
				playlist_browser_btns.pack_start(browser_btn, false, false, 2)
				
				settings_btn = ImageButton.new{emit_signal("SETTINGS")}
				settings_btn.set_images(
					File.join(@imagedir, "settings.png"),
					File.join(@imagedir, "settingsHOVER.png"),
					40 * @scale
				)
				
				vbg_pix = Gdk::Pixbuf.new(
					File.join(@imagedir, "vol.png"), 60 * @scale, 198 * @scale
				)
				vol_bg = Gtk::Image.new(vbg_pix)
				
				@slider_area = Gtk::EventBox.new
				@slider_area.set_size_request(60.0 * @scale, 238.0 * @scale)
				@slider_area.set_visible_window(false)
				@slider_area.signal_connect("expose_event"){|w, e| draw_slider(w, e)}
				@slider_area.signal_connect('motion_notify_event'){ |w, e| move_vol_slider(w, e)}

				@slider_pix = Gdk::Pixbuf.new(
					File.join(@imagedir, "volslider.png"), 38 * @scale, 35 * @scale
				)
				

			layout.put(@cover_image, cover_x, cover_y)
			layout.put(@table_overlay, 0, 0)
			layout.put(@arm_area, 300.0 * @scale, 0)
			layout.put(transport_btns, 486.0 * @scale, 500.0 * @scale)
			layout.put(@shuf_btn, 545.0 * @scale, 460.0 * @scale)
			layout.put(playlist_browser_btns, 14.0 * @scale, 518.0 * @scale)
			layout.put(settings_btn, 32.0 * @scale, 26.0 * @scale)
			layout.put(vol_bg, 630.0 * @scale, 280.0 * @scale)
			layout.put(@slider_area, 630.0 * @scale, 260.0 * @scale)
			
		@main.pack_start(layout, true, true, 2)
	end
	
	def draw_arm(w)
		@acc.destroy if @acc
		@acc = w.window.create_cairo_context
		@acc.translate(622.0 * @scale, 149.0 * @scale)
		@acc.rotate((@arm_pos + 18.25) * Math::PI / 180)
		@acc.set_source_pixbuf(@arm_pix, -109.0 * @scale, -119.0 * @scale)
		@acc.paint
	end
	
	def set_arm_pos(percent)
		@arm_pos=(((percent * 23) / 100))
		@arm_area.queue_draw
	end
	
	def draw_slider(w, e)
		@scc.destroy if @cc
		@scc = w.window.create_cairo_context
		@scc.translate(622.0 * @scale, 149.0 * @scale)
		@scc.set_source_pixbuf(@slider_pix, 16.0 * @scale, ((127.0 * @scale) + @vol_pos))
		@scc.paint
	end
	
	def move_vol_slider(w, e)
		y = e.y - (35.0 * @scale)
		y = 0 if y < 0; y = 170 * @scale if y > 170 * @scale
		@vol_pos = y
		@slider_area.queue_draw
		vol = (((@vol_pos / (170 * @scale)) - 1) * -1).round(1)
		vol = 0 if vol < 0; vol = 1.0 if vol > 1.0
		emit_signal(["VOLUME", vol])
	end
	
	def set_state(state)
		if state == "playing"
			@table_overlay.pixbuf = @play_overlay
			@play_btn.set_images(
				File.join(@imagedir, "pause.png"),
				File.join(@imagedir, "pauseHOVER.png"),
				68 * @scale
			)
		else
			@table_overlay.pixbuf = @pause_overlay
			@play_btn.set_images(
				File.join(@imagedir, "play.png"),
				File.join(@imagedir, "playHOVER.png"),
				68 * @scale
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

		if path
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
				45 * @scale
			)
		else
			@shuf_btn.set_images(
				File.join(@imagedir, "default.png"),
				File.join(@imagedir, "defaultHOVER.png"),
				45 * @scale
			)
		end
		
		@shuf_btn.show_all
	end
	
	def emit_signal(signal)
		changed; notify_observers(signal)
	end
	
end	#Turntable
