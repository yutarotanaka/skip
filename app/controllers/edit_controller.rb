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

class EditController < ApplicationController
  before_filter :setup_layout,
                :except => [ :ado_get_name ]
  before_filter :check_author,
                :only => [ :edit, :update, :destroy,
                           :ado_remove_image, :delete_trackback ]

  after_filter  :post_mail,   :only => [ :create, :update ]

  verify :method => :post, :only => [ :create, :update, :destroy ],
         :redirect_to => { :action => :index }

  # tab_menu
  def index
    @board_entry = BoardEntry.new
    @board_entry.entry_type = params[:entry_type] || BoardEntry::DIARY
    @board_entry.symbol = params[:symbol] || session[:user_symbol]
    @board_entry.title = params[:title]
    @board_entry.category = params[:category]

    params[:entry_type] ||= @board_entry.entry_type
    params[:symbol] ||= @board_entry.symbol

    params[:publication_type] ||= "public"
    params[:publication_symbols_value] = ""

    case params[:editor_mode] ||= "hiki"
    when "hiki"
      params[:contents_hiki] = params[:contents]
    when "richtext"
      params[:contents_richtext] = params[:contents]
    when "plaintext"
      params[:contents_plaintext] = params[:contents]
    end

    @sent_mail_flag = "checked"
  end

  # post_action
  def create
    @board_entry = BoardEntry.new(params[:board_entry])

    case @board_entry.editor_mode = params[:editor_mode]
    when "hiki"
      @board_entry.contents = params[:contents_hiki]
    when "richtext"
      @board_entry.contents = params[:contents_richtext]
    when "plaintext"
      @board_entry.contents = params[:contents_plaintext]
    end

    unless validate_params params, @board_entry
      @sent_mail_flag = "checked" if params[:sent_mail][:send_flag] == "1"
      flash[:warning] = "不正なパラメータがあります"
      render :action => 'index'
      return
    end

    @board_entry.user_id  = session[:user_id]
    @board_entry.last_updated = Time.now
    @board_entry.publication_type = params[:publication_type]
    @board_entry.publication_symbols_value = params[:publication_type]=='protected' ? params[:publication_symbols_value] : ""

    if @board_entry.save

      params[:image].each{ |key,image| upload_file(@board_entry, image) } if params[:image]

      target_symbols  = analyze_params
      target_symbols.first.each do |target_symbol|
        @board_entry.entry_publications.create(:symbol => target_symbol)
      end
      target_symbols.last.each do |target_symbol|
        @board_entry.entry_editors.create(:symbol => target_symbol)
      end

      message, new_trackbacks = @board_entry.send_trackbacks(login_user_symbols, params[:trackbacks])
      make_trackback_message(new_trackbacks)


      flash[:notice] = '正しく作成されました。' + message
      redirect_to @board_entry.get_url_hash
      return
    else
      render :action => 'index'
      return
    end

    @sent_mail_flag = "checked" if params[:sent_mail][:send_flag] == "1"
    render :action => 'index'
  end

  # link_action
  def edit
    unless check_entry_permission
      render :text => "不正な操作です"
      return false
    end

    params[:entry_type] ||= @board_entry.entry_type
    params[:symbol] ||= @board_entry.symbol

    params[:publication_type] = ""
    params[:publication_symbols_value] = ""

    params[:editor_symbols_value] = ""
    params[:editor_symbol] = false

    entry_trackbacks = EntryTrackback.find_all_by_tb_entry_id(@board_entry.id)
    params[:trackbacks] = entry_trackbacks.map{|trackback| trackback.board_entry_id }.join(',')

    if @board_entry.public?
      params[:publication_type] = "public"
      params[:publication_symbols_value] = ""
      params[:editor_symbols_value] = ""
      params[:editor_symbol]  = true if @board_entry.entry_editors.size == 1 && @board_entry.entry_editors.first.symbol == @board_entry.symbol
    elsif @board_entry.private?
        params[:publication_type] = "private"
        params[:editor_symbols_value] = ""
        params[:editor_symbol]  = true if @board_entry.entry_editors.size == 1 && @board_entry.entry_editors.first.symbol == @board_entry.symbol
    else
      params[:publication_type] = "protected"
      writer = User.find(@board_entry.user_id)
      params[:publication_symbols_value] = @board_entry.publication_symbols_value
      @board_entry.entry_editors.each do |editor|
        unless  editor.symbol == writer.symbol
          params[:editor_symbols_value] << editor.symbol
          params[:editor_symbols_value] << ","
        end
      end
      params[:editor_symbols_value] = params[:editor_symbols_value].chomp(',')
    end

    case params[:editor_mode] ||= @board_entry.editor_mode
    when "hiki"
      params[:contents_hiki] = @board_entry.contents
    when "richtext"
      params[:contents_richtext] = @board_entry.contents
    when "plaintext"
      params[:contents_plaintext] = @board_entry.contents
    end

    @img_urls = get_img_urls @board_entry

    # まだ送信していないメールが存在する場合のみ、自動で送信チェックボックスをチェックする
    login_user_symbol_type, login_user_symbol_id = Symbol.split_symbol(session[:user_symbol])
    @sent_mail_flag = "checked" if Mail.find_by_from_user_id_and_user_entry_no_and_send_flag(login_user_symbol_id, @board_entry.user_entry_no, false)
  end

  # post_acttion
  def update
    #編集の競合をチェック
    @conflicted = false
    @img_urls = get_img_urls @board_entry

    unless params[:lock_version].to_i == @board_entry.lock_version
      @conflicted = true
      flash.now[:warning] = "他の人によって同じ投稿に更新がかかっています。編集をやり直しますか？"
      @img_urls = get_img_urls @board_entry
      @sent_mail_flag = "checked" if params[:sent_mail][:send_flag] == "1"
      render :action => 'edit'
      return
    end

    unless validate_params params, @board_entry
      @sent_mail_flag = "checked" if params[:sent_mail][:send_flag] == "1"
      flash[:warning] = "不正なパラメータがあります"
      render :action => 'edit'
      return
    end

    update_params = params[:board_entry].dup

    case update_params[:editor_mode] = params[:editor_mode]
    when "hiki"
      update_params[:contents] = params[:contents_hiki]
    when "richtext"
      update_params[:contents] = params[:contents_richtext]
    when "plaintext"
      update_params[:contents] = params[:contents_plaintext]
    end

    update_params[:publication_type] = params[:publication_type]
    update_params[:publication_symbols_value] = params[:publication_type]=='protected' ? params[:publication_symbols_value] : ""


    # ちょっとした更新でなければ、last_updatedを更新する
    update_params[:last_updated] = Time.now unless params[:non_update]

    if @board_entry.update_attributes(update_params)
      params[:image].each { |key,image| upload_file(@board_entry, image) } if params[:image]

      @board_entry.entry_publications.clear
      @board_entry.entry_editors.clear
      target_symbols = analyze_params
      target_symbols.first.each do |target_symbol|
        @board_entry.entry_publications.create(:symbol => target_symbol)
      end
      target_symbols.last.each do |target_symbol|
        @board_entry.entry_editors.create(:symbol => target_symbol)
      end

      message, new_trackbacks = @board_entry.send_trackbacks(login_user_symbols, params[:trackbacks])
      make_trackback_message(new_trackbacks)

      flash[:notice] = 'エントリの更新に成功しました。' + message
      redirect_to @board_entry.get_url_hash
      return
    else
      render :action => 'edit'
      return
    end


    @sent_mail_flag = "checked" if params[:sent_mail][:send_flag] == "1"
    render :action => 'edit'
  end

  # post_action
  def destroy
    id = @board_entry.id
    user_id = @board_entry.user_id

    url = @board_entry.get_url_hash
    url[:entry_id] = nil

    if @board_entry.destroy
      FileUtils.rm(Dir.glob(File.join(get_dir_path, user_id.to_s, id.to_s + "_*.{jpg,JPG,png,PNG,jpeg,JPEG,gif,GIF}")))
      flash[:notice] = '削除しました。'
    else
      flash[:notice] = '削除に失敗しました。'
    end

    redirect_to url
  end

  def delete_trackback
    tb_entries = EntryTrackback.find_all_by_board_entry_id_and_tb_entry_id(@board_entry.id, params[:tb_entry_id])
    tb_entries.each do |tb_entry|
      tb_entry.destroy
    end

    flash[:notice] = "指定のトラックバックを削除しました"
    redirect_to @board_entry.get_url_hash
  end

  # ajax_action
  def ado_preview
    board_entry = BoardEntry.new(params[:board_entry])
    board_entry.contents = params[:contents_hiki]
    board_entry.id = params[:id]
    board_entry.user_id = session[:user_id]
    render :partial=>'board_entries/board_entry_box', :locals=>{:board_entry=>board_entry}
  end

  # ajax_action
  def ado_remove_image
    FileUtils.rm(File.join(get_dir_path, @board_entry.user_id.to_s, @board_entry.id.to_s + '_' + params[:filename]))
    img_urls = get_img_urls @board_entry
    render :partial => "board_entries/view_images", :locals=>{:img_urls=>img_urls, :board_entry_id=>@board_entry.id}
  end

