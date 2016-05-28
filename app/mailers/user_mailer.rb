class UserMailer < ActionMailer::Base
  add_template_helper ActivityFeedsHelper

  default from: "\"#{APP_CONFIG['project_name']}\" <#{APP_CONFIG['do-not-reply-email']}>"
  default_url_options.merge!(protocol: 'https') if APP_CONFIG['mailer_https_url']

#  include Resque::Mailer # send email async

  def build_list_notification(build_list, user)
    set_locale user
    @user, @build_list = user, build_list

    subject = "[№ #{build_list.id}] "
    subject << (build_list.project ? build_list.project.name_with_owner : t("layout.projects.unexisted_project"))
    subject << " - #{build_list.human_status} "
    subject << I18n.t("notifications.subjects.for_arch", arch: @build_list.arch.name)
    mail(
      to:      email_with_name(user, user.email),
      subject: subject,
      from:    email_with_name(build_list.publisher || build_list.user)
    ) do |format|
      format.html
    end
  end

  def metadata_regeneration_notification(platform, user)
    set_locale user
    @user, @platform = user, platform

    subject = "[#{platform.name}] "
    subject << I18n.t("notifications.subjects.metadata_regeneration", status: I18n.t("layout.regeneration_statuses.last_regenerated_statuses.#{platform.human_regeneration_status}"))
    mail(
      to:      email_with_name(user, user.email),
      subject: subject,
      from:    email_with_name(platform.owner)
    ) do |format|
      format.html
    end
  end

  protected

  def set_locale(user)
    I18n.locale = user.language if user.language
  end

  def email_with_name(user, email = APP_CONFIG['do-not-reply-email'])
    "\"#{user.user_appeal}\" <#{email}>"
  end

  def subject_for_issue(issue, new_issue = false)
    subject = new_issue ? '' : 'Re: '
    subject << "[#{issue.project.name}] #{issue.title} (##{issue.serial_id})"
  end
end
