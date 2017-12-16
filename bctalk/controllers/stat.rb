Tweb::Bctalk.controllers :stat do

  get :users do
    #LogHelper.log_req(request)

    @uranks = Tweb::Bctalk.cache['s9_user_rank_map']

    from = DateTime.now.new_offset(3/24.0)-1
    today_posts = Posts.filter('siteid=? and addeddate > ?',9,from)
    .order(:addeddate).select(:addeduid, :addedby).all

    @threads = Tweb::Bctalk.cache['s9_all_threads_titles']

    @day_posts = [ today_posts ]
    @dates = [from]

    render 'users_for_week'
  end

  get :user_posts, :with => [:id, :date] do

    #LogHelper.log_req(request)

    from = DateTime.parse(params[:date])

    @threads = Tweb::Bctalk.cache['s9_all_threads_titles']
    @posts = Posts.filter('siteid=? and addeddate > ? and addeddate < ?', 9, from, from +1)
    .where(:addeduid => params[:id])
    .order(:addeddate)
    .all

    render 'user_posts'
  end

  get :users_threads, :with => [:fid] do
    #LogHelper.log_req(request)
    fid=params[:fid]

    @from=DateTime.now.new_offset(3/24.0)-0.5

    @uranks = Tweb::Bctalk.cache['s9_user_rank_map']
    @threads = Tweb::Bctalk.cache['s9_all_threads_titles']

    @posts = Posts.join(:threads, :tid=>:tid).filter('posts.siteid=? and threads.fid=? and addeddate > ? and addeddate < ?', 9, fid, @from, @from+1)
    .order(:addeddate)
    .select(:addeduid, :addedby, :addeddate, :posts__tid).all

    render 'users_threads'
  end

  get :threads_with_stars_users, :with => [:fid] do
    #LogHelper.log_req(request)
    fid=params[:fid]

    @hours = 12
    @from=DateTime.now.new_offset(0/24.0)-@hours/24.0


    @uranks = Tweb::Bctalk.cache['s9_user_rank_map']
    @threads = Tweb::Bctalk.cache['s9_all_threads_titles']

    @posts = Posts.join(:threads, :tid=>:tid).join(:users, :uid=>Sequel[:posts][:addeduid])
    .left_join(:bct_post_marks, :mid=>Sequel[:posts][:mid])
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ?  and rank>=4", 9, fid, @from))
    .order(:addeddate)
    .select(:addeduid, :addedby, :addeddate, Sequel[:posts][:tid], :rank, :mark).all

    render 'threads_with_stars_users'

  end

  get :filtered_thread_posts, :with => [:tid,:h] do
    #LogHelper.log_req(request)

    @tid=tid=params[:tid]
    h=tid=params[:h].to_i

    @from=DateTime.now.new_offset(0/24.0)-h/24.0
    @uranks = Tweb::Bctalk.cache['s9_user_rank_map']

    @threads = Tweb::Bctalk.cache['s9_all_threads_titles']
    tp = Threads.first(siteid:9, tid: @tid)
    @fid = tp.fid if tp

    @thread_posts = Posts.join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
    .left_join(:bct_post_marks, :mid=>:posts__mid)
    .filter(Sequel.lit('posts.siteid=? and threads.tid=? and addeddate > ? and rank>=1', 9, @tid, @from))
    .order(:addeddate)
    .select( :addeduid, :addedby, :addeddate, :posts__tid, :posts__mid, :body, :bct_post_marks__mark).all

    render 'filtered_thread_posts'

  end  

  get '/:fid/new_posts' do
    @hours=1
    @from=DateTime.now.new_offset(0/24.0)- @hours/24.0
    @fid=params[:fid]

    @uranks = Tweb::Bctalk.cache['s9_user_rank_map']
    @threads = Tweb::Bctalk.cache['s9_all_threads_titles']

    @posts = Posts.join(:threads, :tid=>:tid).join(:users, :uid=>:posts__addeduid)
    .left_join(:bct_post_marks, :mid=>:posts__mid)
    .filter(Sequel.lit("posts.siteid=? and threads.fid=? and addeddate > ?  and rank>=1", 9, @fid, @from))
    .order(:addeddate)
    .select(:addeduid, :addedby, :addeddate, :posts__tid, :rank, :mark).all

    render 'threads_with_stars_users'
  end

  get "/mark_post/:fid/:tid/:mid/:uid/:mark" do
    #LogHelper.log_req(request)
    #tp = Threads.first(siteid:9, tid: tid)
    fid=params[:fid]
    tid=params[:tid]
    mid=params[:mid]
    uid=params[:uid]
    mark=params[:mark].to_i
    
    if mark!=0
        rec = BctPostMarks.where(tid:tid, mid:mid, uid:uid)
        if 1 != rec.update(mark:mark, updated_at: DateTime.now.new_offset(3/24.0))
            rec.insert({fid:fid,tid:tid,mid:mid,uid:uid,mark:mark,updated_at: DateTime.now.new_offset(3/24.0)})
        end
    else
        BctPostMarks.where(tid:tid, mid:mid, uid:uid).delete
    end

  end 

end
