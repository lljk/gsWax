=begin
	
	this file is part of: gsWax v. 0.12.01

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


class ScrollBox
  attr_accessor :main
	
	def initialize(txt)
		@txt = txt
		@scroll_text = txt + "   "
		bgc = Settings.bg_color
		@bg_color = Gdk::Color.new(bgc[0], bgc[1], bgc[2])

		@main = Gtk::EventBox.new()
		@main.set_size_request(727 * Settings.scale, 75 * Settings.scale)
		@main.signal_connect("enter_notify_event"){hover_toggle}###
		@main.signal_connect("leave_notify_event"){@left = true}###
		@main.modify_bg(Gtk::STATE_NORMAL, @bg_color)
			frame = Gtk::HBox.new(false, 0)
				@text_label = Gtk::Label.new
				@text_label.justify=(Gtk::JUSTIFY_CENTER)
				@text_label.ellipsize = Pango::Layout::ELLIPSIZE_END
			frame.pack_start(@text_label, true, true, 10)
		@main.add(frame)
		show_text(@txt)
	end
	
	def show_text(txt)
		if @text_label
			txc = Settings.text_color
			txt_color = Gdk::Color.new(txc[0], txc[1], txc[2])
			@text_label.set_markup(
				%Q[<span font_desc="#{Settings.font_desc}"foreground="#{txt_color}">#{CGI.escape_html(txt)}</span>]
			)
		end
	end
	
	def set_text(txt)
		stop_scroll if @scrolling
		@scroll_text = txt + "   "
		@text_label.text = @scroll_text
		@text_label.justify=(Gtk::JUSTIFY_CENTER)
		show_text(@scroll_text)
	end
	
	def hover_toggle
		@left = false
		timer = GLib::Timer.new
		GLib::Timeout.add(100){
			if timer.elapsed[0].round(1) > 0.3
				unless @left
					if @scrolling
						stop_scroll
					else
						start_scroll
					end
					timer.stop
				end
				false
			else
				true
			end
		}
		
	end
	
	def start_scroll
		@scrolling = true
		@text_label.justify=(Gtk::JUSTIFY_LEFT)
		@timer = GLib::Timeout.add(100){
			if @scrolling
				first = @scroll_text.slice!(0)
				@scroll_text << first
				show_text(@scroll_text)
			else
				false
			end
		}
	end
	
	def stop_scroll
		@scrolling = false; @timer = nil
	end
	
	def set_text(txt)
		stop_scroll if @scrolling
		@scroll_text = txt + "   "

		show_text(@scroll_text)
	end
	
end
