require 'mechanize'
require 'tempfile'
require 'exifr'

class Spider
  def initialize(url)
    @start_url = url

    start_spidering(@start_url)
    #special_hax('http://wassup.myblog.sg/files/2009/07/queue_outside_comcenter_iphone_3gs.jpg')
  end

  def start_spidering(url)
    agent = WWW::Mechanize.new
    search_page = agent.get(url)
    search_page.search('tr td a img').each do |link|
      if link.to_html =~ /gstatic.com/ # thumbnail?
        image_url = link.to_html.match(/q=tbn:[^:]+:(.*?)"/)[1]
        begin
          puts image_url
          image = agent.get(image_url)
          Tempfile.open('hax') do |file|
            file << image.body
            p get_gps_info(file.path)
          end
        rescue WWW::Mechanize::ResponseCodeError, EOFError, RuntimeError
        rescue Exception => e
          p e.class
          raise $!
        end
      end
    end

    if next_link = search_page.links.detect { |l| l.text == 'Next' }
      start_spidering('http://images.google.com' + next_link.href)
    end
  end

  def get_gps_info(file)
    ex = EXIFR::JPEG.new(file)
    return if ex.nil? || ex.exif.nil? || ex.exif.gps_longitude.nil?
    [sprintf("%.04f", ex.exif.gps_latitude[1]),
     sprintf("%.04f", ex.exif.gps_longitude[0]),
     ex.exif.date_time]
  end
end
