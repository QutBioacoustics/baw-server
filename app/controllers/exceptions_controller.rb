# http://geekmonkey.org/articles/29-exception-applications-in-rails-3-2
# for json responses to exceptions
# not used currently - need to add config.exceptions_app into application.rb
# only used when config.consider_all_requests_local is false
# https://github.com/s-andringa/recipes_exceptions_example/blob/b28b42f2b96c808bde93badbb05aff0bdc2c7fe9/app/controllers/exception_controller.rb
class ExceptionsController < ActionController::Base
  layout 'application'

  # userstamp
  include Userstamp

  # called with env as a parameter
  def show
    @exception = env['action_dispatch.exception']
    @status_code = ActionDispatch::ExceptionWrapper.new(env, @exception).status_code
    @rescue_response = ActionDispatch::ExceptionWrapper.rescue_responses[@exception.class.name]

=begin
    public_path = Rails.public_path
    status = env['PATH_INFO'][1..-1]
    locale_path = "#{public_path}/#{status}.#{I18n.locale}.html" if I18n.locale
    path = "#{public_path}/#{status}.html"

    if !locale_path.blank? && File.exist?(locale_path)
      #render_default(status, File.read(locale_path))
    elsif File.exist?(path)
      #render_default(status, File.read(path))
    else
      #[404, { "X-Cascade" => "pass" }, []]
    end
=end

    respond_to do |format|
      format.html { render :show, status: @status_code, layout: !request.xhr? }
      format.json { render json: details, status: @status_code }
    end

    User.reset_stamper if User.stamper
  end

  protected

  def details
    @details ||= {}.tap do |h|
      I18n.with_options scope: [:exception, :show, @rescue_response], exception_name: @exception.class.name, exception_message: @exception.message do |i18n|
        h[:code] = @status_code
        h[:phrase] = Rack::Utils::HTTP_STATUS_CODES[@status_code]
        h[:name] = i18n.t "#{@exception.class.name.underscore}.title", default: i18n.t(:title, default: @exception.class.name)
        h[:message] = i18n.t "#{@exception.class.name.underscore}.description", default: i18n.t(:description, default: @exception.message)
      end
    end
  end

  helper_method :details

  # def render_default(status, body)
  #   [status, {'Content-Type' => "text/html; charset=#{Response.default_charset}", 'Content-Length' => body.bytesize.to_s}, [body]]
  # end

end