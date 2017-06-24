require 'nokogiri'
require 'open-uri'
require 'launchy'
require 'rmagick'

class DeObfuscator
  def initialize(address)
    @response = Nokogiri.parse(open(address))
    @api_strings = @response.text.scan(/static[^;]*ttf/).flatten
    @return_string = ''

    download_font_files
    build_return_string
    swap_obfuscated_content
    save_edited_html
    launch_browser
    delete_files
  end


  def build_return_string
    obfuscated_text_array = @response.at_xpath('//h1').text.chars

    obfuscated_text_array.each do |char|
      create_image_from_text(char)
      deobfuscated_character = return_text_from_image

      p @return_string << deobfuscated_character
    end
  end

  def return_text_from_image
    input = './tmp_text_img.png'
    `tesseract #{input} tmp_text_from_img -l  eng+hacker_rank -c tessedit_char_whitelist=ABCDEFGHIJKLKMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890 -psm 6`
    File.readlines('tmp_text_from_img.txt')[0].chars.size == 3 ? " " :
      File.readlines('tmp_text_from_img.txt')[0].chars[-2]
  end

  def create_image_from_text(text)
    str = text # I don't know why, but RMagick panics unless I include this line

    canvas = Magick::ImageList.new
    canvas.new_image(500, 200)
    text = Magick::Draw.new

    text.annotate(canvas, 0,0,20,0, 'Oo') {
      self.font = './font_0.ttf'
      self.gravity = Magick::WestGravity
      self.density = '800'
      self.pointsize = 16
    }

    text.annotate(canvas, 0,0,20,0, str) {
      self.font = './font_1.ttf'
      self.gravity = Magick::EastGravity
      self.density = '800'
      self.pointsize = 16
    }

    text.annotate(canvas, 0,0,20,0, str) {
      self.font = './font_2.ttf'
      self.gravity = Magick::EastGravity
      self.density = '800'
      self.pointsize = 16
    }

    canvas.write('tmp_text_img.png') {
      self.units= Magick::PixelsPerInchResolution; self.density = "800"
    }
  end

  def download_font_files
    external_apis = @api_strings.map {
      |text| "http://protext.hackerrank.com/#{text}"
    }

    external_apis.each_with_index do |api, idx|
      reply = open(api, 'Cookie' => 'X-VALID=TRUE').read
      File.open("font_#{idx}.ttf", 'w') { |file| file.write(reply) }
    end
  end

  def swap_obfuscated_content
    h1 = @response.at_xpath('//h1')
    h1.content = @return_string
  end

  def save_edited_html
    File.open('tmp.html', 'w') { |file| file.write(@response) }
  end

  def launch_browser
    Launchy.open('./tmp.html')
  end

  def delete_files
    sleep 1
    File.delete('./tmp.html')
    File.delete('./font_0.ttf')
    File.delete('./font_1.ttf')
    File.delete('./font_2.ttf')
    File.delete('./tmp_text_img.png')
    File.delete('./tmp_text_from_img.txt')
  end
end

DeObfuscator.new('http://protext.hackerrank.com/')
