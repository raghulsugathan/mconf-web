# -*- coding: utf-8 -*-
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

class SpacesController < ApplicationController

  before_filter :authenticate_user!, :only => [:new, :create]

  load_and_authorize_resource :find_by => :permalink, :except => [:edit_recording]
  load_resource :find_by => :permalink, :parent => true, :only => [:edit_recording]

  # all actions that render the sidebar
  before_filter :webconf_room!,
    :only => [:show, :edit, :user_permissions, :webconference,
              :recordings, :edit_recording]

  before_filter :load_spaces_examples, :only => [:new, :create]

  # TODO: cleanup the other actions adding respond_to blocks here
  respond_to :js, :only => [:index, :show]
  respond_to :html, :only => [:new, :edit, :index, :show]

  # User trying to access a space not owned or joined by him
  rescue_from CanCan::AccessDenied do |exception|
    if user_signed_in? and not [:destroy, :update].include?(exception.action)
      # Normal actions trigger a redirect to ask for membership
      flash[:error] = t("join_requests.new_join_request.message_title")
      redirect_to new_space_join_request_path :space_id => params[:id]
    else
      # Logged out users or destructive actions are redirect to the 403 error
      flash[:error] = t("space.access_forbidden")
      render :template => "/errors/error_403", :status => 403, :layout => "error"
    end
  end

  # Create recent activity
  after_filter :only => [:create, :update, :leave] do
    @space.new_activity params[:action], current_user unless @space.errors.any?
  end

  # Recent activity for join requests
  after_filter :only => [:join_request_update] do
    @space.new_activity :join, current_user unless @join_request.errors.any? || !@join_request.accepted?
  end

  def index
    #if params[:space_id] && params[:space_id] != "all" && params[:space_id] !="my" && params[:space_id] !=""
    #  redirect_to space_path(Space.find_by_permalink(params[:space_id]))
    #  return
    #end
    if params[:view].nil? or params[:view] != "list"
      params[:view] = "thumbnails"
    end
    spaces = Space.order('name ASC').all
    @spaces = spaces.paginate(:page => params[:page], :per_page => 18)

    if user_signed_in? && current_user.spaces.any?
      @user_spaces = current_user.spaces.paginate(:page => params[:page], :per_page => 18)
    else
      @user_spaces = []
    end

    if @space
       session[:current_tab] = "Spaces"
    end
    if params[:manage]
      session[:current_tab] = "Manage"
      session[:current_sub_tab] = "Spaces"
    end

    respond_with @spaces do |format|
      format.html { render :index }
      format.js {
        json = @spaces.to_json(space_to_json_hash)
        render :json => json, :callback => params[:callback]
      }
      format.xml { render :xml => @public_spaces }
    end
  end

  def show
    # news
    @news_position = params[:news_position] ? params[:news_position].to_i : 0
    @news = @space.news.order("updated_at DESC").all
    @news_position = @news.length-1 if @news_position >= @news.length
    @news_to_show = @news[@news_position]

    # posts
    posts = @space.posts.not_events
    @latest_posts = posts.where(:parent_id => nil).where('author_id is not null').order("updated_at DESC").first(3)

    # users
    @latest_users = @space.users.order("permissions.created_at DESC").first(3)

    # events
    @upcoming_events = @space.events.order("start_date ASC").select{|e| e.start_date && e.start_date.future? }.first(5)
    @current_events = @space.events.order("start_date ASC").select{|e| e.start_date && !e.start_date.future? && e.end_date.future?}

    # role of the current user
    @permission = Permission.where(:user_id => current_user, :subject_id => @space, :subject_type => 'Space').first

    respond_to do |format|
      format.html { render :layout => 'spaces_show' }
      format.js {
        json = @space.to_json(space_to_json_hash)
        render :json => json, :callback => params[:callback]
      }
    end
  end

  def new
    @space = Space.new
    respond_with @space do |format|
      format.html { render :layout => 'application' }
    end
  end

  def create
    @space = Space.new(params[:space])

    if @space.save
      respond_with @space do |format|

        # the user that created the space is always an admin
        @space.add_member!(current_user, 'Admin')
        current_user.institution.spaces << @space

        flash[:success] = t('space.created')
        format.html { redirect_to :action => "show", :id => @space  }
      end
    else
      respond_with @space do |format|
        format.html { render :new, :layout => "application" }
      end
    end
  end

  def edit
    render :layout => 'spaces_show'
  end

  def update
    unless params[:space][:bigbluebutton_room_attributes].blank?
      params[:space][:bigbluebutton_room_attributes][:id] = @space.bigbluebutton_room.id
    end

    if @space.update_attributes(space_params)
      respond_to do |format|
        if params[:space][:logo_image].present?
          format.html { redirect_to logo_images_crop_path(:model_type => 'space', :model_id => @space) }
        else
          format.html {
            flash[:success] = t('space.updated')
            redirect_to edit_space_path(@space)
          }
        end
      end
    else
      respond_to do |format|
        flash[:error] = t('error.change')
        format.html { redirect_to edit_space_path(@space) }
      end
    end
  end

  def destroy
    @space_destroy = Space.find_with_param(params[:id])
    @space_destroy.disable
    respond_to do |format|
      format.html {
        if request.referer.present? && request.referer.include?("manage") && current_user.superuser?
          flash[:notice] = t('space.disabled')
          redirect_to manage_spaces_path
        else
          flash[:notice] = t('space.deleted')
          redirect_to(spaces_path)
        end
      }
    end
  end

  def user_permissions
    @users = @space.users.order("name ASC")
    @permissions = space.permissions.sort{
      |x,y| x.user.name <=> y.user.name
    }
    @roles = Space.roles
    render :layout => 'spaces_show'
  end

  def enable
    unless @space.disabled?
      flash[:notice] = t('space.error.enabled', :name => @space.name)
      redirect_to request.referer
      return
    end

    @space.enable

    flash[:success] = t('space.enabled')
    respond_to do |format|
      format.html { redirect_to manage_spaces_path }
    end
  end

  def leave
    permission = @space.permissions.find_by_user_id(current_user)

    if permission
      permission.destroy
      respond_to do |format|
        format.html {
          flash[:success] = t('space.leave.success', :space_name => @space.name)
          if can?(:read, @space)
            redirect_to space_path(@space)
          else
            redirect_to root_path
          end
        }
      end
    else
      respond_to do |format|
        format.html { redirect_to space_path(@space) }
      end
    end
  end

  # Action used to show a webconference room of a space
  # This action is here and not in CustomBigbluebuttonRoomsController because it seems out of place
  # there, the before_filters and other methods don't really match. It's more related to spaces then
  # to webconference rooms.
  def webconference
    # FIXME: Temporarily matching users by name, should use the userID
    @webconf_attendees = []
    unless @webconf_room.attendees.nil?
      @webconf_room.attendees.each do |attendee|
        profile = Profile.find(:all, :conditions => { "full_name" => attendee.full_name }).first
        unless profile.nil?
          @webconf_attendees << profile.user
        end
      end
    end
    render :layout => 'spaces_show'
  end

  # Action used to show the recordings of a space
  # This action is here and not in CustomBigbluebuttonRoomsController because it seems out of place
  # there, the before_filters and other methods don't really match. It's more related to spaces then
  # to webconference rooms.
  def recordings
    @recordings = @webconf_room.recordings.published().order("end_time DESC")
    if params[:limit]
      @recordings = @recordings.first(params[:limit].to_i)
    end
    if params[:partial]
      render :layout => false
    else
      render :layout => 'spaces_show'
    end
  end

  # Page to edit a recording.
  def edit_recording
    # @space = Space.find_by_permalink(params[:space_id])
    @redir_url = recordings_space_path(@space.to_param) # TODO: not working, no support on bbb_rails
    @recording = BigbluebuttonRecording.find_by_recordid(params[:id])
    authorize! :space_edit, @recording
    if request.xhr?
      render :layout => false
    else
      render :layout => "spaces_show"
    end
  end

  # Finds spaces by name (params[:q]) and returns a list of selected attributes
  def select
    name = params[:q]
    limit = params[:limit] || 5   # default to 5
    limit = 50 if limit.to_i > 50 # no more than 50
    if name.nil?
      @spaces = Space.limit(limit).all
    else
      @spaces = Space.where("name like ? ", "%#{name}%").limit(limit)
    end

    respond_with @spaces do |format|
      format.json
    end
  end

  private

  def space
    if params[:action] == "enable"
      @space ||= Space.find_with_disabled_and_param(params[:id])
    else
      @space ||= Space.find_with_param(params[:id])
    end
  end

  def space_to_json_hash
    { :methods => :user_count, :include => {:logo => { :only => [:height, :width], :methods => :logo_image_path } } }
  end

  def load_spaces_examples
    # TODO: RAND() is specific for mysql
    @spaces_examples = Space.order('RAND()').limit(3)
  end

  def space_params
    unless params[:space].nil?
      params[:space].permit(*space_allowed_params)
    else
      []
    end
  end

  def space_allowed_params
    [ :name, :description, :logo_image, :public, :permalink, :repository,
      :crop_x, :crop_y, :crop_w, :crop_h,
      :bigbluebutton_room_attributes =>
        [ :id, :attendee_password, :moderator_password ] ]
  end
end
