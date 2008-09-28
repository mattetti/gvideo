require 'rubygems'
require 'hpricot'
require 'open-uri'

# Retrieve the videos associated to a user (limited to 100 videos)
#
# Usage example
# A005148908335059515423
# user = Gvideo::User.new("A005148908335059515423")
# videos = user.fetch_videos
#
# You can find a user's id by using firebug and inspect the call made to "see more videos from a user"
#
# $Gvideo_verbose = true # set this constant to true in your app to see some debugging output



module Gvideo
  
  class GvideoException < RuntimeError
    def initialize (message)
      super(message)
    end
  end
  
  # A generic record that initializes instance variables from the supplied hash
  # mapping symbol names to their respective values.
  # borrowed from http://www.rubyforge.org/projects/google-video/
  class Record
    def initialize (params)
      if params != nil
        params.each do |key, value| 
          name = key.to_s
          instance_variable_set("@#{name}", value) if respond_to?(name)
        end
      end
    end
  end
  
  # Video object represent a google video object with various attributes
  # such as its docid, title, video url (to playback the video), duration, thumbnail_url
  # 
  class Video < Record
    
    attr_reader :docid
    attr_reader :title
    attr_reader :video_url
    attr_reader :duration
    attr_reader :duration_in_minutes
    attr_reader :thumbnail_url
    
    
    def embed_player(width=400, height=326)
      "<embed id='VideoPlayback-#{docid}' src='http://video.google.com/googleplayer.swf?docid=#{docid}&hl=en&fs=true' style='width:#{width}px;height:#{height}px' allowFullScreen='true' allowScriptAccess='always' type='application/x-shockwave-flash'></embed>"
    end
    
  end
  
  class User
    
    # Google user id
    # Example: "005148908335059515423"
    attr_reader :g_id
    
    def initialize (google_user_id)
      @g_id = google_user_id
      @user_video_url = "http://video.google.com/videomorefrom?q=source%3#{@g_id}&filter=0&hl=en&num=100&start=0"
      @video_raw_data = {}
      @video_count = nil
    end
    
    
    # returns an array of videos
    #
    # pass a hash of conditions
    # available conditions can only target
    # the title or the duration of a video
    #
    # ---
    # @api public
    def fetch_videos(conditions = {})
      videos = []
      # if video_count > 100 get all the videos using a higher cursor
      0.upto((video_count/100.to_f).ceil - 1) do |cursor| 
        p "fetching videos with cursor: #{cursor}" if $Gvideo_verbose
        cursor = (cursor * 100) if cursor > 0 
        videos << extract_video_elements_from_raw_data(video_raw_data(cursor), cursor, conditions)
      end
      
      videos.flatten
    end
    
    # returns the amount of videos uploaded by the user
    def video_count
      if @video_count.nil?
        count = video_raw_data.at("div#morefromuser div").inner_text
        @video_count = count.nil? ? nil : count.to_i
      else
        @video_count 
      end
    end
    
    private
    
    def user_video_url(cursor=0)
      "http://video.google.com/videomorefrom?q=source%3#{@g_id}&filter=0&hl=en&num=100&start=#{cursor}"
    end
    
    #
    # creates a video instance using the scrapped data
    #
    # ---
    # @api private
    def extract_video(element, conditions)
      docid               = element['docid']
      duration            = element['dur'].to_i
      title               = element.at("div.vli-metadata span.vlim-title a")['title']
      thumbnail_url       = element.at("span.vli-thumbnail a img")['src']
      video_url           = element['url']
      duration_in_minutes = element.at("div.vli-metadata span.vlim-duration").inner_text
      
      if conditions.has_key?(:title)
        return if conditions[:title].is_a?(String) && conditions[:title] != title
        return if conditions[:title].is_a?(Regexp) && title.match(conditions[:title]).nil?
      end
      if conditions.has_key?(:duration)
        return if conditions[:duration].is_a?(Integer) && conditions[:duration] != duration
        return if conditions[:duration].is_a?(Range) && !conditions[:duration].include?(duration)
      end
      Video.new( {  :docid                => docid,
                    :duration             => duration,
                    :title                => title,
                    :thumbnail_url        => thumbnail_url,
                    :video_url            => video_url,
                    :duration_in_minutes  => duration_in_minutes } )
    end
    
    
    #
    # extract video elements from a raw video data and returns an array of Gvideo::Video objects
    #
    def extract_video_elements_from_raw_data(video_raw_data, cursor=0, conditions={})
      videos = []
      video_raw_data(cursor).search("div.video-list-item").each do |element|
        videos << extract_video(element, conditions)
      end
      videos.compact
    end
    
    #
    # retrieves video data if cached otherwise fetches it
    #
    def video_raw_data(cursor=0)
      @video_raw_data[cursor] ||= fetch_video_raw_data(cursor)
      p "at cursor: #{cursor} first docid: #{@video_raw_data[cursor].search("div.video-list-item").first['docid']}" if $Gvideo_verbose
      @video_raw_data[cursor]
    end
    
    #
    # open and parse the user video url (raw data gets reset)
    # pass a cursor to start fetching data after a certain point
    #
    def fetch_video_raw_data(cursor=0)
      p "fetching raw video data for cursor #{cursor}" if $Gvideo_verbose
      
      # reset video count
      @video_count = nil unless cursor > 0
      
      # open the user video url
      begin
        url = open(user_video_url(cursor))
      rescue 
        raise GvideoException.new("failed to access user's video")
      end
      # parse the url and return the hpricot doc
      begin
        doc = Hpricot(url)
      rescue
        raise GvideoException.new("failed to parse raw Google video data")
      else
        @video_raw_data[cursor] = doc
      end
    end #of video_raw_data
      
  end #of user
  
end