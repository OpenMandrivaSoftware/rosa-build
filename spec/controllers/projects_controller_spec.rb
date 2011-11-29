require 'spec_helper'
require 'shared_examples/projects_controller'

describe ProjectsController do
	before(:each) do
    @project = Factory(:project)
    @another_user = Factory(:user)
    @create_params = {:project => {:name => 'pro', :unixname => 'pro2'}}
    @update_params = {:project => {:name => 'pro2', :unixname => 'pro2'}}

    platform = Factory(:platform)
    any_instance_of(Project, :collected_project_versions => ['v1.0', 'v2.0'])
    @process_build_params = {:build => {
      :arches => {Factory(:arch).id => '1'}, 
      :project_version => 'v1.0',
      :bpl => {platform.id => '1'},
      :pl => platform.id,
      :update_type => 'security'
    }}
	end

	context 'for guest' do
    it 'should not be able to perform index action' do
      get :index
      response.should redirect_to(new_user_session_path)
    end

    it 'should not be able to perform update action' do
      put :update, {:id => @project.id}.merge(@update_params)
      response.should redirect_to(new_user_session_path)
    end
  end

  context 'for admin' do
  	before(:each) do
  		@admin = Factory(:admin)
  		set_session_for(@admin)
		end

    it_should_behave_like 'be_able_to_perform_index_action'
    it_should_behave_like 'be_able_to_perform_update_action'
    it_should_behave_like 'update_collaborator_relation'

    it 'should be able to perform create action' do
      post :create, @create_params
      response.should redirect_to(project_path( Project.last.id ))
    end

    it 'should change objects count on create' do
      lambda { post :create, @create_params }.should change{ Project.count }.by(1)
    end

    it_should_behave_like 'be_able_to_fork_project'
  end

  context 'for owner user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		@project.update_attribute(:owner, @user)
  		r = @project.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'admin')
  		r.save!
		end

    it_should_behave_like 'be_able_to_perform_update_action'
    it_should_behave_like 'update_collaborator_relation'
    it_should_behave_like 'be_able_to_perform_build_action'
    it_should_behave_like 'be_able_to_perform_process_build_action'

    it 'should be able to perform destroy action' do
      delete :destroy, {:id => @project.id}
      response.should redirect_to(@project.owner)
    end

    it 'should change objects count on destroy' do
      lambda { post :create, @create_params }.should change{ Project.count }.by(-1)
    end

    it 'should not be able to fork project' do
      post :fork, :id => @project.id
      response.should redirect_to(forbidden_path)
    end
  end

  context 'for reader user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		r = @project.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'reader')
  		r.save!
		end

    it_should_behave_like 'be_able_to_perform_index_action'

    it 'should be able to perform show action' do
      get :show, :id => @project.id
      response.should render_template(:show)
    end

    it_should_behave_like 'be_able_to_fork_project'
  end

  context 'for writer user' do
  	before(:each) do
  		@user = Factory(:user)
  		set_session_for(@user)
  		r = @project.relations.build(:object_type => 'User', :object_id => @user.id, :role => 'writer')
  		r.save!
		end

    it_should_behave_like 'be_able_to_perform_update_action'
    it_should_behave_like 'update_collaborator_relation'
    it_should_behave_like 'be_able_to_perform_build_action'
    it_should_behave_like 'be_able_to_perform_process_build_action'
    it_should_behave_like 'be_able_to_fork_project'
  end
end
