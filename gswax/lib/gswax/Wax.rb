=begin
	
	this file is part of: gsWax v. 0.0.2

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
=end


require 'gst'

module Wax

  include Observable
  
  attr_accessor  :wax_coverart, :wax_duration, :wax_state, :wax_pipeline,
		:wax_batter, :wax_lineup, :wax_lupine, :wax_info, :wax_tracking
  
  #----------------------
  #  INITIALIZE
  #----------------------
  
  def init_wax
		Settings.read
    @wax_pipeline = Gst::ElementFactory.make("playbin2")
    @wax_state = "stopped"
    @wax_info = ""
    read_wax_lineup
  end

  def read_wax_lineup
    @wax_lineup = []
		if Settings.line_up
			@wax_lineup = Settings.line_up
			@wax_info = "gsWax - ready to rock"
		else
			@wax_info = "gsWax"
			send_wax_info("wax_info")
		end
		@wax_lineup.compact!
		@wax_lupine = @wax_lineup.shuffle
		
		if Settings.shuffle
			if Settings.at_bat
				@wax_batter = @wax_lupine.index(Settings.at_bat)
			else
				@wax_batter = 0
			end
		else
			if Settings.at_bat
				@wax_batter = @wax_lineup.index(Settings.at_bat)
			else
				@wax_batter = 0
			end
		end
		
		batter_up_wax
	end
  
  def batter_up_wax
		@wax_batter = 0 unless @wax_batter
    @wax_lupine = @wax_lineup.shuffle if @wax_lupine.empty?
    if Settings.shuffle
      Settings.at_bat = @wax_lupine[@wax_batter] 
    else
      Settings.at_bat = @wax_lineup[@wax_batter]
    end
  end
  
  
  #-----------------------------------------------------------
  #  PLAY / GET DURATION / GET TAGS
  #-----------------------------------------------------------
  
  def play_wax
    if @wax_lineup.empty?
      batter_up_wax
    end
		if @stream_thread; @stream_thread.exit; @stream_thread = nil; end
    if Settings.at_bat
			if Settings.at_bat =~ /http:/
				@wax_pipeline.uri = Settings.at_bat
				@wax_tracking = false
        @wax_state = "playing"
				@wax_info = "Stream: #{Settings.at_bat}"
				send_wax_info("wax_info")
				@stream_thread = Thread.new{@wax_pipeline.play}
      elsif File.exists?(Settings.at_bat)
        @wax_pipeline.uri= GLib.filename_to_uri(Settings.at_bat)
				@wax_tracking = true
        @wax_pipeline.play
        @wax_state = "playing"
        get_wax_duration
      end
			@tagMsg = []
			@wax_pipeline.bus.add_watch{|bus, message|
				case message.type
					when Gst::Message::ERROR
						p message.parse
					when Gst::Message::EOS
						@wax_state = "stopped"
						next_wax
						send_wax_info("eos")
					when Gst::Message::TAG
						@tagMsg << message.structure.entries
						get_wax_tags
				end
				true
			}
    else
      @wax_info = "no tracks"
      send_wax_info("wax_info")
      
    end
  end
  
  def get_wax_duration
    now = Time.now.sec.to_f
    now = 0.0 if now == 59.0
    @limit = now + 2.0
    
    GLib::Timeout.add(100){
      @qd = Gst::QueryDuration.new(3)#(Gst::Format::Type::TIME)
      @wax_pipeline.query(@qd)
      @wax_duration = @qd.parse[1]/1000000000
      if @wax_duration > 0
				send_wax_info("TRACK_PROGRESS")
        false
      elsif
        Time.now.sec.to_f > @limit
        false
      else
        true
      end
    }
  end
  
  def get_wax_tags
    @gotTags = false
    @tags = @tagMsg.flatten
    
    if @tags.include?("title")
      @title = @tags[@tags.index("title") + 1]; @gotTags = true
    else @title = nil; end
    if @tags.include?("artist")
      @artist = @tags[@tags.index("artist") + 1]; @gotTags = true
    else @artist = nil; end
    if @tags.include?("album")
      @album = @tags[@tags.index("album") + 1]; @gotTags = true
    else @album = nil; end
    if @tags.include?("comments")
      @comments = @tags[@tags.index("comments") + 1]; @gotTags = true
    else @comments = nil; end
    if @tags.include?("track-number")
      @tracknumber = @tags[@tags.index("track-number") + 1]; @gotTags = true
    else @tracknumber = nil; end
    if @tags.include?("genre")
      @genre = @tags[@tags.index("genre") + 1]; @gotTags = true
    else @genre = nil; end
    if @tags.include?("album-artist")
      @albumartist = @tags[@tags.index("album-artist") + 1]; @gotTags = true
    else @albumartist = nil; end
  
    split = Settings.title_format.split("#")
    @infoentries = []
    split.each{|i|
      i = @title if i == "title"
      i = @album if i == "album"
      i = @artist if i == "artist"
      i = @genre if i == "genre"
      i = @albumartist if i == "album-artist"
      i = @tracknumber if i == "track-number"
      i = @comments if i == "comments"
      @infoentries << i
    }
  
    if @gotTags == false
      @wax_info = File.basename(Settings.at_bat)
      send_wax_info("wax_info")
    else
      @infoentries.compact!
      @wax_info = @infoentries.join
      send_wax_info("wax_info")
    end
  end #get_wax_tags
  
  
  #-----------------------
  #  TRANSPORT
  #-----------------------
  
  def play_pause_wax
    if Settings.at_bat
      if @wax_state == "stopped"
        play_wax
      elsif @wax_state == "paused"
        resume_wax
      else
        pause_wax
      end
      
    else
      @wax_info = "no tracks"
      send_wax_info("wax_info")
    end
  end

  def next_wax
    @wax_pipeline.stop
    @wax_batter += 1
    batter_up_wax
    play_wax
  end

  def prev_wax
    @wax_pipeline.stop
    @wax_batter -= 1
    batter_up_wax
    play_wax
  end

  def pause_wax
    @wax_pipeline.pause if @wax_pipeline
    @wax_state = "paused"
  end

  def resume_wax
    @wax_pipeline.play
    @wax_state = "playing"
  end
  
  def stop_wax
    @wax_pipeline.stop if @wax_pipeline
    @wax_state = "stopped"
  end
	
	def toggle_wax_shuffle
		Settings.shuffle  = !Settings.shuffle
    @wax_batter = @wax_lineup.index(Settings.at_bat)
  end


  #------------------------------------
  #  SEEK / SEND / SAVE
  #------------------------------------
  
  def seek_to_wax(position_in_ms)
    if @wax_pipeline
      @wax_pipeline.send_event(Gst::EventSeek.new(1.0, 
      Gst::Format::Type::TIME, 
      Gst::Seek::FLAG_FLUSH.to_i | Gst::Seek::FLAG_KEY_UNIT.to_i, 
      Gst::Seek::TYPE_SET, position_in_ms * 1000000, Gst::Seek::TYPE_NONE, -1))
    end
  end


  def send_wax_info(info)
    changed
    notify_observers(info)
  end

end  #module Wax
