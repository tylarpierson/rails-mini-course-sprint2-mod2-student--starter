Customer.create!([
  { email: "jane@example.com" },
  { email: "jason@example.com" },
  { email: "sara@example.com" },
])

Product.create!([
  { name: "Widget Part 27A",    inventory: 100, cost_cents: 100_00 },
  { name: "Complete Widget A",  inventory: 3,   cost_cents: 1_000_00 },
  { name: "Widget Assembly",    inventory: 45,  cost_cents: 900_00 },
  { name: "Widget Kit",         inventory: 123, cost_cents: 1_200_00 },
  { name: "Refurbished Widget", inventory: 39,  cost_cents: 900_00 },
])
