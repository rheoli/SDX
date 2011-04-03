#!/usr/bin/env ruby

require 'goliath'

class SDXUpload < Goliath::API

  # reload code on every request in dev environment
  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params             # parse & merge query and body parameters
  use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  use Goliath::Rack::Formatters::JSON   # JSON output formatter
  use Goliath::Rack::Render             # auto-negotiate response format

  def on_headers(env, headers)
    env.logger.info 'received headers: ' + headers.inspect
    env['async-headers'] = headers
    env['async-size'] = 0
  end

  def on_body(env, data)
    env['async-size']+=data.size if !data.nil?
    begin
      env.logger.info "received data size: #{((env['async-size']/env['async-headers']['Content-Length'].to_f)*100).to_i}"
    rescue Exception=>e
      env.logger.info e
    end
    (env['async-body'] ||= '') << data
  end

  def on_close(env)
    env.logger.info 'closing connection'
  end

  def response(env)
    [200, {}, {body: env['async-body'].size, head: env['async-headers']}]
  end
end
