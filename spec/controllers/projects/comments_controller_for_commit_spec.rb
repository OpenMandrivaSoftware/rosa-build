# -*- encoding : utf-8 -*-
require 'spec_helper'

describe Projects::CommentsController do
  before(:each) do
    stub_symlink_methods
    @project = FactoryGirl.create(:project)
    %x(cp -Rf #{Rails.root}/spec/tests.git/* #{@project.repo.path}) # maybe FIXME ?
    @commit = @project.repo.commits.first

    @create_params = {:comment => {:body => 'I am a comment!'}, :owner_name => @project.owner.uname, :project_name => @project.name, :commit_id => @commit.id}
    @update_params = {:comment => {:body => 'updated'}, :owner_name => @project.owner.uname, :project_name => @project.name, :commit_id => @commit.id}

    any_instance_of(Project, :versions => ['v1.0', 'v2.0'])
    @comment = FactoryGirl.create(:comment, :commentable => @commit, :project => @project)
    @user = FactoryGirl.create(:user)
    @own_comment = FactoryGirl.create(:comment, :commentable => @commit, :user => @user, :project => @project)
    set_session_for(@user)
    @path = {:owner_name => @project.owner.uname, :project_name => @project.name, :commit_id => @commit.id}
    @return_path = commit_path(@project, @commit.id)
  end

  context 'for project admin user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'admin')
    end

    it_should_behave_like 'user with create comment ability'
    it_should_behave_like 'user with update stranger comment ability'
    it_should_behave_like 'user with update own comment ability'
    it_should_behave_like 'user with destroy comment ability'
    #it_should_behave_like 'user with destroy ability'
  end

  context 'for project owner user' do
    before(:each) do
      set_session_for(@project.owner)
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user with update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user with destroy comment ability'
  end

  context 'for project reader user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'reader')
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user without update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user without destroy comment ability'
  end

  context 'for project writer user' do
    before(:each) do
      @project.relations.create!(:actor_type => 'User', :actor_id => @user.id, :role => 'writer')
    end

   it_should_behave_like 'user with create comment ability'
   it_should_behave_like 'user without update stranger comment ability'
   it_should_behave_like 'user with update own comment ability'
   it_should_behave_like 'user without destroy comment ability'
  end
end
