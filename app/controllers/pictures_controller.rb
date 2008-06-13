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

class PicturesController < ApplicationController

  def picture
    @picture = Picture.find(params[:id])
    send_data(@picture.data, :filename => @picture.name, :type => @picture.content_type, :disposition => "inline")
  end

  # プロフィール画像をファイルとして取得する。外部アプリからの利用を想定。
  def profile_image
    if user = User.find_by_uid(params['uid'])
      if picture = user.pictures.first
        send_data(picture.data, :filename => picture.name, :type => picture.content_type, :disposition => 'inline')
        return
      end
    end
    send_file "#{RAILS_ROOT}/public/images/default_picture.png", :type => 'image/png', :disposition => 'inline'
  end
end
