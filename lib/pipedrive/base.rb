require 'httparty'
require 'ostruct'
require 'forwardable'

module Pipedrive

  # Globally set request headers
  HEADERS = {
    "User-Agent" => "Ruby.Pipedrive.Api",
    "Accept" => "application/json",
    "Content-Type" => "application/x-www-form-urlencoded"
  }

  # Base class for setting HTTParty configurations globally
  class Base < OpenStruct

    include HTTParty

    base_uri 'https://api.pipedrive.com/v1'
    headers HEADERS
    format :json

    extend Forwardable
    def_delegators 'self.class', :delete, :get, :post, :put, :resource_path, :bad_response

    attr_reader :data

    # Create a new Pipedrive::Base object.
    #
    # Only used internally
    # @param [Hash] attributes
    # @return [Pipedrive::Base]
    def initialize(attrs = {})
      if attrs['data']
        struct_attrs = attrs['data']

        if attrs['additional_data']
          struct_attrs.merge!(attrs['additional_data'])
        end
      else
        struct_attrs = attrs
      end

      super(struct_attrs)
    end

    # Updates the object.
    #
    # @param [Hash] opts
    def update(opts = {})
      res = put "#{resource_path}/#{id}", body: opts
      if res.success?
        res['data'] = Hash[res['data'].map { |k, v| [k.to_sym, v] }]
        OpenStruct.new(@table.merge!(res['data']))
      else
        false
      end
    end

    ##
    # Deletes the object
    # @param [Hash] opts
    # @return [Object]
    def destroy(opts = {})
      res = delete "#{resource_path}/#{id}"
      res.ok? ? res : bad_response(res, opts)
    end

    class << self
      # Sets the authentication credentials in a class variable.
      #
      # @return [Hash] authentication credentials
      def authenticate(token)
        default_params api_token: token
      end

      # Examines a bad response and raises an appropriate exception
      #
      # @param [HTTParty::Response] response
      def bad_response(response, _params = {})
        if response.class == HTTParty::Response
          raise HTTParty::ResponseError, response
        end

        raise StandardError, 'Unknown error'
      end

      def new_list(attrs)
        if attrs['data'].is_a?(Array)
          attrs['data'].map { |data| new('data' => data) }
        elsif attrs['data'].is_a?(Hash) && attrs['data']['items'].any?
          attrs['data']['items'].map { |data| new('data' => data['item']) }
        else
          []
        end
      end

      def all(response = nil, options = {})
        res = response || get(resource_path, query: options)
        if res.ok?
          new_list(res)
        else
          bad_response(res, options)
        end
      end

      def create(opts = {})
        res = post resource_path, body: opts
        if res.success?
          res['data'] = opts.merge res['data']
          new(res)
        else
          bad_response(res, opts)
        end
      end

      def find(id)
        res = get "#{resource_path}/#{id}"
        res.ok? ? new(res) : bad_response(res, id)
      end

      def find_by(*args)
        return unless args.is_a?(Array)

        arguments = args.first
        field = arguments&.keys&.first
        value = arguments&.values&.first
        additional_args = arguments&.reject { |key, _| key.eql?(field) }
        puts "arguments: #{args.first} field: #{field}, value: #{value}, additional_args: #{additional_args}"
        res = get "#{resource_path}/search", query: { term: value, fields: field, exact_match: true, **additional_args }

        new_list(res).first if res.ok?
      end

      def find_by_name(name, opts = {})
        klass = self.name.split('::').last
        case klass
        when 'Pipeline'
          self.name.constantize.all.find { |i| i.name == name }
        else
          res = get "#{resource_path}/find", query: { term: name }.merge(opts)
          if res.ok?
            list_items = new_list(res)
            return list_items if list_items.count <= 1

            # If fuzzy match generates more than one result, search by exact result.
            list_items.filter { |item| item.name == name }
          else
            bad_response(res, { name: name }.merge(opts))
          end
        end
      end

      def resource_path
        # The resource path should match the camelCased class name with the
        # first letter downcased.  Pipedrive API is sensitive to capitalisation
        klass = name.split('::').last
        klass[0] = klass[0].chr.downcase
        klass.end_with?('y') ? "/#{klass.chop}ies" : "/#{klass}s"
      end
    end
  end

end
