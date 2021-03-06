require 'bitbucket_rest_api'

# API documentation:
# https://confluence.atlassian.com/display/BITBUCKET/Use+the+Bitbucket+REST+APIs

class RepoProvider::Bitbucket
  
  URL_PATTERNS = [
    /^git@bitbucket.org:(?<user>[^\/]+)\/(?<repo>.+)\.git$/,
    /^(ssh:\/\/)?git@bitbucket.org\/(?<user>[^\/]+)\/(?<repo>.+)\.git$/
  ]

  def self.get_repo url
    # find the url pattern that matches the url
    URL_PATTERNS.map{|p| p.match url }.compact.first
  end

  def issues_list opts = {}
    # get issues for this repo
    issues = bitbucket.issues.list_repo(repo['user'], repo['repo'])
    # filter closed issues if the user doesn't want all
    if not opts[:all]
      issues = issues.find_all{|i|
          'resolved' != i['status']
        }
    end
    # return issues
    format_issues( issues )
  end

  def issue_create title, content
    ret = bitbucket.issues.create( repo['user'], repo['repo'], {
      title:    title,
      content:  content
      })
    id = ret['resource_uri'].match(/[0-9]+$/)
    id && id[0].to_i || -1
  end

  def issue_delete id
    bitbucket.issues.delete( repo['user'], repo['repo'], id)
  end

  def provider
    bitbucket
  end

  private

  def format_issues is
    Array(is).map do |i|
      i['number'] = i['local_id']
      i['state'] = i['status']
      i
    end
  end

  def bitbucket
    init_bitbucket if @bitbucket.nil?
    @bitbucket
  end

  def init_bitbucket
    ot,os = oauth_consumer_key_and_secret
    # get configuration from oauth token and secret
    if( not ot.nil? and not os.nil? )
      @bitbucket = BitBucket.new client_id: ot, client_secret: os
    else
      # use login and password otherwise
      @bitbucket = BitBucket.new login: user, password: password
    end
  end

end
