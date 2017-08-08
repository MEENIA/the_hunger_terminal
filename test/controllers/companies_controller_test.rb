require "test_helper"

class CompaniesControllerTest  < ActionController::TestCase

  before :each do
    @company = create :company,name: "Company1"
    @company2 = create :company,name: "Company2"    
    @user = create :user
    @user.update_attribute(:role, "employee")
  end

  test " should get new company" do
    get :new
    assert_response :success
  end

  test "should create company" do 
    post :create, 
    params: 
      { company:
        { name: "dummy software", landline: "02472240728", 
         email: "info@dummysoftware.com", subsidy: 50, start_ordering_at: Time.parse("12 AM"),end_ordering_at: Time.parse("12:30 PM"),
         address_attributes:
          { house_no: "23A", pincode: 416415, locality:"Baner", city: "pune", state: "mh"}, 
          employees_attributes: 
          { "0" => {name: "kiran", email: "kiran@dummysoftware.com", mobile_number: "9898989898", password: "123456"} 
          } 
        } 
      }
    assert_response :redirect
    assert_redirected_to new_user_session_path
   end

  test "should not create a company" do
    post :create,
      params: 
        {company:
          { name: "", landline: "",email: "", subsidy: "",start_ordering_at: "", end_ordering_at: "", review_ordering_at: "",
            address_attributes: 
            {
              address: {house_no: "", pincode: "", locality: "",city: "",state: ""}
            },
            employees_attributes:
            {
              "0" => {name: "", email: "",mobile_number: "",password: ""}
            }
          }
        }

    assert_response :success
  end

  #For now, we are updating the values from get_order_details form
  test "company should be updated by admin only" do
    sign_in_admin
    other_user = create(:user, company: create(:company))
    other_user.company = @company
    patch :update, params: {id: @company, company:{ name: @company.name} }, company: {subsidy: 50, start_ordering_at: Time.parse("12 AM"), end_ordering_at: Time.parse("12:30 PM")}
    assert_redirected_to root_url
  end

  
  test "Company_admin should not be allowed to update the ordering information of other company" do
    sign_in_admin
    get :get_order_details, params: {id: @company2, company:{ name: "Company2"} }, company: {subsidy: -5, start_ordering_at: Time.parse("12 AM"), end_ordering_at: Time.parse("12:30 PM")}
    assert_redirected_to vendors_url
  end

  test "Ordering Information should not be updated for invalid values" do
    sign_in_admin
    get :get_order_details, params: {id: @company, company:{ name: @company.name} }, company: {subsidy: -5, start_ordering_at: Time.parse("12 AM"), end_ordering_at: Time.parse("12:30 PM")}
    assert_response :success
  end

  test "company admin can't download invalid csv file of other Company" do
    sign_in_admin
    old_controller = @controller
    @controller = UsersController.new

    file_name = File.new(Rails.root.join("test/fixtures/files/invalid_employees.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')
    post :add_multiple_employee_records, params: {company_id: @company.id, file: csv_file, commit: "Import"}
    
    @controller = old_controller
    get :download_invalid_csv, params: {id: @company2.id}
    assert_redirected_to vendors_url
  end

  test "should download invalid sample csv file" do
    sign_in_admin
    old_controller = @controller
    @controller = UsersController.new

    file_name = File.new(Rails.root.join("test/fixtures/files/invalid_employees.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')
    post :add_multiple_employee_records, params: {company_id: @company.id, file: csv_file, commit: "Import"}
    assert_response :redirect
    assert_redirected_to company_users_url(@company)

    @controller = old_controller
    get :download_invalid_csv, params: {id: @company.id}
    assert_response :success
  end

  test "company should not be updated by another company's admin" do
    sign_in_admin
    patch :update, params: {id: @company2.id, company:{name: @company2.name}}
    assert_redirected_to vendors_url
  end

  test "company should be updated by that company's admin" do
    sign_in_admin
    patch :update, params: {id: @company.id, company:{name: @company.name}}
    assert_redirected_to root_url
  end

  test "company should not be updated by an employee" do
    sign_in_employee
    company_id = @user.company.id
    company_name = @user.company.name
    patch :update, params: {id: company_id, company:{name: company_name}}, company: {name: Faker::Company.name}
    assert_redirected_to vendors_url
  end

  def sign_in_admin
    admin = @company.employees.find_by(role: "company_admin")
    admin.confirm
    sign_in admin
  end

  def sign_in_employee
   @user.confirm
   sign_in @user
  end

end