Tweb::Bctalk.controllers :forum do
  SID=9

  get :list do
    #LogHelper.log_req(request)
    @title = "BCTalk::forums"
    @forums = Forums.filter(siteid:9,check:1).all

    render 'list'
  end

  get '/manage/:fid' do |fid=nil|
    #LogHelper.log_req(request)
    @title = "BCTalk::forums"
    
    fid = params[:fid]

    if fid
      @forums = Forums.filter(siteid:SID,parent_fid:fid).order(:fid).all
    else
      @forums = Forums.filter(siteid:SID,level:0).order(:fid).all
    end
    render 'manage'
  end
    
  get :show, :with => :id do
    #LogHelper.log_req(request)
    @fid = params[:id]
    forum = Forums.first(siteid:SID, fid: @fid)
    @title = forum.title
    from = DateTime.now.new_offset(3/24.0)-13

    @topics = Threads.filter(fid:@fid, siteid:SID).reverse_order(:updated).extension(:pagination).paginate(1, 200).all
    render 'show'
  end
  
  get :max_responses, :with => :id do
    #LogHelper.log_req(request)
    @fid = params[:id]

    @hours=6
    forum = Forums.first(siteid:SID, fid: @fid)
    res=BctReport.forum_threads_with_max_answers(@fid, @hours, 40) ## fid, hours, page_size
    
    @title = forum[:title]
    @threads = res[:data]
    render 'max_resps_threads'
  end

  get '/tracking_threads' do
    #LogHelper.log_req(request)

    @title = "BCTalk::tracking"
    @topics = Threads.filter(siteid:SID,bot_tracked: 1).exclude(fid:287).order(:title).all
    render 'show'
  end

  get '/track_f/:id' do
    #LogHelper.log_req(request)
    Forums.where(siteid:SID, fid: params[:id]).update(check: 1)
    redirect "#{request.referrer}"
  end

  get '/untrack_f/:id' do
    #LogHelper.log_req(request)
    Forums.where(siteid:SID, fid: params[:id]).update(check: 0)
    redirect "#{request.referrer}"
  end

  get :max_reposnses_threads_file do
    data = BctReport.list_forum_threads_with_max_answers([67,159,240],24)
    res=[]
   
    data.each do |dd|  
      res<< dd[:title] 
      res+= dd[:data].map { |dd| "responses:#{dd[:responses]} #{dd[:url]} #{dd[:title]}"  } 
    end
   
    res.join("<br />")
  end

end
