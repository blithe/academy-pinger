require 'json'
require 'uri'
require 'net/http'
require 'rest-client'
require 'socket'
require 'geocoder'

def ip_address
	ip = IPSocket.getaddress(Socket.gethostname)
	"IP: #{ip}"
end

def heb_results
	uri = URI("https://heb-ecom-covid-vaccine.hebdigital-prd.com/vaccine_locations.json")
	response = Net::HTTP.get(uri)
	info = JSON.parse(response)

	stores = info.dig('locations')
	output = "Found #{stores.count} HEB stores"

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

def cvs_results
	uri = URI("https://www.cvs.com/immunizations/covid-19-vaccine.vaccine-status.TX.json?vaccineinfo")

	response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
		request = Net::HTTP::Get.new uri
		request['Referer'] = 'https://www.cvs.com/immunizations/covid-19-vaccine?icid=cvs-home-hero1-banner-1-link2-coronavirus-vaccine'

		http.request request # Net::HTTPResponse object
	end

	info = JSON.parse(response.body)
	stores = info.dig('responsePayloadData', 'data', 'TX')

	output = "Found #{stores.count} CVS stores"

	stores.each do |store|
		status = store['status']
		next if status == 'Fully Booked'

		city = store['city']

		output << ("\n#{city} has availability")
	end

	output
end

def walgreens_results
	uri = URI("https://www.walgreens.com/hcschedulersvc/svc/v1/immunizationLocations/availability")

	response = Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
		request = Net::HTTP::Post.new uri
		request["Content-Type"] = 'application/json'

		data = {position: {latitude:30.5119, longitude:-97.8178},
				appointmentAvailability: {startDateTime: Time.now.strftime("%Y-%m-%d")}}
		request.body = data.to_json

		http.request request # Net::HTTPResponse object
	end

	info = JSON.parse(response.body)
	status = info.dig('appointmentsAvailable')

	"Walgreens availabile? #{status}"
end

def email_body
	[ip_address, heb_results, cvs_results, walgreens_results].join("\n\n")
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
puts ip_address
puts heb_results
puts cvs_results
puts walgreens_results

send_email(email_body)
puts 'done'
