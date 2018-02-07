require "open-uri"
require "nokogiri"

class GoApi

  attr_accessor :networks, :content, :series, :response, :properties, :cms_headers


  def initialize(opts = {})
    opts.each {|k,v| self.send("#{k}=", v)}
    self.networks ||= networks
    self.content ||= []
    self.series ||= {}
    self.response ||= {}
    self.properties = set_properties(opts[:properties])
  end

  def networks
    @networks = [
      "dfc", 
      "ahc", 
      "dlf",
      "dsc",
      "dam",
      "apl",
      "sci",
      "tlc",
      "ids",
      "vel",
      "des",
      "dsf"
      ]
  end

  def pull
    @content = []
    @series = {}
    # @networks.each {|net| get_roku(net)}
    @networks.each {|net| 
      puts "Pulling #{net}"
      vidora(net)
    }
    self
  end


  def as_hash
    @start = Time.now
    # @content = []
    # @series = {}
    # # @networks.each {|net| get_roku(net)}
    # @networks.each {|net| 
    #   puts "Pulling #{net}"
    #   vidora(net)
    # }
    pull
    # @response = {}
    @content.each{|c| @response ||= {}; @response[c[:slug] = c]}
    @response
  end


  def as_csv
    # @start = Time.now
    # @content = []
    # @series = {}
    # @networks.each {|net| 
    #   puts "Pulling #{net}"
    #   vidora(net)
    # }
    pull
    # match_to_cms
    to_csv
    display_counts
  end

  def get_roku(net)
    @content ||= []
    url = "http://api.discovery.com/feeds/roku/#{net}/channel-search"
    @doc = Nokogiri::XML(open(url))

    # @doc.xpath("//partnerContent/seriesItems/series") # Returns all series
    # @doc.css("partnerContent seriesItems series titles title") # Returns all series titles (CSS syntax)


    # The below will create an episode-level table. If we want detailed metadata on the show beyond the title and ID we'll set this up differently.
    # Get an array of series:
    series = @doc.css("partnerContent seriesItems series")
    series.each do |show|
      show_hash = {id: show.attributes["id"].value, title: show.css("titles title")[0].inner_text}
      show_id = show.attributes["id"].value
      show_title = show.css("titles title")[0].inner_text
      show.css("seasons season").each do |season|
        season_number = season.at_css("seasonNumber").inner_text
        season.css("episodes episode").each do |episode|
          video = {}
          video[:id] = episode.attributes["id"].value
          video[:title] = episode.at_css("titles title").inner_text
          video[:show_id] = show_id
          video[:show_title] = show_title
          video[:network_code] = net.upcase
          video[:season_num] = season_number
          video[:episode_num] = episode.at_css("episodeNumber").inner_text
          video[:parental_rating] = episode.at_css("ratings rating rating").inner_text
          # Roku data doesn't include: season_id, slug, adVideoId (paid), duration
          @content << video
        end
      end
    end
  end

  def set_properties(arr)
    @properties = arr.nil? ? vidora_properties : vidora_properties.select{|k,v| arr.map{|x| x.to_sym}.include? k}
  end


  def vidora_properties
    # Slug, AdVideoID/PAID, Show_title not available.
    {
      video_id: "id",
      title: "title",
      show_id: "showId",
      # show_title: "",
      network_code: "networks network",
      season_num: "seasonNumber",
      episode_num: "episodeNumber",
      parental_rating: "rating",
      video_type: "subType",
      type: "type",
      season_id: "seasonId",
      # slug: "",
      # adVideoId: "",
      duration: "duration",
      publish_date: "publishDate",
      air_date: "airDate",
      start_date: "license startDate",
      end_date: "license endDate"
    }
  end


  def vidora(net)
    # DFC is not available on Vidora....
    return if ["dfc","dsf","des"].include? net
    @content ||= []
    url = "http://api.discovery.com/feeds/vidora/#{net}/vidora-catalog"
    @doc = Nokogiri::XML(open(url))
    # series = {}
    @doc.css("contentFeed item").select{|x| x.at_css("contentType").inner_text == "show"}.each{|s| @series[s.at_css("id").inner_text] = s.at_css("title").inner_text}
    @doc.css("contentFeed item").select{|x| x.at_css("contentType").inner_text == "video"}.each do |video|
      @vid = {}
      @properties.each do |k,v|
        @vid[k] = video.at_css(v).inner_text if video.at_css(v)
        if @properties.keys.include? :show_id
          @vid[:show_title] = @series[@vid[:show_id]]
          # @vid[:slug] = "#{to_slug(@vid[:show_title])}|#{to_slug(@vid[:title])}"
          @vid[:slug] = title_slug(@vid[:show_title], @vid[:title])
        end
        # start and end dates
        # will need to convert some of these (duration, ep_num, etc..) to integers
      end
      @content << @vid 
    end
    @content 
  end

  def display_counts
    puts "Total - #{@content.count}"
    @content.map{|x| x[:network_code]}.uniq.each{|x| puts "#{x} - #{@content.select{|y| y[:network_code] == x}.count}"}
    puts "Nil PAID: #{@content.select{|x| x[:paid].nil?}.count}"
  end

  def match_to_cms
    @content ||= []
    @cms = load_report_to_hash
    # @headers = @cms[0]
    puts @cms_headers
    puts @content.count
    puts @cms.count
    # @content[0] << "paid"
    @content.each {|x| x[:paid] = @cms[x[:slug]][@cms_headers.index("imediapaid")]}
  end

  def to_csv
    require "csv"
    @content ||= []
    return if @content.count < 1
    CSV.open("vidora_export_#{Time.now.to_s}.csv", "w+") do |csv|
      csv << @content[0].keys.map{|x| x.to_s}
      # @content = @content.first(100)
      @content.each {|v| csv << v.values}
    end
  end


  def to_slug(str)
    str.to_s.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end

  def title_slug(show_title, ep_title)
    "#{to_slug(show_title)}|#{to_slug(ep_title)}"
  end


  #### Loading existing CSV Report

  def load_report_to_hash(file = nil)
    # Need to add option to pass an array
    require "csv" unless defined? CSV
    file ||= Dir.glob("#{ENV["HOME"]}/Google Drive/CMS Reports/cms_report*.csv").sort_by{|x| File.mtime(x)}.last
    @data = CSV.read(file)
    @data[0] = @data[0].map{|x| x.downcase.gsub(" ","_")} #convert headers to slug
    @cms_headers = @data[0]
    @data[1..-1].map {|r| 
      @cms ||= {}
      @cms[title_slug(r[@cms_headers.index("show_name")], r[@cms_headers.index("video_name")])] = r
    }
    puts "CMS: #{@cms.count}"
    @cms
  end


  ## This works, but I need to reverse it so that instead of looking at the CMS and grabbing a PAID from there the CMS report can pull this and then add the episode_id, show_id, season_id, etc.. to the CMS report and then store that in the database.

end


# GoApi.new(properties: ["title", "network_code"]).as_csv

GoApi.new.as_csv


