module Nfe
  module ApiResource
    BASE_URL = 'http://api.nfe.io'
    SSL_BUNDLE_PATH = File.dirname(__FILE__) + '/../data/ssl-bundle.crt'

    def url_encode(key)
      URI.escape(key.to_s, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end

    def encode(params)
      params.map { |k,v| "#{k}=#{url_encode(v)}" }.join('&')
    end

    def api_request(url, method, params=nil)
      url = "#{BASE_URL}#{url}"
      api_key = Nfe.access_keys

      if method == :get && params
        params_encoded = encode(params)
        url = "#{url}?#{params_encoded}"
        params = nil
      end

      begin
        payload = params.to_json
        response = RestClient::Request.new(method: method, url: url, payload: payload,
                                           headers: {authorization: api_key,
                                                        content_type: 'application/json',
                                                        accept: '*/*'}).execute

      rescue RestClient::ExceptionWithResponse => e
        if rcode = e.http_code and rbody = e.http_body
          rbody = JSON.parse(rbody)
          rbody = Util.symbolize_names(rbody)

          raise NfeError.new(rcode, rbody, rbody, rbody[:message])
        else
          raise e
        end
      rescue RestClient::Exception => e
        raise e
      end
      return { } if response.empty?
      JSON.parse(response)
    end

    def self.included(base)
      base.extend(ApiResource)
    end
  end
end