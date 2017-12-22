Tweb::App.controllers :forum do
  
  @pid=2
  FORUMS=[8,1,67,159]

  get :max_reposnses_threads do
    #system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb stat_all"

    data = BctReport.list_forum_threads_with_max_answers(FORUMS,8,15) ## forums, h_back, thread_size
    text =''
    data.each do |dd|  
      
      #text+= render('shared/max_resps_threads', :layout => false)
      @threads = dd[:data]
      @title = dd[:title]

      text+= partial('forum/max_resps_threads', object: @threads, title: @title)
    end

    text  
  end
  
  get :save_forum_thread_to_stat, with:[:fid] do
    fid = params[:fid]

    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb max_responses #{fid}"
    "SAVED #{fid}"
  end
  
  get :load_posts, with:[:tid] do
    tid = params[:tid]
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb load_posts #{tid}"
   
    tp = Threads.first(siteid:9, tid: tid)
    @title = tp.title if tp
   
    #.exclude(body: nil,body: "")
    @posts = Posts.where(siteid:9,tid:tid)
    .reverse_order(:addeddate).limit(20).all
    #p "load_posts size:#{@posts.size}"
    
    #render '_last_posts'
    partial('forum/last_posts', object: @posts)
    
  end

  get :max_reposnses_threads_file do
    hours_back=10
    thread_count=14
    data = BctReport.list_forum_threads_with_max_answers(FORUMS, hours_back, thread_count)
    res=[]
   
    res<<"list_forums: #{FORUMS} hours_back: #{hours_back} thread_count: #{thread_count}"
   
    data.each do |dd|  
      res<< dd[:title] 
      res+= dd[:data].map { |dd| "responses:#{dd[:responses]}   #{dd[:url]}   #{dd[:title]}"  } 
    end
   
    res.join("<br />")
  end

end
