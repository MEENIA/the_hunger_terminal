require "test_helper"

class UsersControllerTest  < ActionController::TestCase

  before :each do
    @company = create :company,name: "Company1"
    @company2 = create :company,name: "Company2"
  end

  test "company admin won't be allowed to access other company's employees index" do
    sign_in_admin
    get :index, params: {company_id: @company2.id}
    assert_redirected_to vendors_url
  end

  test "company admin should only be able to access its employee index" do
    sign_in_admin
    get :index, params: {company_id: @company.id}
    assert_response :success
  end

  test "company admin won't be allowed to add employees for other company" do
    sign_in_admin
    get :new, params: {company_id: @company2.id}
    assert_redirected_to vendors_url
  end

  test "company admin should be allowed to add employees his/her company" do
    sign_in_admin
    get :new, params: {company_id: @company.id},format: 'js', xhr: true
    assert_response :success
  end

  test "company admin won't be allowed to search user records of other company" do
    sign_in_admin
    get :search, params: {company_id: @company2.id, search_value: "dummy"}
    assert_redirected_to vendors_url
  end

  test "should not render index for non logged-in admin"  do
    get :index, params: {company_id: @company.id }
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "render index for logged-in admin" do
    sign_in_admin
    get :index, params: {company_id: @company.id}
    assert_response :success
  end

  test "should get a new user" do 
    sign_in_admin
    get :new, params: {company_id: @company.id}, format: 'js', xhr: true
    assert_response :success  
  end

  test "company admin not allowed to create user for other company" do
    sign_in_admin
    assert_difference 'User.count',0 do
      post :create, params:
      {user: { name: "dummy", email: "dummy@dummysoftware.com", mobile_number: "3456789089"}, company_id: @company2.id},format: 'js', xhr: true
    end
  end

  test "should create user" do
    sign_in_admin

    assert_difference 'User.count' do
      post :create, params: 
      {user: { name: "dummy", email: "dummy@dummysoftware.com", mobile_number: "3456789089"}, company_id: @company.id},format: 'js', xhr: true
    end
  end

  test "should not create user" do
    sign_in_admin

    assert_difference 'User.count', 0 do
      post :create, params: 
      {user: { name: "", email: "", mobile_number: ""}, company_id: @company.id},format: 'js', xhr: true
    end
  end


  #While updating user, we are just changing status of user
  test "user status should be updated by that company's admin only" do
    sign_in_admin
    patch :update, params: {id: @admin.id, company_id: @company2.id, user: {is_active: 'false'}, page: "1" }
    assert_redirected_to vendors_url
  end

  test "user status should be updated by admin only" do
    sign_in_admin
    create_other_user
    patch :update, params: {id: @other_user.id, company_id: @company.id, user: {is_active: 'false'}, page: "1" }
    assert_redirected_to company_users_path(@company, page: "1")
  end

  test "should not update user status when no parameter is present" do
    sign_in_admin
    create_other_user
    assert_raises ActionController::ParameterMissing do
      patch :update, params: {id: @other_user.id, company_id: @company.id,}
    end
    assert_response :success
  end

  test "user status should not be updated by an employee" do
    sign_in_employee
    create_other_user
    patch :update, params: {id: @other_user.id, company_id: @company.id, user: {is_active: 'false'}, page: "1" }
    assert_redirected_to vendors_url
  end


  test "user records should be searched" do
    sign_in_admin
    get :search, params: {company_id: @company.id, search_value: "dummy"}
    assert_response :success
  end

  test "company admin won't not be allowed to add bulk records for other company" do
    sign_in_admin
    file_name = File.new(Rails.root.join("test/fixtures/files/invalid_employees.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')
    #This CSV file has no record
    assert_difference 'User.count', 0 do
      post :add_multiple_employee_records, params: {company_id: @company2.id, file: csv_file, commit: "Import"}
    end
  end

  test "valid bulk records should be added" do
    sign_in_admin
    file_name = File.new(Rails.root.join("test/fixtures/files/employees.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')
    #This CSV file has only one record
    assert_difference 'User.count' do 
      post :add_multiple_employee_records, params: {company_id: @company.id, file: csv_file, commit: "Import"}
    end
  end

  test "invalid bulk records should not be added" do
    sign_in_admin
    file_name = File.new(Rails.root.join("test/fixtures/files/invalid_employees.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')
    #This CSV file has no record
    assert_difference 'User.count', 0 do 
      post :add_multiple_employee_records, params: {company_id: @company.id, file: csv_file, commit: "Import"}
    end
  end

  test "should download sample file" do
    sign_in_admin
    get :download_sample_file, params: {file_type: "csv"}
    assert_response :success
  end

  test "company admin won't be allowed to see other company employee" do
    sign_in_admin
    create_other_user
    get :show, params: {id: @other_user.id, company_id: @company2.id }
    assert_redirected_to vendors_url
  end

  test "company admin should be allowed to see details of company employee" do
    sign_in_admin
    create_other_user
    get :show, params: {id: @other_user.id, company_id: @company.id }
    assert_response :success
  end

  def sign_in_admin
    @admin = @company.employees.first
    @admin.update_attribute(:role, "company_admin")
    @admin.confirm
    sign_in @admin
  end

  def sign_in_employee

   employee = @company.employees.first
   employee.update_attribute(:role, "employee")
   employee.confirm
   sign_in employee
  end

  def create_other_user
    @other_user = create(:user, company: @company)
    @other_user.update_attribute(:role, "employee")
    @company.employees << @other_user
  end

end
