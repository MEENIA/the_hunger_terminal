class OrderDetail < ApplicationRecord

  validates :status, :menu_item, :order, :menu_item_name, :price, presence: true
  validates :status, inclusion: {in: ORDER_DETAIL_STATUS}
  validates :price, numericality: { greater_than: 0 }
  validates :quantity, numericality: { greater_than: 0,less_than: 11 }

  belongs_to :menu_item
  belongs_to :order, inverse_of: :order_details

  before_validation :assign_menu_item_details, if: :menu_item

  def assign_menu_item_details
    self.menu_item_name = menu_item.name
    self.price = menu_item.price  
    self.status = 'available' 
  end
end
