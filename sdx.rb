#!/usr/bin/env ruby

SDX_ROOT = "#{File.dirname(__FILE__)}" unless defined?(SDX_ROOT)

$: << SDX_ROOT+"/lib"

require 'openssl'
require 'digest/sha1'
require 'goliath'

class SdxSender 
  def initialize(fn) 
    @fn = fn 
  end
  
  def each
    c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
    c.decrypt
    c.key = Digest::SHA1.hexdigest("test")
    File.open(@fn,"rb") do |f| 
      while blk = f.read(65536)
        blk=c.update(blk) unless blk.nil? or blk==""
        yield blk 
      end
    end
    blk=c.final
    yield blk
  end 
end

class SdxUpload < Goliath::API

  # reload code on every request in dev environment
  use ::Rack::Reloader, 0 if Goliath.dev?

  use Goliath::Rack::Params             # parse & merge query and body parameters
  #use Goliath::Rack::DefaultMimeType    # cleanup accepted media types
  #use Goliath::Rack::Render             # auto-negotiate response format

  def on_headers(env, headers)
    begin
      env['sdx-method']="noop"
      env['sdx-method']="download" if env['REQUEST_METHOD']=="GET" and env['REQUEST_PATH']=="/download"
      if env['REQUEST_METHOD']=="POST" and env['REQUEST_PATH']=="/upload"
        env['sdx-method']="upload"
        env['sdx-file']=File.open("#{SDX_ROOT}/data/test.dat", "w")
        c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
        c.encrypt
        c.key = Digest::SHA1.hexdigest("test")
        #c.iv = c.random_iv
        env['sdx-crypt']=c
      end
      env.logger.info 'method: ' + env['sdx-method']
      #env.logger.info 'received headers: ' + headers.inspect
      env['sdx-size-total'] = headers["Content-Length"]
      env['sdx-size-now'] = 0
    rescue Exception=>e
      env['sdx-method']="exception"
      env['sdx-exception']=e
      env.logger.info e
    end
  end

  def on_body(env, data)
    begin
      if env['sdx-method']=="upload"
        env['sdx-size-now']+=data.size if !data.nil?
        env['sdx-file'].write(env['sdx-crypt'].update(data))
        begin
          #env.logger.info "received data size: #{((env['sdx-size-now']/env['sdx-size-total'].to_f)*100).to_i}"
        rescue Exception=>e
          env.logger.info e
        end
        return
      end
    rescue Exception=>e
      env['sdx-method']="exception"
      env['sdx-exception']=e
      env.logger.info e
    end
  end

  def on_close(env)
    env.logger.info 'closing connection'
  end

  def response(env)
    begin
      http_ret=404
      http_msg="Not found"
      if env['sdx-method']=="download"
        http_ret=200
        http_msg=SdxSender.new("#{SDX_ROOT}/data/test.dat")
      end
      if env['sdx-method']=="upload"
        env['sdx-file'].write(env['sdx-crypt'].final)
        env['sdx-file'].close
        http_ret=200
        http_msg="Upload"
      end
      if env['sdx-method']=="exception"
        http_ret=500
        http_msg="Server Error: #{env['sdx-exception']}"
      end
      [http_ret, {}, http_msg]
    rescue Exception=>e
      env.logger.info e
      [500, {}, "Server Error: #{e}"]
    end
  end
end

#=EOF