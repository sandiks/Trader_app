Tweb::Bctalk.controllers :bot do

  get '/check_forums' do
    #LogHelper.log_req(request)
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_forums.rb check_forums 1"
    redirect "#{request.referrer}"
  end


  get '/check_forum/:id/pg/:pg' do
    #LogHelper.log_req(request)
    fid = params[:id]
    pg = params[:pg]
    p "bot::parse_forum_diff2 #{fid} #{pg}"
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb max_responses #{fid}" #fid page
    redirect "/bctalk/forum/show/#{fid}"
  end

  get '/max_responses/:id' do
    #LogHelper.log_req(request)
    fid = params[:id]
    p "ruby run_for_site.rb stat #{fid}"
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb max_responses #{fid}" 
    redirect "/bctalk/forum/max_responses/#{fid}"
  end
  
  get '/max_responses_list/:list' do
    #LogHelper.log_req(request)

    fid = params[:list]#.split('_')
    
    p "ruby run_for_site.rb stat #{fid}"
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb max_responses_list #{fid}" 
    redirect "/bctalk/forum/max_responses/#{fid}"
  end
  get '/calc_thread_realibility/:fid/:tid' do
    #LogHelper.log_req(request)
    fid = params[:fid]
    tid = params[:tid]
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb calc_thread #{fid} #{tid}" 
    redirect "#{request.referrer}"

  end
  get '/load_thread/:id/:hh' do
    #LogHelper.log_req(request)
    tid=params[:id]
    hours=params[:hh]

    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_for_site.rb thread #{tid} #{hours}" #bctalk.rb tid, pages_back
    #redirect "bctalk/thread/#{tid}/p/1"
    redirect "#{request.referrer}"
  end

  get '/check_tracking_threads' do 
    #LogHelper.log_req(request)
    system "cd '#{ForumHelper::CRAWLER_DIR}'; ruby run_forums.rb selected"
    redirect "#{request.referrer}"
  end

end
