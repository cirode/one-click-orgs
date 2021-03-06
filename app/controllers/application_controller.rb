require 'lib/one_click_orgs/setup'

require 'lib/unauthenticated'
require 'lib/not_found'

class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :ensure_set_up
  before_filter :ensure_organisation_exists
  before_filter :ensure_authenticated
  before_filter :ensure_member_active
  #before_filter :ensure_organisation_active
  before_filter :ensure_member_inducted
  before_filter :prepare_notifications
  
  # Returns the organisation corresponding to the subdomain that the current
  # request has been made on (or just returns the organisation if the app
  # is running in single organisation mode).
  helper_method :current_organisation
  def current_organisation
    @current_organisation ||= (
      if Setting[:single_organisation_mode]
        Organisation.first
      else
        Organisation.find_by_host(request.host_with_port)
      end
    )
  end
  alias :co :current_organisation
  
  helper_method :current_organisation, :co
  
  def date_format(d)
    d.to_s(:long)
  end
  
  helper_method :current_user
  def current_user
    @current_user if user_logged_in?
  end
  
  # Returns true if a user is logged in; false otherwise.
  def user_logged_in?
    current_user = @current_user
    current_user ||= session[:user] && co ? co.members.find_by_id(session[:user]) : false
    @current_user = current_user
    current_user.is_a?(Member)
  end
  
  # Stores the given user as the 'current user', thus marking them as logged in.
  def current_user=(user)
    session[:user] = (user.nil? || user.is_a?(Symbol)) ? nil : user.id
    @current_user = user
  end
  
  def store_location
    session[:return_to] = request.fullpath
  end
  
  def redirect_back_or_default(default = root_path)
    session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
    session[:return_to] = nil
  end
  
  def prepare_constitution_view
    @organisation_name = co.name
    @objectives = co.objectives
    @assets = co.assets
    @website = co.domain

    @period  = co.clauses.get_integer('voting_period')
    @voting_period = VotingPeriods.name_for_value(@period)

    @general_voting_system = co.constitution.voting_system(:general)
    @membership_voting_system = co.constitution.voting_system(:membership)
    @constitution_voting_system = co.constitution.voting_system(:constitution)
  end
  
  # Notifications
  
  def prepare_notifications
    return unless current_user
    
    # If you have a notification you want to show the user, put the
    # logic in here, and the template in shared/notifications.
    # 
    # Call show_notification_once if you only want the user to
    # see your notification once ever (e.g. a 'welcome to the
    # system' notification).
    # 
    # Call show_notification if it doesn't matter whether the user
    # has seen this notification before (e.g. a 'you have a new
    # message' notification).
    
    if co.pending? && current_user.member_class.name == "Founder"
      show_notification_once(:convener_welcome)
    end

    fop = co.found_organisation_proposals.last
    
    if co.pending? && fop && fop.closed? && !fop.accepted?
      show_notification_once(:founding_proposal_failed)
    end
    
    # Only display founding_proposal_passed notification to
    # members who were founding members
    if co.active? && fop && current_user.created_at <= fop.creation_date
      show_notification_once(:founding_proposal_passed)
    end
  end
  
  def show_notification_once(notification)
    return unless current_user
    return if current_user.has_seen_notification?(notification)
    show_notification(notification)
  end
  
  def show_notification(notification)
    @notification = notification
  end
  
  protected
  
  def ensure_set_up
    unless OneClickOrgs::Setup.complete?
      redirect_to(:controller => 'setup')
    end
  end
  
  def ensure_organisation_exists
    unless current_organisation
      redirect_to(new_organisation_url(:host => Setting[:signup_domain]))
    end
  end
  
  def ensure_authenticated
    if user_logged_in?
      true
    else
      raise Unauthenticated
    end
  end
  
  def ensure_member_active
    if current_user && !current_user.active?
      session[:user] = nil
      raise Unauthenticated
    end
  end
  
  # def ensure_organisation_active
  #   return if co.active?
  #   
  #   if co.pending?
  #     redirect_to(:controller => 'induction', :action => 'founding_meeting')
  #   else
  #     redirect_to(:controller => 'induction', :action => 'founder')
  #   end
  # end
  
  def ensure_member_inducted
    redirect_to_welcome_member if co.active? && current_user && !current_user.inducted?
  end
  
  def redirect_to_welcome_member
    redirect_to(:controller => 'welcome', :action => 'index')
  end
  
  # EXCEPTIONS
  
  rescue_from NotFound, :with => :render_404
  rescue_from ActiveRecord::RecordNotFound, :with => :render_404
  def render_404
    render :file => "#{Rails.root}/public/404.html", :status => 404, :layout => false
  end
  
  rescue_from Unauthenticated, :with => :handle_unauthenticated
  def handle_unauthenticated
    store_location
    redirect_to login_path
  end
end