private
  def setup_layout
    symbol = params[:symbol] || session[:user_symbol]

    @categories_hash =  BoardEntry.get_categories_hash(login_user_symbols, {:symbol=>symbol})
    @place, @target_url_param = BoardEntry.get_place_name_and_target_url_param symbol

    @main_menu = @title = 'ブログを書く'
    @title = 'エントリを投稿する'
    @title = 'エントリを編集する' if ["edit", "update"].include? action_name
  end

  def check_author
    begin
      @board_entry = BoardEntry.find(params[:id])
    rescue ActiveRecord::RecordNotFound => ex
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
    unless @board_entry and @board_entry.editable?(login_user_symbols, session[:user_id])
      flash[:warning] = 'その操作は許可されていません。'
      redirect_to :controller => 'mypage', :action => 'index'
      return false
    end
  end

  def analyze_params
    target_symbols_publication = []
    target_symbols_editor = []
    case params[:publication_type]
    when "public"
      target_symbols_publication << "sid:allusers"
      target_symbols_editor  << params[:editor_symbol] if (params[:entry_type] != 'DIARY' && params[:editor_symbol])
    when "private"
      target_symbols_publication << params[:board_entry][:symbol] unless params[:entry_type] == 'DIARY'
      target_symbols_editor  << params[:editor_symbol] if (params[:entry_type] != 'DIARY' && params[:editor_symbol])
      target_symbols_publication << User.find(@board_entry.user_id).symbol
    when "protected"
      target_symbols_publication = params[:publication_symbols_value].split(/,/).map {|symbol| symbol.strip }
      target_symbols_editor = params[:editor_symbols_value].split(/,/).map {|symbol| symbol.strip }
      target_symbols_publication << User.find(@board_entry.user_id).symbol
    else
      raise "パラメータが不正です"
    end
    return target_symbols_publication, target_symbols_editor
  end

  def upload_file board_entry, src_image_file
    # FIXME 以下のチェックに失敗した場合のエラー処理が全くない。
    if valid_upload_file? src_image_file
      dir_path = File.join(get_dir_path, board_entry.user_id.to_s)
      FileUtils.mkdir_p dir_path
      target_image_file_name = File.join(dir_path, @board_entry.id.to_s + '_' + src_image_file.original_filename)
      open(target_image_file_name, "w+b") do |f|
        f.write(src_image_file.read)
      end
    end
  end

  def get_img_urls board_entry
    board_entry_id = board_entry.id.to_s
    dir_path = File.join('board_entries', board_entry.user_id.to_s)
    img_urls = {}
    img_files = Dir.glob(File.join(ENV['IMAGE_PATH'], dir_path, board_entry_id.to_s + "_*"))
    img_files.each do |img_file|
      img_name = File.basename(img_file)
      img_key = img_name.gsub(board_entry_id+"_",'')
      img_urls[img_key] = url_for(:controller=>'image', :action=>'show', :path=>File.join(dir_path, img_name))
    end
    return img_urls
  end

  def get_dir_path
    File.join(ENV['IMAGE_PATH'], "board_entries")
  end

  def post_mail
    return unless @board_entry.errors.empty?
    @board_entry.cancel_mail

    if params[:sent_mail] && params[:sent_mail][:send_flag] == "1"
      @board_entry.prepare_send_mail
    end
  end

  # 独自のバリデーション（成功ならtrue）
  def validate_params params, entry
    # 公開範囲のタイプ
    unless %(public, private, protected).include? params[:publication_type]
      entry.errors.add nil, "公開範囲の指定が不正です"
    end
    # 公開範囲の値
    if params[:publication_type] == "protected" && params[:publication_symbols_value]
      unless params[:publication_symbols_value].empty?
        unless /\A[\s]*((u|g|e)id:[^,]*,)*[\s]*(u|g|e)id[^,]*\Z/ =~ params[:publication_symbols_value]
          entry.errors.add nil, "公開範囲の指定が不正です"
        end
      end
    end
    # 公開日付
    unless Date.valid_date?(eval(params[:board_entry]["date(1i)"]), eval(params[:board_entry]["date(2i)"]), eval(params[:board_entry]["date(3i)"]))
      entry.errors.add(:date, "には存在する日付を指定してください")
    end
    entry.errors.empty?
  end

  def make_trackback_message(new_trackbacks)
    new_trackbacks.each do |trackback|
      next if trackback.board_entry.user_id == session[:user_id]
      link_url = url_for(trackback.tb_entry.get_url_hash.update({:only_path => true}))
      Message.save_message("TRACKBACK", trackback.board_entry.user_id, link_url, trackback.tb_entry.title)
    end
  end
end
