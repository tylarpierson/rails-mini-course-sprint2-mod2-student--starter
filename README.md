# Rails Mini Course - Sprint 2 - Module 2 - You Do (Starter)

## Setup

Clone the application and bundle install, create, migrate and seed the database

## Intro

This app is a partially completed API that will power a warehouse fulfillment client application. We have already built the customer and products portions but need to add orders and a way to associate orders with products.

Here is a breakdown of the existing data model for the application:

**`Customer`**

| attribute  | type     |
| ---------- | -------- |
| id         | integer  |
| email      | string   |
| created_at | datetime |
| updated_at | datetime |

**`Product`**

| attribute  | type     |
| ---------- | -------- |
| id         | integer  |
| name       | string   |
| cost_cents | integer  |
| inventory  | integer  |
| created_at | datetime |
| updated_at | datetime |

**`Order`**

| attribute   | type     |
| ----------- | -------- |
| id          | integer  |
| status      | string   |
| customer_id | integer  |
| created_at  | datetime |
| updated_at  | datetime |

**`OrderProduct`**

| attribute  | type     |
| ---------- | -------- |
| id         | integer  |
| order_id   | integer  |
| product_id | integer  |
| created_at | datetime |
| updated_at | datetime |

### Resources

Here is a breakdown of the existing resource API for the application:

| verb   | resource | route                                 | controller#action        | note                           |
| ------ | -------- | ------------------------------------- | ------------------------ | ------------------------------ |
| GET    | customer | /api/v1/customers                     | api/v1/customers#index   | list all customers             |
| POST   | customer | /api/v1/customers                     | api/v1/customers#create  | create a customer              |
| GET    | customer | /api/v1/customers/:id                 | api/v1/customers#show    | get a customer                 |
| PATCH  | customer | /api/v1/customers/:id                 | api/v1/customers#update  | update a customer              |
| PUT    | customer | /api/v1/customers/:id                 | api/v1/customers#update  | update a customer              |
| DELETE | customer | /api/v1/customers/:id                 | api/v1/customers#destroy | delete a customer              |
| GET    | order    | /api/v1/orders                        | api/v1/orders#index      | list all orders                |
| GET    | order    | /api/v1/customers/:customer_id/orders | api/v1/orders#index      | list all orders for a customer |
| POST   | order    | /api/v1/customers/:customer_id/orders | api/v1/orders#create     | create an order for a customer |
| GET    | order    | /api/v1/orders/:id                    | api/v1/orders#show       | get a specific order           |
| POST   | order    | /api/v1/orders/:id/ship               | api/v1/orders#ship       | ship a specific order          |
| GET    | product  | /api/v1/products                      | api/v1/products#index    | list all products              |
| GET    | product  | /api/v1/products/:id                  | api/v1/products#show     | get a specific product         |
| GET    | product  | /api/v1/orders/:order_id/products     | api/v1/products#index    | list all products for an order |
| POST   | product  | /api/v1/orders/:order_id/products     | api/v1/products#create   | add a product to an order      |

## Step One - Improve Shipment Handling

Currently, our shipment functionality in `orders#ship` merely marks an order as "shipped". It doesn't check to see if the order has already shipped, or if it has any products in it. We need to prevent shipping empty orders and shipping orders more than once.

To get started, we'll need a list of our products for an order. We'll use the same query that is used in the `products#index` action but with a different `id` from params.

```ruby
# app/controllers/api/v1/products_controller.rb
module Api
  module V1
    class ProductsController < ApplicationController
      def index
        if params[:order_id].present?
          product_ids = OrderProduct.where(order_id: params[:order_id]).pluck(:product_id)
          @products = Product.find(product_ids)
        else
          @products = Product.where("inventory > ?", 0).order(:cost)
        end

        render json: @products
      end

      ...
    end
  end
end
```

We'll add the following to the `ship` action after line 31:

```ruby
@order = Order.find(params[:id])
```

That should be enough set up to start adding our shipment business rules.

1. Inside the orders#ship controller action, create a variable named `shippable`. `shippable` will be `true` if the order is not marked as shipped *and* there is at least 1 product in the order. Otherwise, `shippable` should be `false`.
2. Make sure you implement the following response handling using the `shippable` variable and the result of `update(status: "shipped")`

   - If an order is shippable (see definition above)
     - Mark it as shipped and render the json result as we are currently doing
   - If an order is not shippable (see definition above)
     - Do not mark as shipped, and render the error below as json
     - `{ message: "There was a problem shipping your order." }`
   - If the order does not update/save correctly
     - render the error below as json
     - `{ message: "There was a problem shipping your order." }`

Be sure to commit your work at this stage before moving on, we'll be refactoring this code in the next section and want a snapshot of your work up until this point.

## Step Two - Extract Shipment Handling to Model

Now our `orders#ship` controller action is doing work that isn't the controller's responsibility. We want to keep our controllers light weight and focused on handling requests and responses by coordinating with models and views (for our API, the view is just json rendering). Ideally, the products query, `shippable` boolean, and the status update will be the model's responsibility.

1. On the `Order` model, create the following:
   - Create a `products` instance method on the order model that performs the products query and returns the list of the order's products.
   - Create a `shippable?` instance method on the order model that checks whether the order has been shipped and if there are any products.
   - Create a `ship` instance method on the order model that checks if the order is `shippable?` and marks the order as shipped; it should return `true` if both conditions pass and `false` otherwise.
2. Refactor the controller code to simply call `ship` on the model

When you are done, the `ship` controller action should look quite similar to the simple `create` controller action.

The `ship` controller action should now achieve the following:

1. Get the order
2. Call a method on it
3. If the method is successful, render a success response
4. If not, render an error response

Test your changes by shipping some orders via the API.

*Note: make sure to commit all work before moving on to the next step.*

## Step Three - Enhance Inventory Management

Currently, we are not tracking our inventory when we ship an order. We need to make sure that orders not only have products, but that we have enough inventory to satisfy those shipments. We also need to update the product inventory whenever we ship an order. This will involve interactions between products and orders that don't really fit in either model because they involve both. Instead of bloating the Order model with all this logic, we'll create an `OrderProcessor` object to manage the shipment.

1. Create an `OrderProcessor` service object in `app/services` that accepts an `order` as a param in `initialize`.
2. Initialize an `@order` instance variable.
3. Initialize a `@products` instance variable by using the `products` method on order.
4. Create a `ship` method on `OrderProcessor` where we will write our code.
5. Call `@order.ship` inside the `ship` method and replace the `@order.ship` in the controller with the call to order processor's `ship` method.

At this point we should have the same functionality as we did before. However, in order to ship, our controller is calling the service object instead of the model. Let's add some more code to track our inventory. Right now, our orders can only have a single version of each product. So, each order can at most include one of any specific product. First, we'll add some methods to our Product model to make this process cleaner.

1. Add an `available?` instance method to `Product` model that returns `true` if the inventory is greater than zero.
2. Add a `reduce_inventory` instance method to `Product` model that updates the inventory by reducing it by 1

Now back to our `OrderProcessor`

1. Create a new private instance method called `products_available?` on the order processor that:
   - Iterates through `@products` and ensures that all of them are available
2. Use `products_available?` inside of OrderProcessor's `ship` method to prevent shipping an order that can't be fulfilled because of inventory
   - If `products_available?` is `true`
     - Update all the products to reduce their inventory to account for the shipment
     - Call `ship` on `@order` and return the result of `@order.ship` from `ship`
   - If `products_available?` is `false`
     - Do not call `ship` on the order
     - Return `false` from `ship` on the processor
