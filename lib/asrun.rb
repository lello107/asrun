require "asrun/version"
require "bindata"
require 'builder'
require 'pathname'

module Asrun


	def self.convert(source)

		io = File.open(source)
		asrun = AsrunLouth.read(io)

		filename = File.basename(source,".log")
		path = File.dirname(source)
		xml_file="#{path}/#{filename}.xml"
		puts "target file: #{xml_file}"
		puts "source file: #{source}"
		
		file = File.new(xml_file, "wb")
		xml = Builder::XmlMarkup.new( target: file, :indent=>2)
		xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"

		
			xml.BxfMessage { |bxfmessage|
				bxfmessage.BxfQueryResponse { |bxfqueryresponse|

					asrun.rows.each do |row|

					bxfqueryresponse.AsRun { |asrun|
						asrun.BasicAsRun { |basicasrun|
						 	basicasrun.AsRunEventId {|asruneventid|
						 		asruneventid.EventId("#{row.reconcile_key}")

						}
						basicasrun.Content { |content|
							content.ContentId { |contentid|
								contentid.HouseNumber("#{row.id}")
								contentid.Name("#{row.title}")
							}
						}
						basicasrun.AsRunDetail {|asrundetail|
							status = row.error_code == 1020 ? "OK" : "RAN_SHORT"
							asrundetail.Status("#{status}")
							smtpedate = DateTime.strptime("#{row.real_onair_date}","%d/%m/%y")
							asrundetail.StartDateTime(:broadcastDate => "#{smtpedate.strftime("%Y-%m-%d")}") { |startdatetime| 
								
								startdatetime.SmpteTimeCode("#{row.real_onair_tc}")
							}
							asrundetail.Duration { |duration| duration.SmpteDuration{ |smpteduration| smpteduration.SmpteTimeCode("#{row.dur}")}}
							asrundetail.SOM(:frameRate=>"25") { |som| som.SmpteTimeCode("00:00:00:00")  }
							asrundetail.Type("")

						}

					}
				}
				end
			}
		}
		



		# TODO: Add your tags
		file.close
	end

  	# Private: Set/Get BCD value from harris lst file
	#
	# BCD: Binary code decimal
	#
	class ErrorCode < BinData::Primitive

	  uint8  :valore_0, :read_length => 1, :initial_value=>255
	  uint8  :valore_1, :read_length => 1, :initial_value=>255
	  uint8  :valore_2, :read_length => 1, :initial_value=>255
	  uint8  :valore_3, :read_length => 1, :initial_value=>255

	  def get
	  	return valore_0 + valore_1 + valore_2 + valore_3
	  end

	  def set(v)
	  	 self.valore=v
	  end

	end
  

  	# Private: Set/Get BCD value from harris lst file
	#
	# BCD: Binary code decimal
	#
	class Bcd < BinData::Primitive

	  uint8  :valore, :read_length => 1, :initial_value=>255

	  def get
	  	return valore
	  end

	  def set(v)
	  	 self.valore=v
	  end

	end

  	# Private: Timecode primitive BinData, set value in Harris BCD value
	# => get BCD value and convert it to String with ":" separator
	#
	#
	# Returns "10:00:01:24"
	#
	class BcdDate < BinData::Primitive

	  uint8  :valore_day, :read_length => 1, :initial_value=>0
	  uint8  :valore_month, :read_length => 1, :initial_value=>0
	  uint8  :valore_year, :read_length => 1, :initial_value=>0

	  def get
	  	return addzero(valore_day.to_i.to_s(16)) + "/" + addzero(valore_month.to_i.to_s(16)) + "/" + addzero(valore_year.to_i.to_s(16))
	  end

	  def set(v)
	  	arr = v.split("/").reverse
	  	self.valore_day		= arr[0].to_i(16)
	  	self.valore_month	= arr[1].to_i(16)
	  	self.valore_year	= arr[2].to_i(16)

	  end

	  	 def addzero(val)
		      newval=""
		      if val.to_i <= 9 and not val == "ff"
		        newval="0"+val.to_s
		      else
		        return val
		      end
		    return newval
		end 

	end  
  	# Private: Timecode primitive BinData, set value in Harris BCD value
	# => get BCD value and convert it to String with ":" separator
	#
	#
	# Returns "10:00:01:24"
	#
	class BcdTimecode < BinData::Primitive

	  uint8  :valore_fr, :read_length => 1, :initial_value=>0
	  uint8  :valore_sec, :read_length => 1, :initial_value=>0
	  uint8  :valore_min, :read_length => 1, :initial_value=>0
	  uint8  :valore_hours, :read_length => 1, :initial_value=>0

	  def get
	  	return addzero(valore_hours.to_i.to_s(16)) + ":" + addzero(valore_min.to_i.to_s(16)) + ":" + addzero(valore_sec.to_i.to_s(16)) + ":"+ addzero(valore_fr.to_i.to_s(16))
	  end

	  def set(v)
	  	arr = v.split(":").reverse
	  	self.valore_fr		= arr[0].to_i(16)
	  	self.valore_sec		= arr[1].to_i(16)
	  	self.valore_min		= arr[2].to_i(16)
	  	self.valore_hours	= arr[3].to_i(16)
	  end

	  	 def addzero(val)
		      newval=""
		      if val.to_i <= 9 and not val == "ff"
		        newval="0"+val.to_s
		      else
		        return val
		      end
		    return newval
		end 

	end

  
  class AsrunStruct < BinData::Record
  	empty_chr = 32.chr
	null_chr = 255.chr

  	#0
  	uint8le			:type_, :initial_value=>0
  	#1
  	string			:reconcile_key,:length => 8,  :pad_byte=>null_chr
  	#9
  	BcdDate			:onair_date, :length=>3
  	#12
  	BcdTimecode		:onair_tc, :length=>4
  	#16
  	string			:id, :length => 8,  :pad_byte=>empty_chr
  	#24
  	string			:title, :length => 16,  :pad_byte=>empty_chr
  	#40
  	BcdDate			:real_onair_date, :length=>3
  	#43
  	BcdTimecode		:real_onair_tc, :length=>4  	
  	#47
  	BcdTimecode		:dur, :length=>4
  	#51
  	uint8le			:vtr_number, :initial_value=>0
  	#52
  	uint8le			:bin_number, :initial_value=>0
  	#53
  	uint8le			:channel, :initial_value=>0
  	#54
  	ErrorCode		:error_code, :length=>4, :initial_value=>0
  	#58
  	Bcd				:segment, :length=>1
  	#59
  	string			:reserved, :length=>5
  	#64 bytes
  end
 
 	class AsrunLouth < BinData::Record

		array :rows, :type=> AsrunStruct, read_until: :eof

	end

end
