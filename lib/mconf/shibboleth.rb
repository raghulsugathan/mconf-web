# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

module Mconf
  class Shibboleth

    # the root key used to store all the information in the session
    ENV_KEY = :shib_data

    # `session` is the session object where the user information will be stored
    def initialize(session)
      @session = session
    end

    # Saves the information in the environment variables `env_variables` to the
    # session. Uses `filters` to know which variables should be stored and which
    # should be ignored.
    # `filters` is a string with one or more filters separated by '\n' or '\r\n'.
    # The filters can be a simple string or a string in the format of a regex.
    # e.g. `email\nshib-.*\r\nuid`: will get the variables that match /^email$/,
    #   /^shib-.*$/, and /^uid$/
    # If `filters` is blank, will use the default filter /^shib-/
    def save_to_session(env_variables, filters='')
      unless filters.blank?
        vars = filters.clone
        vars = vars.split(/\r?\n/).map{ |s| s.strip.downcase }
        filter = vars.map{ |v| /^#{v}$/  }
      else
        filter = [/^shib-/]
      end

      shib_data = {}
      env_variables.each do |key, value|
        unless filter.select{ |f| key.to_s.downcase =~ f }.empty?
          shib_data[key.to_s] = value
        end
      end
      @session[ENV_KEY] = shib_data
      shib_data
    end

    # Returns whether the basic information needed for a user to login is present
    # in the session or not.
    def has_basic_info
      @session[ENV_KEY] && get_email() && get_name()
    end

    # Returns the email stored in the session, if any.
    def get_email
      result = nil
      if @session.has_key?(ENV_KEY)
        result   = @session[ENV_KEY][Site.current.shib_email_field]
        result ||= @session[ENV_KEY]["Shib-inetOrgPerson-mail"]
        result = result.clone unless result.nil?
      end
      result
    end

    # Returns the name of the user stored in the session, if any.
    def get_name
      result = nil
      if @session.has_key?(ENV_KEY)
        result   = @session[ENV_KEY][Site.current.shib_name_field]
        result ||= @session[ENV_KEY]["Shib-inetOrgPerson-cn"]
        result = result.clone unless result.nil?
      end
      result
    end

    # Returns the login of the user stored in the session, if any.
    def get_login
      result = nil
      if @session.has_key?(ENV_KEY)
        result   = @session[ENV_KEY][Site.current.shib_login_field]
        result ||= get_name # uses the name by default
        result = result.clone unless result.nil?
      end
      result
    end

    # Returns the shibboleth provider of the user stored in the session, if any.
    def get_identity_provider
      result = nil
      if @session.has_key?(ENV_KEY)
        # TODO: is this really the key normally used for the identity provider
        result = @session[ENV_KEY]['Shib-Identity-Provider']
        result = result.clone unless result.nil?
      end
      result
    end

    # Returns all the shibboleth data stored in the session.
    def get_data
      @session[ENV_KEY]
    end

    # Returns whether the user is signed in via federation or not.
    def signed_in?
      !@session.nil? && @session.has_key?(ENV_KEY)
    end

    # Returns the name of the attributes used to get the basic user information from the
    # session. Returns and array with [ <attribute for email>, <attribute for name> ]
    def basic_info_fields
      [ Site.current.shib_email_field || "Shib-inetOrgPerson-mail",
        Site.current.shib_name_field || "Shib-inetOrgPerson-cn" ]
    end

    # Finds the ShibToken associated with the user whose information is stored in the session.
    def find_token
      ShibToken.find_by_identifier(get_email())
    end

    # Searches for a ShibToken using data in the session and returns it. Creates a new
    # ShibToken if no token is found and returns it.
    def find_or_create_token
      token = find_token()
      token = create_token(get_email()) if token.nil?
      token
    end

    # Creates a new user using the information stored in the session. Will only create
    # the user if there's no user already registered with the target email.
    # Returns nil if there's already a user with the target email or the User created
    # otherwise. The User returned might have errors if the call to `save` failed.
    # Expects that at least the email and email will be set in the session!
    def create_user
      password = SecureRandom.hex(16)
      login = get_login
      login = login.parameterize unless login.nil?
      params = {
        :username => login, :email => get_email,
        :password => password, :password_confirmation => password,
        :_full_name => get_name
      }

      unless User.find_by_email(params[:email])
        # TODO: if the user is disabled he won't be found and the create below will fail
        user = User.new(params)
        user.skip_confirmation!
        user.save
        user
      else
        nil
      end
    end

    private

    def create_token(id)
      ShibToken.create!(:identifier => id)
    end

  end
end
