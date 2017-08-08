  require 'csv'
class TerminalsController < ApplicationController

  load_and_authorize_resource :user
  load_and_authorize_resource :company
  
  before_action :authenticate_user!  
  before_action :load_company , except: [:edit ,:update,:download_invalid_csv]
  before_action :load_terminal, only: [:show, :update, :destroy]

  add_breadcrumb "Home", :root_path
  add_breadcrumb "Terminals", :company_terminals_path, except: [:edit, :update]
  add_breadcrumb "New Terminal", :new_company_terminal_path, only: [:new, :create]
  add_breadcrumb "Edit Terminal", :edit_terminal_path, only: [:edit, :update]
  
  def new
    @terminal = @current_company.terminals.build
    @terminal.menu_items.build  
  end
  
  def create
    @terminal = @current_company.terminals.build terminal_params
    if @terminal.save
      flash[:success] = "terminal created successfully" 
      unless params[:terminal][:CSV_menu_file].nil?
        result = MenuItemsUploadService.new(file: params[:terminal][:CSV_menu_file],terminal_id: @terminal.id, company_id: @current_company.id).upload_records
        flash[:notice] = result[:value]
        
      end
      @terminal.payable = @terminal.current_amount - @terminal.payment_made
      @terminal.save
      @terminal_report = @terminal.terminal_reports.build(name:@terminal.name, current_amount:@terminal.current_amount, 
        payment_made: @terminal.payment_made, payable: @terminal.payable)
      @terminal_report.save
      redirect_to terminal_menu_items_path(@terminal)

    else
      render :new and return
    end
  end

  def index
    if params[:search].present?
      search_type = params[:search]
      @terminals = @current_company.terminals.where(["LOWER(name) LIKE :search OR landline LIKE :search", search: "%#{params[:search].downcase}%"]).page(params[:page]).per(6)
    else
      @terminals = @current_company.terminals.order(:name).page(params[:page]).per(6)
    end
  end

  def update
    if @terminal.update_attributes(terminal_params)
      respond_to do |format|
        if request.format.js?
          flash[:success] = "payment made successfully"
          Terminal.save_last_payment_made_to_terminal(@terminal.id, current_user.company_id)
          Terminal.update_post_payment_details_of_terminal(@terminal.id, current_user.company_id)
        else
          flash[:success] = "terminal updated successfully"
          format.html {  redirect_to company_terminals_path(current_user.company_id) and return }
        end
        format.js { render inline: "location.reload();"  }
      end   
    else
      render :edit and return
    end
  end

  def download_invalid_csv 

    terminal = Terminal.find(params[:terminal_id])
    send_file("#{Rails.root}/public/#{terminal.name}-invalid_records.csv",
    type: "application/csv"
    ) 
  end

  def edit
    @terminal = Terminal.find params[:id]
  end
 
  private

  def terminal_params
    params.require(:terminal).permit(:name,:landline, :active, :email, :min_order_amount, :company_id, :image, :payment_made, :gstin, :tax)
  end

  def load_company
    @current_company = Company.find params[:company_id]
    
  end

  def load_terminal
    @terminal = Terminal.find params[:id]
  end  
end
    