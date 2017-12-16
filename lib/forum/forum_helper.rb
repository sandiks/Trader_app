# Helper methods defined here can be accessed in any controller or view in the application

module ForumHelper

  CRAWLER_DIR="/home/kilk/work/0my_ruby/Trader-app/xcrawler-bct"

  def self.thread_page_size(sid)
    page_size = [0,20,20,50,20,20,25,77,88,20,20][sid]
  end

  def self.last_thread_page(responses, page_size=50)
    return 1 if responses == 0
    page = responses/page_size+1
    page-=1 if responses % page_size ==0
    page
  end

  def self.need_dwnl_page(sid, tid, page)

    tpages = Tpages.filter(siteid:sid, tid:tid).to_hash(:page,:postcount)
    thr = Threads.first(siteid:sid, tid: tid)
    page_size = [0,20,20,50,20,20,25][sid]
    return  tpages[page]!=page_size

  end

  def self.get_site_name(sid)
    sites = ['','','rsdn','lor','gamedev', 'onln', 'sqlru']
    sites[sid]

  end

  def self.get_real_thread_url(sid, fid, tid, page=1)
    site_names = ['','','rsn','lor','gamedev', 'onln', 'sqlru','7','8','bitcointalk','4pda']

    fname = get_forum_name_for_url(fid,sid)
    fname = fid if fname.nil?

    case sid
    when 2
      "http://rsdn.org/forum/#{fname}/#{tid}.flat.#{page}"

    when 3
      pp = page>1 ? "/page#{page-1}" : ""
      "http://www.linux.org.ru/forum/#{fname}/#{tid}#{pp}"

    when 4
      pp = page>1 ? "&page=#{page}" : ""
      "http://www.gamedev.ru/#{fname}/forum/?id=#{tid}#{pp}"

    when 6
      pp = page>1 ? "-#{page}" : ""
      title=""
      "http://www.sql.ru/forum/#{tid}#{pp}#{title}"

    when 9
      pp = page>1 ? "#{page*20-20}" : "0"
      title=""
      "https://bitcointalk.org/index.php?topic=#{tid}.#{pp}"

    when 10

      if page>1
        pp = "st=#{(page-1)*30}"
        # "http://4pda.ru/forum/index.php?showforum=#{fid}&sort_key=last_post&sort_by=Z-A&prune_day=100&topicfilter=all&#{pp}"
        "http://4pda.ru/forum/index.php?showtopic=#{tid}&#{pp}"
      else
        "http://4pda.ru/forum/index.php?showtopic=#{tid}"
      end
    end

  end

  def self.get_forum_name(fid,sid=0)
    return if sid==0
    forums = Tweb::Bctalk.cache['fbot_forums']

    ff = forums.find{|f| f[:siteid]==sid && f[:fid]==fid}
    ff[:name]
  end

  def self.get_forum_name_for_url(fid,sid=0)
    return if sid==0
    forums = Tweb::Bctalk.cache['fbot_forums']

    ff = forums.find{|f| f[:siteid]==sid && f[:fid]==fid}
    if sid ==4
      fid0 = ff[:parent_fid]
      ff0 = forums.find{|f| f[:siteid]==sid && f[:fid]==fid0}
      ff0[:name] unless ff0.nil?
    else
      ff[:name] unless ff.nil?
    end
  end

  def self.get_bot_script_name(sid)
    sites = ['','','rsn','lor','gamed', 'onln', 'sqlr']
    sites[sid]

  end

  def self.get_forums_for_select
    [["rsdn",2],["lor",3],["gamedev",4],["sql.ru",6]]

  end


end
