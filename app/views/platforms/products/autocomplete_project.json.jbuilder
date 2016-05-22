json.array!(@items) do |item|
  json.id               item.id
  json.name             item.name_with_owner
end
