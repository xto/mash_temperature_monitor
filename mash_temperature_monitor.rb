require 'sinatra'
require 'json'
require 'serialport'
require 'yaml'
#params for serial port


class RequestLogger < Sinatra::Base
  get '/temperatures' do
    headers 'Access-Control-Allow-Origin' => '*'
    content_type :json

    {temperatures: [
      {
        "temperature" => read_from_serial.to_f,
        "readAt" => Time.now.to_s,
        "unit" => "C"
      }
    ]}.to_json
  end

  post '/temperatures' do
    headers 'Access-Control-Allow-Origin' => '*'
    content_type :json
    mash_name = params['mash_name']
    temperatures = JSON.parse(params['temperatures'])

    temperatures = temperatures.map do |temp_string|
      JSON.parse(temp_string)
    end

    File.open("mashes/#{mash_name}.json","w+") do |file|
      file.write({mash_name => temperatures}.to_json)
    end

    {status: 201, body: "Created"}.to_json
  end

  get '/mashes/:mash_name' do
    headers 'Access-Control-Allow-Origin' => '*'
    content_type :json

    return {status: 404, body: "Not Found"}.to_json unless File.exist?("mashes/#{params[:mash_name]}.json")

    {"temperatures" => JSON.parse(File.open("mashes/#{params[:mash_name]}.json").read)[params[:mash_name]]}.to_json
  end

  def read_from_serial
    port_str = "/dev/cu.usbmodem1411"
    baud_rate = 9600
    data_bits = 8
    stop_bits = 1
    parity = SerialPort::NONE

    serial_port_reading = ""
    serial_port = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)
    serial_port.read_timeout=300
    serial_port. << "X"
    sleep(0.5)
    serial_port_reading = serial_port.readline("\r\n")
    serial_port.close
    return serial_port_reading
  end
end
