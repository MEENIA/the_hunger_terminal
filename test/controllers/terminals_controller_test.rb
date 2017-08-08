require "test_helper"

class TerminalsControllerTest < ActionController::TestCase
  
  before :each do    
    @company = create :company,name: "Company1"
    @terminal = create :terminal, company: @company
    @company2 = create :company,name: "Company2"
  end

  test "company admin won't be allowed to access other company's terminal index" do
    sign_in_admin
    get :index, params: {company_id: @company2.id}
    assert_redirected_to vendors_url
  end

  test "should not render index for non logged-in admin"  do
    get :index, params: {company_id: @company.id }
    assert_response :redirect
  end

  test "render index for logged-in admin" do
    sign_in_admin
    get :index, params: {company_id: @company.id}
    assert_response :success
  end

  test "company admin won't be allowed to add terminals for other company" do
    sign_in_admin
    get :new, params: {company_id: @company2.id}
    assert_redirected_to vendors_url
  end

  test "should get new" do
    sign_in_admin
    get :new, params: {company_id: @company.id}
    assert_response :success  
  end

  test "company admin won't be allowed to create terminals for other company" do
    sign_in_admin
    assert_difference 'Terminal.count',0 do
      post :create, params:
      {terminal: { name: "kfc", email: "info@kfc.com", landline: "03456789089", payment_made: 0.0, min_order_amount: 50,tax: "",gstin: ""}, company_id: @company2.id}
    end
  end

  test "should create terminal without uploading menu items" do
    sign_in_admin
    assert_difference 'Terminal.count' do
      post :create, params: 
      {terminal: { name: "kfc", email: "info@kfc.com", landline: "03456789089", payment_made: 0.0, min_order_amount: 50,tax: "",gstin: ""}, company_id: @company.id}
    end
  end

  test "should create terminal without gstin" do
    sign_in_admin

    assert_difference 'Terminal.count' do
      post :create, params: 
      {terminal: { name: "kfc", email: "info@kfc.com", landline: "03456789089", payment_made: 0.0, min_order_amount: 50,tax: "",gstin: ""}, company_id: @company.id}
    end
  end

  test "should create terminal without tax but with proper gstin" do
    sign_in_admin
    assert_difference 'Terminal.count' do
      post :create, params: 
      {terminal: { name: "kfc", email: "info@kfc.com", landline: "03456789089", payment_made: 0.0, min_order_amount: 50,tax: "",gstin: "11ASDEW1245Z1Z6"}, company_id: @company.id}
    end
  end

  test "should create terminal with uploading menu items" do
    sign_in_admin
    file_name = File.new(Rails.root.join("test/fixtures/files/menu.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')

    assert_difference 'Terminal.count' do
      post :create, params: 
      {terminal: { name: "kfc", email: "info@kfc.com", landline: "03456789089", payment_made: 0.0, min_order_amount: 50,tax: "", gstin: "", CSV_menu_file: csv_file}, company_id: @company.id}
    end
  end

  test "should not create terminal" do
    sign_in_admin
    assert_difference 'Terminal.count', 0 do
      post :create, params: 
      {terminal: { name: "", email: "", landline: "", payment_made: 0.0, min_order_amount: 50,tax: 0}, company_id: @company.id}
    end
  end

  test "edit" do
    sign_in_admin
    get :edit, params: {id: @terminal.id}
    assert_response :success
    assert_template :edit
  end

  test "should update" do
    sign_in_admin
    patch :update, params:
     {terminal: { name: "kfc", email: "info@kfc.com", landline: "03456789089", payment_made: 0.0, min_order_amount: 50,tax: 0}, id: @terminal.id}
    assert_response :redirect
    assert_redirected_to company_terminals_url(@company)
  end

  test "should download invalid sample csv file" do
    sign_in_admin
    old_controller = @controller
    @controller = MenuItemsController.new

    file_name = File.new(Rails.root.join("test/fixtures/files/menu_invalid.csv"))
    csv_file = Rack::Test::UploadedFile.new(file_name, 'text/csv')
    post :import, params: {file: csv_file, terminal_id: @terminal.id}
    assert_redirected_to terminal_menu_items_url(@terminal)

    @controller = old_controller
    get :download_invalid_csv, params: {terminal_id: @terminal.id}
    assert_response :success
  end

  test "should not update for invalid record" do
    sign_in_admin
    patch :update, params:
     {terminal: { name: "", email: "", landline: "", payment_made: 0.0, min_order_amount: 50,tax: 0}, id: @terminal.id}
    assert_response :success
  end


  test "terminal records should be searched" do
    sign_in_admin
    get :index, params: {company_id: @company.id, search: "dummy"}
    assert_response :success
  end

  def sign_in_admin
    admin = @company.employees.find_by(role: "company_admin")
    admin.confirm
    sign_in admin
  end

end
