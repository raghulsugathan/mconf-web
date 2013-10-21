# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require "spec_helper"

describe ShibbolethController do

  shared_examples_for "has the before_filter :check_shib_enabled" do
    context "redirects to /login if shibboleth is disabled" do
      before { Site.current.update_attributes(:shib_enabled => false) }
      before(:each) { run_route }
      it { should redirect_to(login_path) }
    end
  end

  shared_examples_for "has the before_filter :check_current_user" do
    context "redirects to the user's home if there's already a user logged" do
      let(:user) { FactoryGirl.create(:user) }
      before { Site.current.update_attributes(:shib_enabled => true) }
      before(:each) {
        login_as(user)
        run_route
      }
      it { should redirect_to(my_home_path) }
    end
  end

  describe "#login" do

    context "before filters" do
      let(:run_route) { get :login }
      it_should_behave_like "has the before_filter :check_shib_enabled"
      it_should_behave_like "has the before_filter :check_current_user"
    end

    # to make sure we're not forgetting a call to #test_data (happened before)
    it "doesn't call #test_data" do
      Site.current.update_attributes(:shib_enabled => true)
      controller.should_not_receive(:test_data)
      get :login
      request.env.each { |key, value| key.should_not match(/shib-/i) }
    end

    context "renders an error page if there's not enough information on the session" do
      before {
        Site.current.update_attributes(:shib_name_field => 'name', :shib_email_field => 'email')
        Site.current.update_attributes(:shib_enabled => true)
        request.env['Shib-Any'] = 'any'
      }
      before(:each) { get :login }
      it { should render_template('attribute_error') }
      it { should render_with_layout('no_sidebar') }
      it { should assign_to(:attrs_required).with(['email', 'name']) }
      it { should assign_to(:attrs_informed).with({ 'Shib-Any' => 'any' }) }
    end

    context "if the user's information is ok" do
      let(:user) { FactoryGirl.create(:user) }
      before { setup_shib(user.full_name, user.email, false) }

      context "logs the user in if he already has a token" do
        before { ShibToken.create!(:identifier => user.email, :user => user) }
        before(:each) {
          request.flash[:success] = 'message set previously by #create_association'
          should set_the_flash.to('message set previously by #create_association')
          get :login
        }
        it { subject.current_user.should eq(user) }
        it { should redirect_to(my_home_path) }
        pending("persists the flash messages") {
          # TODO: The flash is being set and flash.keep is called, but this test doesn't work.
          #  Testing in the application the flash is persisted, as it should.
          should set_the_flash.to('message set previously by #create_association')
        }
      end

      context "renders the association page if the user doesn't have a token yet" do
        before(:each) { get :login }
        it { should render_template('associate') }
        it { should render_with_layout('no_sidebar') }
      end

    end
  end

  describe "#create_association" do

    context "before filters" do
      let(:run_route) { post :create_association }
      it_should_behave_like "has the before_filter :check_shib_enabled"
      it_should_behave_like "has the before_filter :check_current_user"
    end

    context "if params has no known option, redirects to /secure with a warning" do
      let(:user) { FactoryGirl.create(:user) }
      before { setup_shib(user.full_name, user.email, false) }
      before(:each) { post :create_association }
      it { should redirect_to(shibboleth_path) }
      it { should set_the_flash.to(I18n.t('shibboleth.create_association.invalid_parameters')) }
    end

    context "if params[:new_account] is set" do
      let(:attrs) { FactoryGirl.attributes_for(:user) }
      before { setup_shib(attrs[:_full_name], attrs[:email]) }

      context "redirects to /secure if the user already has a valid token" do
        let(:user) { FactoryGirl.create(:user) }
        before { ShibToken.create!(:identifier => user.email, :user => user) }
        before(:each) { post :create_association, :new_account => true }
        it { should redirect_to(shibboleth_path) }
      end

      context "if there's no valid token yet" do

        context "creates a new token with the correct information and goes back to /secure" do
          before(:each) {
            expect {
              post :create_association, :new_account => true
            }.to change{ ShibToken.count }.by(1)
          }
          subject { ShibToken.last }
          it { subject.identifier.should eq(attrs[:email]) }
          it { subject.user.should_not be_nil } # just in case the find_by_email below fails
          it { subject.user.should eq(User.find_by_email(attrs[:email])) }
          it {
            expected = {}
            expected["Shib-inetOrgPerson-cn"] = attrs[:_full_name]
            expected["Shib-inetOrgPerson-mail"] = attrs[:email]
            subject.data.should eq(expected.to_yaml) # it's a Hash in the db, so compare using to_yaml
          }
          it { controller.should redirect_to(shibboleth_path) }
          it { controller.should set_the_flash.to(I18n.t('shibboleth.create_association.account_created', :url => new_user_password_path)) }
        end

        context "if fails to create the new user, goes to /secure with an error message" do
          before {
            @user = FactoryGirl.build(:user)
            @user.errors.add(:name, "can't be blank") # any fake error
            Mconf::Shibboleth.any_instance.should_receive(:create_user).and_return(@user)
          }
          before(:each) {
            expect {
              post :create_association, :new_account => true
            }.not_to change{ ShibToken.count }
          }
          it { controller.should redirect_to(shibboleth_path) }
          it { controller.should set_the_flash.to(I18n.t('shibboleth.create_association.error_saving_user', :errors => @user.errors.full_messages.join(', '))) }
        end

        context "if there's already a user with the target email, goes to /secure with an error message" do
          before { FactoryGirl.create(:user, :email => attrs[:email]) }
          before(:each) {
            expect {
              post :create_association, :new_account => true
            }.not_to change{ ShibToken.count }
          }
          it { controller.should redirect_to(shibboleth_path) }
          it { controller.should set_the_flash.to(I18n.t('shibboleth.create_association.existent_account', :email => attrs[:email])) }
        end
      end
    end

    context "if params[:existent_account] is set" do
      let(:attrs) { FactoryGirl.attributes_for(:user) }
      before { setup_shib(attrs[:_full_name], attrs[:email]) }

      context "if there's no user info in the params, goes back to /secure with an error" do
        before(:each) { post :create_association, :existent_account => true }
        it { should redirect_to(shibboleth_path) }
        it { should set_the_flash.to(I18n.t('shibboleth.create_association.invalid_credentials')) }
      end

      context "if the user info in the params is wrong, goes back to /secure with an error" do
        before(:each) { post :create_association, :existent_account => true, :user => { :so_wrong => 2  } }
        it { should redirect_to(shibboleth_path) }
        it { should set_the_flash.to(I18n.t('shibboleth.create_association.invalid_credentials')) }
      end

      context "if the target user is not found goes back to /secure with an error" do
        before(:each) { post :create_association, :existent_account => true, :user => { :login => 'any' } }
        it { User.find_first_by_auth_conditions({ :login => 'any' }).should be_nil}
        it { should redirect_to(shibboleth_path) }
        it { should set_the_flash.to(I18n.t('shibboleth.create_association.invalid_credentials')) }
      end

      context "if found the user but the password is wrong goes back to /secure with an error" do
        let(:user) { FactoryGirl.create(:user) }
        before(:each) { post :create_association, :existent_account => true, :user => { :login => user.username } }
        it("finds the user") {
          User.find_first_by_auth_conditions({ :login => user.username }).should_not be_nil
        }
        it { should redirect_to(shibboleth_path) }
        it { should set_the_flash.to(I18n.t('shibboleth.create_association.invalid_credentials')) }
      end

      context "if the user is disabled goes back to /secure with an error" do
        let(:user) { FactoryGirl.create(:user, :disabled => true, :password => '12345') }
        before(:each) { post :create_association, :existent_account => true, :user => { :login => user.username, :password => '12345' } }
        it("does not find the disabled user") {
          User.find_first_by_auth_conditions({ :login => user.username }).should be_nil
        }
        it { should redirect_to(shibboleth_path) }
        it { should set_the_flash.to(I18n.t('shibboleth.create_association.invalid_credentials')) }
      end

      context "if the found the user, authenticated and it's not disabled" do
        let(:user) { FactoryGirl.create(:user, :password => '12345') }
        before {
          # the user that is trying to login has to be the same user that has variables
          # on the session, so we do this setup again
          setup_shib(user.full_name, user.email)
        }

        context "goes back to /secure with a success message" do
          before(:each) { post :create_association, :existent_account => true, :user => { :login => user.username, :password => '12345' } }
          it("finds the user") {
            User.find_first_by_auth_conditions({ :login => user.username }).should_not be_nil
          }
          it("uses the correct password") {
            User.find_first_by_auth_conditions({ :login => user.username }).valid_password?('12345').should be_true
          }
          it { should redirect_to(shibboleth_path) }
          it { should set_the_flash.to(I18n.t("shibboleth.create_association.account_associated", :email => user.email)) }
        end

        context "creates a ShibToken and associates it with the user" do
          before(:each) {
            expect {
              post :create_association, :existent_account => true, :user => { :login => user.username, :password => '12345' }
            }.to change{ ShibToken.count }.by(1)
          }
          subject { ShibToken.last }
          it("sets the user in the token") { subject.user.should eq(user) }
          it("sets the data in the token") { subject.data.should eq(@shib.get_data().to_yaml) }
        end

        context "uses the user's ShibToken if it already exists" do
          before { ShibToken.create!(:identifier => user.email) }
          before(:each) {
            expect {
              post :create_association, :existent_account => true, :user => { :login => user.username, :password => '12345' }
            }.to change{ ShibToken.count }.by(0)
          }
          subject { ShibToken.last }
          it("sets the user in the token") { subject.user.should eq(user) }
          it("sets the data in the token") { subject.data.should eq(@shib.get_data().to_yaml) }
        end

      end
    end

  end

  describe "#info" do
    before { Site.current.update_attributes(:shib_enabled => true) }

    context "assigns @data with the data in the session" do
      let(:expected) { { :one => "anything" } }
      before { controller.session[:shib_data] = expected }
      before(:each) { get :info }
      it { should assign_to(:data).with(expected) }
    end

    context "renders with no layout" do
      before(:each) { get :info }
      it { should_not render_with_layout() }
    end
  end

  private

  def setup_shib(name, email, save_to_session=true)
    request.env["Shib-inetOrgPerson-cn"] = name
    request.env["Shib-inetOrgPerson-mail"] = email
    Site.current.update_attributes(:shib_enabled => true)
    # save it to the session, as #login would do
    @shib = Mconf::Shibboleth.new(session)
    @shib.save_to_session(request.env)
  end

end
