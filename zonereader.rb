#!/usr/bin/env ruby -w
  
require 'termios'

class Menu
	attr_reader	:menu_items, :title

	def initialize(title = "Menu", entries = [])
		@title = title
		@menu_items = []
		count = 0

		entries.collect { | entry |
			@menu_items << [count, entry]
			count += 1
			}
		@menu_items << @menu_items.shift
	end

	def display()
		print "\n#{@title}\n\n"
		@menu_items.each { | entry |
			print "#{entry[0]}. #{entry[1]}\n"
			}
		print "\n"

# This code imports the Termios library and gets the current terminal control
# settings for STDIN. It then disables canonical input mode (ICANON) by
# modifying the local modes flag (lflag), and applies the new settings to STDIN.
# Now, every call to STDIN.getc() will return after a single key is pressed,
# as demonstrated in the loop.
		t = Termios.tcgetattr(STDIN)
		t.lflag &= ~Termios::ICANON
#		t.lflag &= ~Termios::ECHO
		Termios.tcsetattr(STDIN,0,t)

		selected_option = poll_keyboard()

# Return termios to original - not working
#		t = Termios.tcgetattr(STDIN)
#		t.lflag &= Termios::ICANON
#		t.lflag &= Termios::ECHO
#		Termios.tcsetattr(STDIN,0,t)
		selected_option
	end

	def poll_keyboard()
		selected_option = nil
		begin
			selected_option = STDIN.getc.chr
		end until ('0'..'9').member?(selected_option)
		return selected_option
	end
end

class ZoneTool
	CommentPattern = /^[[:space:]]*[;]/
	WhitespacePattern = /\s+/
	TextPattern = /\S+/
	MessageSizePattern = /MSG SIZE/
	DigitPattern = /\d+/
	TTLPattern = /^\$TTL/
	OriginPattern = /^\$ORIGIN/
	IN_SOA_Pattern = /[[:space:]]*IN[[:space:]]*SOA/ 
	IN_NS_Pattern = /[[:space:]]*IN[[:space:]]*NS/
	IN_A_Pattern = /[[:space:]]*IN[[:space:]]*A/
	SerialPattern = /[[:space:]]*[;][[:space:]]serial/
	RefreshPattern = /[[:space:]]*[;][[:space:]]refresh/
	RetryPattern = /[[:space:]]*[;][[:space:]]retry/
	ExpirePattern = /[[:space:]]*[;][[:space:]]expire/
	MinimumPattern = /[[:space:]]*[;][[:space:]]minimum/
	
	def initialize()
		@check = "/usr/local/sbin/named-checkconf"
		@reload = "/usr/local/sbin/rndc"
		@config_file = "/private/etc/named.conf"
		@comments = []
		@ttl=0
		@origin="lookup.telnic.org"
		@serial=0
		@refresh=""
		@retry=""
		@expire=""
		@soa=""
		@ns="lookup.telnic.org"
		@a="127.0.0.1"
		
		puts("DNS Zone Editor\n")
		menu()
	end

	def menu()
	# Main Menu
		entries = ["Quit", "Load Zone", "Edit Zone", "Check Zone", "Save Zone\n"]
		mymenu=Menu.new("\nDNS Zone", entries)
		out=mymenu.display()
		
		case
			when out=='1'
				puts "\n< Load Zone\n\n"
				LoadZone()
			when out=='2'
				puts "\n< Edit Zone\n\n"
				EditZone()
			when out=='3'
				puts "\n< Check Zone\n\n"
				CheckZone()
			when out=='4'
				puts "\n< Save Zone\n\n"
				SaveZone()
			when out=='0'
				puts "\n< Quit\n\n"
				Quit()
		end
	end
	
	def LoadZone()
		puts("Loading Zone\n")
		puts "\nEnter file: \n\n"
		file=/\n/.match(gets()).pre_match()
		# need to catch file not found

		@buffer=File.open(file,"r+")
		@buffer.readlines.each { | zone_entry |
			case zone_entry
				when CommentPattern
					puts "< Comment here>"
					@comments << zone_entry
				when OriginPattern
					@origin = zone_entry.match(OriginPattern).post_match()
					puts "< Origin: #{@origin}"
				when IN_SOA_Pattern
					@soa = zone_entry.match(IN_SOA_Pattern).post_match()
					puts "< IN SOA: #{@soa}"
				when TTLPattern
					@ttl = zone_entry.match(TTLPattern).post_match()
					puts "< TTL Pattern: #{@ttl}"
				when IN_NS_Pattern
					@ns = zone_entry.match(IN_NS_Pattern).post_match()
					puts "< IN NS: #{@ns}"
				when IN_A_Pattern
					@a = zone_entry.match(IN_A_Pattern).post_match()
					puts "< IN A: #{@a}"
				when SerialPattern
					@serial= zone_entry.match(SerialPattern).pre_match()
					puts "< serial: #{@serial}"					
				when RefreshPattern
					@refresh = zone_entry.match(RefreshPattern).pre_match()
					puts "< refresh: #{@refresh}"
				when RetryPattern
					@retry = zone_entry.match(RetryPattern).pre_match()
					puts "< retry: #{@retry}"
				when ExpirePattern				
					@expire = zone_entry.match(ExpirePattern).pre_match()
					puts "< expire: #{@expire}"	
				when MinimumPattern
					@minimum = zone_entry.match(MinimumPattern).pre_match()
					puts "< minimum: #{@minimum}"
			else 
				$stderr.puts "< #{zone_entry}>"
			end
		}

		menu()

	end

	def EditZone()
		entries = ["Main Menu", "SOA", "TTL", "NS", "A","Serial","Refresh","Retry","Expire","Minimum\n"]
		mymenu=Menu.new("Change Zone Entries", entries)
		out=mymenu.display()
		
		case
			when out=='1'
				puts "\n< Change SOA\n\n"
				puts "Enter new SOA\n\n"
				@soa=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='2'
				puts "\n< Change TTL\n\n"
				puts "Enter new TTL\n\n"
				@ttl=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='3'
				puts "\n< Change NS\n\n"
				puts "Enter new NS\n\n"
				@ns=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='4'
				puts "\n< Change A\n\n"
				puts "Enter new A\n\n"
				@a=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='5'
				puts "\n< Change Serial\n\n"
				puts "Enter new Serial\n\n"
				@serial=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='6'
				puts "\n< Change Refresh\n\n"
				puts "Enter new Refresh\n\n"
				@refresh=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='7'
				puts "\n< Change Retry\n\n"
				puts "Enter new Retry\n\n"
				@retry=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='8'
				puts "\n< Change Expire\n\n"
				puts "Enter new Expire\n\n"
				@expire=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='9'
				puts "\n< Change Minimum\n\n"
				puts "Enter new Minimum\n\n"
				@minimum=/\n/.match(gets()).pre_match()
				EditZone()
			when out=='0'
				puts "\n< Back to Main Menu\n\n"
				menu()
		end

	end

	def CheckZone()
		puts("Check DNS Zone\n")
		system(@check, @config_file)
		menu()
	end

	def SaveZone()
		puts("Save DNS Zone\n")
		menu()
	end
	
	def Quit()
	end
end

ZoneTool.new()
