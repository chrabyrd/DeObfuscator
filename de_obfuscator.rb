require 'nokogiri'
require 'open-uri'
require 'launchy'

class DeObfuscator
  def initialize(address)
    @response = Nokogiri.parse(open(address))
    @api_strings = @response.text.scan(/static[^;]*ttf/).flatten

    download_font_files
    edit_html_style
    save_edited_html
    launch_browser
    delete_files
  end

  def download_font_files
    external_apis = @api_strings.map { |text| "http://protext.hackerrank.com/#{text}"}

    external_apis.each_with_index do |api, idx|
      reply = open(api, 'Cookie' => 'X-VALID=TRUE').read
      File.open("font_#{idx}.ttf", 'w') { |file| file.write(reply) }
    end
  end

  def edit_html_style
    style = @response.at_xpath('//style')

    @api_strings.each_with_index do |str, idx|
      style.content = style.content.sub str, "./font_#{idx}.ttf"
    end

    style.content = style.content.sub 'h1', 'h2'
  end

  def save_edited_html
    File.open('tmp.html', 'w') { |file| file.write(@response) }
  end

  def launch_browser
    Launchy.open('http://protext.hackerrank.com/')
    Launchy.open('./tmp.html')
  end

  def delete_files
    sleep 1
    File.delete('./tmp.html')
    File.delete('./font_0.ttf')
    File.delete('./font_1.ttf')
    File.delete('./font_2.ttf')
  end
end

DeObfuscator.new('http://protext.hackerrank.com/')
