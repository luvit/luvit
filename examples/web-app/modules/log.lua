return function (app)
  return function (req, res)
    app(req, function (code, headers, body)
      print(req.method .. ' ' .. req.url.path .. ' ' .. code)
      res(code, headers, body)
    end)
  end
end
