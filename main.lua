local math = require("std.math")
print("--- Range Loop ---")
for i = 0, 5 do
  print("Iter:", i)
end
print("--- Array Loop ---")
local numbers = {10, 20, 30}
for _, num in ipairs(numbers) do
  print("Num:", num)
end
print("--- Math ---")
print("Sqrt(16):", math.sqrt(16))