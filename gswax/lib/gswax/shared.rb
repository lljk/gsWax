=begin
	
	this file is part of: gsWax v. 0.12.01

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


require 'yaml'

module Settings
	
	def self.read
		@brains_dir = File.join(File.dirname(File.expand_path(__FILE__)))
		@settings_file = File.join(@brains_dir, "settings", "settings.yml")
		if File.exists?(@settings_file)
			@settings = begin
				YAML.load(File.open(@settings_file))
			rescue ArgumentError => e
				puts "Unable to parse YAML: #{e.message}"
			end
		else
			@settings = [
				nil,
				false,
				nil,
				"#title# - #artist# - #album#",
				0.65,
				"Impact 13",
				[65000, 65000, 65000],
				[0, 0, 0],
				nil,
				0.5,
				[]
			]
			self.save
		end
	end
	
	def self.save
		#unless File.exists?(@settings_file)
		#	Dir.mkdir(File.join(@brains_dir, "settings"), 0777)
		#	File.new(@settings_file, "w")
		#end
		File.open(@settings_file, "w"){|file|
			file.write(@settings.to_yaml)
		}
	end
	
	def self.brains_dir
		@brains_dir
	end
	
	def self.settings
		@settings
	end
	
	def self.playlist_file
		@settings[0]
	end
	def self.playlist_file= (file)
		@settings[0] = file
	end
	
	def self.shuffle
		@settings[1]
	end
	def self.shuffle= (tof)
		@settings[1] = tof
	end
	
	def self.at_bat
		@settings[2]
	end
	def self.at_bat= (atbat)
		@settings[2] = atbat
	end
	
	def self.title_format
		@settings[3]
	end
	def self.title_format= (format)
		@settings[3] = format
	end
	
	def self.scale
		@settings[4]
	end
	def self.scale= (int)
		@settings[4] = int
	end
	
	def self.font_desc
		@settings[5]
	end
	def self.font_desc= (desc)
		@settings[5] = desc
	end
	
	def self.text_color
		@settings[6]
	end
	def self.text_color= (rgb_array)
		@settings[6] = rgb_array
	end
	
	def self.bg_color
		@settings[7]
	end
	def self.bg_color= (rgb_array)
		@settings[7] = rgb_array
	end
	
	def self.music_dir
		@settings[8]
	end
	def self.music_dir= (dir)
		@settings[8] = dir
	end
	
	def self.volume
		@settings[9]
	end
	def self.volume= (vol)
		@settings[9] = vol
	end
	
	def self.line_up
		@settings[10]
	end
	def self.line_up= (line_up)
		@settings[10] = line_up
	end
	
end	#Settings


class ImageButton < Gtk::EventBox
	attr_accessor :image, :cold_pix, :hot_pix
	
	def initialize
		super
		self.set_visible_window(false)
		self.signal_connect("enter_notify_event"){enter_event}
		self.signal_connect("leave_notify_event"){leave_event}
		self.signal_connect("button_press_event"){yield if block_given?}
	end
	
	def set_images(img_file, hov_file, width, height= width)
		self.remove(@image) if @image
		@cold_pix = Gdk::Pixbuf.new(img_file, width, height)
		@hot_pix = Gdk::Pixbuf.new(hov_file, width, height)
		@image = Gtk::Image.new(@cold_pix)
		self.add(@image)

	end
	
	def enter_event
		@image.pixbuf = @hot_pix if @image
	end
	
	def leave_event
		@image.pixbuf = @cold_pix if @image
	end
	
end


class ListView
	include Observable
	attr_accessor :store, :list, :list_selection
	
	def initialize
		@store = Gtk::ListStore.new(String, String)
		@list = Gtk::TreeView.new(@store)
		@list.enable_search=(true)
		@list.headers_visible=(false)
		renderer = Gtk::CellRendererText.new
		column = Gtk::TreeViewColumn.new("", renderer, :text => 0)
		@list.append_column(column)
		@list_selection = @list.selection
		@list_selection.mode=(Gtk::SELECTION_MULTIPLE)
		@list.signal_connect("row-activated"){|view, path, column|
			emit_signal("row-activated", view, path, column)
		}
		@list_selection.signal_connect("changed"){|view, path, column|
			emit_signal("changed", view, path, column)
		}
	end
	
	def add_to_list(entry, position = "append")
		if  position == "append" 
			iter = @store.append
		else
			iter = @store.prepend
		end
		@store.set_value(iter, 0, File.basename(entry))
		@store.set_value(iter, 1, entry)
	end
	
	def emit_signal(*args)
		changed; notify_observers(*args)
	end
	
end	#ListView
