require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'rtranslate'


require 'rtf'
include RTF

require 'rtf-extensions/rtf/utf8.rb'
require 'rtf-extensions/rtf/hyperlink.rb'

$KCODE ='u'
require 'jcode'

module SohuNovel

  BASE = "http://lz.book.sohu.com"
  
  def self.get_list(book_number)
    puts "Geting List..."
    # extract chapter list
    
    url = "#{BASE}/serialize-id-#{book_number}.html"
    
    doc = Nokogiri::HTML(open(url))
    content_raw = doc.search(".boxI")
    chapter_list = []
    content_raw.each do |c|
      c.search("ul.clear li a").each do |a|
        chapter_title = a.content
        link = a['href']
        chapter_list << [chapter_title, link]
      end
    end
    return chapter_list
  end

  def self.translate_text_by_paragraph(string)
    # Google Translate text limit is among 200

    if string.mb_chars.length < 200
      return RTranslate.t(string,"zh-CN", "zh-TW")
    else
      length = string.mb_chars.length
      round = length/200+1
      new_string = ""
      for i in 0..round
        startpoint = i*200
        endpoint = i*200 +199
        s = string.mb_chars[startpoint..endpoint].to_s 
        new_string += RTranslate.t(s, "zh-CN", "zh-TW")
      end
      return new_string
    end
  end

  def self.transcode(string)
    puts "Transcoding ...."
    return Iconv.iconv("UTF-8//IGNORE","GB2312//IGNORE",string.to_s).to_s
  end

  def self.strip_tag(string)
    puts "String Tags..."
    string = string.gsub!("<p>","\n")
    string = string.gsub!("</p>","\n")
    string = string.gsub!("<br>","\n\n")
    return string
  end

  def self.translate(string)
    puts "Translating ...."
    
    s = ""
    string.each_line do |p|
      s += translate_text_by_paragraph(p)
      s += "\n"
    end
    return s
  end

  def self.write_to_txt_file(filename,text)
    puts "Writing to txt ile: #{filename}"
    File.open(filename, 'w') {|f| f.write(text) }
  end
  
  def self.write_to_rtf_file(chapter)
    puts "Writing to rtf ile: #{@book_number}"
    
    doc = RTF::Document.new(Font.new(Font::ROMAN, 'Times New Roman'))

    
    chapter.each do |c|
      filename = c[1].gsub(".html", ".txt")
      myfile = File.open(filename)
      myfile.readlines.each do |text|
        doc.paragraph do |p|
          p << text
        end
      end
    end

    f = File.open("#{@book_number}.rtf", 'w')
    f.write(doc.to_rtf)
    f.close
  end
  
  def self.get_chapter(link,title)
    url = "#{BASE}/#{link}"
    puts "Fetching novel #{url}"
    doc = Nokogiri::HTML(open(url))
    content_raw = doc.search("#txtBg p")
    utf8_content = transcode(content_raw)
    strip_content = strip_tag(utf8_content)
    content = translate(strip_content)
    
    
    filename = link.gsub(".html",".txt")
    write_to_txt_file(filename,content)

  end
  
  def self.get_book(book_number)
    @book_number = book_number
    chapter = get_list(book_number)
    
    chapter.each do |c|
      link = c[1]
      title = translate(c[0])
      puts "Fetching #{title} #{link}"
      get_chapter(link,title)
    end
    
    write_to_rtf_file(chapter)
  end
  
end

book_num = ARGV[0]

SohuNovel.get_book(book_num)

