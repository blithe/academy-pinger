require 'json'
require 'uri'
require 'net/http'
require 'rest-client'
require 'socket'
require 'geocoder'

def heb_results
	radius = 500

	uri = URI("https://heb-ecom-covid-vaccine.hebdigital-prd.com/vaccine_locations.json")
	response = Net::HTTP.get(uri)
	info = JSON.parse(response)


	stores = info.dig('locations')


	output = "Found #{stores.count} stores"

	ip = IPSocket.getaddress(Socket.gethostname)
	output << "\nIP: #{ip}"

	stores.each do |store|


		city = store['city']
		state = store['state']
		address = store['street']
		latitude = store['latitude']
		longitude = store['longitude']
		timeslots = store['openTimeslots']
		next if timeslots == 0

		if latitude && longitude
			distance = Geocoder::Calculations.distance_between("cedar park, TX", [latitude, longitude])		
			output << ("\nStore: (#{address} #{city}, #{state}) Distance: #{distance} miles")
		else 
			output << ("\nStore: #{address} #{city}, #{state}")
		end
	end

	output
end

def send_email(content)

	api_key = ENV['MAILGUN_API_KEY']
	domain = ENV['MAILGUN_DOMAIN']
	api_url = "https://api:#{api_key}@api.mailgun.net/v2/#{domain}"

	RestClient.post api_url+"/messages",
	    :from => "blitherocher+heroku@gmail.com",
	    :to => "blitherocher@gmail.com",
	    :subject => "Stock update",
	    :text => content
end

puts 'starting'
puts heb_results

send_email(heb_results)
puts 'done'