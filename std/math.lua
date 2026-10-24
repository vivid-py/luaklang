local function sqrt(num)
  return (num ^ 0.5)
end
local function pow(num, num2)
  return (num ^ num2)
end
local function sign(num)
  if (num > 0) then
  return 1
end
  if (num < 0) then
  return (-1)
end
  if (num == 0) then
  return 0
end
end
local function is_even(num)
  if ((num % 2) == 0) then
  return true
end
  if ((num % 2) ~= 0) then
  return false
end
end
local function abs(num)
  if (num == 0) then
  return 0
end
  if (num > 0) then
  return num
end
  if (num < 0) then
  return (num * (-1))
end
end
local function add(a, b)
  return (a + b)
end
local function substract(a, b)
  return (a - b)
end
local function divide(a, b)
  return (a / b)
end
local function multiply(a, b)
  return (a * b)
end
return { sqrt = sqrt, pow = pow, sign = sign, is_even = is_even, abs = abs, add = add, substract = substract, divide = divide, multiply = multiply }