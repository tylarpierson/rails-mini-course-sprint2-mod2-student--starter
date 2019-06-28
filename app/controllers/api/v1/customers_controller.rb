module Api
  module V1
    class CustomersController < ApplicationController
      def index
        @customers = Customer.all
        @formatted_customers = @customers.map { |customer| format_customer(customer) }

        render json: @formatted_customers
      end

      def show
        @customer = Customer.find(params[:id])

        render json: format_customer(@customer)
      end

      def create
        @customer = Customer.new(customer_params)

        if @customer.save
          render json: @customer, status: :created, location: api_v1_customer_url(@customer)
        else
          render json: @customer.errors, status: :unprocessable_entity
        end
      end

      def update
        @customer = Customer.find(params[:id])

        if @customer.update(customer_params)
          render json: @customer, status: :created, location: api_v1_customer_url(@customer)
        else
          render json: @customer.errors, status: :unprocessable_entity
        end
      end

      def destroy
        Customer.find(params[:id]).destroy
        head :no_content
      end

      private

      def customer_params
        params.require(:customer).permit(:email)
      end

      def format_customer(customer)
        # this is a guard clause to prevent `orders` calls until we write the orders association
        return customer unless customer.respond_to?(:orders)

        {
          id: customer.id,
          email: customer.email,
          orders: customer.orders.map do
            {
              id: order.id,
              status: order.status,
            }
          end
        }
      end
    end
  end
end
