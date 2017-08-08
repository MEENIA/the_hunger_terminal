# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  
  $(document).on "change", ".item-qty",->

    quantity = parseInt($(this).val())
    product  = $(this).parent().parent()
    
    price    = parseInt(product.find('.price').text())
    product_name  = product.find(".product-name").text()
    vendor_name   = product.find(".vendor-name").text()
    product.find(".sub-total").text(quantity * price)
    menu_item_id = product.find('.menu_item_id').text()
    order_detail_id = product.find('.order_detail_id').text() 
    order_detail = {}
    order_detail.menu_item_name = product_name
    order_detail.vendor_name  = vendor_name
    order_detail.total  = (quantity * price)
    order_detail.quantity = quantity
    order_detail.menu_item_id = menu_item_id
    order_detail.price = price
    order_detail.id = order_detail_id
    render_menu_item_detail(order_detail)

  $(document).on 'click', '.delete_new', ->  
    text=$(this).parent().parent().attr('data-menu-item-id')
    $("table").find("#"+text).find('.sub-total').text('0')
    $("table").find("#"+text).find('.item-qty').val('0')
    $(this).parent().parent().remove()
    find_total($(this).parent().parent())
  
  $(document).on 'click', '.delete', ->
    text=$(this).parent().parent().attr('data-menu-item-id')
    $("table").find("#"+text).find('.sub-total').text('0')
    $("table").find("#"+text).find('.item-qty').val('0')

    order_detail_id = $(this).parent().parent().find("#order_detail_id").val() 

    order_detail = find_order_detail_targeted(order_detail_id)
    
    order_detail = check_for_order_detail_id(order_detail)
    
    template = $("#order_detail_template").html()
    od       = Mustache.render(template, order_detail)
    # $('.order-details').append(od) 
    $(this).parent().parent().replaceWith(od)
    $(".order-details").find(".row[data-menu-item-id=#{order_detail.menu_item_id}]").hide()
    $(".order-details").find(".row[data-menu-item-id=#{order_detail.menu_item_id}]").find('.total').text(0)
    find_total($(".order-details").find(".row[data-menu-item-id=#{order_detail.menu_item_id}]"))

  
@load_orders_data = (order_details) ->
  $.each order_details, (i, order_detail) ->
    render_menu_item_detail(order_detail)

find_order_detail_targeted = (order_detail_id) ->
  od = ''
  $.each order_details, (i,order_detail) ->
    if order_detail_id == order_detail.id.toString()
      od = order_detail
  od

render_menu_item_detail = (order_detail) ->
  selected_item = $('.order-details').find('*[data-menu-item-id="'+  order_detail.menu_item_id + '"]')
  if selected_item.length
    selected_item.find('#order_detail_qty').val(order_detail.quantity)
    selected_item.find('.total').text(order_detail.quantity*order_detail.price)
    order_detail = check_for_order_detail_quantity(order_detail)
    template = $("#order_detail_template").html()
    od       = Mustache.render(template, order_detail)
    selected_item.replaceWith(od)
    $(".order-details").find(".row[data-menu-item-id=#{order_detail.menu_item_id}]").hide() if order_detail.quantity == 0
  else
    template = $("#order_detail_template").html()
    order_detail.total = order_detail.quantity * order_detail.price
    od       = Mustache.render(template, order_detail)
    $('.order-details').append(od) 
  find_total(selected_item)
  
check_for_order_detail_quantity = (order_detail) ->
  if order_detail.quantity == 0
    order_detail_id = $(".order-details").find(".row[data-menu-item-id=#{parseInt(order_detail.menu_item_id)}]").find("#order_detail_id").val()  
    if order_detail_id == ""
      $(".order-details").find(".row[data-menu-item-id=#{parseInt(order_detail.menu_item_id)}]").remove()
    else
      order_detail.destroy_order_detail_id = true
      $(".order-details").find(".row[data-menu-item-id=#{order_detail.menu_item_id}]").hide()
  else
    $(".order-details").find(".row[data-menu-item-id=#{parseInt(order_detail.menu_item_id)}]").show()
  order_detail 


check_for_order_detail_id = (order_detail) ->
  od = ''
  order_detail_id = $(".order-details").find(".row[data-menu-item-id=#{parseInt(order_detail.menu_item_id)}]").find("#order_detail_id").val()  
  if order_detail_id == ""
    $(".order-details").find(".row[data-menu-item-id=#{parseInt(order_detail.menu_item_id)}]").remove()
  else
    order_detail.destroy_order_detail_id = true
    $(".order-details").find(".row[data-menu-item-id=#{order_detail.menu_item_id}]").hide()
    od = order_detail
  od

find_total = (selected_item) ->
    sum = 0
    arr = $('.total')
    $.each arr, (key, value) ->
      num=parseInt($(value).text())
      sum += num
    tax1 = Math.round((tax/100)*sum)
    $('#tax').text(tax1)
    if (subsidy < (subsidy/100)*sum)
      $('#discount').text(subsidy)
      $('#grand_total').text(sum+tax1-subsidy)
    else
      $('#discount').text((subsidy/100)*sum)
      $('#grand_total').text(sum+tax1-(subsidy/100)*sum)
    $('#total').text(sum)
    $('#order_total_cost').val(sum+tax1)
    if sum == 0
      $('.place_order').prop("disabled", true);
      $('i').show()
    else
      $('.place_order').prop("disabled", false);
      $('i').hide()