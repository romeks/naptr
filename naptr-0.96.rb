#!/usr/bin/env ruby -w
#require 'rubygems'
require 'termios'

module HTML
# Useful html output format routines
    ON = true
    OFF = false

    ARIAL_20_POINT = ["body,td,a,p,.h{font-family:arial,sans-serif;}", ".h{font-size: 20px;}", ".q{color:#0000cc;}"]
    STANDARD_TABLE = {"border" => "1", "cellspacing" => "1", "cellpadding" => "4"}
    STANDARD_MARGINS = {"marginheight" => "0", "marginwidth" => "0", "leftmargin" => "0", "topmargin" => "0"}

	BLANK_SPACE = "\0"

    def tag_parameters(parameters)
        text = ""
        parameters.each { | key, value |
            text += %{#{key} = "#{value}" }
            }
        text
    end

	def doctype(identifier)
		%{<!DOCTYPE HTML PUBLIC "#{identifier}">}
	end

    def html(status)
        status ? "<html>" : "</html>"
    end

    def head(status)
        status ? "<head>" : "</head>"
    end

    def meta(parameters)
	text = "<meta #{tag_parameters(parameters)}>"
    end

    def body(status, parameters = {})
        status ? "<body #{tag_parameters(parameters)}>" : "</body>"
    end

    def form(status, parameters = {})
        status ? "<form #{tag_parameters(parameters)}>" : "</form>"
    end

    def title(text)
        "<title>#{text}</title>"
    end

    def header(text, level = 1)
        "<h#{level}>#{text}</h#{level}><br>"
    end

    def comment(text)
        "<!-- #{text} -->"
    end

    def single_line(text)
        "#{text}<br>"
    end

	def anchor(link, caption = nil)
		%{<a href="#{link}"><b>#{caption || link}</b></a>}
	end

	def query(parameters={})
		text = "?"
		queries = []
		parameters.each { | name, value |
			queries << "#{name}=#{value}"
			}
		text << queries.join("&")
	end

	def clickable_query(link, parameters, caption = nil)
		anchor(link + query(parameters), caption)
	end

	def text_navigation_bar(parameters={})
		navigation_bar = ""
		parameters.each { | name, value |
			navigation_bar << anchor(value, name)
			}
		navigation_bar
	end

	def image(filename, parameters = {})
		%{<img src="#{filename}" #{tag_parameters(parameters)}>}
	end

    def bold(text)
        "<b>#{text}</b>"
    end

    def italic(text)
        "<i>#{text}</i>"
    end

	def center()
		"<center>"
	end

    def new_paragraph()
        "<p>"
    end

    def non_breaking_spaces(count = 1)
        "&nbsp;" * count
    end

    def script(status)
        status ? "<script>" : "</script>"
    end

    def style(status, parameters = {})
        status ? "<style #{tag_parameters(parameters)}>" : "</style>"
    end

    def table(status, parameters = {})
        status ? "<table #{tag_parameters(parameters)}>" : "</table>"
    end

    def row(status)
        status ? "<tr>" : "</tr>"
    end

    def cell(status, parameters = {})
        status ? "<td #{tag_parameters(parameters)}>" : "</td>"
    end

    def print_hash(hash)
        text = table(ON, {"border" => "1", "cellspacing" => "0", "cellpadding" => "4"})
        hash.each { | key, value |
            text += row(ON) +
                    cell(ON) +
                    key +
                    cell(OFF) +
                    cell(ON) +
                    value +
                    cell(OFF) +
                    row(OFF)
            }
        text += table(OFF)
    end

    def edit_box(parameters)
        "<input #{tag_parameters(parameters)}>"
    end

    def button(parameters)
        %{<input type="submit" #{tag_parameters(parameters)}>}
    end
end

class NAPTR
# NAPTR toolset

	include HTML
	include Comparable

	NAPTRPattern = /NAPTR/
	TERMINATOR_PATTERN = /.i?$/
	TextPattern = /\S+/

	TERMINAL_CONFIG = {			:zone => nil,
														:ttl => 60,
														:resource_type => "NAPTR",
														:resource_class =>  "IN",
														:order => 100,
														:preference => 50,
														:flags => "U",
														:service => "",
														:regexp => "^.*$",
														:replacement => "",
														:terminator => ".",
														:delimiter => "!"}

	NON_TERMINAL_CONFIG = {	:zone => nil,
														:ttl => 60,
														:resource_type => "NAPTR",
														:resource_class =>  "IN",
														:order => 32767,
														:preference => 50,
														:flags => "U",
														:service => "",
														:regexp => "",
														:replacement => "",
														:terminator => ".",
														:delimiter => ""}

	attr_accessor	:zone, :resource_type, :resource_class, :ttl, :order, :preference, :flags, :service, :regexp, :replacement, :terminator, :delimiter

	def initialize(config = TERMINAL_CONFIG)
		@zone = config[:zone]
		@resource_type = config[:resource_type]
		@resource_class = config[:resource_class]
		@ttl = config[:ttl]
		@order = config[:order]
		@preference = config[:preference]
		@flags = config[:flags]
		@service = config[:service]
		@regexp = config[:regexp]
		@replacement = config[:replacement]
		@terminator = config[:terminator]
		@delimiter = config[:delimiter]
	end
	
	def <=>(other)
		answer =	case
						when @order < other.order then -1
						when @order > other.order then 1
						when @preference < other.preference then -1
						when @preference > other.preference then 1
						else 0
					end
	end

	def from_str(text)
		tokens = []
		text.scan(TextPattern).each { | word | tokens << word if word.length > 0 }

		if tokens.length == 10 then
			@zone = tokens.shift
		else
			@zone = " "
		end

		if tokens.length == 9 then
			@ttl = tokens.shift
		else
			@ttl = " "
		end

		if tokens.length == 8 then
			@resource_class = tokens.shift
			@resource_type = tokens.shift
			@order = tokens.shift
			@preference = tokens.shift
			@flags = tokens.shift.delete(%{"})
			@service = tokens.shift.delete(%{"})

			raw_regexp = tokens.shift
			if raw_regexp.length > 2 then
				@delimiter = raw_regexp[1,1]
				dummy, @regexp, @replacement = raw_regexp.delete(%{"}).split(@delimiter)
			else
				@delimiter = ""
				@regexp = ""
				@replacement = ""
			end

			@terminator = tokens.shift
		else
			raise "Invalid Format"
		end
	end

	def to_str()
		%{#{@zone} #{@ttl} #{@resource_class} #{@resource_type} #{@order} #{@preference} "#{@flags}" "#{@service}" "#{@delimiter}#{@regexp}#{@delimiter}#{@replacement}#{delimiter}" #{@terminator}}
	end
end

=begin
NAPTR Creator Function
Args (Order, Preference, Flags, Regexp, Replacement)
=end

class Zone
  NAPTRPattern = /NAPTR/
  CommentPattern = /^[[:space:]]*[;]/
  WhitespacePattern = /\s+/
  TextPattern = /\S+/
  MessageSizePattern = /MSG SIZE/
  DigitPattern = /\d+/

	def initialize
		@zone=[]
		@naptrs=[]
		@txt=[]

		@ttl = 600
		@soa = "lookup.telnic.org"
		@refresh = 600
		@retry = 600
		@expire = 600
		@minimum = 600
		@ns = "ns.telnic.org"
		@origin = "1.4.4.e164.arpa"
		#@a=AESKeyGen.new()
	end

	def load_from_file
		@records = []
		@comments = []
		@naptrs = []
		
		File.open("zonefile","r+").readlines.each { | dns_entry |
			case dns_entry
				when CommentPattern
					@comments << dns_entry
					if MessageSizePattern.match(dns_entry) then
						@response_size = DigitPattern.match(dns_entry).to_s
					end
					
				when NAPTR::NAPTRPattern
					begin
						naptr = NAPTR.new()
						naptr.from_str(dns_entry)
						@naptrs << naptr
					rescue Exception => e
						$stderr.puts "<#{dns_entry}>"
					end
			end
			}

		@naptrs.sort!()

		print "Loaded \"zonefile\"\n\n"
	end

	def save_to_file(filename)
		File.open(filename, "w") { | file |
			@naptrs.each { | naptr | file.puts naptr.to_str }
			}
	end

	def create
		record=NAPTR.new()
		
# %{#{@zone} #{@ttl} #{@resource_class} #{@resource_type} #{@order} #{@preference} #{@flags} #{@service} "#{@delimiter}#{@regexp}#{@delimiter}#{@replacement}#{delimiter}" #{@replacement}}

		record.ttl=60
		record.resource_class="IN"
		record.resource_type="NAPTR"
		
		puts "Enter order:"
		record.order=/\n/.match(gets()).pre_match()
		
		puts "Enter preference:"
		record.preference=/\n/.match(gets()).pre_match()

		record.flags="U"
		record.delimiter='!'

		puts "Enter service:"
		record.service=/\n/.match(gets()).pre_match()
		
		puts "Enter regexp:"
		record.regexp=/\n/.match(gets()).pre_match()

		puts "Enter replacement:"
		record.replacement=/\n/.match(gets()).pre_match()

		record.terminator='.'
	
		@naptrs << record
		print "\nCreated NAPTR\n\n"
	end

	def edit
		record_menu()
		c = ''
		while c != '0' do	 #	Quit
  			c = STDIN.getc.chr
			case
				when ('1'...'9').include?(c)
					puts "Editing record #{c}:"
					puts @naptrs[(c.to_i)-1].to_str
					puts "\nChange?"
					puts "1. TTL: #{@naptrs[(c.to_i)-1].ttl}\n"
					puts "2. Order: #{@naptrs[(c.to_i)-1].order}\n"
					puts "3. Preference: #{@naptrs[(c.to_i)-1].preference}\n"
					puts "4. Service: #{@naptrs[(c.to_i)-1].service}\n"
					puts "5. Regexp: #{@naptrs[(c.to_i)-1].regexp}\n"
					puts "6. Replacement: #{@naptrs[(c.to_i)-1].replacement}\n"
					puts "7. Delimiter: #{@naptrs[(c.to_i)-1].delimiter}\n"
					puts "0. Return to Edit Menu\n\n"

					d = ''
					while d != '0' do	 #	Quit
  						d = STDIN.getc.chr()
						case
							when d == '1'	 #	Load Zone Record
  								puts "\nEdit TTL\n\n"
								@naptrs[(c.to_i)-1].ttl=STDIN.gets()
								puts @naptrs[(c.to_i)-1].to_str
							when d == '2'	 #	Display Zone Record
  								puts "\nEdit Order\n\n" 
								@naptrs[(c.to_i)-1].order=STDIN.gets()
								puts @naptrs[(c.to_i)-1].to_str
							when d == '3'	 #	Save Zone Record
  								puts "\nEdit Preference\n\n"
								@naptrs[(c.to_i)-1].preference=STDIN.gets()
								puts @naptrs[(c.to_i)-1].to_str
							when d == '4'	 #	Create NAPTR
  								puts "\nEdit Service\n\n"
								@naptrs[(c.to_i)-1].service=STDIN.gets()
								puts @naptrs[(c.to_i)-1].to_str
							when d == '5'	 #	Edit NAPTR
  								puts "\nEdit Regexp\n\n"
								@naptrs[(c.to_i)-1].regexp=STDIN.gets()
								puts @naptrs[(c.to_i)-1].to_str
							when d == '6'	 #	Delete NAPTR
								puts "\nEdit Replacement\n\n"
								@naptrs[(c.to_i)-1].replacement=STDIN.gets()
								puts @naptrs[(c.to_i)-1].to_str
							when d == '9'	 #	Delete TXT	
  								puts "\nDecrypt NAPTR\n\n"
								@naptrs[(c.to_i)-1].replacement=@a.decrypt(@naptrs[(c.to_i)-1].replacement)
								puts @naptrs[(c.to_i)-1].to_str
							when d == '0'	 #	Quit
  								puts "\n\nQuit\n\n"
						end
					end
				when c == '0'	 #	Return to Main Menu
  					puts "\n\nReturn to Main Menu\n\n"
			end
		end		
	end
	
	def record_menu
		lineno=0	# no lineno for this - may tidy later RS 260106
		@naptrs.each{|naptr|
			lineno+=1
			puts "#{lineno}. #{naptr.to_str}"
		}
		puts "0. Return to Main Menu\n\n"
	end

	def delete
		record_menu()
		c = ''
		while c != '0' do	 #	Quit
  			c = STDIN.getc.chr
			case
				when ('1'...'9').include?(c)
  					puts "\n\nReceived #{c}\n\n"
					@naptrs.delete_at((c.to_i)-1)
  				
				record_menu()
				when c == '0'	 #	Return to Main Menu
  					puts "\n\nReturn to Main Menu\n\n"
			end
		end
	end

	def display
		print "Display NAPTR and TXT Objects for Zone\n\n"
		
		@naptrs.each{|naptr|
			puts naptr.to_str
#			$stderr.puts "<#{naptr.to_str}>"
		}
		puts "\n"
	end
end

class Menu
	def initialize
		print "\nDNS Zone NAPTR Editor\n\n"
		print "1. Load Zone Record\n"
		print "2. Display Zone Record\n"
		print "3. Save Zone Record\n\n"
		print "4. Create NAPTR\n"
		print "5. Edit NAPTR\n"
		print "6. Delete NAPTR\n\n"
		print "9. Display Menu\n\n"
		print "0. Quit\n"
		print "\n"
		record=Zone.new

# This code imports the Termios library and gets the current terminal control
# settings for STDIN. It then disables canonical input mode (ICANON) by
# modifying the local modes flag (lflag), and applies the new settings to STDIN.
# Now, every call to STDIN.getc() will return after a single key is pressed,
# as demonstrated in the loop.
		t = Termios.tcgetattr(STDIN)
		t.lflag &= ~Termios::ICANON
#		t.lflag &= ~Termios::ECHO
		Termios.tcsetattr(STDIN,0,t)

		c = ''
		while c != '0' do	 #	Quit
  			c = STDIN.getc.chr()
			case
				when c == '1'	 #	Load Zone Record
  					puts "\nLoad Zone Record\n\n"
					record.load_from_file
				when c == '2'	 #	Display Zone Record
  					puts "\nDisplay Zone Record\n\n" 
					record.display
				when c == '3'	 #	Save Zone Record
  					puts "\nSave Zone Record\n\n"
					record.save_to_file("zonefile")
				when c == '4'	 #	Create NAPTR
  					puts "\nCreate NAPTR Record\n\n"
					record.create
				when c == '5'	 #	Edit NAPTR
  					puts "\nEdit NAPTR Record\n\n"
					record.edit
				when c == '6'	 #	Delete NAPTR
					puts "\nSelect NAPTR to delete\n\n"
					record.delete
				when c == '9'	 #	Delete TXT	
  					puts "\nDisplay Menu\n\n"
					puts to_str()
				when c == '0'	 #	Delete TXT	
  					puts "\n\nQuit\n\n"
			end
		end
	end

	def to_str()
		"\nDNS Zone NAPTR Editor\n\n1. Load Zone Record\n2. Display Zone Record\n3. Save Zone Record\n\n4. Create NAPTR\n5. Edit NAPTR\n6. Delete NAPTR\n\n9. Display Menu\n\n0. Quit\n\n"
	end
end
Menu.new()
