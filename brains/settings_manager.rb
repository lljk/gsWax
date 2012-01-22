=begin
	
	this file is part of: gsWax v. 0.12.01

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


class SettingsCell < Gtk::Frame
	attr_accessor :label
	
	def set(label_text, label_pos, width, height)
		@label = Gtk::Label.new(label_text)
		self.label_widget = @label
		self.set_width_request(width) if width
		self.set_height_request(height) if height
		self.label_xalign = label_pos if label_pos
	end
	
	def hover
		@label.state = Gtk::StateType::SELECTED
	end
	
	def leave
		@label.state = Gtk::StateType::NORMAL
	end
	
end


class SettingsManager
	include Observable
	
 def initialize
		Settings.read
		bga = Settings.bg_color
		@bg_color = Gdk::Color.new(bga[0], bga[1], bga[2])
		tca = Settings.text_color
		@text_color = Gdk::Color.new(tca[0], tca[1], tca[2])
		@font_desc = Pango::FontDescription.new(Settings.font_desc)
		init_ui
	end

	def init_ui
		@win = Gtk::Window.new
		@win.title = "gsWax Settings"
		@win.icon = Gdk::Pixbuf.new File.join(DIR, '../static/gshoes-icon.png')
		@win.set_size_request(400, 400)
		@win.signal_connect("destroy"){
			changed; notify_observers("SETTINGS_CLOSED")
		}
			nb = Gtk::Notebook.new
				page1 = Gtk::VBox.new(false, 2)
			
				mdir_frame = SettingsCell.new
				mdir_frame.set("music library directory:", 0.95, nil, 50)
					mdir_btn = Gtk::EventBox.new()
						@mdir_text = Gtk::Label.new(Settings.music_dir)
						@mdir_text.set_alignment(0.05, 0.3)
						@mdir_text.set_wrap(true)
						@mdir_text.justify = Gtk::JUSTIFY_LEFT
					mdir_btn.add(@mdir_text)
					mdir_btn.signal_connect("button_press_event"){music_dir_select}
					mdir_btn.signal_connect("enter_notify_event"){mdir_frame.hover}
					mdir_btn.signal_connect("leave_notify_event"){mdir_frame.leave}
				mdir_frame.add(mdir_btn)
				
				hbox1 = Gtk::HBox.new(false, 5)
				hbox1.set_height_request(50)
					scale_frame = SettingsCell.new
					scale_frame.set("scale: [0.35 - 1.0]", 0.05, 193, nil)
						scale_btn = Gtk::EventBox.new()
							@scale_text = Gtk::Entry.new
							@scale_text.text = Settings.scale.to_s
							@scale_text.xalign = 0.95
							@scale_text.signal_connect("enter_notify_event"){scale_frame.hover}
							@scale_text.signal_connect("leave_notify_event"){scale_frame.leave}
						scale_btn.add(@scale_text)
					scale_frame.add(scale_btn)
			
					bg_frame = SettingsCell.new
					bg_frame.set("background color:", 0.95, nil, nil)
						@bg_btn = Gtk::EventBox.new()
						@bg_btn.modify_bg(Gtk::STATE_NORMAL, @bg_color)
						@bg_btn.signal_connect("button_press_event"){bg_color_select}
						@bg_btn.signal_connect("enter_notify_event"){bg_frame.hover}
						@bg_btn.signal_connect("leave_notify_event"){bg_frame.leave}
					bg_frame.add(@bg_btn)
				hbox1.pack_start(scale_frame, false, false, 0)
				hbox1.pack_start(bg_frame, true, true, 2)
		
				hbox2 = Gtk::HBox.new(false, 5)
				hbox2.set_height_request(50)
					font_frame = SettingsCell.new
					font_frame.set("text font:", 0.05, 193, nil)
						font_btn = Gtk::EventBox.new()
							@font_text = Gtk::Label.new(@font_desc)
							@font_text.modify_font(@font_desc)
							@font_text.xalign = 0.95
							@font_text.justify = Gtk::JUSTIFY_RIGHT
						font_btn.add(@font_text)
						font_btn.signal_connect("button_press_event"){font_select}
						font_btn.signal_connect("enter_notify_event"){font_frame.hover}
						font_btn.signal_connect("leave_notify_event"){font_frame.leave}
					font_frame.add(font_btn)
			
					txtclr_frame = SettingsCell.new
					txtclr_frame.set("text color:", 0.95, nil, nil)
						@txtclr_btn = Gtk::EventBox.new()
						@txtclr_btn.modify_bg(Gtk::STATE_NORMAL, @text_color)
						@txtclr_btn.modify_fg(Gtk::STATE_SELECTED, @text_color)
						@txtclr_btn.signal_connect("button_press_event"){text_color_select}
						@txtclr_btn.signal_connect("enter_notify_event"){txtclr_frame.hover}
						@txtclr_btn.signal_connect("leave_notify_event"){txtclr_frame.leave}
					txtclr_frame.add(@txtclr_btn)
				hbox2.pack_start(font_frame, false, false, 0)
				hbox2.pack_start(txtclr_frame, true, true, 2)
			
				format_frame = SettingsCell.new
				format_frame.set("title format:", 0.05, nil, nil)
					format_box = Gtk::EventBox.new
						vbox = Gtk::VBox.new(false, 5)
						
							valign = Gtk::Alignment.new(0.05, 0.15, 0, 0)
								@format_text = Gtk::TextView.new
								@format_text.set_size_request(390, 200)
								@format_text.wrap_mode = Gtk::TextTag::WRAP_WORD
								@format_text.justification = Gtk::JUSTIFY_LEFT
								@format_text.editable =  true
								@format_text.cursor_visible =  true
								@format_text.pixels_above_lines = 5
								@format_text.pixels_below_lines = 5
								@format_text.pixels_inside_wrap = 5
								@format_text.left_margin = 10
								@format_text.right_margin = 10
								@format_text.buffer.text = Settings.title_format
							valign.add(@format_text)
						
							halign = Gtk::Alignment.new(0.01, 0, 1, 0)
								add_field = Gtk::ComboBox.new
									fields = ["add field", "#track-number#", "#title#", "#album#",
									"#artist#", "#album-artist#", "#genre#", "#comments#"
									]
									fields.each{|field| add_field.append_text(field)}
								add_field.active = 0
								add_field.signal_connect("changed"){
									@format_text.buffer.insert(
										@format_text.buffer.end_iter, add_field.active_iter[0]
									)
								}
							halign.add(add_field)
						
						vbox.pack_start(valign, true, true, 2)
						vbox.pack_start(halign, false, false, 2)
					format_box.add(vbox)
					format_box.signal_connect("enter_notify_event"){format_frame.hover}
					format_box.signal_connect("leave_notify_event"){format_frame.leave}
				format_frame.add(format_box)
		
				btn_box = Gtk::HBox.new(false, 2)
					save_btn = Gtk::Button.new(" save settings ")
					save_btn.signal_connect("clicked"){save_settings}
					close_btn = Gtk::Button.new("  close  ")
					close_btn.signal_connect("clicked"){@win.destroy}

				btn_box.pack_end(close_btn, false, false, 2)
				btn_box.pack_end(save_btn, false, false, 2)		
	
			page1.pack_start(mdir_frame, false, false, 10)
			page1.pack_start(hbox1, false, false, 2)
			page1.pack_start(hbox2, false, false, 2)
			page1.pack_start(format_frame, true, true, 12)
			page1.pack_start(btn_box, false, false, 0)
			
			page2 = Gtk::VBox.new(false, 2)
				about_frame = Gtk::Frame.new()
				about = "gsWax version 0.12.1\nhttps://github.com/lljk/shoeWax/tree/onGreenShoes"
				about_text = Gtk::Label.new(about)
				about_text.set_alignment(0.05, 0.5)
				about_text.set_wrap(true)
				about_text.justify = Gtk::JUSTIFY_CENTER
				about_frame.add(about_text)
			page2.pack_start(about_frame, true, true, 2)
	
			label1 = Gtk::Label.new("  general  ")
			label2 = Gtk::Label.new("  about  ")
		
			nb.append_page(page1, label1)
			nb.append_page(page2, label2)
		@win.add(nb)
		@win.show_all
	end	#init_ui
	
	def music_dir_select
		if Settings.music_dir
			open_dir = Settings.music_dir if File.exists?(Settings.music_dir)
		else
			open_dir = File.dirname(File.expand_path(__FILE__))
		end
		dialog = Gtk::FileChooserDialog.new(
			nil,nil,
			Gtk::FileChooser::ACTION_SELECT_FOLDER,
			nil,
			["Cancel", Gtk::Dialog::RESPONSE_CANCEL],
			["Select", Gtk::Dialog::RESPONSE_ACCEPT]
		)
		dialog.current_folder = (open_dir)
		dialog.signal_connect("delete_event"){dialog.destroy}
		if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
			Settings.music_dir = dialog.filename
			@mdir_text.text = Settings.music_dir
			dialog.destroy
		end
	end

	def bg_color_select
		d = Gtk::ColorSelectionDialog.new
		sel = d.colorsel
		sel.set_previous_color(@bg_color)
		sel.set_current_color(@bg_color)
		sel.set_has_palette(true)
		response = d.run

		if response == Gtk::Dialog::RESPONSE_OK
			bgR = sel.current_color.red
			bgG = sel.current_color.green
			bgB = sel.current_color.blue
			Settings.bg_color = [bgR, bgG, bgB]
			@bg_color = Gdk::Color.new(bgR, bgG, bgB)
			@bg_btn.modify_bg(Gtk::STATE_NORMAL, @bg_color)
		end
		d.destroy
	end

	def text_color_select
		d = Gtk::ColorSelectionDialog.new
		sel = d.colorsel
		sel.set_previous_color(@text_color)
		sel.set_current_color(@text_color)
		sel.set_has_palette(true)
		response = d.run

		if response == Gtk::Dialog::RESPONSE_OK
			tR = sel.current_color.red
			tG = sel.current_color.green
			tB = sel.current_color.blue
			Settings.text_color = [tR, tG, tB]
			@text_color = Gdk::Color.new(tR, tG, tB)
			@txtclr_btn.modify_bg(Gtk::STATE_NORMAL, @text_color)
		end
		d.destroy
	end

	def font_select
		d = Gtk::FontSelectionDialog.new
		d.set_font_name(Settings.font_desc)
		response = d.run
		
		if response == Gtk::Dialog::RESPONSE_OK
			font = d.font_name
			Settings.font_desc = font
			@font_desc = Pango::FontDescription.new(font)
			@font_text.text = font
			@font_text.modify_font(@font_desc)
		end
		d.destroy
	end
	
	def save_settings
		scale = @scale_text.text.to_f
		scale = 0.35 if scale < 0.35; scale = 1.0 if scale > 1.0
		Settings.scale = scale
		Settings.title_format = @format_text.buffer.text
		Settings.save
		changed; notify_observers("UPDATE_SETTINGS")
		@win.destroy
	end
	
	def close_window
		@win.destroy
	end
	
end	#class SettingsManager
