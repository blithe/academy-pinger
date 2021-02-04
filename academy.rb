require 'json'
require 'uri'
require 'net/http'
require 'rest-client'
require 'socket'

def email_body
	radius = 500

	uri = URI("https://www.academy.com/api/stores?lat=27.8005828&lon=-97.39638099999999&rad=#{radius}&bopisEnabledFlag=true&storeDetailsID=store-0197&skus=8056450:1")
	response = Net::HTTP.get(uri)
	info = JSON.parse(response)

	stores = info['stores']

	output = "Found #{stores.count} stores"

	ip = IPSocket.getaddress(Socket.gethostname)
	output << "\nIP: #{ip}"

	stores.each do |store|
		properties = store['properties']
		city = properties['city']
		state = properties['state']
		address = properties['streetAddress']
		distance = properties['distance']

		inventory = store['inventory']
		skus = inventory['skus']
		next if skus.nil?

		status = skus.first['inventoryStatus']
		next if status == 'OUT_OF_STOCK'

		output << ("\nStore: (#{address} #{city}, #{state}) Distance: #{distance} miles")
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
puts email_body

send_email(email_body)
puts 'done'
