=begin
	
	this file is part of: gsWax v. 0.12.01

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


class PlayList
	include Observable
	attr_accessor :listview, :main
	
	def initialize
		@selected = []
		@listview = ListView.new		# def in share.rb
		@listview.list.reorderable = true
		@listview.add_observer(self, :on_list_signals)
		init_ui
	end
	
	def init_ui
		@win = Gtk::Window.new
		@win.set_size_request(500, 500)
		@win.icon = Gdk::Pixbuf.new File.join(DIR, '../static/gshoes-icon.png')
		@win.title = 'Playlist'
		@win.signal_connect("destroy"){changed; notify_observers("PLAYLIST_CLOSED")}
		
		@main = Gtk::VBox.new(false, 5)

		show_list
		
		@win.add(@main)
		@win.show_all
	end
	
	def show_list
		list_panel = Gtk::ScrolledWindow.new
		list_panel.set_size_request(500, 460)
		
		hadjust = list_panel.hadjustment
		vadjust = list_panel.vadjustment
		viewport = Gtk::Viewport.new(hadjust, vadjust)
		list_panel.set_policy(Gtk::POLICY_AUTOMATIC, Gtk::POLICY_ALWAYS)
		list_panel.add_with_viewport(@listview.list)
		
		btn_panel = Gtk::HBox.new(true, 2)
		
		add_tracks_btn = Gtk::Button.new("add tracks")
		add_tracks_btn.signal_connect("clicked"){call_browser}
		
		@remove_tracks_btn = Gtk::Button.new("remove tracks")
		@remove_tracks_btn.signal_connect("clicked"){remove_tracks}
		@remove_tracks_btn.sensitive = false
		
		@clear_list_btn = Gtk::Button.new("clear list")
		@clear_list_btn.signal_connect("clicked"){clear_list}
		@clear_list_btn.sensitive = false
		
		load_list_btn = Gtk::Button.new("load list")
		load_list_btn.signal_connect("clicked"){load_list}
		
		@save_list_btn = Gtk::Button.new("save list")
		@save_list_btn.signal_connect("clicked"){save_list}
		@save_list_btn.sensitive = false
		
		btn_panel.pack_start(add_tracks_btn, true, true, 1)
		btn_panel.pack_start(@remove_tracks_btn, true, true, 1)
		btn_panel.pack_start(@clear_list_btn, true, true, 1)
		btn_panel.pack_start(load_list_btn, true, true,	1)
		btn_panel.pack_start(@save_list_btn, true, true, 1)
		
		
		@main.pack_start(list_panel, true, true, 0)
		@main.pack_end(btn_panel, true, true, 0)
	end
	
	def add(entry, position = "append")
		if entry.class == String
			@listview.add_to_list(entry, position)
		elsif entry.class == Array
			entry.each{|e| @listview.add_to_list(e, position)}
		end
		@clear_list_btn.sensitive = true
		@save_list_btn.sensitive = true
	end
	
	def on_list_signals(*signal)
		case signal[0]
			when "changed"
				@remove_tracks_btn.sensitive = true
			when "row-activated"
				iter = @listview.store.get_iter(signal[2])
				entry = iter[1]
				changed; notify_observers(["PLAY_NOW", entry])
		end
	end
	
	def on_browser_signals(signal)
		case signal[0]
			when "PREPEND"
				add(signal[1..-1], "prepend")
			when "APPEND"
				add(signal[1..-1])
			when "PLAY_NOW"
				add(signal[1])
		end
		changed; notify_observers(signal)	
	end
	
	def call_browser
		changed; notify_observers("BROWSER")
	end
	
	def remove_tracks
		tracks = []

		@listview.list_selection.selected_rows.each{|path|
			iter = @listview.store.get_iter(path)
			tracks << iter[1]
			@listview.store.remove(iter)
		}
		tracks.insert(0, "REMOVE")
		changed; notify_observers(tracks)
	end
	
	def clear_list
		if confirm("clear playlist?")
			@listview.store.clear
			@clear_list_btn.sensitive = false
			@save_list_btn.sensitive = false
			changed; notify_observers("CLEAR_LIST")
		end
	end
	
	def load_list
		list = []
		playlist_dir = File.join(Settings.brains_dir, "playlists")
		unless Dir.exists?(playlist_dir)
			Dir.mkdir(playlist_dir)
		end
		Dir.chdir(playlist_dir){
			@openfile = ask_open_file
		}
		if @openfile
			File.open(@openfile, "r"){|file|
				file.each_line{|line| list << line.chomp}
			}
		end
		
		@listview.store.clear
		add(list)
		
		list.insert(0, @openfile)
		list.insert(0, "LOAD_LIST")
		changed; notify_observers(list)
	end
	
	def save_list
		unless Dir.exists?((File.join(Settings.brains_dir, "playlists")))
			Dir.mkdir(File.join(Settings.brains_dir, "playlists"))
		end
		Dir.chdir(File.join(Settings.brains_dir, "playlists")){
			@savefile = ask_save_file
		}
		
		if @savefile
			@listview.list_selection.select_all
			File.open(@savefile, "w+"){|file|
				@listview.list_selection.selected_each{|mod, path, iter| file.puts iter[1]}
			}
			@listview.list_selection.unselect_all
		
			changed; notify_observers(["SAVE_LIST", @savefile])
		end
	end
	
	def close_window
		@win.destroy
	end
	
end
