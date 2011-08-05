require 'helper'

class TestLinkr < Test::Unit::TestCase
  def test_basics
    FakeWeb.register_uri(:get, "http://bbc.in/pdTHqe",  :location => "http://www.bbc.co.uk", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://www.bbc.co.uk",  :status => ["200", "OK"], :body => "Hello World")

    l = Linkr.new("http://bbc.in/pdTHqe", {
      :redirect_limit => 10,
      :timeout => 10
    })
    assert_equal l.class, Linkr
    assert_equal l.original_url, "http://bbc.in/pdTHqe"
    assert_equal l.redirect_limit, 10
    assert_equal l.timeout, 10
    assert_equal l.body, 'Hello World'
    assert_equal l.response.class, Net::HTTPOK 
  end

  def test_normal_link
    FakeWeb.register_uri(:get, "http://www.bbc.co.uk",  :status => ["200", "OK"], :body => "Hello World")
    assert_equal  Linkr.resolve("http://www.bbc.co.uk"), "http://www.bbc.co.uk"
  end

  def test_internal_error
    FakeWeb.register_uri(:get, "http://www.bbc.co.uk",  :status => ["500", "Internal Error"])
    assert_equal  Linkr.resolve("http://www.bbc.co.uk"), "http://www.bbc.co.uk"
  end

  def test_unauthorized
    FakeWeb.register_uri(:get, "http://www.bbc.co.uk",  :body => "Unauthorized", :status => ["401", "Unauthorized"])
    assert_equal  Linkr.resolve("http://www.bbc.co.uk"), "http://www.bbc.co.uk"
  end

  def test_some_invalid_urls
    # These are invalid based on a regular expression
    # /(^$)|(^(http|https):\/\/[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(([0-9]{1,5})?\/.*)?$)/ix
    # and is because Net/HTTP bails on uris that URI and Addressable deem fine 
    ['http','xxx','whomwah.com','0','123','http://foo'].each do |link|
      assert_raise(Linkr::InValidUrl) {
        Linkr.resolve(link)
      }
    end
  end

  def test_empty_args
    assert_raise(ArgumentError) {
      Linkr.resolve('')
    }
  end

  def test_simple_resolve
    FakeWeb.register_uri(:get, "http://bbc.in/pdTHqe",  :location => "http://www.bbc.co.uk", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://www.bbc.co.uk",  :status => ["200", "OK"])
    assert_equal  Linkr.resolve("http://bbc.in/pdTHqe"), "http://www.bbc.co.uk"
  end

  def test_too_many_redirects
    FakeWeb.register_uri(:get, "http://bbc.in/pdTHqe",  :location => "http://url1.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url1.com",       :location => "http://url2.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url2.com",       :location => "http://url3.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url3.com",       :location => "http://url4.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url4.com",       :location => "http://url5.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url5.com",       :location => "http://url6.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url6.com",       :location => "http://url7.com", :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://url7.com",       :status => ["200", "OK"])
    assert_raise(Linkr::TooManyRedirects) {
      Linkr.resolve("http://bbc.in/pdTHqe")
    }
  end

  def test_relative_urls_in_the_redirect
    FakeWeb.register_uri(:get, "http://foo.in/duncan",  :location => "/fred",    :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://foo.in/fred",    :status => ["200", "OK"])
    assert_equal  Linkr.resolve("http://foo.in/duncan"),  "http://foo.in/fred"
  end

  def test_redirect_with_location_in_body
    FakeWeb.register_uri(:get, "http://foo.in/duncan",  :body => "<p><a href='http://bar.in/fred'>Redirecting...</a>",    :status => ["301", "Moved permanently"])
    FakeWeb.register_uri(:get, "http://bar.in/fred",    :status => ["200", "OK"])
    assert_equal  Linkr.resolve("http://foo.in/duncan"),  "http://bar.in/fred"
  end
end
