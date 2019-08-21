class OrderProcessor
    attr_reader :order
    def initialize(order)
        @order = order
        @products = @order.products
    end
  
    def ship
      if products_available?
        @products.each do |product|
          product.reduce_inventory
        end
        @order.ship
      else
        false
      end
    end
  
    private
  
    def products_available?
      @products.each do |product|
        if product[:inventory] <= 0
          return false
        end
      end
      return true
    end
  
  end