require File.dirname(__FILE__) + '/spec_helper'

# We are testing against a real google user data
# make sure you have an internet connection
# make sure the user's account is still active and working:
# http://video.google.com/videomorefrom?q=source%3A005148908335059515423&filter=0&hl=en&num=16&start=0
# should display properly
# if it doesn't, or google changed their UI and the scaper fails, or the user account was disabled

describe "Gvideo testing against real API" do
  
  it "should let you create a google video user" do
    Gvideo::User.new("A005148908335059515423").should be_an_instance_of(Gvideo::User)
  end
  
  describe "Gvideo::User" do
    before(:all) do
      @user = Gvideo::User.new("A005148908335059515423")
    end
    
    it "should be able to fetch videos" do
      videos = @user.fetch_videos
      
      videos.should be_an_instance_of(Array)
      videos.first.should be_an_instance_of(Gvideo::Video)
    end
    
    it "should have a videos count" do
      @user.video_count.should > 0
    end
    
    it "should have unique videos" do
      videos = @user.fetch_videos
      videos.map{|v| v.docid}.uniq.size.should == videos.size
    end
    
  end
  
  describe "Gvideo::Video" do
    before(:all) do
      @user = Gvideo::User.new("A005148908335059515423")
      @videos = @user.fetch_videos
      @video = @videos.first
    end
    
    it "should have a docid" do
      @video.docid.should_not be_nil
    end
    
    it "should have a title" do
      @video.title.should_not be_nil
    end
    
    it "should have a video url" do
      @video.video_url.should_not be_nil
    end
    
    it "should have a duration" do
      @video.duration.should_not be_nil
    end
    
    it "should have a duration in minutes" do
      @video.duration_in_minutes.should_not be_nil
    end
    
    it "should have a thumbnail_url" do
      @video.thumbnail_url.should_not be_nil
    end
    
    it "should have an embed_player" do
      @video.embed_player.should_not be_nil
    end
    
  end
  
end


describe "Gvideo testing against mocks" do
  
  before(:each) do
    @user = Gvideo::User.new("12345")
    @raw_data = mock('raw_data')
    @element_value = mock('element_value')
    @user.stub!(:fetch_video_raw_data).and_return(@raw_data)
    @user.stub!(:video_count).and_return(5)
    @raw_data.stub!(:search).and_return([])
    @raw_data.stub!(:at).and_return(@element_value)
    @element_value.stub!(:inner_text).and_return('some string value')
  end
  
  it "should retrieve the user's video pages" do
    @user.should_receive(:video_raw_data).with(0).at_least(1).times.and_return(@raw_data)
    @user.fetch_videos
  end
  
  it "should not fetch raw data more than once" do
    @user.should_receive(:fetch_video_raw_data).with(0).and_return(@raw_data)
    @user.fetch_videos
  end
  
  it "should set the video count after fetching videos" do
    @user.should_receive(:video_count).and_return(5)
    @user.fetch_videos
  end
  
  it "should fetch all the video pages when a user has more than 100 photos" do
    @user.stub!(:video_count).and_return(152)
    @user.should_receive(:fetch_video_raw_data).with(0).and_return(@raw_data)
    @user.should_receive(:fetch_video_raw_data).with(100).and_return(@raw_data)
    @user.fetch_videos
  end
  
end