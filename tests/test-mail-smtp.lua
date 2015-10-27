--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local mail = require('mail')
require('tap')(function(test)
  test('test tap smtp client', function(expect)
    local from = "<zhaozhiguo@scanywhere.com>" -- 发件人

    -- 发送列表
    local rcpt = {
        "<zhaozhiguo@scanywhere.com>",
        "<shybt@163.com>"
    }

    local mesgt = {
        headers = {
            to = rcpt[1], -- 收件人
            cc = rcpt[2], -- 抄送
            subject = "This is Mail Title"
        },
        body = "This is  Mail Content."
    }

    r, e = mail.send({
        server="mail.scanywhere.com",
        user="zhaozhiguo@scanywhere.com",
        password="Letmein51",
        from = from,
        rcpt = rcpt,
        --source = smtp.message(mesgt)
        message = mesgt
    },function(a,b)
        assert(not a)
        assert(not b)
    end)
  end)
end)
