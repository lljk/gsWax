=begin
	
	this file is part of: gsWax v. 0.0.2

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


class DirBrowser
	include Observable
	
	def initialize(path = File.expand_path(File.dirname(__FILE__)))
		@okfiles = [/.mp3/, /.flac/, /.ogg/, /.wav/]
		@selected = []
		@listview = ListView.new		# def in shared.rb
		@listview.add_observer(self, :on_list_signals)
		
		init_ui
		pathscan(path)
		update_ui
	end
	
	def init_ui
		@win = Gtk::Window.new
		@win.set_size_request(750, 450)
		@win.icon = Gdk::Pixbuf.new File.join(DIR, '../static/gshoes-icon.png')
		@win.title = 'Directory Browser'
		@win.signal_connect("destroy"){changed; notify_observers("BROWSER_CLOSED")}
			@main = Gtk::HBox.new(false, 5)
				@leftalign = Gtk::Alignment.new(0.5, 0, 0, 0)
					@left = Gtk::VBox.new(false, 2)
					@left.set_size_request(200, 450)
					
						current_btn_frame = Gtk::Frame.new()
							@current_dir_btn = Gtk::EventBox.new()
							@current_dir_btn.set_size_request(200, 200)
								@img = Gtk::Image.new()
							@current_dir_btn.add(@img)
							@current_dir_btn.signal_connect("button_press_event"){
								@listview.list_selection.select_all
							}
						current_btn_frame.add(@current_dir_btn)
				
						up_btn_frame = Gtk::Frame.new("/../")
						up_btn_frame.label_xalign = 0.05
							@up_dir_btn = Gtk::EventBox.new()
								@current_dir_text = Gtk::Label.new()
								@current_dir_text.width_chars = (26)
								@current_dir_text.set_wrap(true)
								@current_dir_text.justify = Gtk::JUSTIFY_CENTER
								@current_dir_text.ypad = 5
							@up_dir_btn.add(@current_dir_text)
							@up_dir_btn.signal_connect("button_press_event"){up_one_dir}
						up_btn_frame.add(@up_dir_btn)
					
						add_btns_box = Gtk::HBox.new(true, 2)
							@append_btn = Gtk::Button.new("list <<")
							@append_btn.signal_connect("clicked"){notify_add_selected}
							@prepend_btn = Gtk::Button.new(">> list")
							@prepend_btn.signal_connect("clicked"){notify_add_selected("prepend")}
							@append_btn.sensitive = false
							@prepend_btn.sensitive = false
						add_btns_box.pack_start(@append_btn, true, true, 2)
						add_btns_box.pack_start(@prepend_btn, true, true, 2)
			
					@left.pack_start(current_btn_frame, false, false, 10)
					@left.pack_start(up_btn_frame, false, false, 10)
					@left.pack_end(add_btns_box, false, false, 10)
				
				@leftalign.add(@left)
				
				@rightalign = Gtk::Alignment.new(0, 0, 1, 0)
					@right = Gtk::VBox.new(false, 2)
						@rightpane = Gtk::ScrolledWindow.new
						@rightpane.set_size_request(500, 450)
							horizontal = @rightpane.hadjustment
							vertical = @rightpane.vadjustment
							viewport = Gtk::Viewport.new(horizontal, vertical)
						@rightpane.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
						@rightpane.add_with_viewport(@listview.list)
					@right.pack_start(@rightpane, true, true, 2)
				@rightalign = Gtk::Alignment.new(0, 0, 1, 0)
				@rightalign.add(@right)
				
			@main.pack_start(@leftalign, true, true, 2)
			@main.pack_start(@rightalign, true, true, 2)
		
		@win.add(@main)
		@win.show_all
	end
	
	def update_ui
		##left side
		@current_dir_btn.remove(@img)
		pbuf = Gdk::Pixbuf.new(@image_file, 200, 200)
		@img = Gtk::Image.new(pbuf)
		@current_dir_btn.add(@img)
		@current_dir_text.text = @current_dir
		@left.show_all
		
		##right side
		@listview.store.clear
		@dirs.each{|dir| @listview.add_to_list(dir)} if @dirs[0]
		@files.each{|file| @listview.add_to_list(file)} if @files[0]
	end
	
	def on_list_signals(*signal)
		case signal[0]
			when "changed"
				add_btns_active(true)
			when "row-activated"
				right_select(signal[2])
				add_btns_active(false)
		end
	end
	
	def right_select(path)
		iter = @listview.store.get_iter(path)
		entry = iter[1]
		if @dirs.include?(entry)
			update_dir(entry)
		elsif @files.include?(entry)
			changed; notify_observers(["PLAY_NOW", entry])
		end
	end
	
	def notify_add_selected(position = "append")
		dirs = []
		files = []
		@listview.list_selection.selected_each{|mod, path, iter|
			dirs << iter[1] ? File.directory?(iter[1]) : files << iter[1]
		}
		
		if files[0]
			files.each{|path|
				if File.extname(path.downcase) == ".pls" or File.extname(path.downcase) == ".m3u"
					File.open(path){|file|
						file.each_line{|line|
							if line.include?("http:")
								@selected << /http.+/.match(line).to_s
							end
						}
					}
				else
					@selected << path
				end
			}
		end
		
		if dirs[0]
			dirs.each{|dir| 
				Find.find(dir){|item|
					@okfiles.each{|ok| @selected << item if File.extname(item.downcase) =~ ok}
					if File.extname(item.downcase) == ".pls" or File.extname(item.downcase) == ".m3u"
						File.open(item){|file|
							file.each_line{|line|
								if line.include?("http:")
									@selected << /http.+/.match(line).to_s
								end
							}
						}
					end
				}	
			}
		end
		
		if position == "prepend"
			@selected.reverse!.insert(0, "PREPEND")
		else
			@selected.insert(0, "APPEND")
		end
		
		changed; notify_observers(@selected)
		@selected = []
		@listview.list_selection.unselect_all
		add_btns_active(false)
	end
	
	def pathscan(path)
		if path
			if File.directory?(path)
				dirs = []
				files = []
				Dir.open(path){|dir|
					for entry in dir
						next if entry == '.'
						next if entry == '..'
						unless entry[0] == '.'
							item = path + File::Separator + entry
							if File.directory?(item)
								dirs << item unless File.basename(item)[0] == "."
							else
								@okfiles.each{|ok| files << item if File.extname(item.downcase) =~ ok}
							end
						end
					end
				}
				@dirs = dirs.sort
				@files = files.sort
				@current_dir = path
				@left_width = 200
				get_image(@current_dir)
			end
		else
			@current_dir = Settings.brains_dir
			@image_file = Settings.brains_dir + File::Separator + "images" + File::Separator + "no_cover.png"
		end
	end
	
	def get_image(path)
		if path
			image_files = []
			Dir.entries(path).each{|entry|
				image_files << entry if entry.downcase.include?(".jpg") || entry.downcase.include?(".png") || entry.downcase.include?(".gif")
			}
			if image_files[0]
				@image_file = path + File::Separator + image_files[0]
			else
				@image_file = Settings.brains_dir + File::Separator + "images" + File::Separator + "no_cover.png"
			end
		else
			@image_file = Settings.brains_dir + File::Separator + "images" + File::Separator + "no_cover.png"
		end
	end
	
	def up_one_dir
		newpath = @current_dir.split(File::Separator)[0..-2].join(File::Separator)
		update_dir(newpath)
		add_btns_active(false)
	end
	
	def update_dir(path)
		pathscan(path)
		update_ui
	end
	
	def add_btns_active(boolean)
		@append_btn.sensitive = boolean
		@prepend_btn.sensitive = boolean
	end
	
	def close_window
		@win.destroy
	end
	
end	#DirBrowser
