module Api
  module ControllerHelper
    extend ActiveSupport::Concern

    # based on https://codelation.com/blog/rails-restful-api-just-add-water
    private

    # The singular name for the resource class based on the controller
    # @return [String]
    def resource_name
      @resource_name ||= self.controller_name.singularize
    end

    # The plural name for the resource class based on the controller
    # @return [String]
    def resource_name_plural
      @resource_name_plural ||= resource_name.pluralize
    end

    # Returns the resource from the created instance variable
    # @return [Object]
    def get_resource
      instance_variable_get("@#{resource_name}")
    end

    # Sets the resource instance variable to the given value
    # @param [Object] value
    # @return [void]
    def set_resource(value)
      instance_variable_set("@#{resource_name}", value)
    end

    # Returns the resource from the created instance variable
    # @return [Object]
    def get_resource_plural
      instance_variable_get("@#{resource_name_plural}")
    end

    # Sets the resource instance plural variable to the given value
    # @param [Object] value
    # @return [void]
    def set_resource_plural(value)
      instance_variable_set("@#{resource_name_plural}", value)
    end

    # The resource class based on the controller
    # @return [Class]
    def resource_class
      @resource_class ||= resource_name.classify.constantize
    end

    # Set a <user>_id to the current_user's id
    # @param [String, Symbol] attribute_name
    # @return [void]
    def set_user_id(attribute_name)
      responds = get_resource.respond_to?("#{attribute_name}=".to_sym)
      is_blank = responds ? get_resource.send("#{attribute_name}".to_sym).blank? : false
      current_user_valid = !current_user.blank?
      if responds && is_blank && current_user_valid
        get_resource.send("#{attribute_name}=".to_sym, current_user.id)
      end
    end

    def respond_index(opts = {})
      items = get_resource_plural.map { |item|
        Settings.api_response.prepare(item, current_user, opts)
      }
      built_response = Settings.api_response.build(:ok, items, opts)
      render json: built_response, status: :ok, layout: false
    end

    # also used for update_success and new
    def respond_show
      item_resource = get_resource

      item = Settings.api_response.prepare(item_resource, current_user)

      built_response = Settings.api_response.build(:ok, item)
      render json: built_response, status: :ok, layout: false
    end

    def respond_create_success(location = nil)
      item_resource = get_resource

      item = Settings.api_response.prepare(item_resource, current_user)

      built_response = Settings.api_response.build(:created, item)
      render json: built_response, status: :created, location: location.blank? ? item_resource : location, layout: false
    end

    # used for create fail and update fail
    def respond_change_fail
      built_response = Settings.api_response.build(
          :unprocessable_entity,
          nil,
          {
              error_details: 'Record could not be saved',
              error_info: get_resource.errors
          })
      render json: built_response, status: :unprocessable_entity, layout: false
    end

    def respond_destroy
      built_response = Settings.api_response.build(:no_content, nil)
      render json: built_response, status: :no_content, layout: false
    end

    def respond_error(status_symbol, message, opts = {})
      render_error(
          status_symbol,
          message,
          nil,
          'respond_error',
          opts)
    end

    def respond_filter(content, opts = {})

      items = content.map { |item|
        Settings.api_response.prepare(item, current_user, opts)
      }

      built_response = Settings.api_response.build(:ok, items, opts)
      render json: built_response, status: :ok, content_type: 'application/json', layout: false
    end

    # def attributes_and_authorize(custom_params = nil)
    #   # need to do what cancan would otherwise do due to before_action creating instance variable, so cancan
    #   # assumes already authorized
    #
    #   do_authorize!
    # end

    # def do_authorize!
    #   authorize! action_name.to_sym, (get_resource || resource_class)
    # end

    def api_filter_params
      # for filter api, all validation is done in modules rather than in strong parameters.
      params.permit!
    end

    # Replacement methods for CanCanCan authorize_resource, load_resource, load_and_authorize_resource.

    def do_set_attributes(custom_params = nil)
      # see https://github.com/CanCanCommunity/cancancan/wiki/Controller-Authorization-Example
      current_ability.attributes_for(action_name.to_sym, resource_class).each do |key, value|
        get_resource.send("#{key}=", value)
      end
      capture_params = custom_params.nil? ? params[resource_name.to_sym] : custom_params
      get_resource.attributes = capture_params if !capture_params.blank? && capture_params.is_a?(Hash)
    end

    def do_new_resource
      set_resource(resource_class.new)
    end

    def do_load_resource
      set_resource(resource_class.find(params[:id]))
    end

    def do_load_resources
      set_resource_plural(resource_class.accessible_by(current_ability))
    end

    def do_authorize_instance(custom_action_name = nil, custom_resource = nil)
      authorize! (custom_action_name ||action_name).to_sym, (custom_resource || get_resource)
    end

    def do_authorize_class(custom_action_name = nil, custom_class = nil)
      authorize! (custom_action_name || action_name).to_sym, (custom_class || resource_class)
    end

    def do_authorise_instance_or_class
      authorize! action_name.to_sym, (get_resource || resource_class)
    end


  end
end
