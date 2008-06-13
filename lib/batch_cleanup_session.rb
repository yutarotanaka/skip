# SKIP（Social Knowledge & Innovation Platform）
# Copyright (C) 2008  TIS Inc.
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
# 
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path(File.dirname(__FILE__) + "/../config/environment")

class CleanupSession < BatchBase

  def self.execute options={}
    #expireをすぎたら消す(session生成時expireはlogin_saveがあれば1ヵ月後なければ24時間後に設定)
    Session.destroy_all("expire_date <= '#{Time.now.strftime("%Y-%m-%d %H:%M")}'")
  end
end

CleanupSession.execution()
