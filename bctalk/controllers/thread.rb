Tweb::Bctalk.controllers :thread do

  get '/track/:tid' do
    #LogHelper.log_req(request)
    Threads.where(siteid:9, tid: params[:tid]).update(bot_tracked: 1)
    redirect "#{request.referrer}"
  end

  get '/untrack/:tid' do
    #LogHelper.log_req(request)
    Threads.where(siteid:9, tid: params[:tid]).update(bot_tracked: 0)
    redirect "#{request.referrer}"
  end

  get :index, :map => "/thread/:tid/p/:page" do
    #LogHelper.log_req(request)

    @tid=tid=params[:tid]
    @page = params[:page].to_i

    tp = Threads.first(siteid:9, tid: tid)
    @title = tp.title if tp
    @fid = tp.fid if tp

    @last_viewed = tp.last_viewed
    #binding.pry

    @pages_count =Tpages.filter(siteid:9, tid:tid).map([:page,:postcount])

    @posts = Posts.where(siteid:9,tid:tid).exclude(body: nil,body: "").reverse_order(:addeddate).extension(:pagination).paginate(@page, 20).all

    @thread_users = @posts.map{ |pp| {addeduid: pp.addeduid, addedby: pp.addedby}}
    .group_by{ |p| p[:addeduid] }.sort_by{|k,v| -v.size}.map { |k,v| [k,v.first[:addedby],v.size]  }

    @responses = tp.responses.to_i
    @url = "/bctalk/thread/#{tid}"

    #set last viewed time
    current_time = DateTime.now.new_offset(3/24.0)
    Threads.where(siteid:9, tid:tid).update(last_viewed: current_time)
    render 'index'
  end
  get :index, :map => "/rthread/:tid/p/:page" do
    #LogHelper.log_req(request)

    @tid=tid = params[:tid]
    @page = params[:page].to_i

    tp = Threads.first(siteid:9, tid: tid)
    @title = tp.title
    @fid = tp.fid

    @last_viewed = tp.last_viewed
    #binding.pry

    @pages_count =Tpages.filter(siteid:9, tid:tid).map([:page,:postcount])

    @posts = Posts.where(siteid:9, :tid => tid).order(:addeddate).extension(:pagination).paginate(@page, 20).all

    @responses = tp.responses.to_i
    @url = "/bctalk/rthread/#{tid}"

    #set last viewed time    
    render 'index'
  end

  get :by_user, :map => "/thread/:tid/by_user/:uid" do

    #LogHelper.log_req(request)
    @tid = params[:tid]

    tp = Threads.first(siteid:9, tid: @tid)

    @title = tp.title if tp
    @fid = tp.fid if tp

    @posts = Posts.where(siteid:9, tid: @tid, addeduid: params[:uid]).order(:addeddate).all #extension(:pagination).paginate(@page, 20).all
    @thread_users = Posts.where(siteid:9, tid: @tid).select(:addeduid, :addedby).all
    .group_by{ |p| p[:addeduid] }.sort_by{|k,v| -v.size}.map { |k,v| [k,v.first[:addedby],v.size]  }

    @responses = tp.responses.to_i
    @url = "/bctalk/thread/#{@tid}"
    @page = 1
    render 'index'
  end

  get :by_user_page, :map => "/thread/:tid/by_user/:uid/p/:pg" do

    #LogHelper.log_req(request)
    @tid = params[:tid]
    pg = params[:pg].to_i

    tp = Threads.first(siteid:9, tid: @tid)
    @title = tp.title if tp
    @fid = tp.fid if tp

    @posts = Posts.where(siteid:9, tid: @tid, addeduid: params[:uid]).order(:addeddate).extension(:pagination).paginate(pg, 100).all
    @thread_users = Posts.where(siteid:9, tid: @tid).select(:addeduid, :addedby).all
    .group_by{ |p| p[:addeduid] }.sort_by{|k,v| -v.size}.map { |k,v| [k,v.first[:addedby],v.size]  }

    @responses = tp.responses.to_i
    @url = "/bctalk/thread/#{@tid}"
    @page = 1
    render 'index'
  end
end
