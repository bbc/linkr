require 'ostruct'
require 'net/http'
require 'addressable/uri'

class Linkr
  class TooManyRedirects < StandardError; end
  class InValidUrl < StandardError; end
  
  attr_accessor :original_url, :redirect_limit, :timeout
  attr_writer :url, :response
  
  def initialize(original_url, opts={})
    opts = {
     :redirect_limit   => 5,
     :timeout => 5 
    }.merge(opts)

    @original_url = original_url 
    @redirect_limit = opts[:redirect_limit]
    @timeout = opts[:timeout]
    @proxy = ENV['http_proxy'] ? Addressable::URI.parse(ENV['http_proxy']) : OpenStruct.new
    @link_cache = nil
  end

  def url
    resolve unless @url
    @url
  end

  def body
    response.body
  end

  def response
    resolve unless @response
    @response
  end

  def self.resolve(*args)
    self.new(*args).url
  end

  private

  def resolve
    raise TooManyRedirects if @redirect_limit < 0

    self.url = original_url unless @url
    @uri = Addressable::URI.parse(@url).normalize

    fix_relative_url if !@uri.normalized_site && @link_cache

    raise InValidUrl unless valid?

    http = Net::HTTP::Proxy(@proxy.host, @proxy.port).new(@uri.host, @uri.port)
    http.read_timeout = http.open_timeout = @timeout
    request = Net::HTTP::Get.new(@uri.omit(:scheme,:authority).to_s)
    self.response = http.request(request)

    redirect if response.kind_of?(Net::HTTPRedirection)      
  end

  def redirect
    @link_cache = @uri.normalized_site
    self.url = redirect_url 
    @redirect_limit -= 1
    resolve
  end

  def fix_relative_url
    @url = File.join(@link_cache, @uri.omit(:scheme,:authority).to_s)
    @uri = Addressable::URI.parse(@url).normalize
    @link_cache = nil 
  end

  def redirect_url
    if response['location'].nil?
      response.body.match(/<a href=[\"|\']([^>]+)[\"|\']>/i)[1]
    else
      response['location']
    end
  end

  def valid?
    regex = /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
    true if self.url && self.url =~ regex
  end
end
