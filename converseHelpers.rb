require 'sinatra/base'

module Sinatra
    module ConverseHelpers
        def user_not_found(msg='The specified user does not exist')
            not_found msg end
        def user_db_error(msg='Error retrieving user from database')
            error 500, msg end
        def board_db_error(msg='Error retrieving board from database')
            error 500, msg end
        def board_not_found(msg='The specified board does not exist')
            not_found msg end
        def loggedin?() session[:loggedin] end
        def username?(u) session[:username]==u end

        def yes_or_true?(v) 
            not v.nil? and ((v.casecmp 'yes')==0 or (v.casecmp 'true')==0) 
        end

        def request_headers
            env.inject({}) do
                |acc, (k,v)| acc[$1.downcase] = v if k =~ /^http_(.*)/i; acc
            end
        end

        def must_be_loggedin()
            if not loggedin? then error 403, 'You are not logged in' end
        end

        def json_req_error(err, params={})
            err_hash = {:error => err}
            err_hash.merge! params
            content_type :json
            halt [400, err_hash.to_json]
        end

        def must_have_waited(atleast, secs)
            if secs < 20 then
                json_req_error :slow_down, :wait_atleast => 20
            end
        end

        class ParameterCheck

            attr_accessor :params, :missing_params, :badsized_params

            def missing_param(p) missing_params.push p end
            def missing_params?() not missing_params.empty? end
            def badsized_param(p) badsized_params.push p end
            def badsized_params?() not badsized_params.empty? end

            def initialize(params, &block)

                self.params = params
                self.missing_params = []
                self.badsized_params = []

                instance_eval &block
            end

            def required_parameter(param, options={})
                val = params[param]
                if val.nil? or val.empty? or val =~ /\A\s+\z/ then
                    missing_param param
                end
                min_len = options[:min_len]
                if min_len and val.strip.length < min_len then
                    badsized_param :param => param, :min_len => min_len
                end
                max_len = options[:max_len]
                if max_len and val.strip.length > max_len then
                    badsized_param :param => param, :max_len => max_len
                end
            end
        end

        def check_parameters(&block)
            check = ParameterCheck.new params, &block
            if check.missing_params? then
                json_req_error :missing_params, 
                    :params => check.missing_params
            end
            if check.badsized_params? then
                json_req_error :badsized_params, 
                    :params => check.badsized_params
            end
        end

    end

    helpers ConverseHelpers
end
