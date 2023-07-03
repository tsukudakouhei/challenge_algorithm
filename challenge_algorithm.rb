require 'net/http'
require 'uri'
require 'json'
require 'logger'

logger = Logger.new(STDOUT)
logger.level = Logger::INFO

url = 'http://challenge.z2o.cloud/challenges'
nickname = 'tsukuda'

post_uri = URI.parse("#{url}?nickname=#{nickname}")
http = Net::HTTP.new(post_uri.host, post_uri.port)

post_request = Net::HTTP::Post.new(post_uri)
post_response = http.request(post_request)

post_response_body = JSON.parse(post_response.body)
change_id = post_response_body['id']
next_request_time_unix_ms = post_response_body['actives_at']

buffer_time_seconds = 0.131

loop do
  sleep_time = [(next_request_time_unix_ms - Time.now.to_f * 1000) / 1000.0 - buffer_time_seconds, 0].max
  sleep(sleep_time)

  request_start_time = Time.now.to_f * 1000
  
  put_uri = URI(url)
  put_request = Net::HTTP::Put.new(put_uri)
  put_request['X-Challenge-Id'] = change_id
  
  put_response = http.request(put_request)
  put_response_body = JSON.parse(put_response.body)

  request_time = Time.now
  logger.info("Request time: #{request_time}::#{put_response_body}")

  if put_response_body['result']
    puts put_response_body['result']
    break
  else
    next_request_time_unix_ms = put_response_body['actives_at']
    response_delay = put_response_body['called_at'] - request_start_time
    buffer_time_seconds = response_delay / 1000.0 + 0.01
  end
end
