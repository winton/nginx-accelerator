require 'json'

$:.unshift File.dirname(__FILE__)

class Accelerator

  def initialize(host_and_port)
    @memc = Memcached.new(host_and_port)
  end

  def expire(uri)
    data = get_and_set_time(uri)
    @memc.set(uri, data.to_json)
  end

  def get(uri)
    data = get_and_parse(uri)
    [ data.delete(:body), data ]
  end

  def set(uri, body)
    data = get_and_set_time(uri)
    data[:body] = body
    @memc.set(uri, data.to_json)
  end

  private

  def get_and_parse(uri)
    JSON.parse(@memc.get(uri), :symbolize_names => true)
  end

  def get_and_set_time(uri)
    data = get_and_parse(uri)
    data[:time] = Time.now.to_i
    data
  end
end