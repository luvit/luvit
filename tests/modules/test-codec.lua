return function (processor, inputs)
  local outputs = {}
  local i = 0
  processor(function ()
    i = i + 1
    return inputs[i]
  end, function (value)
    outputs[#outputs + 1] = value
  end)
  return outputs
end
