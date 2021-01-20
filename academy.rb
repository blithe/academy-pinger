require 'json'
require 'uri'
require 'net/http'
require 'sendgrid-ruby'
include SendGrid


def run
	puts 'starting'

	radius = 2500

	uri = URI("https://www.academy.com/api/stores?lat=27.8005828&lon=-97.39638099999999&rad=#{radius}&bopisEnabledFlag=true&storeDetailsID=store-0197&skus=8056450:1")
	response = Net::HTTP.get(uri)
	info = JSON.parse(response)

	stores = info['stores']

	puts "Found #{stores.count} stores"

	stores.each do |store|
		properties = store['properties']
		city = properties['city']
		state = properties['state']
		address = properties['streetAddress']

		inventory = store['inventory']
		status = inventory['skus'].first['inventoryStatus']

		next if status == 'OUT_OF_STOCK'
			
		puts "Store: (#{address} #{city}, #{state}) Status: #{status}"
			
	end


	puts 'done'
end

def send_email(content)

	from = Email.new(email: 'test@example.com')
	subject = 'Hello World from the SendGrid Ruby Library!'
	to = Email.new(email: 'blitherocher@gmail.com')
	content = Content.new(type: 'text/plain', value: content)
	mail = Mail.new(from, subject, to, content)

	sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
	response = sg.client.mail._('send').post(request_body: mail.to_json)
	puts response.status_code
	puts response.body
	puts response.headers
end

send_email(run)
