-- name: GetOrder :one
SELECT * FROM orders
WHERE id = $1 LIMIT 1;

-- name: ListOrders :many
SELECT * FROM orders
ORDER BY orders.id;

-- name: CreateOrder :one
INSERT INTO orders (
  productname, quantity
) VALUES (
  $1, $2
)
RETURNING id;

-- name: DeleteOrder :exec
DELETE FROM orders
WHERE id = $1;
